from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any

# Profile Sections
class ExperienceItem(BaseModel):
    company: str
    role: str
    start_date: str
    end_date: str
    description: str
    skills_used: Optional[List[str]] = []
    duration: Optional[str] = None
    experience_type: Optional[str] = "Job"
    responsibilities: Optional[List[str]] = []
    tools: Optional[List[str]] = []
    certificate_link: Optional[str] = None


class ProjectItem(BaseModel):
    title: str
    description: str
    technologies: List[str]
    link: Optional[str] = None
    github_link: Optional[str] = None
    problem_statement: Optional[str] = None
    role_or_teammates: Optional[str] = None
    features: Optional[List[str]] = []
    screenshots: Optional[List[str]] = []
    outcomes_or_metrics: Optional[str] = None


class EducationItem(BaseModel):
    institution: str
    degree: str
    field_of_study: str
    graduation_year: str
    gpa: Optional[str] = None
    branch: Optional[str] = None
    duration: Optional[str] = None
    coursework: Optional[List[str]] = []
    education_type: Optional[str] = "college"


class CertificationItem(BaseModel):
    name: str
    issuer: str
    date: str
    link: Optional[str] = None

class AchievementItem(BaseModel):
    title: str
    description: str
    date: str

class SkillItem(BaseModel):
    name: str
    category: str
    proficiency: Optional[str] = None
    icon: Optional[str] = None

class ExtracurricularItem(BaseModel):
    activity: str
    role: str
    organization: Optional[str] = None
    duration: Optional[str] = None
    description: Optional[str] = None

class TestimonialItem(BaseModel):
    quote: str
    name: str
    designation: Optional[str] = None
    relation: Optional[str] = None

class BlogItem(BaseModel):
    title: str
    date: str
    summary: Optional[str] = None
    link: str

# Core User Profile Data
class UserProfile(BaseModel):
    full_name: str
    professional_title: str
    email: str
    phone: Optional[str] = None
    location: Optional[str] = None
    profile_photo_url: Optional[str] = None
    about_me: str
    skills: List[str]
    education: List[EducationItem] = []
    experience: List[ExperienceItem] = []
    projects: List[ProjectItem] = []
    certifications: List[CertificationItem] = []
    achievements: List[AchievementItem] = []
    languages: Optional[List[str]] = []
    interests: Optional[List[str]] = []
    github: Optional[str] = None
    linkedin: Optional[str] = None
    portfolio_url: Optional[str] = None
    resume_path: Optional[str] = None
    availability_status: Optional[str] = None
    career_objective: Optional[str] = None
    skills_details: Optional[List[SkillItem]] = []
    competitions: Optional[List[str]] = []
    publications: Optional[List[str]] = []
    scholarships: Optional[List[str]] = []
    extracurriculars: Optional[List[ExtracurricularItem]] = []
    testimonials: Optional[List[TestimonialItem]] = []
    blogs: Optional[List[BlogItem]] = []
    social_links: Optional[Dict[str, str]] = {}

# Design Preferences
class DesignPreferences(BaseModel):
    template: str
    primary_color: str
    secondary_color: str
    font: str
    animations: bool = True
    section_order: List[str] = ["home", "about", "skills", "experience", "projects", "education", "certifications", "contact"]
    background_style: str = "gradient"
    icon_pack: str = "lucide"
    button_style: str = "rounded"
    inspiration_description: Optional[str] = None
    inspiration_url: Optional[str] = None
    inspiration_image_path: Optional[str] = None
    portfolio_template: Optional[str] = "minimal"
    cv_template: Optional[str] = "classic"


# Recruiter Score Card
class RecruiterScoreCard(BaseModel):
    overall_score: int
    strengths: List[str]
    weaknesses: List[str]
    suggestions: List[str]

# Full Portfolio Data
class PortfolioData(BaseModel):
    id: Optional[str] = None
    user_id: str
    profile: UserProfile
    design: DesignPreferences
    html_code: Optional[str] = None
    css_code: Optional[str] = None
    js_code: Optional[str] = None
    deployment_url: Optional[str] = None
    qr_code_base64: Optional[str] = None
    recruiter_scorecard: Optional[RecruiterScoreCard] = None
    created_at: str
    updated_at: str
    is_active: bool = True
    version: int = 1

# Authentication
class UserLogin(BaseModel):
    email: str
    password: str

class UserRegister(BaseModel):
    email: str
    password: str
    full_name: str

class UserResponse(BaseModel):
    id: str
    email: str
    full_name: str
    role: str = "user"
    token: Optional[str] = None

# Analytics
class AnalyticsSummary(BaseModel):
    visitors: int = 0
    views: int = 0
    countries: Dict[str, int] = {}
    devices: Dict[str, int] = {}
    sources: Dict[str, int] = {}
    resume_downloads: int = 0

class PageViewLog(BaseModel):
    portfolio_id: str
    visitor_id: str
    timestamp: str
    country: str
    device: str
    source: str
    is_resume_download: bool = False
