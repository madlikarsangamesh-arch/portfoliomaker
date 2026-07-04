from fastapi import APIRouter
from backend.api.auth import router as auth_router
from backend.api.portfolio import router as portfolio_router
from backend.api.analytics import router as analytics_router
from backend.api.admin import router as admin_router

api_router = APIRouter()
api_router.include_router(auth_router)
api_router.include_router(portfolio_router)
api_router.include_router(analytics_router)
api_router.include_router(admin_router)
