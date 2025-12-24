import os
from datetime import timedelta
from dotenv import load_dotenv
import json

# #region agent log
log_data = {
    'sessionId': 'debug-session',
    'runId': 'run1',
    'hypothesisId': 'A',
    'location': 'config.py:5',
    'message': 'Before load_dotenv - checking DATABASE_URL',
    'data': {
        'database_url_before_dotenv': str(os.getenv('DATABASE_URL'))[:50] + '...' if os.getenv('DATABASE_URL') else None
    },
    'timestamp': int(__import__('time').time() * 1000)
}
with open('d:\\CODE\\Project\\FinancialApp\\financial_app\\.cursor\\debug.log', 'a', encoding='utf-8') as f:
    f.write(json.dumps(log_data) + '\n')
# #endregion

load_dotenv()

# #region agent log
log_data = {
    'sessionId': 'debug-session',
    'runId': 'run1',
    'hypothesisId': 'A',
    'location': 'config.py:12',
    'message': 'After load_dotenv - checking DATABASE_URL',
    'data': {
        'database_url_after_dotenv': str(os.getenv('DATABASE_URL'))[:50] + '...' if os.getenv('DATABASE_URL') else None,
        'has_dotenv_file': os.path.exists('.env')
    },
    'timestamp': int(__import__('time').time() * 1000)
}
with open('d:\\CODE\\Project\\FinancialApp\\financial_app\\.cursor\\debug.log', 'a', encoding='utf-8') as f:
    f.write(json.dumps(log_data) + '\n')
# #endregion

class Config:
    # PostgreSQL Database Configuration (Supabase/Render)
    # Support connection string (Supabase/Render format) or individual parameters
    # DATABASE_URL is the preferred method for production (Render, Supabase, etc.)
    # Format: postgresql://user:password@host:port/database
    DATABASE_URL = os.getenv('DATABASE_URL')  # Connection string format (required for production)
    
    # #region agent log
    _log_data = {
        'sessionId': 'debug-session',
        'runId': 'run1',
        'hypothesisId': 'A',
        'location': 'config.py:25',
        'message': 'Config class DATABASE_URL assignment',
        'data': {
            'config_database_url': str(DATABASE_URL)[:50] + '...' if DATABASE_URL else None,
            'config_database_url_length': len(DATABASE_URL) if DATABASE_URL else 0
        },
        'timestamp': int(__import__('time').time() * 1000)
    }
    with open('d:\\CODE\\Project\\FinancialApp\\financial_app\\.cursor\\debug.log', 'a', encoding='utf-8') as f:
        f.write(json.dumps(_log_data) + '\n')
    # #endregion
    
    # Individual parameters (for development or if DATABASE_URL not provided)
    POSTGRES_HOST = os.getenv('POSTGRES_HOST', 'localhost')
    POSTGRES_USER = os.getenv('POSTGRES_USER', 'postgres')
    POSTGRES_PASSWORD = os.getenv('POSTGRES_PASSWORD', '')
    POSTGRES_DB = os.getenv('POSTGRES_DB', 'financial_db_232143')
    POSTGRES_PORT = int(os.getenv('POSTGRES_PORT', 5432))
    
    # Legacy MySQL support (for backward compatibility during migration)
    # These will be removed after full migration
    MYSQL_HOST = os.getenv('MYSQL_HOST', 'localhost')
    MYSQL_USER = os.getenv('MYSQL_USER', 'root')
    MYSQL_PASSWORD = os.getenv('MYSQL_PASSWORD', '')
    MYSQL_DB = os.getenv('MYSQL_DB', 'financial_db_232143')
    MYSQL_PORT = int(os.getenv('MYSQL_PORT', 3306))
    
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