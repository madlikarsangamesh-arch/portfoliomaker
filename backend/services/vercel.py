import requests
import logging
from backend.config import settings

logger = logging.getLogger("PortfolioAI.Vercel")

class VercelService:
    def __init__(self):
        self.token = settings.VERCEL_AUTH_TOKEN
        self.mock = settings.VERCEL_MOCK or not bool(self.token)
        self.headers = {
            "Authorization": f"Bearer {self.token}",
            "Content-Type": "application/json"
        }

    def deploy_static_site(self, project_name: str, html: str, css: str, js: str) -> dict:
        """
        Deploys a static portfolio site directly to Vercel using Vercel REST APIs.
        """
        clean_name = "".join(c for c in project_name.lower() if c.isalnum() or c == "-")
        if not clean_name:
            clean_name = "my-portfolio"
            
        if self.mock:
            logger.info("Simulating Vercel static deployment.")
            mock_url = f"https://{clean_name}-ai-portfolio.vercel.app"
            return {
                "success": True,
                "url": mock_url,
                "deployment_id": "dpl_mock_1234567890",
                "project_name": clean_name
            }

        try:
            url = "https://api.vercel.com/v13/deployments"
            payload = {
                "name": clean_name,
                "files": [
                    {
                        "file": "index.html",
                        "data": html
                    },
                    {
                        "file": "style.css",
                        "data": css
                    },
                    {
                        "file": "script.js",
                        "data": js
                    }
                ],
                "projectSettings": {
                    "framework": None
                }
            }
            
            params = {}
            if settings.VERCEL_TEAM_ID:
                params["teamId"] = settings.VERCEL_TEAM_ID

            response = requests.post(url, headers=self.headers, json=payload, params=params)
            
            if response.status_code in [200, 201]:
                res_data = response.json()
                deploy_url = f"https://{res_data.get('url')}"
                return {
                    "success": True,
                    "url": deploy_url,
                    "deployment_id": res_data.get("id"),
                    "project_name": clean_name
                }
            else:
                logger.error(f"Vercel Deployment Failed (HTTP {response.status_code}): {response.text}")
                return {
                    "success": False,
                    "error": response.text,
                    "url": None
                }
        except Exception as e:
            logger.error(f"Vercel Service Error: {e}")
            return {
                "success": False,
                "error": str(e),
                "url": None
            }

vercel_service = VercelService()
