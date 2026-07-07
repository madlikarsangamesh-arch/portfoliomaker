import json
import sqlite3
from typing import Optional, List
from backend.database.connection import get_db_connection

class PortfolioRepository:
    def __init__(self):
        pass

    def save(self, portfolio_id: str, data: dict) -> dict:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute("SELECT id FROM portfolios WHERE id = ?", (portfolio_id,))
        exists = cursor.fetchone() is not None
        
        profile_json = json.dumps(data.get("profile", {}))
        design_json = json.dumps(data.get("design", {}))
        scorecard_json = json.dumps(data.get("recruiter_scorecard", {}))
        
        if exists:
            cursor.execute("""
                UPDATE portfolios SET 
                    profile = ?, design = ?, html_code = ?, css_code = ?, js_code = ?, 
                    deployment_url = ?, recruiter_scorecard = ?, is_active = ?, 
                    version = ?, updated_at = ?
                WHERE id = ?
            """, (
                profile_json, design_json, data.get("html_code"), data.get("css_code"), 
                data.get("js_code"), data.get("deployment_url"), scorecard_json, 
                1 if data.get("is_active", True) else 0, data.get("version", 1), 
                data.get("updated_at"), portfolio_id
            ))
        else:
            cursor.execute("""
                INSERT INTO portfolios (
                    id, user_id, profile, design, html_code, css_code, js_code, 
                    deployment_url, recruiter_scorecard, is_active, version, created_at, updated_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                portfolio_id, data.get("user_id"), profile_json, design_json, data.get("html_code"),
                data.get("css_code"), data.get("js_code"), data.get("deployment_url"), scorecard_json,
                1 if data.get("is_active", True) else 0, data.get("version", 1),
                data.get("created_at"), data.get("updated_at")
            ))
        conn.commit()
        conn.close()
        return data

    def get_by_id(self, portfolio_id: str) -> Optional[dict]:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM portfolios WHERE id = ?", (portfolio_id,))
        row = cursor.fetchone()
        conn.close()
        if row:
            res = dict(row)
            res["profile"] = json.loads(res["profile"])
            res["design"] = json.loads(res["design"])
            res["recruiter_scorecard"] = json.loads(res["recruiter_scorecard"]) if res["recruiter_scorecard"] else None
            res["is_active"] = bool(res["is_active"])
            return res
        return None

    def get_by_user_id(self, user_id: str) -> List[dict]:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM portfolios WHERE user_id = ? ORDER BY updated_at DESC", (user_id,))
        rows = cursor.fetchall()
        conn.close()
        
        portfolios = []
        for r in rows:
            res = dict(r)
            res["profile"] = json.loads(res["profile"])
            res["design"] = json.loads(res["design"])
            res["recruiter_scorecard"] = json.loads(res["recruiter_scorecard"]) if res["recruiter_scorecard"] else None
            res["is_active"] = bool(res["is_active"])
            portfolios.append(res)
        return portfolios

    def get_all(self) -> List[dict]:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM portfolios ORDER BY updated_at DESC")
        rows = cursor.fetchall()
        conn.close()
        
        portfolios = []
        for r in rows:
            res = dict(r)
            res["profile"] = json.loads(res["profile"])
            res["design"] = json.loads(res["design"])
            res["recruiter_scorecard"] = json.loads(res["recruiter_scorecard"]) if res["recruiter_scorecard"] else None
            res["is_active"] = bool(res["is_active"])
            portfolios.append(res)
        return portfolios

    def save_cv_version(self, user_id: str, portfolio_id: str, resume_url: str, version: int, created_at: str) -> None:
        import uuid
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cv_id = f"cv_{uuid.uuid4().hex[:12]}"
        cursor.execute("""
            INSERT INTO cv_history (id, user_id, portfolio_id, version, resume_url, created_at)
            VALUES (?, ?, ?, ?, ?, ?)
        """, (cv_id, user_id, portfolio_id, version, resume_url, created_at))
        
        # Keep only the last 3 versions
        cursor.execute("""
            SELECT id FROM cv_history 
            WHERE user_id = ? 
            ORDER BY created_at DESC
        """, (user_id,))
        rows = cursor.fetchall()
        if len(rows) > 3:
            for r in rows[3:]:
                cursor.execute("DELETE FROM cv_history WHERE id = ?", (dict(r)["id"],))
                
        conn.commit()
        conn.close()

    def get_cv_history(self, user_id: str) -> List[dict]:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("""
            SELECT * FROM cv_history 
            WHERE user_id = ? 
            ORDER BY created_at DESC 
            LIMIT 3
        """, (user_id,))
        rows = cursor.fetchall()
        conn.close()
        return [dict(r) for r in rows]

portfolio_repository = PortfolioRepository()
