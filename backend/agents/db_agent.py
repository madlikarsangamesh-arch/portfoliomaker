import logging
from typing import Dict, Any, List
from backend.repositories.user_repository import user_repository
from backend.repositories.portfolio_repository import portfolio_repository
from backend.repositories.analytics_repository import analytics_repository

logger = logging.getLogger("PortfolioAI.DBAgent")

class DBAgent:
    def __init__(self):
        pass

    def save_user_profile(self, user_id: str, profile_data: dict) -> dict:
        """
        Updates profile fields inside portfolio records or logs settings.
        """
        logger.info(f"Saving profile parameters for user: {user_id}")
        return profile_data

    def get_user_portfolio_list(self, user_id: str) -> List[dict]:
        return portfolio_repository.get_by_user_id(user_id)

    def save_portfolio_version(self, portfolio_id: str, user_id: str, profile: dict, design: dict, html: str, css: str, js: str, scorecard: dict = None, url: str = None) -> dict:
        """
        Saves a new or existing portfolio snapshot, incrementing version control logs.
        """
        existing = portfolio_repository.get_by_id(portfolio_id)
        version = 1
        created_at = "2026-07-04T20:30:00Z"
        
        if existing:
            version = existing.get("version", 1) + 1
            created_at = existing.get("created_at")

        data = {
            "id": portfolio_id,
            "user_id": user_id,
            "profile": profile,
            "design": design,
            "html_code": html,
            "css_code": css,
            "js_code": js,
            "deployment_url": url or (existing.get("deployment_url") if existing else None),
            "recruiter_scorecard": scorecard or (existing.get("recruiter_scorecard") if existing else None),
            "is_active": True,
            "version": version,
            "created_at": created_at,
            "updated_at": "2026-07-04T20:30:00Z"
        }
        
        return portfolio_repository.save(portfolio_id, data)

    def log_page_view(self, portfolio_id: str, visitor_id: str, country: str, device: str, source: str, is_download: bool = False) -> None:
        log_data = {
            "portfolio_id": portfolio_id,
            "visitor_id": visitor_id,
            "timestamp": "2026-07-04T20:30:00Z",
            "country": country,
            "device": device,
            "source": source,
            "is_resume_download": is_download
        }
        analytics_repository.log_view(log_data)

    def fetch_analytics(self, portfolio_id: str) -> dict:
        return analytics_repository.get_summary(portfolio_id)

db_agent = DBAgent()
