from typing import Dict, Any
from backend.services.llm import llm_service
from backend.prompts.agent_prompts import PLANNER_PROMPT, SKILLS_MAP_PROMPT

TEMPLATE_PRESETS = {
    "developer": {
        "primary_color": "#00ffcc",
        "secondary_color": "#0f172a",
        "font": "Fira Code",
        "background_style": "dark-mesh",
        "button_style": "square",
        "icon_pack": "lucide",
        "animations": True,
        "layout": "split-terminal"
    },
    "minimal": {
        "primary_color": "#111111",
        "secondary_color": "#767676",
        "font": "Inter",
        "background_style": "solid-white",
        "button_style": "pill",
        "icon_pack": "lucide",
        "animations": False,
        "layout": "single-column"
    },
    "corporate": {
        "primary_color": "#1e40af",
        "secondary_color": "#f8fafc",
        "font": "Roboto",
        "background_style": "light-gradient",
        "button_style": "rounded",
        "icon_pack": "lucide",
        "animations": True,
        "layout": "classic-rows"
    },
    "creative": {
        "primary_color": "#ec4899",
        "secondary_color": "#8b5cf6",
        "font": "Outfit",
        "background_style": "neon-glow",
        "button_style": "pill",
        "icon_pack": "lucide",
        "animations": True,
        "layout": "masonry-grid"
    },
    "glassmorphism": {
        "primary_color": "#ffffff",
        "secondary_color": "#3b82f6",
        "font": "Inter",
        "background_style": "glass-blur",
        "button_style": "rounded",
        "icon_pack": "lucide",
        "animations": True,
        "layout": "card-overlay"
    },
    "cyberpunk": {
        "primary_color": "#ffe600",
        "secondary_color": "#ff007c",
        "font": "Share Tech Mono",
        "background_style": "neon-lines",
        "button_style": "square",
        "icon_pack": "lucide",
        "animations": True,
        "layout": "glitch-blocks"
    },
    "apple style": {
        "primary_color": "#1d1d1f",
        "secondary_color": "#86868b",
        "font": "SF Pro Display",
        "background_style": "clean-grey",
        "button_style": "pill",
        "icon_pack": "lucide",
        "animations": True,
        "layout": "horizontal-scroll"
    },
    "modern saas": {
        "primary_color": "#6366f1",
        "secondary_color": "#f4f4f5",
        "font": "Plus Jakarta Sans",
        "background_style": "saas-waves",
        "button_style": "rounded",
        "icon_pack": "lucide",
        "animations": True,
        "layout": "feature-cards"
    },
    "dark theme": {
        "primary_color": "#a855f7",
        "secondary_color": "#09090b",
        "font": "Cabinet Grotesk",
        "background_style": "starry-sky",
        "button_style": "rounded",
        "icon_pack": "lucide",
        "animations": True,
        "layout": "grid-cards"
    },
    "light theme": {
        "primary_color": "#0f172a",
        "secondary_color": "#fafafa",
        "font": "Lora",
        "background_style": "soft-cream",
        "button_style": "rounded",
        "icon_pack": "lucide",
        "animations": True,
        "layout": "clean-rows"
    }
}

class PlannerAgent:
    def __init__(self):
        pass

    def create_portfolio_plan(self, profile: dict, design_prefs: dict) -> dict:
        """
        Creates design choices based on preferences.
        """
        template_name = design_prefs.get("template", "minimal").lower()
        plan = TEMPLATE_PRESETS.get(template_name, TEMPLATE_PRESETS["minimal"]).copy()
        
        if design_prefs.get("primary_color"):
            plan["primary_color"] = design_prefs["primary_color"]
        if design_prefs.get("secondary_color"):
            plan["secondary_color"] = design_prefs["secondary_color"]
        if design_prefs.get("font"):
            plan["font"] = design_prefs["font"]
            
        description = design_prefs.get("inspiration_description", "")
        url = design_prefs.get("inspiration_url", "")
        
        if description or url:
            prompt = PLANNER_PROMPT.format(
                description=description,
                url=url,
                template_name=template_name,
                primary=plan["primary_color"],
                secondary=plan["secondary_color"],
                font=plan["font"],
                layout=plan["layout"]
            )
            
            ai_plan = llm_service.call_json(
                prompt=prompt,
                system_instruction="You are a senior UI/UX designer. Pick elegant palettes, professional layouts, and font hierarchies.",
                fallback_data=plan
            )
            if isinstance(ai_plan, dict):
                for k in plan.keys():
                    if k in ai_plan and ai_plan[k]:
                        plan[k] = ai_plan[k]

        plan["sections"] = design_prefs.get("section_order", [
            "home", "about", "skills", "experience", "projects", "education", "certifications", "contact"
        ])
        
        plan["navigation"] = [
            {"label": s.capitalize(), "anchor": f"#{s}"} for s in plan["sections"]
        ]
        
        prompt_icons = SKILLS_MAP_PROMPT.format(skills=", ".join(profile.get("skills", [])))
        fallback_icons = {s: "code" for s in profile.get("skills", [])}
        
        plan["skills_icons"] = llm_service.call_json(
            prompt=prompt_icons,
            system_instruction="Map tech skills to Lucide icon string representations accurately.",
            fallback_data=fallback_icons
        )

        return plan

planner_agent = PlannerAgent()
