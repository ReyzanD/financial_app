import pymysql
from config import Config

def add_indexes():
    db = pymysql.connect(
        host=Config.MYSQL_HOST,
        user=Config.MYSQL_USER,
        password=Config.MYSQL_PASSWORD,
        database=Config.MYSQL_DB,
        port=Config.MYSQL_PORT,
        charset='utf8mb4',
        cursorclass=pymysql.cursors.DictCursor
    )
    with db.cursor() as cursor:
        # Add index for monthly summary query
        # Add index for user_id and transaction_date
        try:
            cursor.execute("""
                ALTER TABLE transactions_232143 
                ADD INDEX idx_transaction_date_user (user_id_232143, transaction_date_232143)
            """)
            print("✅ Added index idx_transaction_date_user")
        except Exception as e:
            if "Duplicate key name" in str(e):
                print("ℹ️ Index idx_transaction_date_user already exists")
            else:
                raise e
        
        # Add index for type and date
        try:
            cursor.execute("""
                ALTER TABLE transactions_232143 
                ADD INDEX idx_type_date (type_232143, transaction_date_232143)
            """)
            print("✅ Added index idx_type_date")
        except Exception as e:
            if "Duplicate key name" in str(e):
                print("ℹ️ Index idx_type_date already exists")
            else:
                raise e
        
        db.commit()
        print("✅ Indexes added successfully")

if __name__ == "__main__":
    add_indexes()