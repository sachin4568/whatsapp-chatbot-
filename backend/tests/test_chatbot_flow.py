import asyncio
import uuid

from app.services.chatbot_engine import ChatbotEngine
from app.services.database import Database


def test_required_chatbot_navigation_and_escalation():
    async def run_flow():
        database = Database()
        await database.connect()
        engine = ChatbotEngine(database)
        session_id = f"test_{uuid.uuid4().hex}"

        async def send(message):
            return await engine.process_message(
                "org_abc_school",
                session_id,
                message,
            )

        root = await send("Hi")
        assert [option["label"] for option in root["options"]] == [
            "Admission Enquiry",
            "Student Portal",
            "School Info",
            "Others",
        ]

        portal = await send("Student Portal")
        assert [option["label"] for option in portal["options"]] == [
            "Info",
            "Timetable",
            "Attendance",
            "Fees",
            "Events",
            "Transport",
            "Exam",
            "Others",
            "Back",
        ]

        exam = await send("Exam")
        assert [option["label"] for option in exam["options"]] == [
            "Exam Schedule",
            "Exam Results",
            "Back",
        ]

        others = await send("Back")
        assert [option["label"] for option in others["options"]] == [
            "Info",
            "Timetable",
            "Attendance",
            "Fees",
            "Events",
            "Transport",
            "Exam",
            "Others",
            "Back",
        ]
        others = await send("Others")
        assert others["message"] == "Please tell us what you would like help with."

        first_fallback = await send("unsupported request")
        assert first_fallback["agent_required"] is False
        second_fallback = await send("unrecognized question")
        assert second_fallback["agent_required"] is False
        escalation = await send("still unsupported")
        assert escalation["agent_required"] is True
        assert escalation["conversation_state"] == "WAITING_FOR_AGENT"

    asyncio.run(run_flow())