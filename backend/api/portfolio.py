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

    # Save to CV History
    try:
        port_rec = portfolio_repository.get_by_id(portfolio_id)
        ver = port_rec.get("version", 1) if port_rec else 1
        portfolio_repository.save_cv_version(
            user_id=user_id,
            portfolio_id=portfolio_id,
            resume_url=result.get("resume_url"),
            version=ver,
            created_at="2026-07-04T20:30:00Z"
        )
    except Exception as ex:
        import logging
        logging.getLogger("PortfolioAI.API.Portfolio").error(f"Failed to save CV version: {ex}")

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

@router.post("/save")
def save_portfolio(payload: dict):
    portfolio_id = payload.get("portfolio_id")
    user_id = payload.get("user_id")
    profile = payload.get("profile")
    design = payload.get("design")
    
    if not portfolio_id or not user_id:
        raise HTTPException(status_code=400, detail="Missing user_id or portfolio_id.")
        
    existing = portfolio_repository.get_by_id(portfolio_id)
    version = existing.get("version", 1) if existing else 1
    created_at = existing.get("created_at") if existing else "2026-07-04T20:30:00Z"
    
    data = {
        "id": portfolio_id,
        "user_id": user_id,
        "profile": profile,
        "design": design,
        "html_code": existing.get("html_code") if existing else None,
        "css_code": existing.get("css_code") if existing else None,
        "js_code": existing.get("js_code") if existing else None,
        "deployment_url": existing.get("deployment_url") if existing else None,
        "recruiter_scorecard": existing.get("recruiter_scorecard") if existing else None,
        "is_active": True,
        "version": version,
        "created_at": created_at,
        "updated_at": "2026-07-04T20:30:00Z"
    }
    portfolio_repository.save(portfolio_id, data)
    return {"status": "success", "message": "Autosaved successfully."}

@router.post("/upload-image")
async def upload_image(
    file: UploadFile = File(...),
    folder: str = Form("images")
):
    try:
        import os
        from backend.config import settings
        file_bytes = await file.read()
        filename = file.filename
        original_size = len(file_bytes)
        
        # Save file to disk/cloud with compression in firebase_service
        url = firebase_service.upload_file(folder, filename, file_bytes)
        
        # Get compressed size
        compressed_size = original_size
        filename_only = os.path.basename(url)
        local_path = os.path.join(settings.LOCAL_STORAGE_DIR, folder, filename_only)
        if os.path.exists(local_path):
            compressed_size = os.path.getsize(local_path)
            
        return {
            "status": "success", 
            "url": url, 
            "original_size": original_size, 
            "compressed_size": compressed_size
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Image upload failed: {e}")

@router.post("/ai-polish")
def ai_polish(payload: dict):
    from backend.services.llm import llm_service
    text = payload.get("text", "")
    context = payload.get("context", "")
    
    if not text:
        raise HTTPException(status_code=400, detail="No text provided to polish.")
        
    system_instruction = "You are a professional copywriter and resume optimization assistant. Rewrite the user's bullet point or biography to be highly impactful, quantified, professional, and clear. Keep a similar length."
    prompt = f"Optimize this text.\nContext: {context}\nText to polish: {text}\n\nPolished text:"
    
    polished = llm_service.call(
        prompt=prompt,
        system_instruction=system_instruction,
        fallback_response=text
    )
    return {"status": "success", "polished_text": polished.strip()}

@router.get("/cv-history/{user_id}")
def get_cv_history_endpoint(user_id: str):
    history = portfolio_repository.get_cv_history(user_id)
    return history

@router.post("/extract-resume")
async def extract_resume(
    file: UploadFile = File(...)
):
    try:
        from backend.agents.resume_analyzer import resume_analyzer_agent
        file_bytes = await file.read()
        filename = file.filename
        
        parsed_data = resume_analyzer_agent.parse_resume(file_bytes, filename)
        return {"status": "success", "profile": parsed_data}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Resume extraction failed: {e}")


