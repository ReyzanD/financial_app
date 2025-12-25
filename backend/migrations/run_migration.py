"""
Migration script for SQLite database
Note: Budget triggers are already included in the SQLite schema file.
This script is kept for reference but may not be needed if using the full schema.
"""

import sys
import os
import sqlite3
from config import Config

def run_migration():
    """Run migration for SQLite database"""
    print("🔄 Starting migration: Checking budget triggers...")
    print("   Note: Budget triggers should already be in the SQLite schema")
    
    db_path = Config.SQLITE_DB_PATH
    
    try:
        db = sqlite3.connect(db_path)
        db.execute("PRAGMA foreign_keys=ON")
        
        with db.cursor() as cursor:
            # Check if triggers exist
            cursor.execute("""
                SELECT name FROM sqlite_master 
                WHERE type='trigger' 
                AND name LIKE '%transaction%'
            """)
            existing_triggers = [row[0] for row in cursor.fetchall()]
            
            required_triggers = [
                'after_transaction_insert_232143',
                'after_transaction_update_232143',
                'after_transaction_delete_232143'
            ]
            
            missing_triggers = [t for t in required_triggers if t not in existing_triggers]
            
            if not missing_triggers:
                print("✅ All budget triggers already exist!")
                print("\n📊 Existing triggers:")
                for trigger in existing_triggers:
                    print(f"   - {trigger}")
                return
            
            print(f"⚠️  Missing triggers: {', '.join(missing_triggers)}")
            print("   These should be created by the SQLite schema file.")
            print("   If you see this message, re-run init_sqlite_db.py")
        
    except Exception as e:
        print(f"❌ Migration check failed: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
    finally:
        db.close()

if __name__ == '__main__':
    run_migration()
