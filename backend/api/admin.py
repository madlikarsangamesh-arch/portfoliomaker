from fastapi import APIRouter, HTTPException
from backend.repositories.user_repository import user_repository
from backend.repositories.portfolio_repository import portfolio_repository
from backend.agents.planner import TEMPLATE_PRESETS

router = APIRouter(prefix="/admin", tags=["Admin Panel"])

@router.get("/users")
def get_users():
    return user_repository.get_all()

@router.get("/portfolios")
def get_portfolios():
    return portfolio_repository.get_all()

@router.get("/stats")
def get_global_stats():
    users = user_repository.get_all()
    portfolios = portfolio_repository.get_all()
    
    total_users = len(users)
    total_portfolios = len(portfolios)
    
    deployments = [p for p in portfolios if p.get("deployment_url")]
    total_deployments = len(deployments)
    
    # Calculate mock AI usage tokens or score indexes
    scores = [p["recruiter_scorecard"]["overall_score"] for p in portfolios if p.get("recruiter_scorecard")]
    avg_score = sum(scores) / len(scores) if scores else 0.0

    return {
        "total_users": total_users,
        "total_portfolios": total_portfolios,
        "total_deployments": total_deployments,
        "average_recruiter_score": round(avg_score, 1),
        "ai_requests_processed": total_portfolios * 7  # estimates based on loops
    }

@router.get("/templates")
def get_templates():
    """
    Returns list of configured premium design styles.
    """
    return [
        {
            "id": name,
            "name": name.capitalize(),
            "colors": [preset["primary_color"], preset["secondary_color"]],
            "font": preset["font"],
            "layout": preset["layout"]
        }
        for name, preset in TEMPLATE_PRESETS.items()
    ]
