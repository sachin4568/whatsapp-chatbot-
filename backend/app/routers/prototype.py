from typing import Optional

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from app.services.chatbot_engine import ChatbotEngine
from app.services.database import Database

router = APIRouter(prefix="/api", tags=["local prototype"])
database = Database()
engine = ChatbotEngine(database)


class ChatRequest(BaseModel):
    session_id: str
    organization_id: str
    message: str


class UserProfileRequest(BaseModel):
    name: str
    contact: str
    email: str


class BusinessProfileRequest(BaseModel):
    name: str
    verified: bool
    business_type: str
    bio: str
    contact: str
    email: str


@router.get("/chat/organizations")
async def organizations(q: str = ""):
    return await database.organizations(q)


@router.get("/chat/organizations/{organization_id}")
async def organization(organization_id: str):
    result = await database.organization(organization_id)

    if not result:
        raise HTTPException(404, "Organization not found")

    return result


@router.post("/chat")
async def chat(request: ChatRequest):
    try:
        return await engine.process_message(
            request.organization_id,
            request.session_id,
            request.message,
        )
    except ValueError as error:
        raise HTTPException(404, str(error))


@router.post("/profiles/users")
async def create_user_profile(request: UserProfileRequest):
    return await database.create_user_profile(
        request.name,
        request.contact,
        request.email,
    )


@router.post("/business/organizations")
async def create_business(request: BusinessProfileRequest):
    return await database.create_business_profile(
        name=request.name,
        verified=request.verified,
        business_type=request.business_type,
        bio=request.bio,
        contact=request.contact,
        email=request.email,
    )


@router.post("/prototype/reset")
async def reset_prototype():
    await database.reset_prototype()

    return {
        "status": "reset",
        "message": "Chats and user profiles were cleared.",
    }


@router.get("/conversations/{conversation_id}/messages")
async def messages(conversation_id: str):
    return await database.messages(conversation_id)


@router.get("/agent/requests")
async def agent_requests(organization_id: str):
    records = await database.conversations(
        organization_id,
        "WAITING_FOR_AGENT",
    )

    return {
        "count": len(records),
        "conversations": records,
    }


@router.get("/agent/conversations")
async def agent_conversations(
    organization_id: str,
    state: Optional[str] = None,
):
    return await database.conversations(organization_id, state)


@router.post("/agent/conversations/{conversation_id}/intervene")
async def intervene(conversation_id: str):
    await database.update_conversation(conversation_id, "INTERVENED")

    return {
        "conversation_id": conversation_id,
        "state": "INTERVENED",
    }


@router.post("/agent/conversations/{conversation_id}/leave")
async def leave(conversation_id: str):
    await database.update_conversation(conversation_id, "ATTENDED")

    return {
        "conversation_id": conversation_id,
        "state": "ATTENDED",
    }