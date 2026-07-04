import io
import json
import uuid
import zipfile
from typing import Optional, List
from fastapi import APIRouter, File, UploadFile, Form, HTTPException, Depends
from fastapi.responses import StreamingResponse
from backend.models.schemas import UserProfile, DesignPreferences
from backend.repositories.portfolio_repository import portfolio_repository
from backend.agents.orchestrator import orchestrator
from backend.services.firebase import firebase_service

router = APIRouter(prefix="/portfolios", tags=["Portfolios"])

@router.post("/generate")
async def generate_portfolio(
    user_id: str = Form(...),
    portfolio_id: Optional[str] = Form(None),
    profile_data_str: str = Form(...),  # JSON string of profile info
    design_prefs_str: str = Form(...),   # JSON string of design choices
    resume_file: Optional[UploadFile] = File(None)
):
    try:
        profile_dict = json.loads(profile_data_str)
        design_dict = json.loads(design_prefs_str)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid profile or design JSON formats.")

    if not portfolio_id:
        portfolio_id = f"port_{uuid.uuid4().hex[:12]}"

    resume_bytes = None
    resume_name = None
    if resume_file:
        resume_bytes = await resume_file.read()
        resume_name = resume_file.filename
        
        # Upload resume to storage for later downloads
        filename = f"resume_{user_id}_{portfolio_id[:6]}_{resume_name}"
        uploaded_url = firebase_service.upload_file("resumes", filename, resume_bytes)
        profile_dict["resume_url"] = uploaded_url

    # Run loop agents orchestrator pipeline
    result = orchestrator.run_pipeline(
        user_id=user_id,
        portfolio_id=portfolio_id,
        profile_input=profile_dict,
        design_prefs=design_dict,
        resume_bytes=resume_bytes,
        resume_name=resume_name
    )

    if not result.get("success") and result.get("current_step") == "info_collection":
        # Missing fields - return questions
        return {
            "status": "incomplete",
            "missing_fields": result.get("missing_fields"),
            "follow_up_questions": result.get("follow_up_questions"),
            "profile": result.get("profile"),
            "steps": result.get("steps")
        }
    elif not result.get("success"):
        raise HTTPException(status_code=500, detail=result.get("error", "Generation failed"))

    return {
        "status": "completed",
        "portfolio_id": result.get("portfolio_id"),
        "deployment_url": result.get("deployment_url"),
        "recruiter_scorecard": result.get("recruiter_scorecard"),
        "resume_url": result.get("resume_url"),
        "steps": result.get("steps")
    }

@router.get("/user/{user_id}")
def get_user_portfolios(user_id: str):
    return portfolio_repository.get_by_user_id(user_id)

@router.get("/detail/{portfolio_id}")
def get_portfolio_detail(portfolio_id: str):
    portfolio = portfolio_repository.get_by_id(portfolio_id)
    if not portfolio:
        raise HTTPException(status_code=404, detail="Portfolio not found")
    return portfolio

@router.get("/download-source/{portfolio_id}")
def download_source(portfolio_id: str):
    portfolio = portfolio_repository.get_by_id(portfolio_id)
    if not portfolio:
        raise HTTPException(status_code=404, detail="Portfolio not found")
        
    html = portfolio.get("html_code", "")
    css = portfolio.get("css_code", "")
    js = portfolio.get("js_code", "")
    
    # Create ZIP archive in memory
    zip_buffer = io.BytesIO()
    with zipfile.ZipFile(zip_buffer, "w", zipfile.ZIP_DEFLATED) as zip_file:
        zip_file.writestr("index.html", html)
        zip_file.writestr("style.css", css)
        zip_file.writestr("script.js", js)
        
    zip_buffer.seek(0)
    
    headers = {
        'Content-Disposition': f'attachment; filename="portfolio_source_{portfolio_id[:6]}.zip"'
    }
    
    return StreamingResponse(
        zip_buffer,
        media_type="application/x-zip-compressed",
        headers=headers
    )
