import os
import sys

import uvicorn

# Append project root to sys.path so `backend.*` imports resolve correctly
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

if __name__ == "__main__":
    port = int(os.getenv("PORT", "8000"))
    reload = os.getenv("ENVIRONMENT", "development").lower() not in {"production", "prod"}
    uvicorn.run(
        "backend.main:app",
        host=os.getenv("HOST", "0.0.0.0"),
        port=port,
        reload=reload,
        proxy_headers=True,
        forwarded_allow_ips="*",
    )
