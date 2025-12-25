import sqlite3
from flask import g
import config
import os
from pathlib import Path

class SQLiteCursor:
    """Wrapper to make SQLite cursor work like PostgreSQL cursor (for compatibility)"""
    def __init__(self, connection):
        self.connection = connection
        self.cursor = connection.cursor()
        self._closed = False
    
    def execute(self, sql, params=None):
        # Convert %s placeholders to ? for SQLite
        if params:
            sql = sql.replace('%s', '?')
        return self.cursor.execute(sql, params or ())
    
    def fetchone(self):
        row = self.cursor.fetchone()
        if row:
            # Convert Row to dict-like object
            return dict(row)
        return None
    
    def fetchall(self):
        rows = self.cursor.fetchall()
        return [dict(row) for row in rows]
    
    def close(self):
        if not self._closed:
            self.cursor.close()
            self._closed = True
    
    @property
    def rowcount(self):
        return self.cursor.rowcount
    
    def __enter__(self):
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        self.close()

def get_db():
    """Get SQLite database connection (file-based, no pooling needed)"""
    if 'db' not in g:
        try:
            # Get database path from config
            db_path = config.Config.SQLITE_DB_PATH
            
            # Ensure directory exists
            db_dir = os.path.dirname(db_path)
            if db_dir and not os.path.exists(db_dir):
                os.makedirs(db_dir, exist_ok=True)
            
            # Connect to SQLite database
            conn = sqlite3.connect(
                db_path,
                check_same_thread=False,  # Allow use in Flask (multi-threaded)
                timeout=30.0  # Connection timeout in seconds
            )
            
            # Enable row factory for dict-like access (similar to RealDictCursor)
            conn.row_factory = sqlite3.Row
            
            # Enable foreign keys (disabled by default in SQLite)
            conn.execute("PRAGMA foreign_keys=ON")
            
            # Enable WAL mode for better concurrency
            conn.execute("PRAGMA journal_mode=WAL")
            
            # Set busy timeout to handle concurrent writes
            conn.execute("PRAGMA busy_timeout=30000")  # 30 seconds
            
            # Store connection with cursor method
            class DBWrapper:
                def __init__(self, conn):
                    self.conn = conn
                    self.row_factory = conn.row_factory
                
                def cursor(self):
                    return SQLiteCursor(self.conn)
                
                def commit(self):
                    return self.conn.commit()
                
                def rollback(self):
                    return self.conn.rollback()
                
                def close(self):
                    return self.conn.close()
                
                def execute(self, sql, params=None):
                    if params:
                        sql = sql.replace('%s', '?')
                    return self.conn.execute(sql, params or ())
            
            g.db = DBWrapper(conn)
            
            print(f"✅ SQLite database connected: {db_path}")
            
        except Exception as e:
            error_msg = f"❌ SQLite database connection failed: {e}"
            print(error_msg)
            raise e
    
    return g.db

def close_db(e=None):
    """Close SQLite database connection"""
    db = g.pop('db', None)
    if db is not None:
        try:
            db.close()
        except Exception as e:
            print(f"⚠️  Error closing database connection: {e}")

def init_app(app):
    """Initialize database for Flask app"""
    app.teardown_appcontext(close_db)
