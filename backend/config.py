import os
from datetime import timedelta
from dotenv import load_dotenv
from urllib.parse import urlparse

load_dotenv()

class Config:
    # PostgreSQL Database Configuration
    # Production: Use DATABASE_URL from hosting provider
    # Local: Use individual connection parameters
    DATABASE_URL = os.getenv('DATABASE_URL')
    
    if DATABASE_URL:
        # Parse DATABASE_URL for production (Render, Railway, etc.)
        url = urlparse(DATABASE_URL)
        DB_HOST = url.hostname
        DB_USER = url.username
        DB_PASSWORD = url.password
        DB_NAME = url.path[1:]  # Remove leading '/'
        DB_PORT = url.port or 5432
    else:
        # Local development configuration
        DB_HOST = os.getenv('DB_HOST', 'localhost')
        DB_USER = os.getenv('DB_USER', 'postgres')
        DB_PASSWORD = os.getenv('DB_PASSWORD', '')
        DB_NAME = os.getenv('DB_NAME', 'financial_db_232143')
        DB_PORT = int(os.getenv('DB_PORT', 5432))
    
    # JWT Configuration
    JWT_SECRET_KEY = os.getenv('JWT_SECRET_KEY', 'dev-secret-key-232143-change-in-production')
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(days=7)
    
    # API Configuration
    API_PREFIX = '/api/v1'
    DEBUG = os.getenv('DEBUG', 'True').lower() == 'true'