import logging
from backend.services.vercel import vercel_service
from backend.repositories.portfolio_repository import portfolio_repository

logger = logging.getLogger("PortfolioAI.Deployer")

class DeployerAgent:
    def __init__(self):
        pass

    def deploy(self, portfolio_id: str, html: str, css: str, js: str) -> dict:
        """
        Deploys portfolio code to Vercel and links URL metadata.
        """
        portfolio = portfolio_repository.get_by_id(portfolio_id)
        if not portfolio:
            raise ValueError("Portfolio not found in database.")
            
        full_name = portfolio["profile"].get("full_name", "user")
        project_name = f"portfolio-{full_name.lower().replace(' ', '-')}-{portfolio_id[:6]}"
        
        logger.info(f"Deploying project: {project_name} to Vercel.")
        
        result = vercel_service.deploy_static_site(
            project_name=project_name,
            html=html,
            css=css,
            js=js
        )
        
        if result.get("success"):
            url = result.get("url")
            portfolio["deployment_url"] = url
            portfolio_repository.save(portfolio_id, portfolio)
            logger.info(f"Deployment successful: {url}")
            return result
        else:
            logger.error(f"Deployment agent encountered error: {result.get('error')}")
            return result

deployer_agent = DeployerAgent()
