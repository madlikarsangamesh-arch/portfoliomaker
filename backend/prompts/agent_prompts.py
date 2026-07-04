# Prompt templates for modular LLM agents

INTERVIEWER_PROMPT = """
The user wants to generate a professional portfolio website but some fields are missing.
Missing Fields: {missing_fields}

Current (partial) profile:
Name: {name}
Title: {title}
About: {about}

Write a list of 2-3 friendly, conversational, and highly specific follow-up questions to help the user complete their profile.
Format your response as a JSON array of strings.
"""

RESUME_PARSER_PROMPT = """
Extract the following details from this resume text:
1. Full Name
2. Professional Title (or guess from experience)
3. Email Address
4. Phone Number
5. Location
6. Skills (as list of strings)
7. Education (institution, degree, field_of_study, graduation_year, gpa)
8. Experience (company, role, start_date, end_date, description, skills_used)
9. Projects (title, description, technologies, link, github_link)
10. Certifications (name, issuer, date, link)
11. Achievements (title, description, date)
12. Languages (list of strings)

Resume text:
{text}

Return ONLY a valid JSON object matching this structure:
{{
    "full_name": "...",
    "professional_title": "...",
    "email": "...",
    "phone": "...",
    "location": "...",
    "about_me": "(generate a standard professional summary based on the resume)",
    "skills": ["...", "..."],
    "education": [
        {{
            "institution": "...",
            "degree": "...",
            "field_of_study": "...",
            "graduation_year": "...",
            "gpa": "..."
        }}
    ],
    "experience": [
        {{
            "company": "...",
            "role": "...",
            "start_date": "...",
            "end_date": "...",
            "description": "...",
            "skills_used": ["..."]
        }}
    ],
    "projects": [
        {{
            "title": "...",
            "description": "...",
            "technologies": ["..."],
            "link": null,
            "github_link": null
        }}
    ],
    "certifications": [
        {{
            "name": "...",
            "issuer": "...",
            "date": "...",
            "link": null
        }}
    ],
    "achievements": [
        {{
            "title": "...",
            "description": "...",
            "date": "..."
        }}
    ],
    "languages": ["..."]
}}
"""

ABOUT_ME_ENHANCE_PROMPT = """
Improve the following professional "About Me" description for a portfolio website.
Name: {name}
Title: {title}
Current Description: {about}

Rewrite it to be engaging, professional, and grammatically correct. Keep it under 200 words.
Respond with ONLY the enhanced description text. Do not add quotes, introductions or explanations.
"""

SEO_METADATA_PROMPT = """
Based on this user profile, generate:
1. A punchy, creative tagline for a portfolio banner.
2. A short SEO description (under 160 characters) for google search results.
3. A social sharing card preview text (under 80 characters).

Name: {name}
Title: {title}
Bio: {about_me}

Return ONLY a JSON object matching this structure:
{{
    "tagline": "...",
    "seo_description": "...",
    "social_preview": "..."
}}
"""

SKILLS_SUGGESTION_PROMPT = """
Given the following developer details, suggest up to 5 relevant technical/soft skills that might be missing from their profile.
Title: {title}
Current Skills: {skills}
Bio: {about_me}

Return ONLY a JSON array of strings. Do not include skills already in the list.
"""

PLANNER_PROMPT = """
Optimize this design plan based on the user's inspiration descriptions or URLs.
Inspiration Description: {description}
Inspiration URL: {url}

Current template presets:
Template name: {template_name}
Colors: Primary: {primary}, Secondary: {secondary}
Font: {font}
Layout: {layout}

Please suggest appropriate hex codes for styling, layout structures, and font choices from Google Fonts.
Return ONLY a valid JSON object matching this structure:
{{
    "primary_color": "#HEXCODE",
    "secondary_color": "#HEXCODE",
    "font": "Google Font Name",
    "layout": "Choose from: split-terminal, single-column, classic-rows, masonry-grid, card-overlay, glitch-blocks, horizontal-scroll, feature-cards, grid-cards",
    "background_style": "...",
    "button_style": "square/rounded/pill"
}}
"""

SKILLS_MAP_PROMPT = """
Map each of these skills to an appropriate Lucide icon name (e.g. Python -> terminal, React -> code, PostgreSQL -> database, Communication -> users).
Skills: {skills}

Return ONLY a JSON dictionary where key is the skill name and value is the Lucide icon slug (lowercase, e.g. "code", "database", "globe", "cpu", "layers").
"""

QA_REVIEW_PROMPT = """
Review this portfolio profile like a technical recruiter and output a JSON scorecard assessment.
Provide constructive, direct, and actionable advice to improve their hireability.

Name: {name}
Title: {title}
Bio: {about_me}
Skills: {skills}
Experience Count: {experience_len}
Projects Count: {projects_len}

Return ONLY a JSON object matching this structure:
{{
    "overall_score": (integer between 1 and 100 representing hireability),
    "strengths": ["list strength 1", "list strength 2", ...],
    "weaknesses": ["list weakness 1", "list weakness 2", ...],
    "suggestions": ["list suggestion 1", "list suggestion 2", ...]
}}
"""
