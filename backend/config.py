import os
from datetime import timedelta
from dotenv import load_dotenv

load_dotenv()

class Config:
    # MySQL Database Configuration
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