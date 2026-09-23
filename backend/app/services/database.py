import json
import sqlite3
import uuid
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Optional

from app.config import settings


class Database:
    def __init__(self) -> None:
        self.path = Path(settings.DATABASE_PATH)

    def connection(self) -> sqlite3.Connection:
        connection = sqlite3.connect(self.path)
        connection.row_factory = sqlite3.Row
        return connection

    async def connect(self) -> None:
        with self.connection() as db:
            db.executescript("""
            CREATE TABLE IF NOT EXISTS organizations (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                description TEXT NOT NULL,
                verified INTEGER NOT NULL DEFAULT 0,
                profile_color TEXT NOT NULL DEFAULT '#128C7E',
                profile_image_url TEXT NOT NULL DEFAULT '',
                workflow_json TEXT NOT NULL,
                business_type TEXT NOT NULL DEFAULT 'School',
                bio TEXT NOT NULL DEFAULT ''
            );

            CREATE TABLE IF NOT EXISTS business_profiles (
                organization_id TEXT PRIMARY KEY,
                contact TEXT NOT NULL DEFAULT '',
                email TEXT NOT NULL DEFAULT ''
            );

            CREATE TABLE IF NOT EXISTS user_profiles (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                contact TEXT NOT NULL,
                email TEXT NOT NULL,
                linked_parent_key TEXT NOT NULL,
                created_at TEXT NOT NULL
            );

            CREATE TABLE IF NOT EXISTS conversations (
                id TEXT PRIMARY KEY,
                organization_id TEXT NOT NULL,
                session_id TEXT NOT NULL,
                state TEXT NOT NULL,
                workflow_state TEXT NOT NULL,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                UNIQUE(organization_id, session_id)
            );

            CREATE TABLE IF NOT EXISTS messages (
                id TEXT PRIMARY KEY,
                conversation_id TEXT NOT NULL,
                sender_type TEXT NOT NULL,
                text TEXT NOT NULL,
                message_type TEXT NOT NULL,
                status TEXT NOT NULL,
                metadata_json TEXT NOT NULL,
                created_at TEXT NOT NULL
            );

            CREATE TABLE IF NOT EXISTS classes (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                stream TEXT
            );

            CREATE TABLE IF NOT EXISTS teachers (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                subject TEXT NOT NULL
            );

            CREATE TABLE IF NOT EXISTS sections (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                class_id TEXT NOT NULL,
                teacher_id TEXT NOT NULL
            );

            CREATE TABLE IF NOT EXISTS students (
                id TEXT PRIMARY KEY,
                parent_key TEXT NOT NULL,
                student_code TEXT NOT NULL,
                name TEXT NOT NULL,
                date_of_birth TEXT NOT NULL,
                gender TEXT NOT NULL,
                class_id TEXT NOT NULL,
                section_id TEXT NOT NULL,
                roll_no INTEGER NOT NULL
            );

            CREATE TABLE IF NOT EXISTS attendance (
                id TEXT PRIMARY KEY,
                student_id TEXT NOT NULL,
                date TEXT NOT NULL,
                status TEXT NOT NULL
            );

            CREATE TABLE IF NOT EXISTS homework (
                id TEXT PRIMARY KEY,
                class_id TEXT NOT NULL,
                section_id TEXT NOT NULL,
                subject TEXT NOT NULL,
                detail TEXT NOT NULL
            );

            CREATE TABLE IF NOT EXISTS exams (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                class_id TEXT NOT NULL
            );

            CREATE TABLE IF NOT EXISTS exam_schedules (
                id TEXT PRIMARY KEY,
                exam_id TEXT NOT NULL,
                subject TEXT NOT NULL,
                exam_date TEXT NOT NULL,
                start_time TEXT NOT NULL,
                end_time TEXT NOT NULL,
                room_no TEXT NOT NULL
            );

            CREATE TABLE IF NOT EXISTS marks (
                id TEXT PRIMARY KEY,
                student_id TEXT NOT NULL,
                schedule_id TEXT NOT NULL,
                marks_obtained INTEGER NOT NULL,
                max_marks INTEGER NOT NULL
            );

            CREATE TABLE IF NOT EXISTS fees (
                id TEXT PRIMARY KEY,
                student_id TEXT NOT NULL,
                academic_year TEXT NOT NULL,
                total_fee INTEGER NOT NULL,
                paid_amount INTEGER NOT NULL,
                pending_amount INTEGER NOT NULL,
                status TEXT NOT NULL
            );

            CREATE TABLE IF NOT EXISTS transport (
                id TEXT PRIMARY KEY,
                student_id TEXT NOT NULL,
                route_no TEXT NOT NULL,
                pickup_point TEXT NOT NULL,
                transport_fee INTEGER NOT NULL,
                status TEXT NOT NULL
            );
            """)

            organization_columns = {
                row[1]
                for row in db.execute("PRAGMA table_info(organizations)")
            }
            if "profile_image_url" not in organization_columns:
                db.execute(
                    "ALTER TABLE organizations ADD COLUMN "
                    "profile_image_url TEXT NOT NULL DEFAULT ''"
                )
            if "business_type" not in organization_columns:
                db.execute(
                    "ALTER TABLE organizations ADD COLUMN "
                    "business_type TEXT NOT NULL DEFAULT 'School'"
                )
            if "bio" not in organization_columns:
                db.execute(
                    "ALTER TABLE organizations ADD COLUMN "
                    "bio TEXT NOT NULL DEFAULT ''"
                )

            student_columns = {
                row[1]
                for row in db.execute("PRAGMA table_info(students)")
            }
            if "parent_key" not in student_columns:
                db.execute(
                    "ALTER TABLE students ADD COLUMN "
                    "parent_key TEXT NOT NULL DEFAULT 'no_student'"
                )

            self._seed_data(db)
            db.commit()

    def _seed_data(self, db: sqlite3.Connection) -> None:
        workflow = {
            "school_info": {
                "office_hours": "8:00 AM – 4:00 PM",
                "contact": "+91 98765 43210",
                "address": "42 Greenfield Road",
            },
            "agent_phrases": [
                "agent",
                "human",
                "person",
                "representative",
                "talk to someone",
                "school office",
                "someone help",
            ],
        }

        db.execute("""
            INSERT OR IGNORE INTO organizations
            (id, name, description, verified, profile_color, workflow_json,
             business_type, bio, profile_image_url)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            "org_abc_school",
            "ABC International School",
            "KG to Grade 12 school",
            1,
            "#128C7E",
            json.dumps(workflow),
            "School",
            "A WhatsApp-based school communication prototype.",
            "https://images.unsplash.com/photo-1503676260728-1c00da094a0b",
        ))

        db.execute("""
            INSERT OR IGNORE INTO business_profiles
            (organization_id, contact, email)
            VALUES (?, ?, ?)
        """, (
            "org_abc_school",
            "+91 98765 43210",
            "office@abcschool.test",
        ))

        db.execute("""
            UPDATE organizations
            SET profile_image_url = ?
            WHERE id = ? AND profile_image_url = ''
        """, (
            "https://images.unsplash.com/photo-1503676260728-1c00da094a0b",
            "org_abc_school",
        ))

        db.executemany("""
            INSERT OR IGNORE INTO classes (id, name, stream)
            VALUES (?, ?, ?)
        """, [
            ("g1", "Grade 1", None),
            ("g5", "Grade 5", None),
            ("g11s", "Grade 11", "Science"),
        ])

        db.executemany("""
            INSERT OR IGNORE INTO teachers (id, name, subject)
            VALUES (?, ?, ?)
        """, [
            ("t1", "Neha Verma", "Primary"),
            ("t2", "Rakesh Iyer", "Mathematics"),
            ("t3", "Anita Rao", "Science"),
        ])

        db.executemany("""
            INSERT OR IGNORE INTO sections (id, name, class_id, teacher_id)
            VALUES (?, ?, ?, ?)
        """, [
            ("g1a", "A", "g1", "t1"),
            ("g5b", "B", "g5", "t2"),
            ("g11sa", "A", "g11s", "t3"),
        ])

        db.executemany("""
            INSERT OR IGNORE INTO students
            (id, parent_key, student_code, name, date_of_birth, gender,
             class_id, section_id, roll_no)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, [
            (
                "STU001",
                "parent_sharma",
                "STU001",
                "Aarav Sharma",
                "2019-03-14",
                "Male",
                "g1",
                "g1a",
                1,
            ),
            (
                "STU002",
                "parent_sharma",
                "STU002",
                "Anaya Sharma",
                "2016-08-21",
                "Female",
                "g5",
                "g5b",
                12,
            ),
            (
                "STU003",
                "parent_patel",
                "STU003",
                "Kabir Patel",
                "2009-01-09",
                "Male",
                "g11s",
                "g11sa",
                4,
            ),
        ])

        db.execute("""
            UPDATE students
            SET parent_key = 'parent_sharma'
            WHERE id IN ('STU001', 'STU002')
        """)
        db.execute("""
            UPDATE students
            SET parent_key = 'parent_patel'
            WHERE id = 'STU003'
        """)
        db.execute("DELETE FROM students WHERE id = 'STU004'")

        attendance_rows = [
            (
                f"attendance_{day}",
                "STU001",
                f"2026-09-{day:02}",
                "Absent" if day in [5, 12] else "Present",
            )
            for day in range(1, 21)
        ]

        db.executemany("""
            INSERT OR IGNORE INTO attendance (id, student_id, date, status)
            VALUES (?, ?, ?, ?)
        """, attendance_rows)

        db.executemany("""
            INSERT OR IGNORE INTO homework
            (id, class_id, section_id, subject, detail)
            VALUES (?, ?, ?, ?, ?)
        """, [
            (
                "homework_1",
                "g1",
                "g1a",
                "English",
                "Read Chapter 3.",
            ),
            (
                "homework_2",
                "g1",
                "g1a",
                "Mathematics",
                "Complete exercises 1–10.",
            ),
            (
                "homework_3",
                "g1",
                "g1a",
                "Science",
                "Revise the topic Plants.",
            ),
        ])

        db.execute("""
            INSERT OR IGNORE INTO exams (id, name, class_id)
            VALUES (?, ?, ?)
        """, ("term_1_g1", "Term 1", "g1"))

        db.executemany("""
            INSERT OR IGNORE INTO exam_schedules
            (id, exam_id, subject, exam_date, start_time, end_time, room_no)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """, [
            (
                "schedule_english",
                "term_1_g1",
                "English",
                "2026-10-10",
                "09:00 AM",
                "10:00 AM",
                "101",
            ),
            (
                "schedule_maths",
                "term_1_g1",
                "Mathematics",
                "2026-10-13",
                "09:00 AM",
                "10:00 AM",
                "101",
            ),
            (
                "schedule_science",
                "term_1_g1",
                "Science",
                "2026-10-15",
                "09:00 AM",
                "10:00 AM",
                "101",
            ),
        ])

        db.executemany("""
            INSERT OR IGNORE INTO marks
            (id, student_id, schedule_id, marks_obtained, max_marks)
            VALUES (?, ?, ?, ?, ?)
        """, [
            ("mark_english", "STU001", "schedule_english", 88, 100),
            ("mark_maths", "STU001", "schedule_maths", 92, 100),
            ("mark_science", "STU001", "schedule_science", 85, 100),
        ])

        db.execute("""
            INSERT OR IGNORE INTO fees
            (id, student_id, academic_year, total_fee, paid_amount,
             pending_amount, status)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """, (
            "fee_aarav",
            "STU001",
            "2026–27",
            18000,
            9000,
            9000,
            "Partial",
        ))

        db.execute("""
            INSERT OR IGNORE INTO transport
            (id, student_id, route_no, pickup_point, transport_fee, status)
            VALUES (?, ?, ?, ?, ?, ?)
        """, (
            "transport_aarav",
            "STU001",
            "R01",
            "Main Road",
            2500,
            "Active",
        ))

    async def close(self) -> None:
        return None

    async def ping(self) -> bool:
        try:
            with self.connection() as db:
                db.execute("SELECT 1")
            return True
        except sqlite3.Error:
            return False

    async def organizations(self, query: str = "") -> list[dict[str, Any]]:
        pattern = f"%{query.strip()}%"

        with self.connection() as db:
            rows = db.execute("""
                SELECT
                    id,
                    name,
                    description,
                    verified,
                    profile_color,
                    profile_image_url,
                    business_type,
                    bio
                FROM organizations
                WHERE name LIKE ? OR description LIKE ?
                ORDER BY name
            """, (pattern, pattern)).fetchall()

        return [
            dict(row) | {"verified": bool(row["verified"])}
            for row in rows
        ]

    async def organization(
        self,
        organization_id: str,
    ) -> Optional[dict[str, Any]]:
        with self.connection() as db:
            row = db.execute("""
                SELECT
                    organizations.*,
                    business_profiles.contact,
                    business_profiles.email
                FROM organizations
                LEFT JOIN business_profiles
                    ON business_profiles.organization_id = organizations.id
                WHERE organizations.id = ?
            """, (organization_id,)).fetchone()

        if not row:
            return None

        result = dict(row)
        result["verified"] = bool(result["verified"])
        return result

    async def create_user_profile(
        self,
        name: str,
        contact: str,
        email: str,
    ) -> dict[str, Any]:
        user_id = f"user_{uuid.uuid4().hex[:12]}"

        linked_parent_key_by_phone = {
            "9876500001": "parent_sharma",
            "9876500002": "parent_patel",
            "9876500003": "no_student",
        }
        normalized_contact = "".join(
            character for character in contact if character.isdigit()
        )
        linked_parent_key = linked_parent_key_by_phone.get(
            normalized_contact,
            "no_student",
        )

        with self.connection() as db:
            db.execute("""
                INSERT INTO user_profiles
                (id, name, contact, email, linked_parent_key, created_at)
                VALUES (?, ?, ?, ?, ?, ?)
            """, (
                user_id,
                name,
                normalized_contact,
                email,
                linked_parent_key,
                datetime.now(timezone.utc).isoformat(),
            ))
            db.commit()

        return {
            "id": user_id,
            "name": name,
            "contact": normalized_contact,
            "email": email,
        }

    async def create_business_profile(
        self,
        name: str,
        verified: bool,
        business_type: str,
        bio: str,
        contact: str,
        email: str,
    ) -> dict[str, Any]:
        organization_id = f"org_{uuid.uuid4().hex[:12]}"

        workflow = {
            "school_info": {
                "office_hours": "8:00 AM – 4:00 PM",
                "contact": contact,
                "address": "Information can be updated.",
            },
            "agent_phrases": [
                "agent",
                "human",
                "person",
                "representative",
                "talk to someone",
                "school office",
            ],
        }

        with self.connection() as db:
            db.execute("""
                INSERT INTO organizations
                (id, name, description, verified, profile_color, workflow_json,
                 business_type, bio, profile_image_url)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                organization_id,
                name,
                business_type,
                int(verified),
                "#128C7E",
                json.dumps(workflow),
                business_type,
                bio,
                "https://images.unsplash.com/photo-1503676260728-1c00da094a0b",
            ))

            db.execute("""
                INSERT INTO business_profiles
                (organization_id, contact, email)
                VALUES (?, ?, ?)
            """, (organization_id, contact, email))

            db.commit()

        return await self.organization(organization_id)

    async def get_or_create_conversation(
        self,
        organization_id: str,
        session_id: str,
    ) -> tuple[dict[str, Any], bool]:
        now = datetime.now(timezone.utc).isoformat()

        with self.connection() as db:
            existing = db.execute("""
                SELECT * FROM conversations
                WHERE organization_id = ? AND session_id = ?
            """, (organization_id, session_id)).fetchone()

            if existing:
                return dict(existing), False

            conversation_id = f"conversation_{uuid.uuid4().hex[:16]}"

            db.execute("""
                INSERT INTO conversations
                (id, organization_id, session_id, state, workflow_state,
                 created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            """, (
                conversation_id,
                organization_id,
                session_id,
                "BOT_ACTIVE",
                "START",
                now,
                now,
            ))
            db.commit()

            row = db.execute(
                "SELECT * FROM conversations WHERE id = ?",
                (conversation_id,),
            ).fetchone()

        return dict(row), True

    async def update_conversation(
        self,
        conversation_id: str,
        state: str,
        workflow_state: Optional[str] = None,
    ) -> None:
        with self.connection() as db:
            if workflow_state:
                db.execute("""
                    UPDATE conversations
                    SET state = ?, workflow_state = ?, updated_at = ?
                    WHERE id = ?
                """, (
                    state,
                    workflow_state,
                    datetime.now(timezone.utc).isoformat(),
                    conversation_id,
                ))
            else:
                db.execute("""
                    UPDATE conversations
                    SET state = ?, updated_at = ?
                    WHERE id = ?
                """, (
                    state,
                    datetime.now(timezone.utc).isoformat(),
                    conversation_id,
                ))
            db.commit()

    async def add_message(
        self,
        conversation_id: str,
        sender_type: str,
        text: str,
        message_type: str = "TEXT",
        metadata: Optional[dict] = None,
    ) -> None:
        with self.connection() as db:
            db.execute("""
                INSERT INTO messages
                (id, conversation_id, sender_type, text, message_type,
                 status, metadata_json, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                f"message_{uuid.uuid4().hex[:16]}",
                conversation_id,
                sender_type,
                text,
                message_type,
                "READ",
                json.dumps(metadata or {}),
                datetime.now(timezone.utc).isoformat(),
            ))
            db.commit()

    async def messages(self, conversation_id: str) -> list[dict[str, Any]]:
        with self.connection() as db:
            rows = db.execute("""
                SELECT * FROM messages
                WHERE conversation_id = ?
                ORDER BY created_at
            """, (conversation_id,)).fetchall()

        return [
            dict(row) | {"metadata": json.loads(row["metadata_json"])}
            for row in rows
        ]

    async def conversations(
        self,
        organization_id: str,
        state: Optional[str] = None,
    ) -> list[dict[str, Any]]:
        sql = """
            SELECT
                conversations.*,
                COALESCE(user_profiles.name, conversations.session_id) AS user_name,
                COALESCE(user_profiles.contact, '') AS user_contact,
                (
                    SELECT messages.text
                    FROM messages
                    WHERE messages.conversation_id = conversations.id
                    ORDER BY messages.created_at DESC
                    LIMIT 1
                ) AS last_message
            FROM conversations
            LEFT JOIN user_profiles
                ON user_profiles.id = conversations.session_id
            WHERE conversations.organization_id = ?
        """

        parameters: list[Any] = [organization_id]

        if state:
            sql += " AND conversations.state = ?"
            parameters.append(state)

        sql += " ORDER BY conversations.updated_at DESC"

        with self.connection() as db:
            rows = db.execute(sql, parameters).fetchall()

        return [dict(row) for row in rows]

    async def children(self, user_profile_id: str) -> list[dict[str, Any]]:
        with self.connection() as db:
            profile = db.execute("""
                SELECT linked_parent_key
                FROM user_profiles
                WHERE id = ?
            """, (user_profile_id,)).fetchone()

            if not profile:
                return []

            rows = db.execute("""
                SELECT
                    students.*,
                    classes.name AS class_name,
                    classes.stream AS stream,
                    sections.name AS section_name,
                    teachers.name AS teacher_name
                FROM students
                JOIN classes ON classes.id = students.class_id
                JOIN sections ON sections.id = students.section_id
                JOIN teachers ON teachers.id = sections.teacher_id
                WHERE students.parent_key = ?
            """, (profile["linked_parent_key"],)).fetchall()

        return [dict(row) for row in rows]

    async def child(
        self,
        user_profile_id: str,
        selection: str,
    ) -> Optional[dict[str, Any]]:
        children = await self.children(user_profile_id)
        value = selection.lower().strip()

        return next(
            (
                child for child in children
                if child["id"].lower() == value
                or child["student_code"].lower() == value
                or child["name"].lower() == value
            ),
            None,
        )

    async def records(
        self,
        sql: str,
        parameters: tuple,
    ) -> list[dict[str, Any]]:
        with self.connection() as db:
            rows = db.execute(sql, parameters).fetchall()

        return [dict(row) for row in rows]

    async def reset_prototype(self) -> None:
        with self.connection() as db:
            db.execute("DELETE FROM messages")
            db.execute("DELETE FROM conversations")
            db.execute("DELETE FROM user_profiles")
            db.commit()