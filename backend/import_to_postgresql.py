"""
Import Script: Load exported MySQL data into PostgreSQL
"""

import psycopg2
import psycopg2.extras
import json
import os
from datetime import datetime

# PostgreSQL Configuration (update these for your local/production setup)
POSTGRESQL_CONFIG = {
    'host': os.getenv('DB_HOST', 'localhost'),
    'user': os.getenv('DB_USER', 'postgres'),
    'password': os.getenv('DB_PASSWORD', ''),
    'database': os.getenv('DB_NAME', 'financial_db_232143'),
    'port': int(os.getenv('DB_PORT', 5432))
}

def import_data_to_postgresql():
    """Import data from JSON files to PostgreSQL"""
    print("🔄 Connecting to PostgreSQL database...")
    
    try:
        conn = psycopg2.connect(**POSTGRESQL_CONFIG)
        cursor = conn.cursor()
        
        export_dir = 'mysql_export'
        
        # Tables in dependency order
        tables = [
            'users_232143',
            'categories_232143',
            'transactions_232143',
            'budgets_232143',
            'goals_232143',
            'goal_contributions_232143',
            'subscriptions_232143',
            'debts_232143'
        ]
        
        total_imported = 0
        
        for table in tables:
            json_file = f"{export_dir}/{table}.json"
            
            if not os.path.exists(json_file):
                print(f"⚠️  Skipping {table} - file not found")
                continue
            
            print(f"📦 Importing {table}...")
            
            with open(json_file, 'r', encoding='utf-8') as f:
                rows = json.load(f)
            
            if not rows:
                print(f"   ⏭️  No data to import for {table}")
                continue
            
            # Get column names from first row
            columns = list(rows[0].keys())
            placeholders = ', '.join(['%s'] * len(columns))
            column_names = ', '.join(columns)
            
            insert_sql = f"INSERT INTO {table} ({column_names}) VALUES ({placeholders})"
            
            imported_count = 0
            for row in rows:
                try:
                    values = [row[col] for col in columns]
                    cursor.execute(insert_sql, values)
                    imported_count += 1
                except Exception as e:
                    print(f"   ⚠️  Error importing row: {e}")
                    continue
            
            conn.commit()
            total_imported += imported_count
            print(f"   ✅ Imported {imported_count} rows into {table}")
        
        cursor.close()
        conn.close()
        
        print(f"\n✅ Import completed! Total rows imported: {total_imported}")
        
    except Exception as e:
        print(f"❌ Import failed: {e}")
        import traceback
        traceback.print_exc()

if __name__ == '__main__':
    print("=" * 60)
    print("🐘 PostgreSQL Data Import Tool")
    print("=" * 60)
    
    # Check if export directory exists
    if not os.path.exists('mysql_export'):
        print("❌ Error: 'mysql_export' directory not found!")
        print("Please run migrate_to_postgresql.py first to export data.")
        exit(1)
    
    import_data_to_postgresql()
    
    print("\n" + "=" * 60)
    print("✅ MIGRATION COMPLETE!")
    print("=" * 60)
    print("\nYour app is now ready to use PostgreSQL!")
    print("Start the Flask app: python app.py")
    print("=" * 60)
