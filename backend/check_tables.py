#!/usr/bin/env python3
"""
Script to check if required database tables exist
"""
import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app import create_app

def check_tables():
    app = create_app()
    with app.app_context():
        try:
            from models.database import get_db
            db = get_db()
            with db.cursor() as cursor:
                required_tables = [
                    'users_232143',
                    'categories_232143',
                    'transactions_232143',
                    'financial_obligations_232143',
                    'obligation_payments_232143'
                ]

                print("Checking database tables...")
                for table in required_tables:
                    cursor.execute(f"SHOW TABLES LIKE '{table}'")
                    result = cursor.fetchone()
                    if result:
                        print(f"✅ Table '{table}' exists")
                    else:
                        print(f"❌ Table '{table}' does not exist")

                # Check table structures
                print("\nChecking table structures...")
                for table in required_tables:
                    try:
                        cursor.execute(f"DESCRIBE {table}")
                        columns = cursor.fetchall()
                        print(f"✅ Table '{table}' has {len(columns)} columns")
                    except Exception as e:
                        print(f"❌ Error describing table '{table}': {e}")

        except Exception as e:
            print(f"❌ Database check failed: {e}")

if __name__ == "__main__":
    check_tables()
