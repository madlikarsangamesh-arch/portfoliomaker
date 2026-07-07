import os
import logging
from typing import Dict, Any
from backend.config import settings

logger = logging.getLogger("PortfolioAI.ResumeGen")

try:
    from reportlab.lib.pagesizes import letter
    from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle
    from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
    from reportlab.lib import colors
    HAS_REPORTLAB = True
except ImportError:
    HAS_REPORTLAB = False

class ResumeGeneratorAgent:
    def __init__(self):
        pass

    def generate_html_resume(self, profile: dict) -> str:
        """
        Generates an ATS-friendly HTML resume template.
        """
        # Skills details or fallback
        skills_details = profile.get("skills_details", [])
        if skills_details:
            skills_str = ""
            categories = {}
            for s in skills_details:
                cat = s.get("category", "Other")
                if cat not in categories:
                    categories[cat] = []
                categories[cat].append(s.get("name"))
            for cat, items in categories.items():
                skills_str += f"<strong>{cat}:</strong> {', '.join(items)}<br>"
        else:
            skills_str = ", ".join(profile.get("skills", []))
            
        experience_html = ""
        for exp in profile.get("experience", []):
            dur = exp.get("duration") or f"{exp.get('start_date', '')} - {exp.get('end_date', '')}"
            exp_type = f" ({exp.get('experience_type')})" if exp.get("experience_type") else ""
            
            resp_html = ""
            if exp.get("responsibilities"):
                resp_html = "<ul>"
                for r in exp.get("responsibilities", []):
                    resp_html += f"<li>{r}</li>"
                resp_html += "</ul>"
            else:
                resp_html = f"<p>{exp.get('description', '')}</p>"
                
            tools_list = exp.get("tools") or exp.get("skills_used") or []
            tools_str = f"<p><em>Tools: {', '.join(tools_list)}</em></p>" if tools_list else ""
            
            cert_str = f'<p><a href="{exp.get("certificate_link")}">View Certificate</a></p>' if exp.get("certificate_link") else ""
            
            experience_html += f"""
            <div class="resume-item">
                <div class="resume-header">
                    <strong>{exp.get('role')}{exp_type}</strong> | {exp.get('company')}
                    <span class="resume-date">{dur}</span>
                </div>
                {resp_html}
                {tools_str}
                {cert_str}
            </div>
            """
            
        education_html = ""
        for edu in profile.get("education", []):
            dur_str = edu.get("duration") or f"Graduated {edu.get('graduation_year')}"
            branch_str = f" in {edu.get('branch')}" if edu.get("branch") else f" in {edu.get('field_of_study')}"
            course_str = f"<p><em>Coursework: {', '.join(edu.get('coursework', []))}</em></p>" if edu.get("coursework") else ""
            
            education_html += f"""
            <div class="resume-item">
                <div class="resume-header">
                    <strong>{edu.get('degree')}{branch_str}</strong>
                    <span class="resume-date">{dur_str}</span>
                </div>
                <p>{edu.get('institution')}</p>
                {course_str}
            </div>
            """

        projects_html = ""
        for proj in profile.get("projects", []):
            tech_str = ", ".join(proj.get("technologies", []))
            role_str = f"<p><em>Role: {proj.get('role_or_teammates')}</em></p>" if proj.get("role_or_teammates") else ""
            prob_str = f"<p><strong>Problem:</strong> {proj.get('problem_statement')}</p>" if proj.get("problem_statement") else ""
            outcome_str = f"<p><strong>Outcome/Metrics:</strong> {proj.get('outcomes_or_metrics')}</p>" if proj.get("outcomes_or_metrics") else ""
            
            feat_html = ""
            if proj.get("features"):
                feat_html = "<ul>"
                for f in proj.get("features", []):
                    feat_html += f"<li>{f}</li>"
                feat_html += "</ul>"
                
            projects_html += f"""
            <div class="resume-item">
                <div class="resume-header">
                    <strong>{proj.get('title')}</strong> ({tech_str})
                </div>
                {role_str}
                {prob_str}
                <p>{proj.get('description', '')}</p>
                {feat_html}
                {outcome_str}
            </div>
            """

        extra_html = ""
        if profile.get("extracurriculars"):
            extra_html += '<div class="section-title">Extracurricular Activities & Leadership</div>'
            for item in profile.get("extracurriculars", []):
                extra_html += f"""
                <div class="resume-item">
                    <div class="resume-header">
                        <strong>{item.get('role')}</strong> | {item.get('activity')}
                        <span class="resume-date">{item.get('duration')}</span>
                    </div>
                    {f'<p><em>{item.get("organization")}</em></p>' if item.get("organization") else ''}
                    <p>{item.get('description', '')}</p>
                </div>
                """

        awards_html = ""
        if profile.get("competitions") or profile.get("publications") or profile.get("scholarships"):
            awards_html += '<div class="section-title">Honors & Achievements</div>'
            if profile.get("competitions"):
                awards_html += "<p><strong>Competitions:</strong> " + ", ".join(profile.get("competitions")) + "</p>"
            if profile.get("publications"):
                awards_html += "<p><strong>Publications:</strong> " + ", ".join(profile.get("publications")) + "</p>"
            if profile.get("scholarships"):
                awards_html += "<p><strong>Scholarships:</strong> " + ", ".join(profile.get("scholarships")) + "</p>"

        html = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Resume - {profile.get('full_name')}</title>
    <style>
        body {{
            font-family: Arial, sans-serif;
            color: #333;
            line-height: 1.5;
            padding: 2rem;
            max-width: 800px;
            margin: 0 auto;
        }}
        h1 {{
            font-size: 2.25rem;
            margin-bottom: 0.25rem;
            text-align: center;
        }}
        .contact-info {{
            text-align: center;
            font-size: 0.9rem;
            margin-bottom: 1.5rem;
            border-bottom: 1px solid #ccc;
            padding-bottom: 0.75rem;
        }}
        .section-title {{
            font-size: 1.25rem;
            font-weight: bold;
            color: #0f172a;
            border-bottom: 1px solid #334155;
            margin-top: 1.5rem;
            margin-bottom: 0.75rem;
            text-transform: uppercase;
        }}
        .resume-item {{
            margin-bottom: 1rem;
        }}
        .resume-header {{
            display: flex;
            justify-content: space-between;
            margin-bottom: 0.25rem;
        }}
        .resume-date {{
            font-style: italic;
            color: #666;
        }}
    </style>
