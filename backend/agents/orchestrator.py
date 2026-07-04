import logging
import uuid
from typing import Dict, Any, Tuple, List
from backend.agents.info_collector import info_collector_agent
from backend.agents.resume_analyzer import resume_analyzer_agent
from backend.agents.content_enhancer import content_enhancer_agent
from backend.agents.planner import planner_agent
from backend.agents.generator import generator_agent
from backend.agents.qa import qa_agent
from backend.agents.deployer import deployer_agent
from backend.agents.resume_gen import resume_generator_agent
from backend.agents.db_agent import db_agent

logger = logging.getLogger("PortfolioAI.Orchestrator")

class Orchestrator:
    def __init__(self):
        pass

    def run_pipeline(
        self,
        user_id: str,
        portfolio_id: str,
        profile_input: dict,
        design_prefs: dict,
        resume_bytes: bytes = None,
        resume_name: str = None
    ) -> Dict[str, Any]:
        """
        Runs the full 9-agent Loop workflow orchestrating the portfolio generation.
        """
        logger.info(f"Orchestrator pipeline started for user {user_id}")
        steps_log = []
        
        # Step 1: Resume Analysis (if uploaded)
        profile_data = profile_input
        if resume_bytes:
            steps_log.append("Agent 2: Parsing resume files and extracting data structures...")
            parsed = resume_analyzer_agent.parse_resume(resume_bytes, resume_name)
            profile_data = resume_analyzer_agent.merge_profiles(profile_input, parsed)
        else:
            steps_log.append("Agent 2: Skip resume parsing (no upload).")

        # Step 2: Information Collection Check
        steps_log.append("Agent 1: Checking profile data completeness...")
        # Convert profile_data dict to schema representation for validator
        from backend.models.schemas import UserProfile
        try:
            profile_schema = UserProfile(**profile_data)
            is_complete, missing, follow_ups = info_collector_agent.analyze_completeness(profile_schema)
        except Exception as e:
            logger.error(f"Validation mapping failed: {e}")
            is_complete = True
            missing, follow_ups = [], []

        if not is_complete:
            return {
                "success": False,
                "current_step": "info_collection",
                "missing_fields": missing,
                "follow_up_questions": follow_ups,
                "profile": profile_data,
                "steps": steps_log
            }

        # Step 3: Content Enhancement
        steps_log.append("Agent 3: Enhancing profiles, rewriting summaries, generating tagline & SEO metatags...")
        enhanced_profile = content_enhancer_agent.enhance_profile(profile_data)

        # Step 4: Resume compilation (PDF & HTML formats)
        steps_log.append("Agent 8: Generating professional ATS-friendly resumes and PDF formats...")
        resume_filename = f"resume_{user_id}_{portfolio_id[:6]}.pdf"
        resume_url = resume_generator_agent.generate_pdf_resume(enhanced_profile, resume_filename)
        enhanced_profile["resume_url"] = resume_url

        # Step 5: Planning Design layouts
        steps_log.append("Agent 4: Analyzing template options, screenshots & color design preferences...")
        design_plan = planner_agent.create_portfolio_plan(enhanced_profile, design_prefs)

        # Step 6: Code Generation
        steps_log.append("Agent 5: Compiling custom HTML structure, CSS layouts & responsive JS components...")
        html, css, js = generator_agent.generate_portfolio_files(enhanced_profile, design_plan)

        # Step 7: QA validation & correction
        steps_log.append("Agent 6: Verifying mobile viewport targets, accessibility tags & links...")
        html, css, js = qa_agent.verify_and_fix(html, css, js)
        scorecard = qa_agent.perform_recruiter_review(enhanced_profile)

        # Step 8: Database version controls
        steps_log.append("Agent 9: Storing snapshots, scorecard feedback reports and asset tracks...")
        portfolio_record = db_agent.save_portfolio_version(
            portfolio_id=portfolio_id,
            user_id=user_id,
            profile=enhanced_profile,
            design=design_plan,
            html=html,
            css=css,
            js=js,
            scorecard=scorecard
        )

        # Step 9: Vercel Deployer
        steps_log.append("Agent 7: Triggering Vercel deployment pipeline...")
        deploy_res = deployer_agent.deploy(portfolio_id, html, css, js)

        if deploy_res.get("success"):
            steps_log.append("Agent 7: Deployment completed successfully!")
            return {
                "success": True,
                "current_step": "completed",
                "portfolio_id": portfolio_id,
                "deployment_url": deploy_res.get("url"),
                "recruiter_scorecard": scorecard,
                "resume_url": resume_url,
                "steps": steps_log
            }
        else:
            steps_log.append(f"Agent 7: Deployment failed - {deploy_res.get('error')}")
            return {
                "success": False,
                "current_step": "deployment_failed",
                "error": deploy_res.get("error"),
                "steps": steps_log
            }

orchestrator = Orchestrator()
