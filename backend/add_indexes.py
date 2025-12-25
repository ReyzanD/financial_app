import sqlite3
from config import Config

def add_indexes():
    """Add additional indexes to SQLite database for performance optimization"""
    db_path = Config.SQLITE_DB_PATH
    
    try:
        db = sqlite3.connect(db_path)
        db.execute("PRAGMA foreign_keys=ON")
        
        with db.cursor() as cursor:
            # Add index for monthly summary query
            # Add index for user_id and transaction_date
            try:
                cursor.execute("""
                    CREATE INDEX IF NOT EXISTS idx_transaction_date_user 
                    ON transactions_232143 (user_id_232143, transaction_date_232143)
                """)
                print("✅ Added index idx_transaction_date_user")
            except Exception as e:
                if "already exists" in str(e).lower() or "duplicate" in str(e).lower():
                    print("ℹ️ Index idx_transaction_date_user already exists")
                else:
                    raise e
            
            # Add index for type and date
            try:
                cursor.execute("""
                    CREATE INDEX IF NOT EXISTS idx_type_date 
                    ON transactions_232143 (type_232143, transaction_date_232143)
                """)
                print("✅ Added index idx_type_date")
            except Exception as e:
                if "already exists" in str(e).lower() or "duplicate" in str(e).lower():
                    print("ℹ️ Index idx_type_date already exists")
                else:
                    raise e
            
            db.commit()
            print("✅ Indexes added successfully")
    except Exception as e:
        print(f"❌ Error adding indexes: {e}")
        raise
    finally:
        db.close()

if __name__ == "__main__":
    add_indexes()
