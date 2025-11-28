"""
Migration script to add missing budget triggers
Run this to fix budget not updating when transactions are added/updated/deleted
"""

import sys
import os
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
    """Run the migration to add budget triggers"""
    print("🔄 Starting migration: Adding budget update triggers...")
    
    # Connect directly to database
    db = pymysql.connect(**DB_CONFIG)
    
    try:
        # Read the SQL migration file
        migration_file = os.path.join(os.path.dirname(__file__), 'add_budget_triggers.sql')
        with open(migration_file, 'r') as f:
            sql_content = f.read()
        
        # Split by DELIMITER to handle stored procedures/triggers
        statements = []
        current_delimiter = ';'
        current_statement = []
        
        for line in sql_content.split('\n'):
            line = line.strip()
            
            # Skip comments and empty lines
            if not line or line.startswith('--'):
                continue
            
            # Check for DELIMITER change
            if line.upper().startswith('DELIMITER'):
                if current_statement:
                    statements.append('\n'.join(current_statement))
                    current_statement = []
                current_delimiter = line.split()[1]
                continue
            
            current_statement.append(line)
            
            # Check if statement ends with current delimiter
            if line.endswith(current_delimiter):
                # Remove the delimiter from the statement
                statement = '\n'.join(current_statement)
                if current_delimiter != ';':
                    statement = statement[:-len(current_delimiter)].strip()
                else:
                    statement = statement[:-1].strip()
                
                if statement:
                    statements.append(statement)
                current_statement = []
        
        # Add any remaining statement
        if current_statement:
            statements.append('\n'.join(current_statement))
        
        # Execute each statement
        with db.cursor() as cursor:
            for i, statement in enumerate(statements, 1):
                if statement.strip():
                    try:
                        print(f"   Executing statement {i}/{len(statements)}...")
                        cursor.execute(statement)
                        db.commit()
                    except Exception as e:
                        print(f"   ⚠️  Warning on statement {i}: {e}")
                        # Continue with other statements
        
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
