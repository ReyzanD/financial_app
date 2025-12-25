import psycopg2
from psycopg2 import pool
from psycopg2.extras import RealDictCursor
from flask import g
import config
import os
import time
import threading

# Global connection pool
_connection_pool = None
_pool_lock = threading.Lock()

def _get_connection_pool():
    """Initialize and return connection pool (thread-safe singleton)"""
    global _connection_pool
    
    if _connection_pool is None:
        with _pool_lock:
            # Double-check pattern
            if _connection_pool is None:
                try:
                    database_url = config.Config.DATABASE_URL or os.getenv('DATABASE_URL')
                    
                    if not database_url or not database_url.strip():
                        # Fallback to individual parameters (development only)
                        is_production = os.getenv('PORT') or os.getenv('RENDER')
                        if is_production:
                            raise ValueError("DATABASE_URL must be set in production")
                        
                        # Build connection string from individual parameters
                        database_url = (
                            f"postgresql://{config.Config.POSTGRES_USER}:{config.Config.POSTGRES_PASSWORD}"
                            f"@{config.Config.POSTGRES_HOST}:{config.Config.POSTGRES_PORT}/{config.Config.POSTGRES_DB}"
                        )
                    
                    # Create connection pool
                    # For production: minconn=2, maxconn=10 (adjust based on traffic)
                    # For development: minconn=1, maxconn=5
                    is_production = os.getenv('PORT') or os.getenv('RENDER')
                    minconn = 2 if is_production else 1
                    maxconn = 10 if is_production else 5
                    
                    print(f"🔗 Initializing database connection pool (min={minconn}, max={maxconn})...")
                    
                    _connection_pool = pool.ThreadedConnectionPool(
                        minconn=minconn,
                        maxconn=maxconn,
                        dsn=database_url,
                        cursor_factory=RealDictCursor,
                        # Connection timeout (seconds) - increased for Supabase
                        connect_timeout=30,
                        # Keep connections alive
                        keepalives=1,
                        keepalives_idle=30,
                        keepalives_interval=10,
                        keepalives_count=5
                    )
                    
                    print("✅ Database connection pool initialized successfully")
                    
                except Exception as e:
                    print(f"❌ Failed to create connection pool: {e}")
                    raise
    
    return _connection_pool

def get_db():
    """Get database connection from pool (reuses connections efficiently)"""
    if 'db' not in g:
        try:
            pool = _get_connection_pool()
            
            # Get connection from pool
            max_retries = 3
            retry_delay = 0.5  # seconds
            
            for attempt in range(max_retries):
                try:
                    g.db = pool.getconn()
                    
                    # Test connection is alive
                    if g.db.closed:
                        pool.putconn(g.db, close=True)
                        g.db = pool.getconn()
                    
                    # Quick ping to ensure connection is working
                    # Note: Don't set autocommit with Supabase connection pooling (pgbouncer)
                    # PgBouncer doesn't support autocommit mode
                    cursor = g.db.cursor()
                    cursor.execute("SELECT 1")
                    cursor.close()
                    # Commit the test query
                    g.db.commit()
                    
                    break  # Success, exit retry loop
                    
                except (psycopg2.OperationalError, psycopg2.InterfaceError, psycopg2.DatabaseError) as e:
                    error_str = str(e)
                    # Connection might be stale, try to get a new one
                    if 'db' in g and g.db:
                        try:
                            pool.putconn(g.db, close=True)
                        except:
                            pass
                        g.pop('db', None)
                    
                    # Log the error for debugging
                    if attempt == 0:
                        print(f"⚠️  Connection attempt {attempt + 1} failed: {error_str[:100]}")
                    
                    if attempt < max_retries - 1:
                        wait_time = retry_delay * (attempt + 1)
                        print(f"   Retrying in {wait_time}s... (attempt {attempt + 2}/{max_retries})")
                        time.sleep(wait_time)  # Exponential backoff
                        continue
                    else:
                        print(f"❌ All connection attempts failed")
                        raise
                        
        except psycopg2.OperationalError as e:
            error_msg = f"❌ Database connection failed: {e}"
            print(error_msg)
            # Provide more helpful error message
            if "Connection refused" in str(e) or "localhost" in str(e):
                print("⚠️  HINT: Make sure DATABASE_URL is set in your environment variables.")
                print("   For Render.com, set DATABASE_URL in your service environment variables.")
            elif "Network is unreachable" in str(e) or "unreachable" in str(e).lower() or "timeout" in str(e).lower():
                print("⚠️  HINT: Network connectivity issue or timeout detected.")
                print("   Possible solutions:")
                print("   1. Check if Supabase project is active (not paused)")
                print("   2. Verify DATABASE_URL uses Connection Pooling (port 6543)")
                print("   3. Check network connectivity from Render to Supabase")
                print("   4. Try increasing connect_timeout in database.py (currently 30s)")
                print("   5. If using direct connection, switch to Connection Pooling:")
                print("      - Go to Supabase Dashboard → Project Settings → Database")
                print("      - Select 'Connection pooling' tab (not 'URI')")
                print("      - Copy the connection string (port 6543, not 5432)")
                print("      - Update DATABASE_URL in Render with the pooling URL")
            raise e
        except Exception as e:
            print(f"❌ Database connection failed: {e}")
            raise e
    
    return g.db

def close_db(e=None):
    """Return connection to pool (doesn't actually close, just returns to pool)"""
    db = g.pop('db', None)
    if db is not None:
        try:
            pool = _get_connection_pool()
            # Return connection to pool (reuse for next request)
            pool.putconn(db)
        except Exception as e:
            # If pool is closed or error, just close the connection
            try:
                db.close()
            except:
                pass

def close_all_connections():
    """Close all connections in pool (called on app shutdown)"""
    global _connection_pool
    if _connection_pool is not None:
        try:
            _connection_pool.closeall()
            print("✅ All database connections closed")
        except:
            pass
        _connection_pool = None

def init_app(app):
    """Initialize database for Flask app"""
    app.teardown_appcontext(close_db)
    
    # Close all connections on app shutdown
    @app.teardown_appcontext
    def shutdown_db(error):
        # Connection is already returned to pool in close_db
        # This is just for cleanup if needed
        pass