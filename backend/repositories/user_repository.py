import sqlite3
from typing import Optional, List
from backend.database.connection import get_db_connection

class UserRepository:
    def __init__(self):
        pass

    def create(self, user_id: str, email: str, password_hash: str, full_name: str, role: str = "user") -> dict:
        conn = get_db_connection()
        cursor = conn.cursor()
        try:
            cursor.execute(
                "INSERT INTO users (id, email, password_hash, full_name, role) VALUES (?, ?, ?, ?, ?)",
                (user_id, email, password_hash, full_name, role)
            )
            conn.commit()
            return {"id": user_id, "email": email, "full_name": full_name, "role": role}
        except sqlite3.IntegrityError:
            raise ValueError("Email already registered")
        finally:
            conn.close()

    def get_by_email(self, email: str) -> Optional[dict]:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM users WHERE email = ?", (email,))
        row = cursor.fetchone()
        conn.close()
        if row:
            return dict(row)
        return None

    def get_by_id(self, user_id: str) -> Optional[dict]:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM users WHERE id = ?", (user_id,))
        row = cursor.fetchone()
        conn.close()
        if row:
            return dict(row)
        return None

    def get_all(self) -> List[dict]:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT id, email, full_name, role FROM users")
        rows = cursor.fetchall()
        conn.close()
        return [dict(r) for r in rows]

user_repository = UserRepository()
