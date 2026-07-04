import re
from backend.services.llm import llm_service
from backend.prompts.agent_prompts import QA_REVIEW_PROMPT

class QAAgent:
    def __init__(self):
        pass

    def verify_and_fix(self, html: str, css: str, js: str) -> tuple:
        """
        Runs quality checks and auto-corrects simple issues:
        - Ensures '<meta name="viewport"' exists for mobile responsiveness.
        - Ensures all images have 'alt' tags for accessibility.
        - Verifies CSS file links match correctly.
        """
        fixed_html = html
        
        # 1. Viewport verification
        if 'name="viewport"' not in html.lower():
            viewport_tag = '\n    <meta name="viewport" content="width=device-width, initial-scale=1.0">'
            fixed_html = fixed_html.replace("<head>", f"<head>{viewport_tag}")
            
        # 2. Basic accessibility check (alt tag additions)
        img_tags = re.findall(r'<img[^>]+>', fixed_html)
        for tag in img_tags:
            if 'alt=' not in tag.lower():
                alt_tag = tag[:-1] + ' alt="Portfolio Image">'
                fixed_html = fixed_html.replace(tag, alt_tag)
                
        # 3. Simple css verification
        if 'href="style.css"' not in fixed_html:
            style_tag = '\n    <link rel="stylesheet" href="style.css">'
            fixed_html = fixed_html.replace("</head>", f"{style_tag}\n</head>")

        return fixed_html, css, js

    def perform_recruiter_review(self, profile: dict) -> dict:
        """
        Acts like a strict recruiter, rating the profile out of 100
        and listing strengths, weaknesses, and tips to improve hireability.
        """
        prompt = QA_REVIEW_PROMPT.format(
            name=profile.get("full_name", ""),
            title=profile.get("professional_title", ""),
            about_me=profile.get("about_me", ""),
            skills=", ".join(profile.get("skills", [])),
            experience_len=len(profile.get("experience", [])),
            projects_len=len(profile.get("projects", []))
        )
        
        fallback_review = {
            "overall_score": 80,
            "strengths": ["Clear professional title", "Solid list of core skills"],
            "weaknesses": ["About me could highlight more results", "No links provided for projects"],
            "suggestions": ["Include metrics in experience", "Add personal GitHub link"]
        }
        
        scorecard = llm_service.call_json(
            prompt=prompt,
            system_instruction="You are a senior recruiter reviewing portfolios. Be honest, direct, and constructive.",
            fallback_data=fallback_review
        )
        
        return scorecard

qa_agent = QAAgent()
