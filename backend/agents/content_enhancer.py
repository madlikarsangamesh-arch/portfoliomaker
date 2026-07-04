from backend.services.llm import llm_service
from backend.prompts.agent_prompts import (
    ABOUT_ME_ENHANCE_PROMPT,
    SEO_METADATA_PROMPT,
    SKILLS_SUGGESTION_PROMPT
)

class ContentEnhancerAgent:
    def __init__(self):
        pass

    def enhance_profile(self, profile: dict) -> dict:
        """
        Enhances bio/experience/projects and generates taglines/SEOs.
        """
        enhanced = profile.copy()
        about = profile.get("about_me", "")
        title = profile.get("professional_title", "Professional")
        name = profile.get("full_name", "")
        
        # 1. Enhance Bio
        prompt_about = ABOUT_ME_ENHANCE_PROMPT.format(
            name=name,
            title=title,
            about=about
        )
        enhanced["about_me"] = llm_service.call(
            prompt=prompt_about,
            system_instruction="You are a professional copywriter. Write highly engaging, clean biography profiles.",
            fallback_response=about or f"Passionate {title} dedicated to building high-quality solutions."
        ).strip()

        # 2. SEO & Taglines
        prompt_metadata = SEO_METADATA_PROMPT.format(
            name=name,
            title=title,
            about_me=enhanced["about_me"]
        )
        fallback_meta = {
            "tagline": f"Crafting clean code and elegant designs as a {title}.",
            "seo_description": f"Portfolio of {name} - Professional {title}.",
            "social_preview": f"Check out my portfolio! - {name}"
        }
        meta = llm_service.call_json(
            prompt=prompt_metadata,
            system_instruction="You are an SEO and copywriter expert.",
            fallback_data=fallback_meta
        )
        enhanced["tagline"] = meta.get("tagline", fallback_meta["tagline"])
        enhanced["seo_description"] = meta.get("seo_description", fallback_meta["seo_description"])
        enhanced["social_preview"] = meta.get("social_preview", fallback_meta["social_preview"])

        # 3. Enhance Work Experience
        enhanced_experience = []
        for exp in profile.get("experience", []):
            exp_copy = exp.copy()
            desc = exp.get("description", "")
            if desc and len(desc.strip()) > 10:
                prompt_exp = f"""
                Enhance this experience description to be professional and impact-driven.
                Role: {exp.get('role')} at {exp.get('company')}
                Current Description: {desc}
                
                Respond with ONLY the enhanced description. No extra explanation.
                """
                exp_copy["description"] = llm_service.call(
                    prompt=prompt_exp,
                    system_instruction="You are a professional resume writer. Write impact-oriented achievements.",
                    fallback_response=desc
                ).strip()
            enhanced_experience.append(exp_copy)
        enhanced["experience"] = enhanced_experience

        # 4. Enhance Project Descriptions
        enhanced_projects = []
        for proj in profile.get("projects", []):
            proj_copy = proj.copy()
            desc = proj.get("description", "")
            if desc and len(desc.strip()) > 10:
                prompt_proj = f"""
                Enhance this project description for a developer portfolio.
                Project: {proj.get('title')}
                Tech Stack: {', '.join(proj.get('technologies', []))}
                Current Description: {desc}
                
                Respond with ONLY the enhanced description. No extra explanation.
                """
                proj_copy["description"] = llm_service.call(
                    prompt=prompt_proj,
                    system_instruction="You are a technology copywriter. Write engaging project summaries.",
                    fallback_response=desc
                ).strip()
            enhanced_projects.append(proj_copy)
        enhanced["projects"] = enhanced_projects

        # 5. Suggest missing skills
        all_skills = [s.lower() for s in enhanced.get("skills", [])]
        skills_str = ", ".join(all_skills)
        prompt_skills = SKILLS_SUGGESTION_PROMPT.format(
            title=title,
            skills=skills_str,
            about_me=enhanced["about_me"]
        )
        suggested_skills = llm_service.call_json(
            prompt=prompt_skills,
            system_instruction="Suggest highly relevant technical skills.",
            fallback_data=[]
        )
        if isinstance(suggested_skills, list):
            enhanced["suggested_skills"] = suggested_skills[:5]
        else:
            enhanced["suggested_skills"] = []

        return enhanced

content_enhancer_agent = ContentEnhancerAgent()
