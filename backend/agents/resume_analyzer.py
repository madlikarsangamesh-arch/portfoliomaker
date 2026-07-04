import io
import json
import logging
from typing import Dict, Any
from backend.services.llm import llm_service
from backend.prompts.agent_prompts import RESUME_PARSER_PROMPT

logger = logging.getLogger("PortfolioAI.ResumeAnalyzer")

try:
    import PyPDF2
    HAS_PDF_PARSER = True
except ImportError:
    HAS_PDF_PARSER = False

class ResumeAnalyzerAgent:
    def __init__(self):
        pass

    def extract_text_from_pdf(self, pdf_bytes: bytes) -> str:
        if not HAS_PDF_PARSER:
            logger.warning("PyPDF2 is not installed, parsing pdf bytes as raw string decode fallback.")
            try:
                return pdf_bytes.decode('utf-8', errors='ignore')
            except Exception:
                return "Error: PyPDF2 not installed and text decoding failed."
        
        try:
            pdf_file = io.BytesIO(pdf_bytes)
            reader = PyPDF2.PdfReader(pdf_file)
            text = ""
            for page in reader.pages:
                page_text = page.extract_text()
                if page_text:
                    text += page_text + "\n"
            return text
        except Exception as e:
            logger.error(f"Failed to extract text from PDF: {e}")
            return pdf_bytes.decode('utf-8', errors='ignore')

    def parse_resume(self, file_content: bytes, filename: str) -> dict:
        """
        Parses resume text content into structured JSON using LLM.
        """
        if filename.lower().endswith(".pdf"):
            text = self.extract_text_from_pdf(file_content)
        else:
            try:
                text = file_content.decode('utf-8', errors='ignore')
            except Exception as e:
                logger.error(f"Failed to decode text file: {e}")
                text = "Error decoding file."

        prompt = RESUME_PARSER_PROMPT.format(text=text[:6000])

        fallback_data = {
            "full_name": "",
            "professional_title": "",
            "email": "",
            "phone": "",
            "location": "",
            "about_me": "",
            "skills": [],
            "education": [],
            "experience": [],
            "projects": [],
            "certifications": [],
            "achievements": [],
            "languages": []
        }

        parsed = llm_service.call_json(
            prompt=prompt,
            system_instruction="You are a professional resume parser. Parse resume details meticulously into clean, structured JSON.",
            fallback_data=fallback_data
        )

        return parsed

    def merge_profiles(self, manual_info: dict, parsed_resume: dict) -> dict:
        """
        Merges manually entered profile details with resume parsed details.
        """
        merged = {}
        for field in ["full_name", "professional_title", "email", "phone", "location", "profile_photo_url", "about_me", "github", "linkedin"]:
            merged[field] = manual_info.get(field) or parsed_resume.get(field) or ""
            
        skills_set = set()
        for s in manual_info.get("skills", []) + parsed_resume.get("skills", []):
            if s and s.strip():
                skills_set.add(s.strip())
        merged["skills"] = list(skills_set)

        edu_dict = {}
        for item in parsed_resume.get("education", []) + manual_info.get("education", []):
            key = f"{item.get('institution', '')}-{item.get('degree', '')}".lower().strip()
            if key and key != "-":
                edu_dict[key] = item
        merged["education"] = list(edu_dict.values())

        exp_dict = {}
        for item in parsed_resume.get("experience", []) + manual_info.get("experience", []):
            key = f"{item.get('company', '')}-{item.get('role', '')}".lower().strip()
            if key and key != "-":
                exp_dict[key] = item
        merged["experience"] = list(exp_dict.values())

        proj_dict = {}
        for item in parsed_resume.get("projects", []) + manual_info.get("projects", []):
            key = item.get("title", "").lower().strip()
            if key:
                proj_dict[key] = item
        merged["projects"] = list(proj_dict.values())

        cert_dict = {}
        for item in parsed_resume.get("certifications", []) + manual_info.get("certifications", []):
            key = item.get("name", "").lower().strip()
            if key:
                cert_dict[key] = item
        merged["certifications"] = list(cert_dict.values())

        ach_dict = {}
        for item in parsed_resume.get("achievements", []) + manual_info.get("achievements", []):
            key = item.get("title", "").lower().strip()
            if key:
                ach_dict[key] = item
        merged["achievements"] = list(ach_dict.values())

        lang_set = set(manual_info.get("languages", []) or []) | set(parsed_resume.get("languages", []) or [])
        merged["languages"] = list(lang_set)
        
        int_set = set(manual_info.get("interests", []) or []) | set(parsed_resume.get("interests", []) or [])
        merged["interests"] = list(int_set)

        return merged

resume_analyzer_agent = ResumeAnalyzerAgent()
