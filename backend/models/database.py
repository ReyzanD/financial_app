import psycopg2
from psycopg2.extras import RealDictCursor
from flask import g
import config
import os
import json

def get_db():
    if 'db' not in g:
        try:
            # #region agent log
            log_data = {
                'sessionId': 'debug-session',
                'runId': 'run1',
                'hypothesisId': 'A',
                'location': 'database.py:12',
                'message': 'Checking DATABASE_URL sources',
                'data': {
                    'config_database_url': str(config.Config.DATABASE_URL)[:50] + '...' if config.Config.DATABASE_URL else None,
                    'env_database_url': str(os.getenv('DATABASE_URL'))[:50] + '...' if os.getenv('DATABASE_URL') else None,
                    'flask_env': os.getenv('FLASK_ENV'),
                    'has_config_url': bool(config.Config.DATABASE_URL),
                    'has_env_url': bool(os.getenv('DATABASE_URL'))
                },
                'timestamp': int(__import__('time').time() * 1000)
            }
            with open('d:\\CODE\\Project\\FinancialApp\\financial_app\\.cursor\\debug.log', 'a', encoding='utf-8') as f:
                f.write(json.dumps(log_data) + '\n')
            # #endregion
            
            # Prefer DATABASE_URL (Supabase/Render connection string) if available
            # Check both from config and directly from env to ensure we catch it
            database_url = config.Config.DATABASE_URL or os.getenv('DATABASE_URL')
            
            # #region agent log
            log_data = {
                'sessionId': 'debug-session',
                'runId': 'run1',
                'hypothesisId': 'B',
                'location': 'database.py:25',
                'message': 'DATABASE_URL after merge check',
                'data': {
                    'database_url': str(database_url)[:100] + '...' if database_url else None,
                    'database_url_length': len(database_url) if database_url else 0,
                    'database_url_stripped': str(database_url.strip())[:100] + '...' if database_url and database_url.strip() else None,
                    'is_truthy': bool(database_url),
                    'is_stripped_truthy': bool(database_url and database_url.strip())
                },
                'timestamp': int(__import__('time').time() * 1000)
            }
            with open('d:\\CODE\\Project\\FinancialApp\\financial_app\\.cursor\\debug.log', 'a', encoding='utf-8') as f:
                f.write(json.dumps(log_data) + '\n')
            # #endregion
            
            if database_url and database_url.strip():
                # Use connection string (production/preferred method)
                # #region agent log
                # Mask password in log for security
                masked_url = database_url
                try:
                    if '@' in masked_url:
                        parts = masked_url.split('@')
                        if len(parts) >= 2:
                            user_pass = parts[0].split('://')[-1] if '://' in parts[0] else parts[0]
                            if ':' in user_pass:
                                user = user_pass.split(':')[0]
                                masked_url = masked_url.replace(user_pass, f"{user}:***MASKED***")
                except:
                    pass
                
                log_data = {
                    'sessionId': 'debug-session',
                    'runId': 'run1',
                    'hypothesisId': 'D',
                    'location': 'database.py:56',
                    'message': 'Attempting connection with DATABASE_URL',
                    'data': {
                        'connection_string_masked': masked_url[:100] + '...' if len(masked_url) > 100 else masked_url,
                        'connection_string_length': len(database_url),
                        'has_at_symbol': '@' in database_url,
                        'has_percent_encoding': '%' in database_url
                    },
                    'timestamp': int(__import__('time').time() * 1000)
                }
                with open('d:\\CODE\\Project\\FinancialApp\\financial_app\\.cursor\\debug.log', 'a', encoding='utf-8') as f:
                    f.write(json.dumps(log_data) + '\n')
                # #endregion
                print(f"🔗 Connecting to database using DATABASE_URL...")
                try:
                    g.db = psycopg2.connect(
                        database_url,
                        cursor_factory=RealDictCursor
                    )
                except psycopg2.OperationalError as conn_error:
                    # #region agent log
                    log_data = {
                        'sessionId': 'debug-session',
                        'runId': 'run1',
                        'hypothesisId': 'D',
                        'location': 'database.py:85',
                        'message': 'Connection failed with DATABASE_URL',
                        'data': {
                            'error': str(conn_error)[:200],
                            'error_type': type(conn_error).__name__
                        },
                        'timestamp': int(__import__('time').time() * 1000)
                    }
                    with open('d:\\CODE\\Project\\FinancialApp\\financial_app\\.cursor\\debug.log', 'a', encoding='utf-8') as f:
                        f.write(json.dumps(log_data) + '\n')
                    # #endregion
                    raise
                # #region agent log
                log_data = {
                    'sessionId': 'debug-session',
                    'runId': 'run1',
                    'hypothesisId': 'D',
                    'location': 'database.py:45',
                    'message': 'Connection successful with DATABASE_URL',
                    'data': {'status': 'success'},
                    'timestamp': int(__import__('time').time() * 1000)
                }
                with open('d:\\CODE\\Project\\FinancialApp\\financial_app\\.cursor\\debug.log', 'a', encoding='utf-8') as f:
                    f.write(json.dumps(log_data) + '\n')
                # #endregion
                print("✅ Database connection successful (using DATABASE_URL)")
            else:
                # Fallback to individual parameters (development only)
                # In production, this should not happen - DATABASE_URL should be set
                # #region agent log
                log_data = {
                    'sessionId': 'debug-session',
                    'runId': 'run1',
                    'hypothesisId': 'C',
                    'location': 'database.py:50',
                    'message': 'Falling back to individual parameters',
                    'data': {
                        'flask_env': os.getenv('FLASK_ENV'),
                        'flask_env_check': os.getenv('FLASK_ENV') == 'production',
                        'not_flask_env_check': not os.getenv('FLASK_ENV'),
                        'production_check_result': os.getenv('FLASK_ENV') == 'production' or not os.getenv('FLASK_ENV'),
                        'postgres_host': config.Config.POSTGRES_HOST,
                        'postgres_port': config.Config.POSTGRES_PORT,
                        'postgres_db': config.Config.POSTGRES_DB
                    },
                    'timestamp': int(__import__('time').time() * 1000)
                }
                with open('d:\\CODE\\Project\\FinancialApp\\financial_app\\.cursor\\debug.log', 'a', encoding='utf-8') as f:
                    f.write(json.dumps(log_data) + '\n')
                # #endregion
                # Check if we're in production (Render sets PORT, or we can check for Render-specific env vars)
                is_production = os.getenv('PORT') or os.getenv('RENDER') or not os.getenv('FLASK_ENV')
                
                if is_production:
                    # In production, DATABASE_URL must be set
                    error_msg = (
                        "❌ DATABASE_URL environment variable is not set in production! "
                        "Please set DATABASE_URL in Render Dashboard → Environment tab. "
                        f"Current env vars: PORT={os.getenv('PORT')}, RENDER={os.getenv('RENDER')}, "
                        f"FLASK_ENV={os.getenv('FLASK_ENV')}"
                    )
                    print(error_msg)
                    raise ValueError(error_msg)
                
                # Development fallback
                print(f"⚠️  DATABASE_URL not set, using individual parameters (development mode)")
                print(f"   Connecting to: {config.Config.POSTGRES_HOST}:{config.Config.POSTGRES_PORT}/{config.Config.POSTGRES_DB}")
                g.db = psycopg2.connect(
                    host=config.Config.POSTGRES_HOST,
                    user=config.Config.POSTGRES_USER,
                    password=config.Config.POSTGRES_PASSWORD,
                    database=config.Config.POSTGRES_DB,
                    port=config.Config.POSTGRES_PORT,
                    cursor_factory=RealDictCursor
                )
                print("✅ Database connection successful (using individual parameters)")
            
            # PostgreSQL doesn't use autocommit by default, but we can set it
            g.db.autocommit = True
        except psycopg2.OperationalError as e:
            error_msg = f"❌ Database connection failed: {e}"
            print(error_msg)
            # Provide more helpful error message
            if "Connection refused" in str(e) or "localhost" in str(e):
                print("⚠️  HINT: Make sure DATABASE_URL is set in your environment variables.")
                print("   For Render.com, set DATABASE_URL in your service environment variables.")
            raise e
        except Exception as e:
            print(f"❌ Database connection failed: {e}")
            raise e
    return g.db

def close_db(e=None):
    db = g.pop('db', None)
    if db is not None:
        db.close()

def init_app(app):
    app.teardown_appcontext(close_db)