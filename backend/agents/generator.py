import os
import json
from typing import Dict, Any

class GeneratorAgent:
    def __init__(self):
        pass

    def generate_portfolio_files(self, profile: dict, design_plan: dict) -> tuple:
        """
        Generates index.html, style.css, and script.js based on profile data and design plan parameters.
        Returns (html_content, css_content, js_content).
        """
        primary_color = design_plan.get("primary_color", "#3b82f6")
        secondary_color = design_plan.get("secondary_color", "#1f2937")
        font_family = design_plan.get("font", "Inter")
        layout_style = design_plan.get("layout", "grid-cards")
        bg_style = design_plan.get("background_style", "gradient")
        button_style = design_plan.get("button_style", "rounded")
        skills_icons = design_plan.get("skills_icons", {})
        
        is_dark = "dark" in design_plan.get("template", "minimal").lower() or "cyberpunk" in design_plan.get("template", "minimal").lower() or "developer" in design_plan.get("template", "minimal").lower()
        
        body_bg = "#09090b" if is_dark else "#fdfdfd"
        text_color = "#f4f4f5" if is_dark else "#18181b"
        card_bg = "rgba(18, 18, 22, 0.7)" if is_dark else "rgba(255, 255, 255, 0.7)"
        border_color = "rgba(255, 255, 255, 0.1)" if is_dark else "rgba(0, 0, 0, 0.08)"
        blur_val = "12px"
        
        css_content = f"""/* Compiled Styles by PortfolioAI */
@import url('https://fonts.googleapis.com/css2?family={font_family.replace(" ", "+")}:wght@300;400;500;600;700&display=swap');

:root {{
    --primary: {primary_color};
    --secondary: {secondary_color};
    --bg: {body_bg};
    --text: {text_color};
    --card-bg: {card_bg};
    --border: {border_color};
    --font: '{font_family}', sans-serif;
    --transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}}

* {{
    box-sizing: border-box;
    margin: 0;
    padding: 0;
    scroll-behavior: smooth;
}}

body {{
    background-color: var(--bg);
    color: var(--text);
    font-family: var(--font);
    line-height: 1.6;
    overflow-x: hidden;
}}

.glass {{
    background: var(--card-bg);
    backdrop-filter: blur({blur_val});
    -webkit-backdrop-filter: blur({blur_val});
    border: 1px solid var(--border);
    box-shadow: 0 8px 32px 0 rgba(0, 0, 0, 0.2);
}}

header {{
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    z-index: 1000;
    padding: 1.25rem 2rem;
    transition: var(--transition);
}}

header.scrolled {{
    background: var(--card-bg);
    backdrop-filter: blur(10px);
    border-bottom: 1px solid var(--border);
    padding: 0.75rem 2rem;
}}

.nav-container {{
    max-width: 1200px;
    margin: 0 auto;
    display: flex;
    justify-content: space-between;
    align-items: center;
}}

.logo {{
    font-size: 1.5rem;
    font-weight: 700;
    color: var(--primary);
    text-decoration: none;
    letter-spacing: -0.5px;
}}

.nav-links {{
    display: flex;
    gap: 2rem;
    list-style: none;
}}

.nav-links a {{
    color: var(--text);
    text-decoration: none;
    font-weight: 500;
    opacity: 0.8;
    transition: var(--transition);
}}

.nav-links a:hover {{
    color: var(--primary);
    opacity: 1;
}}

.mobile-menu-btn {{
    display: none;
    background: none;
    border: none;
    color: var(--text);
    font-size: 1.5rem;
    cursor: pointer;
}}

/* Hero Section */
.hero {{
    min-height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 8rem 2rem 4rem;
    position: relative;
    overflow: hidden;
}}

.hero::after {{
    content: '';
    position: absolute;
    width: 300px;
    height: 300px;
    background: var(--primary);
    filter: blur(120px);
    opacity: 0.15;
    border-radius: 50%;
    top: 20%;
    right: 10%;
    z-index: -1;
}}

.hero-container {{
    max-width: 1200px;
    display: flex;
    align-items: center;
    gap: 4rem;
    width: 100%;
}}

.hero-content {{
    flex: 1;
}}

.hero-title {{
    font-size: 3.5rem;
    font-weight: 800;
    line-height: 1.1;
    margin-bottom: 1.5rem;
}}

.hero-title span {{
    color: var(--primary);
}}

.hero-tagline {{
    font-size: 1.5rem;
    opacity: 0.9;
    margin-bottom: 2rem;
}}

.hero-buttons {{
    display: flex;
    gap: 1rem;
}}

.btn {{
    padding: 0.75rem 1.75rem;
    border-radius: { '30px' if button_style == 'pill' else '8px' if button_style == 'rounded' else '0px' };
    font-weight: 600;
    text-decoration: none;
    cursor: pointer;
    transition: var(--transition);
    border: none;
}}

.btn-primary {{
    background: var(--primary);
    color: #111115;
}}

.btn-primary:hover {{
    opacity: 0.9;
    box-shadow: 0 0 15px var(--primary);
}}

.btn-secondary {{
    background: transparent;
    border: 1px solid var(--border);
    color: var(--text);
}}

.btn-secondary:hover {{
    background: var(--card-bg);
}}

.hero-image-container {{
    width: 350px;
    height: 350px;
    border-radius: 50%;
    overflow: hidden;
    border: 3px solid var(--primary);
    box-shadow: 0 0 30px var(--primary);
}}

.hero-image-container img {{
    width: 100%;
    height: 100%;
    object-fit: cover;
}}

/* Generic Sections */
section {{
    padding: 6rem 2rem;
    max-width: 1200px;
    margin: 0 auto;
}}

.section-title {{
    font-size: 2.25rem;
    font-weight: 700;
    margin-bottom: 3rem;
    display: flex;
    align-items: center;
    gap: 0.75rem;
}}

.section-title::after {{
    content: '';
    flex: 1;
    height: 1px;
    background: var(--border);
}}

/* Skills Grid */
.skills-grid {{
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(140px, 1fr));
    gap: 1.5rem;
}}

.skill-card {{
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    padding: 1.5rem;
    border-radius: 12px;
    transition: var(--transition);
    text-align: center;
}}

.skill-card:hover {{
    transform: translateY(-5px);
    border-color: var(--primary);
}}

.skill-card i {{
    font-size: 2rem;
    margin-bottom: 1rem;
    color: var(--primary);
}}

/* Experience Timeline */
.timeline {{
    position: relative;
    border-left: 2px solid var(--border);
    padding-left: 2rem;
    margin-left: 1rem;
}}

.timeline-item {{
    position: relative;
    margin-bottom: 3rem;
}}

.timeline-item::after {{
    content: '';
    position: absolute;
    width: 16px;
    height: 16px;
    background: var(--primary);
    border-radius: 50%;
    left: -2.6rem;
    top: 0.25rem;
    box-shadow: 0 0 10px var(--primary);
}}

.timeline-date {{
    font-weight: 600;
    color: var(--primary);
    font-size: 0.9rem;
    margin-bottom: 0.5rem;
}}

.timeline-card {{
    padding: 1.75rem;
    border-radius: 16px;
}}

/* Projects Grid */
.projects-grid {{
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
    gap: 2rem;
}}

.project-card {{
    border-radius: 16px;
    overflow: hidden;
    display: flex;
    flex-direction: column;
    height: 100%;
}}

.project-body {{
    padding: 1.75rem;
    display: flex;
    flex-direction: column;
    flex: 1;
}}

.project-title {{
    font-size: 1.35rem;
    margin-bottom: 1rem;
}}

.project-desc {{
    opacity: 0.8;
    margin-bottom: 1.5rem;
    flex: 1;
}}

.project-tech {{
    display: flex;
    flex-wrap: wrap;
    gap: 0.5rem;
    margin-bottom: 1.5rem;
}}

.tech-tag {{
    font-size: 0.75rem;
    padding: 0.25rem 0.75rem;
    border-radius: 20px;
    background: rgba(255, 255, 255, 0.05);
    border: 1px solid var(--border);
}}

.project-links {{
    display: flex;
    gap: 1rem;
}}

/* Contact Form */
.contact-container {{
    display: grid;
    grid-template-columns: 1fr 1.5fr;
    gap: 4rem;
}}

.contact-info {{
    display: flex;
    flex-direction: column;
    gap: 2rem;
}}

.contact-item {{
    display: flex;
    gap: 1rem;
    align-items: center;
}}

.contact-icon {{
    width: 50px;
    height: 50px;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    background: var(--card-bg);
    border: 1px solid var(--border);
    color: var(--primary);
    font-size: 1.25rem;
}}

.contact-form {{
    padding: 2.5rem;
    border-radius: 20px;
    display: flex;
    flex-direction: column;
    gap: 1.5rem;
}}

.form-group {{
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
}}

.form-group label {{
    font-weight: 500;
    font-size: 0.9rem;
}}

.form-control {{
    padding: 0.75rem 1rem;
    background: rgba(0, 0, 0, 0.1);
    border: 1px solid var(--border);
    border-radius: 8px;
    color: var(--text);
    font-family: var(--font);
    outline: none;
    transition: var(--transition);
}}

.form-control:focus {{
    border-color: var(--primary);
}}

footer {{
    text-align: center;
    padding: 3rem 2rem;
    border-top: 1px solid var(--border);
    opacity: 0.8;
}}

@media (max-width: 968px) {{
    .hero-container {{
        flex-direction: column-reverse;
        text-align: center;
        gap: 2rem;
    }}
    .hero-buttons {{
        justify-content: center;
    }}
    .contact-container {{
        grid-template-columns: 1fr;
        gap: 3rem;
    }}
    .nav-links {{
        display: none;
    }}
    .mobile-menu-btn {{
        display: block;
    }}
}}
"""

        nav_html = ""
        for nav in design_plan.get("navigation", []):
            nav_html += f'<li><a href="{nav["anchor"]}">{nav["label"]}</a></li>\n'
            
        sections_html = ""
        sections = design_plan.get("sections", ["home", "about", "skills", "experience", "projects", "education", "certifications", "extracurriculars", "testimonials", "blogs", "contact"])
        
        for section in sections:
            if section == "about" and (profile.get('about_me') or profile.get('career_objective')):
                career_obj_html = f'<p style="font-size: 1.1rem; font-style: italic; opacity: 0.9; margin-bottom: 1.5rem; color: var(--primary);"><strong>Objective:</strong> {profile.get("career_objective")}</p>' if profile.get("career_objective") else ""
                sections_html += f"""
                <section id="about">
                    <h2 class="section-title"><i data-lucide="user"></i> About Me</h2>
                    <div class="glass" style="padding: 2.5rem; border-radius: 20px;">
                        {career_obj_html}
                        <p style="font-size: 1.15rem; margin-bottom: 2rem;">{profile.get('about_me', '')}</p>
                        <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 2rem;">
                            <div>
                                <h4 style="margin-bottom: 0.5rem; color: var(--primary);">Location</h4>
                                <p>{profile.get('location', 'Remote / Worldwide')}</p>
                            </div>
                            {'<div><h4 style="margin-bottom: 0.5rem; color: var(--primary);">Languages</h4><p>' + ", ".join(profile.get('languages', [])) + '</p></div>' if profile.get('languages') else ''}
                            {'<div><h4 style="margin-bottom: 0.5rem; color: var(--primary);">Interests</h4><p>' + ", ".join(profile.get('interests', [])) + '</p></div>' if profile.get('interests') else ''}
                        </div>
                    </div>
                </section>
                """
            elif section == "skills" and (profile.get("skills_details") or profile.get("skills")):
                skills_details = profile.get("skills_details", [])
                if skills_details:
                    categories = {}
                    for s in skills_details:
                        cat = s.get("category", "Other")
                        if cat not in categories:
                            categories[cat] = []
                        categories[cat].append(s)
                    
                    skills_html = ""
                    for cat, items in categories.items():
                        items_html = ""
                        for item in items:
                            icon = item.get("icon") or skills_icons.get(item.get("name"), "code")
                            prof = f'<span style="font-size: 0.8rem; opacity: 0.6; display: block; margin-top: 0.25rem;">{item.get("proficiency")}</span>' if item.get("proficiency") else ""
                            items_html += f"""
                            <div class="skill-card glass" style="display: flex; flex-direction: column; align-items: center; padding: 1.25rem; border-radius: 12px; min-width: 110px; text-align: center;">
                                <i data-lucide="{icon}"></i>
                                <span style="font-weight: 600; font-size: 0.9rem; margin-top: 0.5rem;">{item.get("name")}</span>
                                {prof}
                            </div>
                            """
                        skills_html += f"""
                        <div class="skill-category" style="margin-bottom: 2.5rem;">
                            <h3 style="margin-bottom: 1.25rem; color: var(--primary); text-transform: capitalize; border-bottom: 1px solid var(--border); padding-bottom: 0.5rem;">{cat}</h3>
                            <div style="display: flex; flex-wrap: wrap; gap: 1rem;">
                                {items_html}
                            </div>
                        </div>
                        """
                else:
                    skills_html = '<div style="display: flex; flex-wrap: wrap; gap: 1rem;">'
                    for skill in profile.get("skills", []):
                        icon_name = skills_icons.get(skill, "code")
                        skills_html += f"""
                        <div class="skill-card glass">
                            <i data-lucide="{icon_name}"></i>
                            <span>{skill}</span>
                        </div>
                        """
                    skills_html += '</div>'

                sections_html += f"""
                <section id="skills">
                    <h2 class="section-title"><i data-lucide="cpu"></i> Technical Skills</h2>
                    <div class="skills-wrapper">
                        {skills_html}
                    </div>
                </section>
                """
            elif section == "experience" and profile.get("experience"):
                exp_html = ""
                for exp in profile.get("experience", []):
                    tools_html = ""
                    tools_list = exp.get("tools") or exp.get("skills_used") or []
                    for t in tools_list:
                        tools_html += f'<span class="tech-tag">{t}</span>'
                    
                    resp_html = ""
                    if exp.get("responsibilities"):
                        resp_html = '<ul style="margin: 1rem 0 1rem 1.5rem; list-style-type: disc; opacity: 0.9; font-size: 0.95rem;">'
                        for resp in exp.get("responsibilities", []):
                            resp_html += f'<li style="margin-bottom: 0.5rem;">{resp}</li>'
                        resp_html += '</ul>'
                    else:
                        resp_html = f'<p style="opacity: 0.9; margin-bottom: 1rem; font-size: 0.95rem;">{exp.get("description", "")}</p>'
                    
                    dur = exp.get("duration") or f"{exp.get('start_date', '')} - {exp.get('end_date', '')}"
                    exp_type = f'<span class="tech-tag" style="background: var(--primary); color: #09090b; font-weight: bold; border: none;">{exp.get("experience_type")}</span>' if exp.get("experience_type") else ""
                    cert_link = f'<a href="{exp.get("certificate_link")}" target="_blank" class="btn btn-secondary" style="padding: 0.35rem 0.75rem; font-size: 0.75rem; display: inline-flex; align-items: center; gap: 4px; margin-top: 0.5rem;"><i data-lucide="award" style="width: 14px; height: 14px;"></i> View Certificate</a>' if exp.get("certificate_link") else ""
                    
                    exp_html += f"""
                    <div class="timeline-item">
                        <div class="timeline-date">{dur} {exp_type}</div>
                        <div class="timeline-card glass">
                            <h3 style="margin-bottom: 0.25rem; font-size: 1.3rem;">{exp.get('role')}</h3>
                            <h4 style="color: var(--primary); font-weight: 500; margin-bottom: 1rem;">{exp.get('company')}</h4>
                            {resp_html}
                            <div class="project-tech">{tools_html}</div>
                            {cert_link}
                        </div>
                    </div>
                    """
                sections_html += f"""
                <section id="experience">
                    <h2 class="section-title"><i data-lucide="briefcase"></i> Work Experience</h2>
                    <div class="timeline">
                        {exp_html}
                    </div>
                </section>
                """
            elif section == "projects" and profile.get("projects"):
                proj_html = ""
                for proj in profile.get("projects", []):
                    tech_tags = ""
                    for tech in proj.get("technologies", []):
                        tech_tags += f'<span class="tech-tag">{tech}</span>'
                        
                    links_html = ""
                    if proj.get("link"):
                        links_html += f'<a href="{proj.get("link")}" target="_blank" class="btn btn-secondary" style="padding: 0.4rem 1rem; font-size: 0.85rem;"><i data-lucide="external-link" style="width: 14px; height: 14px; vertical-align: middle; margin-right: 4px;"></i> Live Demo</a>'
                    if proj.get("github_link"):
                        links_html += f'<a href="{proj.get("github_link")}" target="_blank" class="btn btn-secondary" style="padding: 0.4rem 1rem; font-size: 0.85rem;"><i data-lucide="github" style="width: 14px; height: 14px; vertical-align: middle; margin-right: 4px;"></i> Source</a>'

                    role_str = f'<p style="font-size: 0.85rem; opacity: 0.7; margin-bottom: 0.5rem;"><strong>Role:</strong> {proj.get("role_or_teammates")}</p>' if proj.get("role_or_teammates") else ""
                    prob_str = f'<p style="font-size: 0.9rem; opacity: 0.8; margin-bottom: 1rem; font-style: italic;"><strong>Problem:</strong> {proj.get("problem_statement")}</p>' if proj.get("problem_statement") else ""
                    outcome_str = f'<p style="font-size: 0.9rem; margin-top: 1rem; color: var(--primary);"><strong>Outcome:</strong> {proj.get("outcomes_or_metrics")}</p>' if proj.get("outcomes_or_metrics") else ""
                    
                    screenshot_html = ""
                    if proj.get("screenshots"):
                        screenshot_html = '<div class="screenshot-gallery" style="display: flex; gap: 0.5rem; overflow-x: auto; margin-bottom: 1rem; padding-bottom: 0.5rem; scroll-snap-type: x mandatory;">'
                        for img in proj.get("screenshots", []):
                            screenshot_html += f'<img src="{img}" style="height: 120px; border-radius: 8px; border: 1px solid var(--border); object-fit: cover; scroll-snap-align: start;">'
                        screenshot_html += '</div>'

                    features_html = ""
                    if proj.get("features"):
                        features_html = '<ul style="margin: 0.5rem 0 1rem 1.25rem; list-style-type: square; opacity: 0.85; font-size: 0.85rem;">'
                        for feat in proj.get("features", []):
                            features_html += f'<li>{feat}</li>'
                        features_html += '</ul>'

                    proj_html += f"""
                    <div class="project-card glass">
                        <div class="project-body">
                            <h3 class="project-title" style="font-size: 1.4rem; font-weight: 700; margin-bottom: 0.5rem;">{proj.get('title')}</h3>
                            {role_str}
                            {prob_str}
                            <p class="project-desc">{proj.get('description', '')}</p>
                            {features_html}
                            {screenshot_html}
                            <div class="project-tech">
                                {tech_tags}
                            </div>
                            {outcome_str}
                            <div class="project-links" style="margin-top: 1.25rem;">
                                {links_html}
                            </div>
                        </div>
                    </div>
                    """
                sections_html += f"""
                <section id="projects">
                    <h2 class="section-title"><i data-lucide="folder-git-2"></i> Featured Projects</h2>
                    <div class="projects-grid">
                        {proj_html}
                    </div>
                </section>
                """
            elif section == "education" and profile.get("education"):
                edu_html = ""
                for edu in profile.get("education", []):
                    branch_str = f' &middot; {edu.get("branch")}' if edu.get("branch") else f' &middot; {edu.get("field_of_study")}'
                    dur_str = edu.get("duration") or f"Graduated {edu.get('graduation_year')}"
                    
                    course_html = ""
                    if edu.get("coursework"):
                        course_html = f'<p style="margin-top: 0.5rem; opacity: 0.7; font-size: 0.85rem;"><strong>Coursework:</strong> ' + ", ".join(edu.get("coursework", [])) + '</p>'
                    
                    edu_html += f"""
                    <div class="glass" style="padding: 1.75rem; border-radius: 16px; margin-bottom: 1.5rem;">
                        <span style="font-weight: 600; color: var(--primary); font-size: 0.9rem;">{dur_str}</span>
                        <h3 style="margin: 0.25rem 0; font-size: 1.25rem;">{edu.get('degree')}{branch_str}</h3>
                        <h4 style="font-weight: 500; opacity: 0.8;">{edu.get('institution')}</h4>
                        {f'<p style="margin-top: 0.5rem; opacity: 0.7; font-weight: 600;">Grade/CGPA: ' + edu.get('gpa') + '</p>' if edu.get('gpa') else ''}
                        {course_html}
                    </div>
                    """
                sections_html += f"""
                <section id="education">
                    <h2 class="section-title"><i data-lucide="graduation-cap"></i> Education</h2>
                    <div>
                        {edu_html}
                    </div>
                </section>
                """
            elif section == "certifications" and (profile.get("certifications") or profile.get("competitions") or profile.get("publications") or profile.get("scholarships")):
                cert_html = ""
                for cert in profile.get("certifications", []):
                    cert_html += f"""
                    <div class="glass" style="padding: 1.5rem; border-radius: 12px; display: flex; justify-content: space-between; align-items: center; margin-bottom: 1rem;">
                        <div>
                            <h3 style="font-size: 1.15rem;">{cert.get('name')}</h3>
                            <p style="opacity: 0.8; font-size: 0.9rem;">{cert.get('issuer')} &middot; {cert.get('date')}</p>
                        </div>
                        {f'<a href="' + cert.get('link') + '" target="_blank" class="btn btn-secondary" style="padding: 0.4rem 1rem; font-size: 0.8rem;"><i data-lucide="award"></i> View</a>' if cert.get('link') else ''}
                    </div>
                    """
                
                extra_awards_html = ""
                if profile.get("competitions"):
                    extra_awards_html += '<div style="margin-top: 1.5rem;"><h4>Competitions</h4><ul style="margin-left: 1.5rem; opacity: 0.85;">'
                    for c in profile.get("competitions", []):
                        extra_awards_html += f'<li>{c}</li>'
                    extra_awards_html += '</ul></div>'
                if profile.get("publications"):
                    extra_awards_html += '<div style="margin-top: 1.5rem;"><h4>Publications</h4><ul style="margin-left: 1.5rem; opacity: 0.85;">'
                    for p in profile.get("publications", []):
                        extra_awards_html += f'<li>{p}</li>'
                    extra_awards_html += '</ul></div>'
                if profile.get("scholarships"):
                    extra_awards_html += '<div style="margin-top: 1.5rem;"><h4>Scholarships</h4><ul style="margin-left: 1.5rem; opacity: 0.85;">'
                    for s in profile.get("scholarships", []):
                        extra_awards_html += f'<li>{s}</li>'
                    extra_awards_html += '</ul></div>'

                sections_html += f"""
                <section id="certifications">
                    <h2 class="section-title"><i data-lucide="award"></i> Certifications & Achievements</h2>
                    <div>
                        {cert_html}
                        {extra_awards_html}
                    </div>
                </section>
                """
            elif section == "extracurriculars" and profile.get("extracurriculars"):
                extra_html = ""
                for item in profile.get("extracurriculars", []):
                    extra_html += f"""
                    <div class="glass" style="padding: 1.75rem; border-radius: 16px; margin-bottom: 1.5rem;">
                        <span style="font-weight: 600; color: var(--primary); font-size: 0.9rem;">{item.get('duration')}</span>
                        <h3 style="margin: 0.25rem 0; font-size: 1.25rem;">{item.get('role')} at {item.get('activity')}</h3>
                        {f'<h4 style="font-weight: 500; opacity: 0.8; margin-bottom: 0.5rem;">{item.get("organization")}</h4>' if item.get("organization") else ''}
                        <p style="opacity: 0.7;">{item.get('description', '')}</p>
                    </div>
                    """
                sections_html += f"""
                <section id="extracurriculars">
                    <h2 class="section-title"><i data-lucide="users"></i> Extracurriculars & Leadership</h2>
                    <div>
                        {extra_html}
                    </div>
                </section>
                """
            elif section == "testimonials" and profile.get("testimonials"):
                test_html = ""
                for item in profile.get("testimonials", []):
                    test_html += f"""
                    <div class="glass" style="padding: 1.75rem; border-radius: 16px; margin-bottom: 1.5rem;">
                        <p style="font-style: italic; font-size: 1.1rem; margin-bottom: 1rem;">"{item.get('quote')}"</p>
                        <h4 style="margin: 0; font-size: 1rem; color: var(--primary);">{item.get('name')}</h4>
                        <p style="opacity: 0.7; font-size: 0.85rem;">{item.get('designation', '')} &middot; {item.get('relation', '')}</p>
                    </div>
                    """
                sections_html += f"""
                <section id="testimonials">
                    <h2 class="section-title"><i data-lucide="message-square"></i> Testimonials</h2>
                    <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 1.5rem;">
                        {test_html}
                    </div>
                </section>
                """
            elif section == "blogs" and profile.get("blogs"):
                blog_html = ""
                for item in profile.get("blogs", []):
                    blog_html += f"""
                    <div class="glass" style="padding: 1.75rem; border-radius: 16px; margin-bottom: 1.5rem;">
                        <span style="font-size: 0.85rem; opacity: 0.6;">{item.get('date')}</span>
                        <h3 style="margin: 0.25rem 0 0.5rem 0; font-size: 1.25rem;"><a href="{item.get('link')}" target="_blank" style="color:var(--text); text-decoration:none; transition:var(--transition);">{item.get('title')}</a></h3>
                        <p style="opacity: 0.8; margin-bottom: 1rem;">{item.get('summary', '')}</p>
                        <a href="{item.get('link')}" target="_blank" style="color: var(--primary); text-decoration: none; font-weight: 600; font-size: 0.9rem;">Read Article &rarr;</a>
                    </div>
                    """
                sections_html += f"""
                <section id="blogs">
                    <h2 class="section-title"><i data-lucide="book-open"></i> Publications & Articles</h2>
                    <div>
                        {blog_html}
                    </div>
                </section>
                """

        image_html = ""
        photo_url = profile.get("profile_photo_url")
        if photo_url:
            image_html = f'<img src="{photo_url}" alt="{profile.get("full_name")}">'
        else:
            image_html = f'<div style="width:100%; height:100%; display:flex; align-items:center; justify-content:center; background:linear-gradient(135deg, var(--primary), var(--secondary)); color:#111115; font-size:4rem; font-weight:800;">{profile.get("full_name")[0] if profile.get("full_name") else "P"}</div>'

        avail_status = profile.get("availability_status")
        avail_badge = f'<div style="display:inline-flex; align-items:center; gap:0.5rem; background:rgba(0,255,204,0.1); border:1px solid var(--primary); color:var(--primary); padding:0.25rem 0.75rem; border-radius:20px; font-size:0.85rem; font-weight:600; margin-bottom:1.5rem;"><span style="width:8px; height:8px; background:var(--primary); border-radius:50%; display:inline-block; animation: pulse 2s infinite;"></span>{avail_status}</div><br>' if avail_status else ""

        socials_html = '<div style="display:flex; gap:1.25rem; margin-top:2rem; font-size:1.5rem;">'
        if profile.get("github"):
            socials_html += f'<a href="{profile.get("github")}" target="_blank" style="color:var(--text); opacity:0.8; transition:var(--transition);"><i data-lucide="github"></i></a>'
        if profile.get("linkedin"):
            socials_html += f'<a href="{profile.get("linkedin")}" target="_blank" style="color:var(--text); opacity:0.8; transition:var(--transition);"><i data-lucide="linkedin"></i></a>'
        for name, link in profile.get("social_links", {}).items():
            icon = "link"
            n_low = name.lower()
            if "twitter" in n_low or "x.com" in n_low:
                icon = "twitter"
            elif "instagram" in n_low:
                icon = "instagram"
            elif "youtube" in n_low:
                icon = "youtube"
            elif "facebook" in n_low:
                icon = "facebook"
            socials_html += f'<a href="{link}" target="_blank" style="color:var(--text); opacity:0.8; transition:var(--transition);"><i data-lucide="{icon}"></i></a>'
        socials_html += '</div>'

        html_content = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{profile.get('full_name')} | {profile.get('professional_title')}</title>
    <meta name="description" content="{profile.get('seo_description', '')}">
    
    <meta property="og:title" content="{profile.get('full_name')} - Portfolio">
    <meta property="og:description" content="{profile.get('social_preview', '')}">
    <meta property="og:type" content="website">
    
    <link rel="stylesheet" href="style.css">
    <style>
        @keyframes pulse {{
            0% {{ transform: scale(0.95); box-shadow: 0 0 0 0 rgba(0, 255, 204, 0.7); }}
            70% {{ transform: scale(1); box-shadow: 0 0 0 6px rgba(0, 255, 204, 0); }}
            100% {{ transform: scale(0.95); box-shadow: 0 0 0 0 rgba(0, 255, 204, 0); }}
        }}
    </style>
