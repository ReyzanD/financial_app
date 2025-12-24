import os
from datetime import timedelta
from dotenv import load_dotenv

load_dotenv()

class Config:
    # PostgreSQL Database Configuration (Supabase)
    # Support connection string (Supabase format) or individual parameters
    DATABASE_URL = os.getenv('DATABASE_URL')  # Supabase connection string format
    
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
    JWT_SECRET_KEY = os.getenv('JWT_SECRET_KEY', 'dev-secret-key-232143-change-in-production')
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(days=7)
    
    # API Configuration
    API_PREFIX = '/api/v1'
    DEBUG = os.getenv('DEBUG', 'True').lower() == 'true'
    
    # Server Configuration
    PORT = int(os.getenv('PORT', 5000))