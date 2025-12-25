#!/usr/bin/env python3
"""
Initialize SQLite database with schema
Run this script to create the database and tables
"""
import os
import sqlite3
from pathlib import Path

def init_database(db_path):
    """Initialize SQLite database with schema"""
    
    # Ensure directory exists
    db_dir = os.path.dirname(db_path)
    if db_dir and not os.path.exists(db_dir):
        os.makedirs(db_dir, exist_ok=True)
    
    # Connect to database
    conn = sqlite3.connect(db_path)
    conn.execute("PRAGMA foreign_keys=ON")
    conn.execute("PRAGMA journal_mode=WAL")
    
    # Read and execute schema file
    schema_file = os.path.join(os.path.dirname(__file__), 'financial_db_232143_sqlite.sql')
    
    if not os.path.exists(schema_file):
        print(f"❌ Schema file not found: {schema_file}")
        return False
    
    print(f"📖 Reading schema from: {schema_file}")
    with open(schema_file, 'r', encoding='utf-8') as f:
        schema_sql = f.read()
    
    # Execute schema (SQLite can handle multiple statements)
    print("🔨 Creating tables and indexes...")
    try:
        conn.executescript(schema_sql)
        conn.commit()
        print("✅ Database initialized successfully!")
        print(f"📁 Database file: {db_path}")
        return True
    except sqlite3.Error as e:
        print(f"❌ Error initializing database: {e}")
        conn.rollback()
        return False
    finally:
        conn.close()

if __name__ == "__main__":
    import sys
    from config import Config
    
    # Get database path from config
    db_path = Config.SQLITE_DB_PATH
    
    if len(sys.argv) > 1:
        db_path = sys.argv[1]
    
    print(f"🚀 Initializing SQLite database...")
    print(f"   Path: {db_path}")
    
    if init_database(db_path):
        print("\n✅ Database initialization complete!")
        print("   You can now start the Flask app.")
    else:
        print("\n❌ Database initialization failed!")
        sys.exit(1)