</head>
<body>
    <header id="header">
        <div class="nav-container">
            <a href="#" class="logo">{profile.get('full_name')}</a>
            <ul class="nav-links">
                {nav_html}
            </ul>
            <button class="mobile-menu-btn" id="menuBtn">
                <i data-lucide="menu"></i>
            </button>
        </div>
    </header>

    <section class="hero" id="home">
        <div class="hero-container">
            <div class="hero-content">
                {avail_badge}
                <h1 class="hero-title">Hi, I'm <span>{profile.get('full_name')}</span></h1>
                <p class="hero-tagline">{profile.get('tagline')}</p>
                <div class="hero-buttons">
                    <a href="#contact" class="btn btn-primary">Hire Me</a>
                    {f'<a href="' + profile.get('resume_url', '#') + '" download class="btn btn-secondary" id="downloadResume"><i data-lucide="download"></i> Download Resume</a>' if profile.get('resume_url') else ''}
                </div>
                {socials_html}
            </div>
            <div class="hero-image-container">
                {image_html}
            </div>
        </div>
    </section>

    {sections_html}

    <section id="contact">
        <h2 class="section-title"><i data-lucide="mail"></i> Contact Me</h2>
        <div class="contact-container">
            <div class="contact-info">
                <p style="font-size: 1.1rem; opacity: 0.9;">Feel free to reach out. I would love to connect and discuss opportunities!</p>
                <div class="contact-item">
                    <div class="contact-icon"><i data-lucide="mail"></i></div>
                    <div>
                        <h4 style="font-size: 0.85rem; opacity: 0.7;">EMAIL</h4>
                        <p>{profile.get('email')}</p>
                    </div>
                </div>
                {f'<div class="contact-item"><div class="contact-icon"><i data-lucide="phone"></i></div><div><h4 style="font-size: 0.85rem; opacity: 0.7;">PHONE</h4><p>' + profile.get('phone') + '</p></div></div>' if profile.get('phone') else ''}
                {f'<div class="contact-item"><div class="contact-icon"><i data-lucide="map-pin"></i></div><div><h4 style="font-size: 0.85rem; opacity: 0.7;">LOCATION</h4><p>' + profile.get('location') + '</p></div></div>' if profile.get('location') else ''}
            </div>
            
            <form class="contact-form glass" id="contactForm">
                <div class="form-group">
                    <label for="name">Name</label>
                    <input type="text" id="name" name="name" class="form-control" placeholder="Your Name" required>
                </div>
                <div class="form-group">
                    <label for="email">Email</label>
                    <input type="email" id="email" name="email" class="form-control" placeholder="Your Email" required>
                </div>
                <div class="form-group">
                    <label for="message">Message</label>
                    <textarea id="message" name="message" class="form-control" rows="5" placeholder="Your Message" required></textarea>
                </div>
                <button type="submit" class="btn btn-primary" style="width: 100%;">Send Message</button>
            </form>
        </div>
    </section>

    <footer>
        <p>&copy; 2026 {profile.get('full_name')}. All rights reserved.</p>
    </footer>

    <script src="https://unpkg.com/lucide@latest"></script>
    <script src="script.js"></script>
