import logging
import os
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles

from backend.api.router import api_router
from backend.config import settings
from backend.logging_config import configure_logging
from backend.middleware.security import RateLimitingMiddleware
from backend.utils.n8n import report_error_to_n8n

configure_logging()
logger = logging.getLogger("PortfolioAI.Main")


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info(
        "Starting %s | env=%s | host=%s | port=%s | production=%s",
        settings.PROJECT_NAME,
        settings.ENVIRONMENT,
        settings.HOST,
        settings.PORT,
        settings.IS_PRODUCTION,
    )
    logger.info("CORS origins: %s", settings.CORS_ORIGINS)
    logger.info("LLM fallback enabled: %s", settings.LLM_ALLOW_FALLBACK)
    yield
    logger.info("Shutting down %s", settings.PROJECT_NAME)


app = FastAPI(
    title=settings.PROJECT_NAME,
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan,
)

# CORS — configurable via CORS_ORIGINS env var for Flutter web on Vercel
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Rate limiter and request/error logger middleware
app.add_middleware(RateLimitingMiddleware)

# Unify API endpoints
app.include_router(api_router, prefix=settings.API_V1_STR)

# Mount storage directory for static assets (resumes / photo assets)
app.mount(
    "/api/v1/static",
    StaticFiles(directory=settings.LOCAL_STORAGE_DIR),
    name="static",
)


@app.exception_handler(Exception)
async def unhandled_exception_handler(request: Request, exc: Exception):
    logger.error(
        "Unhandled exception on %s %s: %s",
        request.method,
        request.url.path,
        exc,
        exc_info=True,
    )
    try:
        report_error_to_n8n(exc, request=request, context="FastAPI Unhandled Exception")
    except Exception as n8n_err:
        logger.error("Failed executing n8n reporting block: %s", n8n_err)
    return JSONResponse(status_code=500, content={"detail": "Internal Server Error"})


@app.get("/")
def read_root():
    return {
        "status": "online",
        "service": settings.PROJECT_NAME,
        "version": "1.0.0",
    }


@app.get("/health")
def health_check():
    """Railway health-check endpoint."""
    return {
        "status": "healthy",
        "service": settings.PROJECT_NAME,
        "environment": settings.ENVIRONMENT,
    }
