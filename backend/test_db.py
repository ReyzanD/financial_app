#!/usr/bin/env python3
"""
Simple script to test database connection
"""
import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app import create_app

def test_db_connection():
    app = create_app()
    with app.app_context():
        try:
            from models.database import get_db
            db = get_db()
            with db.cursor() as cursor:
                cursor.execute("SELECT 1")
                result = cursor.fetchone()
                print("✅ Database connection successful!")
                print(f"Test query result: {result}")
            return True
        except Exception as e:
            print(f"❌ Database connection failed: {e}")
            return False

if __name__ == "__main__":
    test_db_connection()
