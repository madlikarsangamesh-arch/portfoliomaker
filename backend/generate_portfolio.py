import os
import sys
import json
import zipfile
import shutil
from PIL import Image, ImageDraw

# Set project root in path
project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.append(project_root)

from backend.config import settings
from backend.agents.orchestrator import orchestrator
from backend.repositories.portfolio_repository import portfolio_repository

def main():
    print("=== AI Portfolio Local Generator ===")
    
    # 1. Ensure local storage folders exist
    os.makedirs(settings.LOCAL_STORAGE_DIR, exist_ok=True)
    os.makedirs(os.path.join(settings.LOCAL_STORAGE_DIR, "profiles"), exist_ok=True)
    os.makedirs(os.path.join(settings.LOCAL_STORAGE_DIR, "resumes"), exist_ok=True)
    os.makedirs(os.path.join(settings.LOCAL_STORAGE_DIR, "portfolios"), exist_ok=True)
    
    # 2. Create a dummy avatar image so base64 compiler can embed a real image
    avatar_path = os.path.join(settings.LOCAL_STORAGE_DIR, "profiles", "avatar.jpg")
    print(f"Creating a sample avatar placeholder at: {avatar_path}")
    img = Image.new('RGB', (128, 128), color = '#00FFCC')
    d = ImageDraw.Draw(img)
    d.ellipse([(32, 32), (96, 96)], fill='#0f172a')
    img.save(avatar_path)
    
    # 3. Define a rich mock developer profile for the user
    user_id = "user_sangamesh"
    portfolio_id = "port_local_dev"
    
    profile = {
        "full_name": "Sangamesh Madlikar",
        "professional_title": "Senior Flutter & AI Engineer",
        "email": "sangamesh@example.com",
        "phone": "+91 98765 43210",
        "location": "Mumbai, India",
        "availability_status": "Open to remote opportunities",
        "profile_photo_url": "/api/v1/static/profiles/avatar.jpg",
        "about_me": "Passionate developer with 5+ years of experience building high-performance cross-platform applications and agentic AI systems. Expert in Flutter, Python, FastAPI, and generative AI integrations.",
        "career_objective": "To architect state-of-the-art mobile and web applications using Flutter and integrate cutting-edge LLM capabilities to automate complex processes.",
        "skills": ["Flutter", "Dart", "Python", "FastAPI", "SQLite", "TensorFlow", "Generative AI", "Vercel", "Git"],
        "skills_details": [
            {"category": "Frontend", "skills": ["Flutter", "Dart", "HTML5", "CSS3"]},
            {"category": "Backend", "skills": ["Python", "FastAPI", "SQLite", "PostgreSQL"]},
            {"category": "AI/ML", "skills": ["Generative AI", "Gemini API", "PyTorch"]}
        ],
        "education": [
            {
                "institution": "Indian University of Technology",
                "degree": "Bachelor of Technology",
                "field_of_study": "Computer Science & Engineering",
                "graduation_year": "2021",
                "gpa": "9.2/10"
            }
        ],
        "experience": [
            {
                "company": "TechSolutions Inc.",
                "role": "Senior Software Engineer",
                "start_date": "2023-06",
                "end_date": "Present",
                "description": "Led a team of 4 developers to build a high-performance Flutter mobile application, improving startup load times by 35%. Architected backend API microservices using FastAPI and SQLite."
            },
            {
                "company": "Innovate Labs",
                "role": "Mobile Developer",
                "start_date": "2021-07",
                "end_date": "2023-05",
                "description": "Developed and deployed multiple Flutter applications to App Store and Google Play. Integrated Firebase Analytics, Cloud Firestore, and push notification systems."
            }
        ],
        "projects": [
            {
                "title": "AI Portfolio Builder",
                "description": "An agentic compiler that interviews users and automatically compiles and deploys stunning portfolios to Vercel.",
                "technologies": ["Flutter", "FastAPI", "Gemini API", "SQLite"],
                "link": "https://github.com/example/portfolio-builder",
                "github_link": "https://github.com/example/portfolio-builder"
            }
        ],
        "certifications": [
            {"name": "Google Certified Professional Cloud Architect", "issuer": "Google Cloud", "date": "2024"}
        ],
        "social_links": {
            "GitHub": "https://github.com/madlikarsangamesh-arch",
            "LinkedIn": "https://linkedin.com/in/sangamesh-madlikar"
        }
    }
    
    design_prefs = {
        "template": "developer",
        "portfolio_template": "developer",
        "cv_template": "modern",
        "primary_color": "#00FFCC",
        "secondary_color": "#0f172a",
        "font": "Fira Code",
    }
    
    # 4. Run the full compilation loop pipeline
    print("Running Orchestration loop pipeline...")
    result = orchestrator.run_pipeline(
        user_id=user_id,
        portfolio_id=portfolio_id,
        profile_input=profile,
        design_prefs=design_prefs,
        resume_bytes=None,
        resume_name=None,
        request=None
    )
    
    if not result.get("success"):
        print(f"Error: Generation failed! Details: {result.get('error')}")
        return
        
    print("Pipeline run completed successfully!")
    
    # 5. Extract compiled code and assets from repository
    portfolio_record = portfolio_repository.get_by_id(portfolio_id)
    if not portfolio_record:
        print("Error: Could not retrieve compiled portfolio from database.")
        return
        
    html = portfolio_record.get("html_code", "")
    css = portfolio_record.get("css_code", "")
    js = portfolio_record.get("js_code", "")
    
    # 6. Create dist/ output directory in workspace root
    dist_dir = os.path.join(project_root, "..", "dist")
    os.makedirs(dist_dir, exist_ok=True)
    
    # Write files
    index_path = os.path.join(dist_dir, "index.html")
    style_path = os.path.join(dist_dir, "style.css")
    script_path = os.path.join(dist_dir, "script.js")
    
    with open(index_path, "w", encoding="utf-8") as f:
        f.write(html)
    with open(style_path, "w", encoding="utf-8") as f:
        f.write(css)
    with open(script_path, "w", encoding="utf-8") as f:
        f.write(js)
        
    # Copy PDF resume if generated
    pdf_filename = f"resume_{user_id}_{portfolio_id[:6]}.pdf"
    pdf_local_path = os.path.join(settings.LOCAL_STORAGE_DIR, "resumes", pdf_filename)
    dist_pdf_path = os.path.join(dist_dir, "resume.pdf")
    if os.path.exists(pdf_local_path):
        shutil.copy(pdf_local_path, dist_pdf_path)
        print("Copied PDF resume to dist/resume.pdf")
        
    # 7. Create ZIP archive
    zip_path = os.path.join(dist_dir, "portfolio_source.zip")
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zip_file:
        zip_file.write(index_path, "index.html")
        zip_file.write(style_path, "style.css")
        zip_file.write(script_path, "script.js")
        if os.path.exists(dist_pdf_path):
            zip_file.write(dist_pdf_path, "resume.pdf")
            
    print("\n=== Generation Results ===")
    print(f"Generated files saved in: {os.path.abspath(dist_dir)}")
    print(f"- HTML file: {os.path.abspath(index_path)}")
    print(f"- CSS file: {os.path.abspath(style_path)}")
    print(f"- JS file: {os.path.abspath(script_path)}")
    print(f"- Source code ZIP package: {os.path.abspath(zip_path)}")
    print("==========================")
    print("You can now open index.html locally in any web browser to view your portfolio offline, or upload the ZIP package manually to Vercel!")

if __name__ == "__main__":
    main()
