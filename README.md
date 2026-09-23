# Organization Chatbot Prototype — Phases 1–2

This workspace keeps the two requested foundations separate:

- `frontend/app` extends `octoi/wb-ui-clone` into the Flutter WhatsApp-style client.
- `backend` extends `botdev-community/whatsapp-bot-starter` into the local FastAPI chatbot service.

## Run locally

1. In `backend`, create a virtual environment, install `requirements.txt`, then run:
   `python -m uvicorn app.main:app --reload`
2. In `frontend/app`, run `flutter pub get`, then `flutter run --dart-define=API_URL=http://10.0.2.2:8000` for an Android emulator. For a physical device, use the computer's LAN IP instead of `10.0.2.2`.

The service creates `backend/prototype.db` automatically. No Meta credentials, MongoDB, or cloud service is needed.

## API

- `GET /health`
- `GET /api/chat/organizations`
- `POST /api/chat`
- `GET /api/agent/requests?organization_id=...`
- `POST /api/agent/conversations/{id}/intervene`
- `POST /api/agent/conversations/{id}/leave`
- `PUT /api/business/organizations/{id}`

## Architecture and customization

Flutter owns presentation only. FastAPI owns organization profiles, conversation/message persistence, agent states, and chatbot processing. `backend/app/services/chatbot_engine.py` is transport-neutral; each organization stores a `workflow_json` configuration seeded by `backend/app/services/database.py`.

Phase 2 is implemented as a school workflow: `ABC International School` has privacy-scoped parent/student associations, KG–12 class/stream examples, teachers, sections, attendance, homework, examinations, marks, fees and transport. The rules in `chatbot_engine.py` select only a linked child and calculate/display responses from SQLite records.

To customize for another institution, update the seeded/local records and workflow/configuration in `backend/app/services/database.py`, then add or adjust state transitions in `backend/app/services/chatbot_engine.py`. Keep Flutter presentation-only.

1️⃣ Backend – FastAPI chatbot service
powershell

# 1️⃣ Change to the backend folder

cd e:\chatbot\backend

# 2️⃣ Create a virtual environment (Windows PowerShell)

python -m venv .venv

# 3️⃣ Activate the virtual environment

.\.venv\Scripts\Activate.ps1 # (or .\venv\Scripts\activate.bat for cmd)

# 4️⃣ Install Python dependencies

pip install -r requirements.txt

# 5️⃣ Run the FastAPI server (auto‑reload enabled)

python -m uvicorn app.main:app --reload

# 1️⃣ Change to the Flutter app folder

cd e:\chatbot\frontend\app

# 2️⃣ Fetch Flutter dependencies

flutter pub get

# 3️⃣ Run the app on an Android emulator (or a connected device)

# The Android emulator accesses the host at 10.0.2.2,

# which forwards to the FastAPI server on localhost.

flutter run --dart-define=API_URL=http://10.0.2.2:8000
