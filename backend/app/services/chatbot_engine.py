"""Transport-neutral school workflow; Flutter only renders its responses."""
import json
import uuid
from app.services.database import Database

MENU = [("child_info", "Child Information"), ("attendance", "Attendance"), ("homework", "Homework"), ("results", "Exam Results"), ("fees", "Fee Information"), ("transport", "Transport Information"), ("school_info", "School Information"), ("agent", "Talk to an Agent")]
STUDENT_SERVICES = {"child_info", "attendance", "homework", "results", "fees", "transport"}
RELATED_OPTIONS = {
    "child_info": [("attendance", "Attendance"), ("homework", "Homework"), ("menu", "Main Menu")],
    "attendance": [("details", "Show details"), ("homework", "Homework"), ("menu", "Main Menu")],
    "homework": [("attendance", "Attendance"), ("fees", "Fee Information"), ("menu", "Main Menu")],
    "results": [("homework", "Homework"), ("fees", "Fee Information"), ("menu", "Main Menu")],
    "fees": [("transport", "Transport"), ("homework", "Homework"), ("menu", "Main Menu")],
    "transport": [("fees", "Fee Information"), ("attendance", "Attendance"), ("menu", "Main Menu")],
}

class ChatbotEngine:
    def __init__(self, database: Database) -> None: self.database = database
    async def process_message(self, organization_id: str, session_id: str, text: str) -> dict:
        org = await self.database.organization(organization_id)
        if not org: raise ValueError("Unknown organization")
        c, created = await self.database.get_or_create_conversation(organization_id, session_id)
        await self.database.add_message(c["id"], "USER", text)
        if c["state"] == "INTERVENED": return await self._reply(c, "A school representative is handling this conversation.")
        if c["state"] == "ATTENDED": return await self._reply(c, "This conversation has been attended. Please send a new message if you need further school assistance.")
        workflow, normalized = json.loads(org["workflow_json"]), text.lower().strip()
        if any(p in normalized for p in workflow.get("agent_phrases", [])) or normalized in {"agent", "talk to an agent"}:
            await self.database.update_conversation(c["id"], "WAITING_FOR_AGENT", "AGENT_REQUESTED"); c["state"]="WAITING_FOR_AGENT"
            return await self._reply(c, "I can connect you with a school representative. Please wait while your request is forwarded to the school team.", agent=True)
        if created or normalized in {"hello", "hi", "hey", "start", "menu", "main menu"}:
            await self.database.update_conversation(c["id"], "BOT_ACTIVE", "MAIN_MENU")
            return await self._reply(c, f"Welcome to {org['name']}. I am the school's virtual assistant. How may I assist you today?", MENU)
        state = c["workflow_state"]
        if state.startswith("SELECT_"):
            service, student = state.removeprefix("SELECT_").lower(), await self.database.child(session_id, text)
            return await self._student_response(c, student, service) if student else await self._select_child(c, session_id, service)
        if state.startswith("ATTENDANCE_DETAIL_") and ("detail" in normalized or "show" in normalized):
            student=await self.database.child(session_id,state.removeprefix("ATTENDANCE_DETAIL_"))
            if student:return await self._attendance(c,student,True)
        intent = self._intent(normalized)
        if intent in STUDENT_SERVICES:return await self._select_child(c,session_id,intent)
        if intent == "school_info":return await self._school_information(c,org,workflow)
        if intent == "schedule":return await self._schedule(c,session_id)
        return await self._reply(c,"I'm sorry, I don't have enough information to answer that. You can choose a school service or request assistance from a school representative.",[("menu","Main Menu"),("agent","Talk to an Agent")])

    def _intent(self,text:str)->str:
        groups={"attendance":["attendance","absent"],"homework":["homework","assignment"],"results":["result","marks","performance"],"fees":["fee","payment","balance"],"transport":["transport","bus","pickup"],"child_info":["child information","student information","student details"],"schedule":["exam","examination","schedule"],"school_info":["school information","timing","office","address","contact","services"]}
        return next((key for key,words in groups.items() if any(w in text for w in words)),"")
    async def _select_child(self,c:dict,user:str,service:str)->dict:
        children=await self.database.children(user)
        if not children:return await self._reply(c,"We do not have a student record linked to this contact number.\n\nPlease verify the registered mobile number or contact the school office.",[("menu","Main Menu"),("agent","Talk to an Agent")])
        await self.database.update_conversation(c["id"],"BOT_ACTIVE",f"SELECT_{service.upper()}")
        return await self._reply(c,"Please select the child whose information you would like to view.",[(x["id"],x["name"]) for x in children])
    async def _student_response(self,c:dict,s:dict,service:str)->dict:
        return await {"child_info":self._child_information,"attendance":self._attendance,"homework":self._homework,"results":self._results,"fees":self._fees,"transport":self._transport}[service](c,s)
    async def _child_information(self,c:dict,s:dict)->dict:
        await self.database.update_conversation(c["id"],"BOT_ACTIVE","MAIN_MENU")
        return await self._reply(c,f"Student Information\n\nName: {s['name']}\nStudent ID: {s['student_code']}\nDate of birth: {s['date_of_birth']}\nGender: {s['gender']}\nClass: {s['class_name']}{' — '+s['stream'] if s['stream'] else ''}\nSection: {s['section_name']}\nRoll No.: {s['roll_no']}\nClass Teacher: {s['teacher_name']}",RELATED_OPTIONS['child_info'])
    async def _attendance(self,c:dict,s:dict,detailed:bool=False)->dict:
        records=await self.database.records("SELECT date,status FROM attendance WHERE student_id=? ORDER BY date",(s["id"],)); total=len(records); present=sum(r["status"]=="Present" for r in records); absent=total-present
        if not total:return await self._reply(c,"Attendance information is not available for this student.",RELATED_OPTIONS['attendance'])
        pct=round(present*100/total);await self.database.update_conversation(c["id"],"BOT_ACTIVE",f"ATTENDANCE_DETAIL_{s['id']}")
        if detailed: text=f"Attendance Summary\n\nStudent: {s['name']}\nPresent: {present} days\nAbsent: {absent} days\nAttendance: {pct}%\n\nRecent absences:\n"+'\n'.join(f"• {r['date']}" for r in records if r['status']=='Absent')
        else:text=f"According to our school records, {s['name']}'s attendance is {pct}%.\n\nPresent: {present} days\nAbsent: {absent} days"
        return await self._reply(c,text,RELATED_OPTIONS['attendance'])
    async def _homework(self,c:dict,s:dict)->dict:
        rows=await self.database.records("SELECT subject,detail FROM homework WHERE class_id=? AND section_id=?",(s['class_id'],s['section_id']));await self.database.update_conversation(c['id'],'BOT_ACTIVE','MAIN_MENU')
        if not rows:return await self._reply(c,"Homework information is not available for this class and section.",RELATED_OPTIONS['homework'])
        return await self._reply(c,f"Homework for {s['class_name']} — Section {s['section_name']}\n\n"+'\n\n'.join(f"{r['subject']}:\n{r['detail']}" for r in rows),RELATED_OPTIONS['homework'])
    async def _results(self,c:dict,s:dict)->dict:
        rows=await self.database.records("SELECT e.name exam_name,m.marks_obtained,m.max_marks,sc.subject FROM marks m JOIN exam_schedules sc ON sc.id=m.schedule_id JOIN exams e ON e.id=sc.exam_id WHERE m.student_id=?",(s['id'],));await self.database.update_conversation(c['id'],'BOT_ACTIVE','MAIN_MENU')
        if not rows:return await self._reply(c,"Examination results are not available for this student.",RELATED_OPTIONS['results'])
        total,maximum=sum(r['marks_obtained'] for r in rows),sum(r['max_marks'] for r in rows);return await self._reply(c,f"{rows[0]['exam_name']} Results\n\n"+'\n'.join(f"{r['subject']}: {r['marks_obtained']}/{r['max_marks']}" for r in rows)+f"\n\nOverall Performance: {total*100/maximum:.1f}%",RELATED_OPTIONS['results'])
    async def _fees(self,c:dict,s:dict)->dict:
        rows=await self.database.records("SELECT * FROM fees WHERE student_id=?",(s['id'],));await self.database.update_conversation(c['id'],'BOT_ACTIVE','MAIN_MENU')
        if not rows:return await self._reply(c,"School fee information is not available for this student.",[("menu","Main Menu")])
        r=rows[0];return await self._reply(c,f"Fee Information\n\nAcademic Year: {r['academic_year']}\nTotal Fee: ₹{r['total_fee']:,}\nPaid: ₹{r['paid_amount']:,}\nPending: ₹{r['pending_amount']:,}\n\nStatus: {r['status']}",RELATED_OPTIONS['fees'])
    async def _transport(self,c:dict,s:dict)->dict:
        rows=await self.database.records("SELECT * FROM transport WHERE student_id=?",(s['id'],));await self.database.update_conversation(c['id'],'BOT_ACTIVE','MAIN_MENU')
        if not rows:return await self._reply(c,"Transport information is not available for this student.",[("menu","Main Menu")])
        r=rows[0];return await self._reply(c,f"Transport Information\n\nRoute: {r['route_no']}\nPickup Point: {r['pickup_point']}\nTransport Fee: ₹{r['transport_fee']:,}\nStatus: {r['status']}",RELATED_OPTIONS['transport'])
    async def _school_information(self,c:dict,org:dict,w:dict)->dict:
        x=w.get('school_info',{});await self.database.update_conversation(c['id'],'BOT_ACTIVE','MAIN_MENU');return await self._reply(c,f"School Information\n\nSchool: {org['name']}\nClasses: KG – Grade 12\nOffice Hours: {x.get('office_hours','Information unavailable')}\nAddress: {x.get('address','Information unavailable')}\n{x.get('contact','')}",[("menu","Main Menu")])
    async def _schedule(self,c:dict,user:str)->dict:
        children=await self.database.children(user)
        if not children:return await self._reply(c,"Examination schedule information is unavailable.")
        s=children[0];rows=await self.database.records("SELECT sc.* FROM exam_schedules sc JOIN exams e ON e.id=sc.exam_id WHERE e.class_id=?",(s['class_id'],))
        if not rows:return await self._reply(c,"The examination schedule is not available for this class.")
        return await self._reply(c,f"Examination Schedule for {s['class_name']}\n\n"+'\n'.join(f"{r['subject']}: {r['exam_date']}, {r['start_time']} – {r['end_time']}, Room {r['room_no']}" for r in rows),[("menu","Main Menu")])
    async def _reply(self,c:dict,text:str,options:list=(),agent:bool=False)->dict:
        data=[{'id':x[0],'label':x[1]} for x in options];await self.database.add_message(c['id'],'BOT',text,'OPTION' if data else 'TEXT',{'options':data});return {'conversation_id':c['id'],'message':text,'options':data,'conversation_state':c['state'],'agent_required':agent}
