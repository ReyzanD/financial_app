import os
from datetime import timedelta
from dotenv import load_dotenv

load_dotenv()

class Config:
    # SQLite Database Configuration
    # This application uses SQLite for fully local operation
    # No cloud database (PostgreSQL/Supabase) or hosting (Render) required
    USE_SQLITE = True  # Always use SQLite - no other database options
    
    SQLITE_DB_PATH = os.getenv('SQLITE_DB_PATH', os.path.join(
        os.path.dirname(os.path.abspath(__file__)), 'financial_app.db'
    ))
    
    # JWT Configuration
    # ⚠️ SECURITY WARNING: The default value below is ONLY for development!
    # In production, you MUST set JWT_SECRET_KEY environment variable with a strong,
    # random secret (minimum 32 characters). Generate using: openssl rand -hex 32
    # NEVER commit production JWT secrets to version control!
    JWT_SECRET_KEY = os.getenv('JWT_SECRET_KEY', 'dev-secret-key-232143-change-in-production')
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(days=7)
    
    # API Configuration
    API_PREFIX = '/api/v1'
    DEBUG = os.getenv('DEBUG', 'True').lower() == 'true'
    
    # Server Configuration
    PORT = int(os.getenv('PORT', 5000))