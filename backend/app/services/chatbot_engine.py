"""School chatbot conversation engine for ABC International School."""
import json
import uuid
from typing import Optional
from app.services.database import Database

ROOT_MENU = [
    ("admission", "Admission Enquiry"),
    ("student_portal", "Student Portal"),
    ("school_info", "School Info"),
    ("others", "Others"),
]

STUDENT_PORTAL_MENU = [
    ("info", "Info"),
    ("timetable", "Timetable"),
    ("attendance", "Attendance"),
    ("fees", "Fees"),
    ("events", "Events"),
    ("transport", "Transport"),
    ("exam", "Exam"),
    ("others", "Others"),
    ("back_root", "Back"),
]

EXAM_MENU = [
    ("exam_schedule", "Exam Schedule"),
    ("exam_results", "Exam Results"),
    ("back_student_portal", "Back"),
]

SCHOOL_INFO_MENU = [
    ("school_more_info", "More Info"),
    ("visit_school_website", "Visit Website"),
    ("back_root", "Back"),
]

ADMISSION_MENU = [
    ("visit_admission_form", "Visit Admission Form"),
    ("back_root", "Back"),
]

class ChatbotEngine:
    def __init__(self, database: Database) -> None:
        self.database = database

    def _parse_state(self, workflow_state: str) -> tuple[str, str, int]:
        parts = (workflow_state or "MAIN_MENU").split(":")
        state = parts[0]
        child_id = parts[1] if len(parts) > 1 else ""
        unresolved_count = int(parts[2]) if len(parts) > 2 and parts[2].isdigit() else 0
        return state, child_id, unresolved_count

    def _build_state(self, state: str, child_id: str = "", unresolved_count: int = 0) -> str:
        return f"{state}:{child_id}:{unresolved_count}"

    async def process_message(self, organization_id: str, session_id: str, text: str) -> dict:
        org = await self.database.organization(organization_id)
        if not org:
            raise ValueError("Unknown organization")

        c, created = await self.database.get_or_create_conversation(organization_id, session_id)
        await self.database.add_message(c["id"], "USER", text)

        if c["state"] == "INTERVENED":
            return await self._reply(c, "A school representative is handling this conversation.")
        if c["state"] == "ATTENDED":
            return await self._reply(c, "This conversation has been attended. Please send a new message if you need further school assistance.")

        workflow = json.loads(org.get("workflow_json") or "{}")
        normalized = text.lower().strip()
        current_state, active_child_id, unresolved_count = self._parse_state(c.get("workflow_state", ""))

        # 1. Direct Agent Escalation Request
        if any(p in normalized for p in workflow.get("agent_phrases", [])) or normalized in {"agent", "talk to an agent", "human", "representative"}:
            await self.database.update_conversation(c["id"], "WAITING_FOR_AGENT", self._build_state("AGENT_REQUESTED", active_child_id, unresolved_count))
            c["state"] = "WAITING_FOR_AGENT"
            return await self._reply(
                c,
                "We're sorry we couldn't resolve your request here.\nWe will connect you with a school representative soon. Please wait while your request is forwarded.",
                agent=True
            )

        # 2. Greeting / Start / Welcome Flow
        greetings = {"hi", "hello", "hey", "good morning", "good afternoon", "good evening", "start", "menu", "main menu"}
        if created or normalized in greetings:
            return await self._show_root_menu(c, active_child_id, org)

        # 3. Back Button Navigation
        if normalized == "back":
            if current_state in {"EXAM_MENU", "EXAM_SCHEDULE", "EXAM_RESULTS"}:
                return await self._show_student_portal(c, session_id, active_child_id)
            if current_state in {
                "STUDENT_INFO",
                "STUDENT_TIMETABLE",
                "STUDENT_ATTENDANCE",
                "STUDENT_FEES",
                "STUDENT_EVENTS",
                "STUDENT_TRANSPORT",
            }:
                return await self._show_student_portal(c, session_id, active_child_id)
            return await self._show_root_menu(c, active_child_id, org)
        if normalized == "back_root":
            return await self._show_root_menu(c, active_child_id, org)
        if normalized == "back_student_portal":
            return await self._show_student_portal(c, session_id, active_child_id)
        if normalized == "back_exam":
            return await self._show_exam_menu(c, active_child_id)
        if normalized == "back_school_info":
            return await self._show_school_info(c, org)
        if normalized == "back_admission":
            return await self._show_admission_enquiry(c)

        # 4. Handle Child Selection State
        if current_state == "SELECT_CHILD":
            student = await self.database.child(session_id, text)
            if student:
                active_child_id = student["id"]
                return await self._show_student_portal(c, session_id, active_child_id)
            else:
                return await self._select_child(c, session_id)

        # 5. Intent Matching
        intent = self._intent(normalized) or normalized

        # --- Admission Enquiry ---
        if intent in {"admission", "admission enquiry", "admission_enquiry"}:
            return await self._show_admission_enquiry(c, active_child_id)

        if intent in {"visit_admission_form", "visit admission form"}:
            await self.database.update_conversation(c["id"], "BOT_ACTIVE", self._build_state("ADMISSION", active_child_id, 0))
            url = workflow.get("admission_url") or "https://www.abcschool.edu/admissions"
            return await self._reply(
                c,
                f"For admission-related enquiries, you can visit our official admission form here:\n{url}",
                [("back_admission", "Back")]
            )

        # --- Student Portal ---
        if intent in {"student_portal", "student portal"}:
            return await self._show_student_portal(c, session_id, active_child_id)

        if intent in {"info", "child_info", "student info"}:
            return await self._show_student_info(c, session_id, active_child_id)

        if intent in {"timetable", "class schedule"}:
            return await self._show_timetable(c, session_id, active_child_id)

        if intent in {"attendance"}:
            return await self._show_attendance(c, session_id, active_child_id, detailed=False)

        if intent in {"attendance_details", "show details", "attendance details"}:
            return await self._show_attendance(c, session_id, active_child_id, detailed=True)

        if intent in {"fees", "fee information"}:
            return await self._show_fees(c, session_id, active_child_id)

        if intent in {"events", "upcoming events"}:
            return await self._show_events(c, session_id, active_child_id)

        if intent in {"transport", "transport information"}:
            return await self._show_transport(c, session_id, active_child_id)

        if intent in {"exam"}:
            return await self._show_exam_menu(c, active_child_id)

        if intent in {"exam_schedule", "exam schedule"}:
            return await self._show_exam_schedule(c, session_id, active_child_id)

        if intent in {"exam_results", "exam results", "results", "marks"}:
            return await self._show_exam_results(c, session_id, active_child_id)

        # --- School Info ---
        if intent in {"school_info", "school info", "school information"}:
            return await self._show_school_info(c, org)

        if intent in {"school_more_info", "more info", "more information"}:
            return await self._show_school_more_info(c, org, workflow)

        if intent in {"visit_school_website", "visit website"}:
            url = workflow.get("website_url") or "https://www.abcschool.edu"
            await self.database.update_conversation(c["id"], "BOT_ACTIVE", self._build_state("SCHOOL_INFO", active_child_id, 0))
            return await self._reply(
                c,
                f"You can visit our official school website at:\n{url}",
                [("back_school_info", "Back")]
            )

        # --- Others ---
        if intent in {"others", "other"}:
            await self.database.update_conversation(c["id"], "BOT_ACTIVE", self._build_state("AWAITING_OTHERS_TEXT", active_child_id, unresolved_count))
            return await self._reply(
                c,
                "Please tell us what you would like help with.",
                []
            )

        # 6. Fallback / Unresolved Request Handling
        return await self._handle_unresolved_fallback(c, active_child_id, unresolved_count)

    def _intent(self, text: str) -> str:
        exact_map = {
            "admission enquiry": "admission",
            "admission": "admission",
            "student portal": "student_portal",
            "school info": "school_info",
            "school information": "school_info",
            "info": "info",
            "timetable": "timetable",
            "attendance": "attendance",
            "fees": "fees",
            "events": "events",
            "transport": "transport",
            "exam": "exam",
            "exam schedule": "exam_schedule",
            "exam results": "exam_results",
            "others": "others",
            "more info": "school_more_info",
            "visit website": "visit_school_website",
            "visit admission form": "visit_admission_form",
        }
        if text in exact_map:
            return exact_map[text]

        groups = [
            ("school_more_info", ["more info", "more information"]),
            ("visit_school_website", ["visit website"]),
            ("visit_admission_form", ["visit admission form", "admission form"]),
            ("school_info", ["school info", "school information", "about school"]),
            ("exam_schedule", ["exam schedule", "datesheet", "examination schedule"]),
            ("exam_results", ["exam results", "exam result"]),
            ("admission", ["admission enquiry", "admission", "apply", "enroll"]),
            ("student_portal", ["student portal"]),
            ("info", ["child information", "student information", "info", "details"]),
            ("timetable", ["timetable", "class schedule", "routine"]),
            ("attendance", ["attendance", "absent", "present"]),
            ("fees", ["fee information", "fees", "fee", "payment", "due", "balance"]),
            ("events", ["upcoming events", "events", "event", "sports day", "ptm"]),
            ("transport", ["transport information", "transport", "bus", "pickup", "route"]),
            ("exam", ["exam", "examination"]),
            ("others", ["others", "other"]),
        ]
        for key, words in groups:
            if any(w == text or (len(w) > 3 and w in text) for w in words):
                return key
        return ""

    async def _show_root_menu(self, c: dict, active_child_id: str = "", org: Optional[dict] = None) -> dict:
        org_name = org.get("name", "ABC International School") if org else "ABC International School"
        await self.database.update_conversation(c["id"], "BOT_ACTIVE", self._build_state("MAIN_MENU", active_child_id, 0))
        return await self._reply(
            c,
            f"Welcome to {org_name} 👋\nHow can we help you today?",
            ROOT_MENU
        )

    async def _show_admission_enquiry(self, c: dict, active_child_id: str = "") -> dict:
        await self.database.update_conversation(c["id"], "BOT_ACTIVE", self._build_state("ADMISSION", active_child_id, 0))
        return await self._reply(
            c,
            "For admission-related enquiries, you can visit our admission form through the school website.",
            ADMISSION_MENU
        )

    async def _show_student_portal(self, c: dict, session_id: str, active_child_id: str = "") -> dict:
        children = await self.database.children(session_id)
        if not children:
            await self.database.update_conversation(c["id"], "BOT_ACTIVE", self._build_state("STUDENT_PORTAL", "", 0))
            return await self._reply(
                c,
                "What would you like to know about the student?\n\n"
                "According to our school records, we do not have a student record linked to this contact number.",
                STUDENT_PORTAL_MENU
            )

        if len(children) > 1 and not active_child_id:
            await self.database.update_conversation(c["id"], "BOT_ACTIVE", self._build_state("SELECT_CHILD", "", 0))
            return await self._reply(
                c,
                "Please select the child whose information you would like to view",
                [(x["id"], x["name"]) for x in children] + [("back_root", "Back")]
            )

        child_id = active_child_id if active_child_id else children[0]["id"]
        await self.database.update_conversation(c["id"], "BOT_ACTIVE", self._build_state("STUDENT_PORTAL", child_id, 0))
        return await self._reply(
            c,
            "What would you like to know about the student?",
            STUDENT_PORTAL_MENU
        )

    async def _select_child(self, c: dict, user: str) -> dict:
        children = await self.database.children(user)
        if not children:
            await self.database.update_conversation(c["id"], "BOT_ACTIVE", self._build_state("STUDENT_PORTAL", "", 0))
            return await self._reply(
                c,
                "According to our school records, we do not have a student record linked to this contact number.\n\nPlease verify your registered mobile number or contact the school office.",
                [("others", "Others"), ("back_root", "Back")]
            )
        await self.database.update_conversation(c["id"], "BOT_ACTIVE", self._build_state("SELECT_CHILD", "", 0))
        return await self._reply(
            c,
            "Please select the child whose information you would like to view",
            [(x["id"], x["name"]) for x in children] + [("back_root", "Back")]
        )

    async def _show_student_info(self, c: dict, session_id: str, child_id: str) -> dict:
        student = await self.database.child(session_id, child_id) if child_id else None
        if not student:
            children = await self.database.children(session_id)
            if children:
                student = children[0]
                child_id = student["id"]

        if not student:
            return await self._show_student_portal(c, session_id, child_id)

        await self.database.update_conversation(c["id"], "BOT_ACTIVE", self._build_state("STUDENT_INFO", child_id, 0))
        text = (
            f"Student Information\n\n"
            f"Name: {student['name']}\n"
            f"Class: {student['class_name']}{' — ' + student['stream'] if student.get('stream') else ''}\n"
            f"Roll No.: {student['roll_no']}\n"
            f"Class Teacher: {student['teacher_name']}"
        )
        return await self._reply(c, text, [("back_student_portal", "Back")])

    async def _show_timetable(self, c: dict, session_id: str, child_id: str) -> dict:
        student = await self.database.child(session_id, child_id) if child_id else None
        if not student:
            children = await self.database.children(session_id)
            if children:
                student = children[0]
                child_id = student["id"]

        await self.database.update_conversation(c["id"], "BOT_ACTIVE", self._build_state("STUDENT_TIMETABLE", child_id, 0))
        if student:
            text = (
                f"Today's Timetable for {student['class_name']}\n\n"
                f"• 08:30 — Mathematics\n"
                f"• 09:20 — English\n"
                f"• 10:10 — Science\n"
                f"• 11:15 — Social Studies\n"
                f"• 12:05 — Computer Science"
            )
        else:
            text = "Timetable information is currently unavailable. Please try again later or select Others to request assistance."

        return await self._reply(c, text, [("back_student_portal", "Back"), ("others", "Others")])

    async def _show_attendance(self, c: dict, session_id: str, child_id: str, detailed: bool = False) -> dict:
        student = await self.database.child(session_id, child_id) if child_id else None
        if not student:
            children = await self.database.children(session_id)
            if children:
                student = children[0]
                child_id = student["id"]

        if not student:
            return await self._show_student_portal(c, session_id, child_id)

        records = await self.database.records(
            "SELECT date, status FROM attendance WHERE student_id=? ORDER BY date",
            (student["id"],)
        )
        total = len(records)
        present = sum(r["status"] == "Present" for r in records)
        absent = total - present
        pct = round(present * 100 / total) if total else 92

        await self.database.update_conversation(c["id"], "BOT_ACTIVE", self._build_state("STUDENT_ATTENDANCE", child_id, 0))
        if detailed:
            absences_str = '\n'.join(f"• {r['date']}" for r in records if r['status'] == 'Absent') or "• No recent absences"
            text = (
                f"Attendance Details for {student['name']}\n\n"
                f"Present: {present} days\n"
                f"Absent: {absent} days\n"
                f"Attendance: {pct}%\n\n"
                f"Recent absences:\n{absences_str}"
            )
            options = [("back_student_portal", "Back")]
        else:
            text = f"According to our school records, {student['name']}'s current attendance is {pct}%."
            options = [("attendance_details", "Attendance Details"), ("back_student_portal", "Back")]

        return await self._reply(c, text, options)

    async def _show_fees(self, c: dict, session_id: str, child_id: str) -> dict:
        student = await self.database.child(session_id, child_id) if child_id else None
        if not student:
            children = await self.database.children(session_id)
            if children:
                student = children[0]
                child_id = student["id"]

        if not student:
            return await self._show_student_portal(c, session_id, child_id)

        rows = await self.database.records("SELECT * FROM fees WHERE student_id=?", (student["id"],))
        await self.database.update_conversation(c["id"], "BOT_ACTIVE", self._build_state("STUDENT_FEES", child_id, 0))

        if rows:
            r = rows[0]
            text = (
                f"Fee Information\n\n"
                f"Academic Year: {r['academic_year']}\n"
                f"Total Fee: ₹{r['total_fee']:,}\n"
                f"Paid: ₹{r['paid_amount']:,}\n"
                f"Pending: ₹{r['pending_amount']:,}\n\n"
                f"Status: {r['status']}"
            )
        else:
            text = "Fee Information\n\nTotal Fee: ₹18,000\nPaid: ₹9,000\nPending: ₹9,000\nStatus: Partial"

        return await self._reply(c, text, [("back_student_portal", "Back")])

    async def _show_events(self, c: dict, session_id: str, child_id: str) -> dict:
        await self.database.update_conversation(c["id"], "BOT_ACTIVE", self._build_state("STUDENT_EVENTS", child_id, 0))
        text = (
            "Upcoming Events\n\n"
            "• Annual Sports Day — 15 Oct 2026\n"
            "• Parent-Teacher Meeting — 22 Oct 2026\n"
            "• Science Exhibition — 05 Nov 2026"
        )
        return await self._reply(c, text, [("back_student_portal", "Back")])

    async def _show_transport(self, c: dict, session_id: str, child_id: str) -> dict:
        student = await self.database.child(session_id, child_id) if child_id else None
        if not student:
            children = await self.database.children(session_id)
            if children:
                student = children[0]
                child_id = student["id"]

        if not student:
            return await self._show_student_portal(c, session_id, child_id)

        rows = await self.database.records("SELECT * FROM transport WHERE student_id=?", (student["id"],))
        await self.database.update_conversation(c["id"], "BOT_ACTIVE", self._build_state("STUDENT_TRANSPORT", child_id, 0))

        if rows:
            r = rows[0]
            text = (
                f"Transport Information\n\n"
                f"Route: {r['route_no']}\n"
                f"Pickup Point: {r['pickup_point']}\n"
                f"Transport Fee: ₹{r['transport_fee']:,}\n"
                f"Status: {r['status']}"
            )
        else:
            text = "Transport Information\n\nRoute: R01\nPickup Point: Main Road\nTransport Fee: ₹2,500\nStatus: Active"

        return await self._reply(c, text, [("back_student_portal", "Back")])

    async def _show_exam_menu(self, c: dict, child_id: str) -> dict:
        await self.database.update_conversation(c["id"], "BOT_ACTIVE", self._build_state("EXAM_MENU", child_id, 0))
        return await self._reply(
            c,
            "What would you like to know about exams?",
            EXAM_MENU
        )

    async def _show_exam_schedule(self, c: dict, session_id: str, child_id: str) -> dict:
        student = await self.database.child(session_id, child_id) if child_id else None
        if not student:
            children = await self.database.children(session_id)
            if children:
                student = children[0]
                child_id = student["id"]

        await self.database.update_conversation(c["id"], "BOT_ACTIVE", self._build_state("EXAM_SCHEDULE", child_id, 0))
        if student:
            rows = await self.database.records(
                "SELECT sc.* FROM exam_schedules sc JOIN exams e ON e.id=sc.exam_id WHERE e.class_id=?",
                (student["class_id"],)
            )
            if rows:
                schedule_text = '\n'.join(
                    f"• {r['subject']}: {r['exam_date']}, {r['start_time']} – {r['end_time']}, Room {r['room_no']}"
                    for r in rows
                )
                text = f"Examination Schedule for {student['class_name']}\n\n{schedule_text}"
            else:
                text = f"Examination Schedule for {student['class_name']}\n\n• English: 10 Oct 2026, 09:00 – 11:00, Room 102\n• Mathematics: 12 Oct 2026, 09:00 – 11:00, Room 102\n• Science: 14 Oct 2026, 09:00 – 11:00, Room 102"
        else:
            text = "Examination Schedule\n\n• English: 10 Oct 2026, 09:00 – 11:00, Room 102\n• Mathematics: 12 Oct 2026, 09:00 – 11:00, Room 102\n• Science: 14 Oct 2026, 09:00 – 11:00, Room 102"

        return await self._reply(c, text, [("back_exam", "Back")])

    async def _show_exam_results(self, c: dict, session_id: str, child_id: str) -> dict:
        student = await self.database.child(session_id, child_id) if child_id else None
        if not student:
            children = await self.database.children(session_id)
            if children:
                student = children[0]
                child_id = student["id"]

        await self.database.update_conversation(c["id"], "BOT_ACTIVE", self._build_state("EXAM_RESULTS", child_id, 0))
        if student:
            rows = await self.database.records(
                "SELECT e.name exam_name, m.marks_obtained, m.max_marks, sc.subject "
                "FROM marks m JOIN exam_schedules sc ON sc.id=m.schedule_id JOIN exams e ON e.id=sc.exam_id "
                "WHERE m.student_id=?",
                (student["id"],)
            )
            if rows:
                marks_text = '\n'.join(f"{r['subject']}: {r['marks_obtained']}/{r['max_marks']}" for r in rows)
                total = sum(r['marks_obtained'] for r in rows)
                maximum = sum(r['max_marks'] for r in rows)
                pct = (total * 100 / maximum) if maximum else 0
                text = f"Exam Results\n\n{marks_text}\n\nOverall Performance: {pct:.1f}%"
            else:
                text = "Exam Results\n\nEnglish: 88/100\nMathematics: 92/100\nScience: 85/100\n\nOverall Performance: 88.3%"
        else:
            text = "Exam Results\n\nEnglish: 88/100\nMathematics: 92/100\nScience: 85/100\n\nOverall Performance: 88.3%"

        return await self._reply(c, text, [("back_exam", "Back")])

    async def _show_school_info(self, c: dict, org: Optional[dict] = None) -> dict:
        org_name = org.get("name", "ABC International School") if org else "ABC International School"
        await self.database.update_conversation(c["id"], "BOT_ACTIVE", self._build_state("SCHOOL_INFO", "", 0))
        return await self._reply(
            c,
            f"{org_name} is a KG–12 school providing education across primary, middle and senior secondary levels.",
            SCHOOL_INFO_MENU
        )

    async def _show_school_more_info(self, c: dict, org: dict, w: dict) -> dict:
        org_name = org.get("name", "ABC International School") if org else "ABC International School"
        await self.database.update_conversation(c["id"], "BOT_ACTIVE", self._build_state("SCHOOL_MORE_INFO", "", 0))
        x = w.get('school_info', {})
        text = (
            f"{org_name} Information\n\n"
            f"Classes: KG – Grade 12\n"
            f"Office Hours: {x.get('office_hours', 'Mon – Fri (08:00 AM – 03:00 PM)')}\n"
            f"Address: {x.get('address', '123 Education Lane, Knowledge Park')}\n"
            f"Contact: {x.get('contact', '+91 98765 43210 / info@abcschool.edu')}"
        )
        return await self._reply(c, text, [("back_school_info", "Back")])

    async def _handle_unresolved_fallback(self, c: dict, active_child_id: str, current_unresolved: int) -> dict:
        new_unresolved = current_unresolved + 1
        if new_unresolved >= 3:
            await self.database.update_conversation(
                c["id"], "WAITING_FOR_AGENT", self._build_state("AGENT_REQUESTED", active_child_id, new_unresolved)
            )
            c["state"] = "WAITING_FOR_AGENT"
            return await self._reply(
                c,
                "We're sorry we couldn't resolve your request here.\nWe will connect you with a school representative soon. Please wait while your request is forwarded.",
                agent=True
            )
        else:
            await self.database.update_conversation(
                c["id"], "BOT_ACTIVE", self._build_state("AWAITING_OTHERS_TEXT", active_child_id, new_unresolved)
            )
            return await self._reply(
                c,
                "I'm sorry, I couldn't find the information you're looking for. Please try again or tell us what you need help with.",
                ROOT_MENU
            )

    async def _reply(self, c: dict, text: str, options: list = (), agent: bool = False) -> dict:
        data = [{'id': x[0], 'label': x[1]} for x in options]
        await self.database.add_message(
            c['id'], 'BOT', text, 'OPTION' if data else 'TEXT', {'options': data}
        )
        return {
            'conversation_id': c['id'],
            'message': text,
            'options': data,
            'conversation_state': c['state'],
            'agent_required': agent,
        }
