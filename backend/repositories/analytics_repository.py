from typing import Dict, Any, List
from backend.database.connection import get_db_connection

class AnalyticsRepository:
    def __init__(self):
        pass

    def log_view(self, data: dict) -> None:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("""
            INSERT INTO analytics (portfolio_id, visitor_id, timestamp, country, device, source, is_resume_download)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """, (
            data.get("portfolio_id"), data.get("visitor_id"), data.get("timestamp"),
            data.get("country"), data.get("device"), data.get("source"),
            1 if data.get("is_resume_download", False) else 0
        ))
        conn.commit()
        conn.close()

    def get_summary(self, portfolio_id: str) -> dict:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM analytics WHERE portfolio_id = ?", (portfolio_id,))
        rows = [dict(r) for r in cursor.fetchall()]
        conn.close()
        
        visitors = len(set(r["visitor_id"] for r in rows))
        views = len(rows)
        
        countries = {}
        devices = {}
        sources = {}
        downloads = 0
        
        for r in rows:
            c = r["country"]
            d = r["device"]
            s = r["source"]
            countries[c] = countries.get(c, 0) + 1
            devices[d] = devices.get(d, 0) + 1
            sources[s] = sources.get(s, 0) + 1
            if r["is_resume_download"]:
                downloads += 1
                
        return {
            "visitors": visitors,
            "views": views,
            "countries": countries,
            "devices": devices,
            "sources": sources,
            "resume_downloads": downloads
        }

analytics_repository = AnalyticsRepository()
