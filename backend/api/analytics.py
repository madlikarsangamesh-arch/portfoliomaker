from fastapi import APIRouter, HTTPException
from backend.repositories.analytics_repository import analytics_repository

router = APIRouter(prefix="/analytics", tags=["Analytics"])

@router.post("/log")
def log_view(payload: dict):
    portfolio_id = payload.get("portfolio_id")
    visitor_id = payload.get("visitor_id")
    if not portfolio_id or not visitor_id:
        raise HTTPException(status_code=400, detail="Missing portfolio_id or visitor_id parameters")
        
    data = {
        "portfolio_id": portfolio_id,
        "visitor_id": visitor_id,
        "timestamp": payload.get("timestamp", "2026-07-04T20:35:00Z"),
        "country": payload.get("country", "United States"),
        "device": payload.get("device", "Desktop"),
        "source": payload.get("source", "Direct"),
        "is_resume_download": payload.get("is_resume_download", False)
    }
    
    analytics_repository.log_view(data)
    return {"success": True}

@router.get("/summary/{portfolio_id}")
def get_analytics_summary(portfolio_id: str):
    return analytics_repository.get_summary(portfolio_id)
