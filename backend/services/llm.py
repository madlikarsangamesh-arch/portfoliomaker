import os
import json
import logging

try:
    import google.generativeai as genai
    HAS_GEMINI = True
except ImportError:
    HAS_GEMINI = False

from backend.config import settings

logger = logging.getLogger("PortfolioAI.LLM")

class LLMService:
    def __init__(self):
        self.api_key = settings.GEMINI_API_KEY
        self.active = HAS_GEMINI and bool(self.api_key)
        if self.active:
            try:
                genai.configure(api_key=self.api_key)
                self.model = genai.GenerativeModel("gemini-1.5-flash")
                logger.info("Gemini API initialized successfully.")
            except Exception as e:
                logger.error(f"Failed to initialize Gemini: {e}")
                self.active = False
        else:
            logger.info("Using simulated LLM service.")

    def _call_gemini(self, prompt: str, system_instruction: str = None) -> str:
        if not self.active:
            raise ValueError("Gemini is not configured or active.")
        try:
            model = self.model
            if system_instruction:
                model = genai.GenerativeModel("gemini-1.5-flash", system_instruction=system_instruction)
            response = model.generate_content(prompt)
            return response.text
        except Exception as e:
            logger.error(f"Gemini API call failed: {e}")
            raise e

    def call(self, prompt: str, system_instruction: str = None, fallback_response: str = "") -> str:
        if self.active:
            try:
                return self._call_gemini(prompt, system_instruction)
            except Exception:
                logger.warning("Gemini call failed. Falling back to simulated response.")
                return fallback_response
        return fallback_response

    def call_json(self, prompt: str, system_instruction: str = None, fallback_data: dict = None) -> dict:
        if fallback_data is None:
            fallback_data = {}
        
        prompt_with_format = f"{prompt}\n\nRespond ONLY with a valid JSON object. Do not include markdown code block formatting (like ```json ... ```)."
        
        raw_response = self.call(prompt_with_format, system_instruction, json.dumps(fallback_data))
        
        try:
            cleaned = raw_response.strip()
            if cleaned.startswith("```json"):
                cleaned = cleaned[7:]
            if cleaned.endswith("```"):
                cleaned = cleaned[:-3]
            cleaned = cleaned.strip()
            return json.loads(cleaned)
        except Exception as e:
            logger.error(f"Failed to parse JSON response: {e}. Raw content: {raw_response[:200]}")
            return fallback_data

llm_service = LLMService()
