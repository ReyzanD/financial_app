"""
Migration script to add location fields to transactions table
Run this to enable location-based recommendations
"""

import sys
import pymysql

# Database connection settings
DB_CONFIG = {
    'host': 'localhost',
    'user': 'root',
    'password': '',
    'database': 'financial_db_232143',
    'charset': 'utf8mb4',
    'cursorclass': pymysql.cursors.DictCursor
}

def run_migration():
    """Add location fields to transactions table"""
    print("🔄 Starting migration: Adding location fields...")
    print("   This will add: location_name, latitude, longitude columns")
    
    db = pymysql.connect(**DB_CONFIG)
    
    try:
        with db.cursor() as cursor:
            # Check if columns already exist
            cursor.execute("""
                SELECT COLUMN_NAME 
                FROM INFORMATION_SCHEMA.COLUMNS 
                WHERE TABLE_SCHEMA = 'financial_db_232143' 
                AND TABLE_NAME = 'transactions_232143'
                AND COLUMN_NAME IN ('location_name_232143', 'latitude_232143', 'longitude_232143')
            """)
            existing_columns = [row['COLUMN_NAME'] for row in cursor.fetchall()]
            
            if len(existing_columns) == 3:
                print("✅ All location columns already exist!")
                return
            
            # Add location_name column
            if 'location_name_232143' not in existing_columns:
                print("   Adding location_name_232143 column...")
                cursor.execute("""
                    ALTER TABLE transactions_232143
                    ADD COLUMN location_name_232143 TEXT
                """)
                db.commit()
                print("   ✅ location_name_232143 added")
            else:
                print("   ⏭️  location_name_232143 already exists")
            
            # Add latitude column
            if 'latitude_232143' not in existing_columns:
                print("   Adding latitude_232143 column...")
                cursor.execute("""
                    ALTER TABLE transactions_232143
                    ADD COLUMN latitude_232143 DECIMAL(10, 7)
                """)
                db.commit()
                print("   ✅ latitude_232143 added")
            else:
                print("   ⏭️  latitude_232143 already exists")
            
            # Add longitude column
            if 'longitude_232143' not in existing_columns:
                print("   Adding longitude_232143 column...")
                cursor.execute("""
                    ALTER TABLE transactions_232143
                    ADD COLUMN longitude_232143 DECIMAL(10, 7)
                """)
                db.commit()
                print("   ✅ longitude_232143 added")
            else:
                print("   ⏭️  longitude_232143 already exists")
            
            # Create index for location-based queries
            print("   Creating index for location queries...")
            try:
                cursor.execute("""
                    CREATE INDEX idx_transactions_location 
                    ON transactions_232143(location_name_232143(255))
                """)
                db.commit()
                print("   ✅ Index created")
            except Exception as e:
                if 'Duplicate key name' in str(e):
                    print("   ⏭️  Index already exists")
                else:
                    print(f"   ⚠️  Warning creating index: {e}")
            
            print("\n✅ Migration completed successfully!")
            print("\n📊 Columns added:")
            print("   - location_name_232143 (TEXT)")
            print("   - latitude_232143 (DECIMAL)")
            print("   - longitude_232143 (DECIMAL)")
            print("\n💡 Location-based recommendations will now work!")
            print("   Add expenses with location to see recommendations on home screen.")
        
    except Exception as e:
        print(f"❌ Migration failed: {e}")
        import traceback
        traceback.print_exc()
        db.rollback()
        sys.exit(1)
    finally:
        db.close()

if __name__ == '__main__':
    print("=" * 60)
    print("  LOCATION FIELDS MIGRATION")
    print("=" * 60)
    run_migration()
    print("=" * 60)
