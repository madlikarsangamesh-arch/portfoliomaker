from typing import Tuple, List
from backend.models.schemas import UserProfile
from backend.services.llm import llm_service
from backend.prompts.agent_prompts import INTERVIEWER_PROMPT

class InfoCollectorAgent:
    def __init__(self):
        pass

    def analyze_completeness(self, profile: UserProfile) -> Tuple[bool, List[str], List[str]]:
        """
        Analyzes profile completeness and returns:
        - is_complete: bool
        - missing_fields: List of missing critical fields
        - follow_up_questions: LLM generated questions to gather the missing info.
        """
        missing = []
        if not profile.full_name or profile.full_name.strip() == "":
            missing.append("Full Name")
        if not profile.professional_title or profile.professional_title.strip() == "":
            missing.append("Professional Title")
        if not profile.email or profile.email.strip() == "":
            missing.append("Email Address")

        if len(missing) == 0:
            return True, [], []

        prompt = INTERVIEWER_PROMPT.format(
            missing_fields=", ".join(missing),
            name=profile.full_name or "Not Provided",
            title=profile.professional_title or "Not Provided",
            about=profile.about_me[:150] if profile.about_me else "Not Provided"
        )
        
        fallback_questions = [f"Please provide details for your {field.lower()} to complete your profile." for field in missing]
        
        questions = llm_service.call_json(
            prompt=prompt,
            system_instruction="You are an expert recruiter and portfolio interviewer. Ask friendly, conversational, and highly specific follow-up questions.",
            fallback_data=fallback_questions
        )
        
        if not isinstance(questions, list):
            questions = fallback_questions

        return False, missing, questions

info_collector_agent = InfoCollectorAgent()
