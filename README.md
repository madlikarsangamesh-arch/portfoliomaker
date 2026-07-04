# AI Portfolio Engineer - Conversational AI Agent

AI Portfolio Engineer is a production-ready, full-stack application. Instead of static forms, it interviews the user in real-time, extracts experiences from uploaded resumes, designs visual layouts, enhances copy, runs quality checks, deploys the static portfolio directly to Vercel, and reviews the final product like a recruiter.

---

## Technical Stack

* **Frontend**: Flutter (Material 3, Glassmorphism design, Riverpod State, GoRouter)
* **Backend**: Python (FastAPI, Uvicorn, Jinja2, ReportLab)
* **Database**: SQLite (out-of-the-box local fallback) and Firebase Firestore compatibility
* **Storage**: Local Storage (out-of-the-box local fallback) and Firebase Storage compatibility
* **Deployment**: Vercel REST APIs (with toggleable local sandboxing emulation)
* **AI Engine**: Gemini-1.5-flash LLM (with offline simulated templates fallback)

---

## Agentic AI Architecture

PortfolioAI utilizes a **9-Agent Loop Architecture** coordinated by a central Root Agent (Orchestrator):

1. **Loop Agent 1 - Information Collection Agent**: Audits user input and suggests follow-up questions for missing sections.
2. **Loop Agent 2 - Resume Analysis Agent**: Extracts work experience, projects, skills, and certifications from PDF/TXT resumes.
3. **Loop Agent 3 - Content Enhancement Agent**: Rewrites text fields, optimizes tone, fixes grammar, generates SEO parameters, and taglines.
4. **Loop Agent 4 - Portfolio Planning Agent**: Plans navigation, template overrides, Google Fonts, and matches skills to Lucide icon classes.
5. **Loop Agent 5 - Portfolio Generation Agent**: Synthesizes responsive HTML/CSS/JS files based on template layout overrides.
6. **Loop Agent 6 - Quality Assurance Agent**: Audits mobile viewports, broken links, accessibility alt attributes, and provides recruiter scorecard reviews out of 100.
7. **Loop Agent 7 - Deployment Agent**: Packages and deploys code assets directly to Vercel.
8. **Loop Agent 8 - Resume Generator Agent**: Assembles letter size ATS-friendly PDF and HTML resumes.
9. **Loop Agent 9 - Database Agent**: Manages snapshot saving, analytics logs, and version control records.

---

## Project Structure

```
portfoliomaker/
├── backend/
│   ├── api/                  # FastAPI routers (auth, portfolio, admin, analytics)
│   ├── agents/               # 9 Loop agents and Orchestrator logic
│   ├── auth/                 # Password hashing & HMAC JWT tokens
│   ├── database/             # SQLite connection initialization
│   ├── middleware/           # CORS, logger, and Client IP rate-limiters
│   ├── models/               # Pydantic schemas validation rules
│   ├── prompts/              # Agent prompt templates configuration literals
│   ├── repositories/         # Database access layer (users, portfolios, views)
│   ├── services/             # API adapters (Gemini, Vercel, Firebase)
│   ├── utils/                # QR code URL and string slugifier tools
│   ├── config.py             # Server configurations
│   ├── main.py               # Server CORS, static files mounting
│   ├── requirements.txt      # Server python package list
│   └── run.py                # Server execution script
├── frontend/
│   ├── pubspec.yaml          # Flutter package locks
│   ├── lib/
│   │   ├── main.dart         # Entry point, router configs
│   │   ├── config/           # AppConstants, Glassmorphic theme styles
│   │   └── presentation/
│   │       ├── providers/    # Riverpod state adapters (auth, portfolio, stats)
│   │       ├── screens/      # Auth, Dashboard, Onboarding, Preview, Analytics, Admin
│   │       └── widgets/      # GlassCard, Stepper loader animation, stats charts
```

---

## Installation & Running Guide

### 1. Prerequisites
- Python 3.9+
- Flutter SDK (to run the client application)

### 2. Run the Backend
```bash
cd backend
python -m venv venv
# Activate virtual environment
# Windows:
.\venv\Scripts\activate
# Unix/MacOS:
source venv/bin/activate

pip install -r requirements.txt
python run.py
```
*The server will start at `http://localhost:8000`. You can visit API documentation at `http://localhost:8000/docs`.*

### 3. Run the Frontend
Make sure you have a simulator active or run target, then execute:
```bash
cd frontend
flutter pub get
flutter run
```

---

## Production Configurations (Firebase & Vercel)
To disable local emulators and connect real Firebase Firestore/Vercel:
Create environment variables or write them inside `backend/config.py`:
- `GEMINI_API_KEY`: Google AI Studio token
- `FIREBASE_MOCK`: Set to `False`
- `FIREBASE_CREDENTIALS_PATH`: Path to Firebase Service Account JSON
- `VERCEL_MOCK`: Set to `False`
- `VERCEL_AUTH_TOKEN`: Your Vercel Developer authorization token
