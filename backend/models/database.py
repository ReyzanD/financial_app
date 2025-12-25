import psycopg2
from psycopg2.extras import RealDictCursor
from flask import g
import config
import os

def get_db():
    if 'db' not in g:
        try:
            # Prefer DATABASE_URL (Supabase/Render connection string) if available
            # Check both from config and directly from env to ensure we catch it
            database_url = config.Config.DATABASE_URL or os.getenv('DATABASE_URL')
            
            if database_url and database_url.strip():
                # Use connection string (production/preferred method)
                print(f"🔗 Connecting to database using DATABASE_URL...")
                try:
                    g.db = psycopg2.connect(
                        database_url,
                        cursor_factory=RealDictCursor
                    )
                except psycopg2.OperationalError as conn_error:
                    raise
                print("✅ Database connection successful (using DATABASE_URL)")
            else:
                # Fallback to individual parameters (development only)
                # In production, this should not happen - DATABASE_URL should be set
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
            elif "Network is unreachable" in str(e) or "unreachable" in str(e).lower():
                print("⚠️  HINT: Network connectivity issue detected.")
                print("   For Supabase, try using Connection Pooling instead of direct connection:")
                print("   1. Go to Supabase Dashboard → Project Settings → Database")
                print("   2. Select 'Connection pooling' tab (not 'URI')")
                print("   3. Copy the connection string (port 6543, not 5432)")
                print("   4. Update DATABASE_URL in Render with the pooling URL")
                print("   Connection pooling is more reliable for production environments.")
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