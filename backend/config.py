import os

class Settings:
    PROJECT_NAME: str = "AI Portfolio Engineer API"
    API_V1_STR: str = "/api/v1"
    ENVIRONMENT: str = os.getenv("ENVIRONMENT", os.getenv("APP_ENV", "development")).lower()
    IS_RENDER: bool = os.getenv("RENDER", "").lower() == "true"
    
    # LLM configurations (using Gemini by default)
    GEMINI_API_KEY: str = os.getenv("GEMINI_API_KEY", "").strip().strip("'\"")
    GEMINI_MODEL: str = os.getenv("GEMINI_MODEL", "gemini-2.5-flash").strip().strip("'\"")
    LLM_ALLOW_FALLBACK: bool = os.getenv(
        "LLM_ALLOW_FALLBACK",
        "False" if IS_RENDER or ENVIRONMENT in {"production", "prod"} else "True"
    ).lower() == "true"
    
    # Firebase configuration (simulated or real Firestore)
    FIREBASE_MOCK: bool = os.getenv("FIREBASE_MOCK", "True").lower() == "true"
    FIREBASE_CREDENTIALS_PATH: str = os.getenv("FIREBASE_CREDENTIALS_PATH", "").strip().strip("'\"")
    
    # Vercel Configuration (simulated or real Vercel API)
    VERCEL_MOCK: bool = os.getenv("VERCEL_MOCK", "True").lower() == "true"
    VERCEL_AUTH_TOKEN: str = os.getenv("VERCEL_AUTH_TOKEN", "").strip().strip("'\"")
    VERCEL_PROJECT_ID: str = os.getenv("VERCEL_PROJECT_ID", "").strip().strip("'\"")
    VERCEL_TEAM_ID: str = os.getenv("VERCEL_TEAM_ID", "").strip().strip("'\"")
    
    # Security keys
    SECRET_KEY: str = os.getenv("SECRET_KEY", "portfolio_ai_super_secret_session_key_12345").strip().strip("'\"")
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 days
    
    # Storage settings
    LOCAL_STORAGE_DIR: str = os.path.join(os.path.dirname(os.path.abspath(__file__)), "storage")

settings = Settings()

# Ensure local storage directories exist
os.makedirs(settings.LOCAL_STORAGE_DIR, exist_ok=True)
os.makedirs(os.path.join(settings.LOCAL_STORAGE_DIR, "resumes"), exist_ok=True)
os.makedirs(os.path.join(settings.LOCAL_STORAGE_DIR, "portfolios"), exist_ok=True)
os.makedirs(os.path.join(settings.LOCAL_STORAGE_DIR, "templates"), exist_ok=True)
