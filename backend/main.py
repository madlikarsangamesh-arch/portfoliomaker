import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from backend.config import settings
from backend.api.router import api_router
from backend.middleware.security import RateLimitingMiddleware

app = FastAPI(
    title=settings.PROJECT_NAME,
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# CORS Policy configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # allow flutter local dev ports
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Custom Rate Limiter and Request logger middleware
app.add_middleware(RateLimitingMiddleware)

# Unify API endpoints
app.include_router(api_router, prefix=settings.API_V1_STR)

# Mount storage directory for static assets (Resumes / photo assets)
app.mount(
    "/api/v1/static",
    StaticFiles(directory=settings.LOCAL_STORAGE_DIR),
    name="static"
)

@app.get("/")
def read_root():
    return {
        "status": "online",
        "service": settings.PROJECT_NAME,
        "version": "1.0.0"
    }
