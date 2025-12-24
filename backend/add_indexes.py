import psycopg2
from psycopg2.extras import RealDictCursor
from config import Config

def add_indexes():
    # Use DATABASE_URL if available (Supabase), otherwise use individual parameters
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
            if "already exists" in str(e).lower():
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
            if "already exists" in str(e).lower():
                print("ℹ️ Index idx_type_date already exists")
            else:
                raise e
        
        db.commit()
        print("✅ Indexes added successfully")

if __name__ == "__main__":
    add_indexes()