</body>
</html>
"""

        js_content = """// Portfolio Interactive Script
document.addEventListener("DOMContentLoaded", () => {
    lucide.createIcons();

    const header = document.getElementById("header");
    window.addEventListener("scroll", () => {
        if (window.scrollY > 50) {
            header.classList.add("scrolled");
        } else {
            header.classList.remove("scrolled");
        }
    });

    const menuBtn = document.getElementById("menuBtn");
    const navLinks = document.querySelector(".nav-links");
    if (menuBtn) {
        menuBtn.addEventListener("click", () => {
            navLinks.style.display = navLinks.style.display === "flex" ? "none" : "flex";
            if (navLinks.style.display === "flex") {
                navLinks.style.flexDirection = "column";
                navLinks.style.position = "absolute";
                navLinks.style.top = "100%";
                navLinks.style.left = "0";
                navLinks.style.width = "100%";
                navLinks.style.background = "var(--card-bg)";
                navLinks.style.backdropFilter = "blur(10px)";
                navLinks.style.padding = "2rem";
                navLinks.style.borderBottom = "1px solid var(--border)";
            }
        });
    }

    const contactForm = document.getElementById("contactForm");
    if (contactForm) {
        contactForm.addEventListener("submit", (e) => {
            e.preventDefault();
            const name = document.getElementById("name").value;
            const email = document.getElementById("email").value;
            const message = document.getElementById("message").value;
            
            console.log("Message received:", { name, email, message });
            alert("Thank you! Your message has been sent successfully.");
            contactForm.reset();
        });
    }
});
"""

        return html_content, css_content, js_content

generator_agent = GeneratorAgent()

