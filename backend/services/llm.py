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

class LLMServiceError(RuntimeError):
    pass

class LLMConfigurationError(LLMServiceError):
    pass

class LLMService:
    def __init__(self):
        self.api_key = settings.GEMINI_API_KEY
        self.active = HAS_GEMINI and bool(self.api_key)
        self.allow_fallback = settings.LLM_ALLOW_FALLBACK
        self.model_name = settings.GEMINI_MODEL
        if self.active:
            try:
                genai.configure(api_key=self.api_key)
                # Query available models to help diagnose key and regional availability
                try:
                    models = [m.name for m in genai.list_models()]
                    logger.info(f"Available Gemini Models for this key: {models}")
                except Exception as list_err:
                    logger.warning(f"Could not list available models for key: {list_err}")

                self.model = genai.GenerativeModel(self.model_name)
                logger.info("Gemini API initialized successfully with model %s.", self.model_name)
            except Exception as e:
                logger.error(f"Failed to initialize Gemini: {e}")
                self.active = False
        else:
            if HAS_GEMINI:
                logger.warning("GEMINI_API_KEY is not configured.")
            else:
                logger.warning("google-generativeai package is not installed.")
            if self.allow_fallback:
                logger.info("Using simulated LLM service because LLM_ALLOW_FALLBACK=true.")

    def _call_gemini(self, prompt: str, system_instruction: str = None) -> str:
        if not self.active:
            if not HAS_GEMINI:
                raise LLMConfigurationError("Gemini SDK is not installed.")
            if not self.api_key:
                raise LLMConfigurationError("GEMINI_API_KEY is not configured.")
            raise LLMConfigurationError("Gemini is not active. Check backend startup logs.")
        try:
            model = self.model
            if system_instruction:
                model = genai.GenerativeModel(self.model_name, system_instruction=system_instruction)
            response = model.generate_content(prompt)
            return response.text
        except Exception as e:
            logger.error(f"Gemini API call failed: {e}")
            error_text = str(e)
            if "API_KEY_INVALID" in error_text or "API key not valid" in error_text:
                raise LLMConfigurationError("GEMINI_API_KEY is invalid or revoked.") from e
            raise LLMServiceError(f"Gemini API call failed: {e}") from e

    def call(self, prompt: str, system_instruction: str = None, fallback_response: str = "") -> str:
        try:
            return self._call_gemini(prompt, system_instruction)
        except LLMServiceError:
            if self.allow_fallback:
                logger.warning("Gemini call failed. Falling back to simulated response.")
                return fallback_response
            raise

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
            if self.allow_fallback:
                return fallback_data
            raise LLMServiceError("Gemini returned invalid JSON and fallback is disabled.") from e

llm_service = LLMService()
