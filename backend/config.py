import os


def _parse_bool(value: str, default: bool = False) -> bool:
    if value is None:
        return default
    return value.strip().lower() in {"1", "true", "yes", "on"}


def _parse_cors_origins(raw: str) -> list[str]:
    if not raw.strip():
        return ["*"]
    return [origin.strip() for origin in raw.split(",") if origin.strip()]


class Settings:
    PROJECT_NAME: str = "AI Portfolio Engineer API"
    API_V1_STR: str = "/api/v1"
    ENVIRONMENT: str = os.getenv("ENVIRONMENT", os.getenv("APP_ENV", "development")).lower()
    IS_RENDER: bool = _parse_bool(os.getenv("RENDER", ""))
    IS_RAILWAY: bool = bool(os.getenv("RAILWAY_ENVIRONMENT", "").strip())
    IS_PRODUCTION: bool = ENVIRONMENT in {"production", "prod"} or IS_RENDER or IS_RAILWAY

    # Server binding (Railway injects PORT at runtime)
    HOST: str = os.getenv("HOST", "0.0.0.0")
    PORT: int = int(os.getenv("PORT", "8000"))

    # CORS — comma-separated origins for Flutter web (Vercel) in production
    CORS_ORIGINS: list[str] = _parse_cors_origins(os.getenv("CORS_ORIGINS", ""))

    # LLM configurations (using Gemini by default)
    GEMINI_API_KEY: str = os.getenv("GEMINI_API_KEY", "").strip().strip("'\"")
    GEMINI_MODEL: str = os.getenv("GEMINI_MODEL", "gemini-2.5-flash").strip().strip("'\"")
    LLM_ALLOW_FALLBACK: bool = _parse_bool(
        os.getenv(
            "LLM_ALLOW_FALLBACK",
            "false" if IS_PRODUCTION else "true",
        ),
        default=not IS_PRODUCTION,
    )

    # Firebase configuration (simulated or real Firestore)
    FIREBASE_MOCK: bool = _parse_bool(os.getenv("FIREBASE_MOCK", "true"), default=True)
    FIREBASE_CREDENTIALS_PATH: str = os.getenv("FIREBASE_CREDENTIALS_PATH", "").strip().strip("'\"")

    # Vercel Configuration (simulated or real Vercel API)
    VERCEL_MOCK: bool = _parse_bool(os.getenv("VERCEL_MOCK", "true"), default=True)
    VERCEL_AUTH_TOKEN: str = os.getenv("VERCEL_AUTH_TOKEN", "").strip().strip("'\"")
    VERCEL_PROJECT_ID: str = os.getenv("VERCEL_PROJECT_ID", "").strip().strip("'\"")
    VERCEL_TEAM_ID: str = os.getenv("VERCEL_TEAM_ID", "").strip().strip("'\"")

    # Security keys
    SECRET_KEY: str = os.getenv("SECRET_KEY", "portfolio_ai_super_secret_session_key_12345").strip().strip("'\"")
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 days

    # n8n Webhook for error reporting
    N8N_WEBHOOK_URL: str = os.getenv("N8N_WEBHOOK_URL", "http://localhost:5678/webhook-test/f1d44745-3536-46d6-adc7-cd449e62f4f7").strip().strip("'\"")

    # Storage settings
    LOCAL_STORAGE_DIR: str = os.path.join(os.path.dirname(os.path.abspath(__file__)), "storage")


settings = Settings()

# Ensure local storage directories exist
os.makedirs(settings.LOCAL_STORAGE_DIR, exist_ok=True)
os.makedirs(os.path.join(settings.LOCAL_STORAGE_DIR, "resumes"), exist_ok=True)
os.makedirs(os.path.join(settings.LOCAL_STORAGE_DIR, "portfolios"), exist_ok=True)
os.makedirs(os.path.join(settings.LOCAL_STORAGE_DIR, "templates"), exist_ok=True)
os.makedirs(os.path.join(settings.LOCAL_STORAGE_DIR, "profiles"), exist_ok=True)
