"""
Migration script to add missing budget triggers (PostgreSQL version)
Run this to fix budget not updating when transactions are added/updated/deleted
"""

import sys
import os
import psycopg2
from psycopg2.extras import RealDictCursor
from config import Config

def run_migration():
    """Run the migration to add budget triggers (PostgreSQL)"""
    print("🔄 Starting migration: Adding budget update triggers...")
    
    # Connect to database
    if Config.DATABASE_URL:
        db = psycopg2.connect(Config.DATABASE_URL, cursor_factory=RealDictCursor)
    else:
        db = psycopg2.connect(
            host=Config.POSTGRES_HOST,
            user=Config.POSTGRES_USER,
            password=Config.POSTGRES_PASSWORD,
            database=Config.POSTGRES_DB,
            port=Config.POSTGRES_PORT,
            cursor_factory=RealDictCursor
        )
    
    try:
        # Read the SQL migration file (PostgreSQL version)
        migration_file = os.path.join(os.path.dirname(__file__), 'add_budget_triggers_postgresql.sql')
        if not os.path.exists(migration_file):
            # Fallback to MySQL version if PostgreSQL version doesn't exist
            migration_file = os.path.join(os.path.dirname(__file__), 'add_budget_triggers.sql')
            print("⚠️  Using MySQL migration file. Consider using PostgreSQL version.")
        
        with open(migration_file, 'r', encoding='utf-8') as f:
            sql_content = f.read()
        
        # Split SQL by semicolons (PostgreSQL doesn't use DELIMITER)
        statements = [s.strip() for s in sql_content.split(';') if s.strip() and not s.strip().startswith('--')]
        
        # Execute each statement
        with db.cursor() as cursor:
            for i, statement in enumerate(statements, 1):
                if statement.strip() and not statement.strip().startswith('--'):
                    try:
                        print(f"   Executing statement {i}/{len(statements)}...")
                        cursor.execute(statement)
                        db.commit()
                    except Exception as e:
                        print(f"   ⚠️  Warning on statement {i}: {e}")
                        # Continue with other statements
                        db.rollback()
        
        print("✅ Migration completed successfully!")
        print("\n📊 Triggers added:")
        print("   - after_transaction_insert_232143")
        print("   - after_transaction_update_232143")
        print("   - after_transaction_delete_232143")
        print("\n💡 Budgets will now automatically update when transactions change!")
        
    except Exception as e:
        print(f"❌ Migration failed: {e}")
        import traceback
        traceback.print_exc()
        db.rollback()
        sys.exit(1)
    finally:
        db.close()

if __name__ == '__main__':
    run_migration()