</head>
<body>
    <h1>{profile.get('full_name')}</h1>
    <div class="contact-info">
        {profile.get('email')} | {profile.get('phone', '')} | {profile.get('location', '')}
        <br>
        {f'LinkedIn: ' + profile.get('linkedin') if profile.get('linkedin') else ''} | {f'GitHub: ' + profile.get('github') if profile.get('github') else ''}
    </div>
    
    {f'<div class="section-title">Career Objective</div><p>' + profile.get('career_objective') + '</p>' if profile.get('career_objective') else ''}
    
    <div class="section-title">Professional Summary</div>
    <p>{profile.get('about_me')}</p>
    
    <div class="section-title">Skills</div>
    <p>{skills_str}</p>
    
    <div class="section-title">Work Experience</div>
    {experience_html}
    
    <div class="section-title">Projects</div>
    {projects_html}
    
    <div class="section-title">Education</div>
    {education_html}
    
    {extra_html}
    
    {awards_html}
</body>
</html>
"""
        return html

    def generate_pdf_resume(self, profile: dict, filename: str) -> str:
        """
        Generates letter size standard PDF using reportlab or mocks local path.
        """
        dest_path = os.path.join(settings.LOCAL_STORAGE_DIR, "resumes", filename)
        
        if not HAS_REPORTLAB:
            logger.warning("ReportLab not installed. Creating fallback resume.html copy.")
            html = self.generate_html_resume(profile)
            html_path = dest_path.replace(".pdf", ".html")
            with open(html_path, "w") as f:
                f.write(html)
            # Return relative endpoint path
            return f"/api/v1/static/resumes/{filename.replace('.pdf', '.html')}"

        try:
            doc = SimpleDocTemplate(dest_path, pagesize=letter, rightMargin=40, leftMargin=40, topMargin=40, bottomMargin=40)
            styles = getSampleStyleSheet()
            
            # Custom styling
            title_style = ParagraphStyle(
                'ResumeTitle',
                parent=styles['Heading1'],
                fontSize=24,
                leading=28,
                alignment=1, # Center
                spaceAfter=6
            )
            contact_style = ParagraphStyle(
                'ResumeContact',
                parent=styles['Normal'],
                fontSize=9,
                leading=12,
                alignment=1, # Center
                spaceAfter=15
            )
            heading_style = ParagraphStyle(
                'ResumeHeading',
                parent=styles['Heading2'],
                fontSize=12,
                leading=15,
                textColor=colors.HexColor('#0f172a'),
                spaceBefore=10,
                spaceAfter=6,
                borderWidth=0.5,
                borderColor=colors.HexColor('#334155'),
                borderPadding=(0, 0, 2, 0) # Bottom border underline effect
            )
            body_style = styles['Normal']
            
            story = []
            
            # Header
            story.append(Paragraph(profile.get('full_name', 'Name'), title_style))
            contact_text = f"{profile.get('email')} | {profile.get('phone', '')} | {profile.get('location', '')}"
            if profile.get('linkedin') or profile.get('github'):
                links = []
                if profile.get('linkedin'): links.append(f"LinkedIn: {profile.get('linkedin')}")
                if profile.get('github'): links.append(f"GitHub: {profile.get('github')}")
                contact_text += "<br>" + " | ".join(links)
            story.append(Paragraph(contact_text, contact_style))
            
            # Summary
            story.append(Paragraph("Professional Summary", heading_style))
            story.append(Paragraph(profile.get('about_me', ''), body_style))
            
            # Skills
            story.append(Paragraph("Technical Skills", heading_style))
            story.append(Paragraph(", ".join(profile.get("skills", [])), body_style))
            story.append(Spacer(1, 10))
            
            # Experience
            story.append(Paragraph("Work Experience", heading_style))
            for exp in profile.get("experience", []):
                role_info = f"<b>{exp.get('role')}</b> - {exp.get('company')}"
                date_info = f"<font color='#666666'><i>{exp.get('start_date')} - {exp.get('end_date')}</i></font>"
                
                # Setup side-by-side Table for title & date alignment
                t = Table([[Paragraph(role_info, body_style), Paragraph(date_info, ParagraphStyle('DateStyle', parent=body_style, alignment=2))]], colWidths=[380, 150])
                t.setStyle(TableStyle([
                    ('VALIGN', (0,0), (-1,-1), 'TOP'),
                    ('LEFTPADDING', (0,0), (-1,-1), 0),
                    ('RIGHTPADDING', (0,0), (-1,-1), 0),
                    ('BOTTOMPADDING', (0,0), (-1,-1), 2),
                ]))
                story.append(t)
                story.append(Paragraph(exp.get('description', ''), body_style))
                story.append(Spacer(1, 10))
                
            # Projects
            story.append(Paragraph("Featured Projects", heading_style))
            for proj in profile.get("projects", []):
                techs = ", ".join(proj.get("technologies", []))
                title_info = f"<b>{proj.get('title')}</b> ({techs})"
                story.append(Paragraph(title_info, body_style))
                story.append(Paragraph(proj.get('description', ''), body_style))
                story.append(Spacer(1, 8))
                
            # Education
            story.append(Paragraph("Education", heading_style))
            for edu in profile.get("education", []):
                edu_info = f"<b>{edu.get('degree')} in {edu.get('field_of_study')}</b> - {edu.get('institution')}"
                grad_info = f"<font color='#666666'><i>{edu.get('graduation_year')}</i></font>"
                
                t = Table([[Paragraph(edu_info, body_style), Paragraph(grad_info, ParagraphStyle('DateStyle2', parent=body_style, alignment=2))]], colWidths=[420, 110])
                t.setStyle(TableStyle([
                    ('VALIGN', (0,0), (-1,-1), 'TOP'),
                    ('LEFTPADDING', (0,0), (-1,-1), 0),
                    ('RIGHTPADDING', (0,0), (-1,-1), 0),
                    ('BOTTOMPADDING', (0,0), (-1,-1), 2),
                ]))
                story.append(t)
                story.append(Spacer(1, 6))

            doc.build(story)
            logger.info("PDF generated successfully.")
            return f"/api/v1/static/resumes/{filename}"
        except Exception as e:
            logger.error(f"Failed to compile PDF via reportlab: {e}")
            # Fallback to HTML
            html = self.generate_html_resume(profile)
            html_path = dest_path.replace(".pdf", ".html")
            with open(html_path, "w") as f:
                f.write(html)
            return f"/api/v1/static/resumes/{filename.replace('.pdf', '.html')}"

resume_generator_agent = ResumeGeneratorAgent()
