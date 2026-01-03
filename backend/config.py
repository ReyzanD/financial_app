import os
from datetime import timedelta
from dotenv import load_dotenv

load_dotenv()

class Config:
    # MySQL Database Configuration (Primary for local development)
    # Support connection string or individual parameters
    # DATABASE_URL is the preferred method for production deployments
    # Format: mysql://user:password@host:port/database
    DATABASE_URL = os.getenv('DATABASE_URL')  # Connection string format (optional for local dev)
    
    # MySQL Individual parameters (for local development - used when DATABASE_URL not provided)
    MYSQL_HOST = os.getenv('MYSQL_HOST', 'localhost')
    MYSQL_USER = os.getenv('MYSQL_USER', 'root')
    MYSQL_PASSWORD = os.getenv('MYSQL_PASSWORD', '')
    MYSQL_DB = os.getenv('MYSQL_DB', 'financial_db_232143')
    MYSQL_PORT = int(os.getenv('MYSQL_PORT', 3306))
    
    # PostgreSQL Database Configuration (Legacy - for backward compatibility)
    # Only used if explicitly configured via DATABASE_URL with postgresql:// prefix
    POSTGRES_HOST = os.getenv('POSTGRES_HOST', 'localhost')
    POSTGRES_USER = os.getenv('POSTGRES_USER', 'postgres')
    POSTGRES_PASSWORD = os.getenv('POSTGRES_PASSWORD', '')
    POSTGRES_DB = os.getenv('POSTGRES_DB', 'financial_db_232143')
    POSTGRES_PORT = int(os.getenv('POSTGRES_PORT', 5432))
    
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