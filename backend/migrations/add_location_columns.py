"""
Migration script to add location fields to transactions table (SQLite version)
Run this to enable location-based recommendations
Note: These columns are already included in the SQLite schema, but this script
can be used to add them to existing databases if needed.
"""

import sys
import sqlite3
from config import Config

def run_migration():
    """Add location fields to transactions table (SQLite)"""
    print("🔄 Starting migration: Adding location fields...")
    print("   This will add: location_name, latitude, longitude columns")
    
    db_path = Config.SQLITE_DB_PATH
    
    try:
        db = sqlite3.connect(db_path)
        db.execute("PRAGMA foreign_keys=ON")
        
        with db.cursor() as cursor:
            # Check if columns already exist (SQLite way)
            cursor.execute("PRAGMA table_info(transactions_232143)")
            columns = {row[1]: row for row in cursor.fetchall()}
            
            existing_location_cols = [
                col for col in ['location_name_232143', 'latitude_232143', 'longitude_232143']
                if col in columns
            ]
            
            if len(existing_location_cols) == 3:
                print("✅ All location columns already exist!")
                return
            
            # Add location_name column
            if 'location_name_232143' not in columns:
                print("   Adding location_name_232143 column...")
                cursor.execute("""
                    ALTER TABLE transactions_232143
                    ADD COLUMN location_name_232143 TEXT
                """)
                print("   ✅ location_name_232143 added")
            else:
                print("   ⏭️  location_name_232143 already exists")
            
            # Add latitude column
            if 'latitude_232143' not in columns:
                print("   Adding latitude_232143 column...")
                cursor.execute("""
                    ALTER TABLE transactions_232143
                    ADD COLUMN latitude_232143 DECIMAL(10, 8)
                """)
                print("   ✅ latitude_232143 added")
            else:
                print("   ⏭️  latitude_232143 already exists")
            
            # Add longitude column
            if 'longitude_232143' not in columns:
                print("   Adding longitude_232143 column...")
                cursor.execute("""
                    ALTER TABLE transactions_232143
                    ADD COLUMN longitude_232143 DECIMAL(11, 8)
                """)
                print("   ✅ longitude_232143 added")
            else:
                print("   ⏭️  longitude_232143 already exists")
            
            # Create index for location-based queries
            print("   Creating index for location queries...")
            try:
                cursor.execute("""
                    CREATE INDEX IF NOT EXISTS idx_transactions_location 
                    ON transactions_232143(location_name_232143)
                    WHERE location_name_232143 IS NOT NULL
                """)
                print("   ✅ Index created")
            except Exception as e:
                if 'already exists' in str(e).lower() or 'duplicate' in str(e).lower():
                    print("   ⏭️  Index already exists")
                else:
                    print(f"   ⚠️  Warning creating index: {e}")
            
            db.commit()
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
    print("  LOCATION FIELDS MIGRATION (SQLite)")
    print("=" * 60)
    run_migration()
    print("=" * 60)
