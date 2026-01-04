import pymysql
from pymysql.cursors import DictCursor
from flask import g
import config
import os
import time
import threading
from queue import Queue, Empty as QueueEmpty, Full as QueueFull

# Global connection pool
_connection_pool = None
_pool_lock = threading.Lock()
_max_connections = 10
_min_connections = 1
# Connection parameters (stored after pool initialization)
_conn_host = None
_conn_port = None
_conn_user = None
_conn_password = None
_conn_database = None
_conn_maxsize = None
_conn_current_size = 0
# Ensure these are always integers, never None after initialization

def _get_connection_pool():
    """Initialize and return connection pool (thread-safe singleton)"""
    global _connection_pool
    
    if _connection_pool is None:
        with _pool_lock:
            # Double-check pattern
            if _connection_pool is None:
                try:
                    database_url = config.Config.DATABASE_URL or os.getenv('DATABASE_URL')
                    
                    # Parse connection parameters
                    if database_url and database_url.strip():
                        # Parse MySQL connection string: mysql://user:password@host:port/database
                        if database_url.startswith('mysql://'):
                            # Remove mysql:// prefix
                            url = database_url[8:]
                            # Parse user:password@host:port/database
                            if '@' in url:
                                auth_part, host_part = url.split('@', 1)
                                if ':' in auth_part:
                                    user, password = auth_part.split(':', 1)
                                else:
                                    user = auth_part
                                    password = ''
                                
                                if '/' in host_part:
                                    host_port, database = host_part.split('/', 1)
                                else:
                                    host_port = host_part
                                    database = ''
                                
                                if ':' in host_port:
                                    host, port = host_port.split(':')
                                    port = int(port)
                                else:
                                    host = host_port
                                    port = 3306
                            else:
                                raise ValueError("Invalid MySQL connection string format")
                        else:
                            raise ValueError("DATABASE_URL must start with mysql:// for MySQL")
                    else:
                        # Fallback to individual parameters (development - use MySQL)
                        is_production = os.getenv('PORT')
                        if is_production:
                            raise ValueError("DATABASE_URL must be set in production")
                        
                        # Use MySQL config parameters
                        user = config.Config.MYSQL_USER
                        password = config.Config.MYSQL_PASSWORD
                        host = config.Config.MYSQL_HOST
                        port = config.Config.MYSQL_PORT
                        database = config.Config.MYSQL_DB
                    
                    # Determine pool size
                    is_production = os.getenv('PORT')
                    minconn = 2 if is_production else 1
                    maxconn = 10 if is_production else 5
                    
                    print(f"🔗 Initializing MySQL connection pool (min={minconn}, max={maxconn})...")
                    print(f"   Connecting to: {host}:{port}/{database}")
                    
                    # Create a simple connection pool using Queue
                    # PyMySQL doesn't have built-in pooling, so we'll create a queue of connections
                    _connection_pool = Queue(maxsize=maxconn)
                    
                    # Pre-populate pool with minimum connections
                    for _ in range(minconn):
                        conn = pymysql.connect(
                            host=host,
                            port=port,
                            user=user,
                            password=password,
                            database=database,
                            cursorclass=DictCursor,
                            autocommit=True,
                            charset='utf8mb4',
                            connect_timeout=10,
                            read_timeout=30,
                            write_timeout=30
                        )
                        _connection_pool.put(conn)
                    
                    # Store connection parameters for creating new connections
                    global _conn_host, _conn_port, _conn_user, _conn_password, _conn_database, _conn_maxsize, _conn_current_size
                    _conn_host = host
                    _conn_port = port
                    _conn_user = user
                    _conn_password = password
                    _conn_database = database
                    _conn_maxsize = maxconn
                    _conn_current_size = minconn
                    
                    print("✅ MySQL connection pool initialized successfully")
                    
                except Exception as e:
                    print(f"❌ Failed to create connection pool: {e}")
                    raise
    
    return _connection_pool

def _create_connection():
    """Create a new MySQL connection"""
    global _conn_host, _conn_port, _conn_user, _conn_password, _conn_database
    # Ensure pool is initialized (this will set the connection parameters)
    _get_connection_pool()
    return pymysql.connect(
        host=_conn_host,
        port=_conn_port,
        user=_conn_user,
        password=_conn_password,
        database=_conn_database,
        cursorclass=DictCursor,
        autocommit=True,
        charset='utf8mb4',
        connect_timeout=10,
        read_timeout=30,
        write_timeout=30
    )

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
                    global _conn_current_size, _conn_maxsize
                    # Try to get connection from pool (non-blocking)
                    try:
                        g.db = pool.get_nowait()
                    except QueueEmpty:
                        # Pool is empty, create new connection if under max
                        # Ensure both variables are initialized before comparison
                        if _conn_maxsize is not None and _conn_current_size is not None:
                            if _conn_current_size < _conn_maxsize:
                                g.db = _create_connection()
                                _conn_current_size += 1
                            else:
                                # Wait for a connection to become available
                                g.db = pool.get(timeout=5)
                        else:
                            # Pool not fully initialized, wait for connection
                            g.db = pool.get(timeout=5)
                    
                    # Test connection is alive
                    try:
                        cursor = g.db.cursor()
                        cursor.execute("SELECT 1")
                        cursor.close()
                    except:
                        # Connection is dead, create a new one
                        try:
                            g.db.close()
                        except:
                            pass
                        g.db = _create_connection()
                    
                    break  # Success, exit retry loop
                    
                except (pymysql.OperationalError, pymysql.InterfaceError) as e:
                    # Connection might be stale, try to get a new one
                    if 'db' in g and g.db:
                        try:
                            g.db.close()
                        except:
                            pass
                        g.pop('db', None)
                    
                    if attempt < max_retries - 1:
                        time.sleep(retry_delay * (attempt + 1))  # Exponential backoff
                        continue
                    else:
                        raise
                        
        except pymysql.OperationalError as e:
            error_msg = f"❌ Database connection failed: {e}"
            print(error_msg)
            # Provide more helpful error message
            if "Access denied" in str(e) or "1045" in str(e):
                print("⚠️  HINT: Check MySQL username and password in your .env file.")
                print("   Make sure MYSQL_USER and MYSQL_PASSWORD are correct.")
            elif "Unknown database" in str(e) or "1049" in str(e):
                print("⚠️  HINT: Database does not exist. Create it first:")
                print("   CREATE DATABASE financial_db_232143;")
            elif "Connection refused" in str(e) or "Can't connect" in str(e):
                print("⚠️  HINT: Make sure MySQL server is running.")
                print("   Check that MySQL is installed and running on localhost:3306")
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
            # Reset connection state before returning to pool
            # Rollback any pending transaction to ensure clean state
            try:
                if not db.open:
                    # Connection is closed, don't return to pool
                    return
                # PyMySQL with autocommit=True doesn't need rollback
                # Just ensure connection is clean
            except:
                pass
            
            pool = _get_connection_pool()
            global _conn_current_size
            # Return connection to pool (reuse for next request)
            try:
                pool.put_nowait(db)
            except QueueFull:
                # Pool is full, close the connection
                try:
                    db.close()
                except:
                    pass
                if _conn_current_size is not None and _conn_current_size > 0:
                    _conn_current_size -= 1
            except Exception:
                # Other error, close the connection
                try:
                    db.close()
                except:
                    pass
                if _conn_current_size is not None and _conn_current_size > 0:
                    _conn_current_size -= 1
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
            while not _connection_pool.empty():
                try:
                    conn = _connection_pool.get_nowait()
                    conn.close()
                except:
                    pass
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
