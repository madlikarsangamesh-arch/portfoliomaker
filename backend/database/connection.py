import os
import sqlite3
from backend.config import settings

SQLITE_DB_PATH = os.path.join(settings.LOCAL_STORAGE_DIR, "database.db")

def get_db_connection():
    """
    Returns a standard SQLite connection with dict/Row row factory.
    """
    conn = sqlite3.connect(SQLITE_DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    """
    Initializes database tables if they do not exist.
    """
    conn = get_db_connection()
    cursor = conn.cursor()
    
    # Users table
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS users (
            id TEXT PRIMARY KEY,
            email TEXT UNIQUE,
            password_hash TEXT,
            full_name TEXT,
            role TEXT DEFAULT 'user'
        )
    """)
    
    # Portfolios table
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS portfolios (
            id TEXT PRIMARY KEY,
            user_id TEXT,
            profile JSON,
            design JSON,
            html_code TEXT,
            css_code TEXT,
            js_code TEXT,
            deployment_url TEXT,
            recruiter_scorecard JSON,
            is_active INTEGER DEFAULT 1,
            version INTEGER DEFAULT 1,
            created_at TEXT,
            updated_at TEXT,
            FOREIGN KEY(user_id) REFERENCES users(id)
        )
    """)
    
    # Analytics table
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS analytics (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            portfolio_id TEXT,
            visitor_id TEXT,
            timestamp TEXT,
            country TEXT,
            device TEXT,
            source TEXT,
            is_resume_download INTEGER DEFAULT 0
        )
    """)
    
    conn.commit()
    conn.close()

# Run database initialization
init_db()
