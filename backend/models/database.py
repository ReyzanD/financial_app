import psycopg2
from psycopg2.extras import RealDictCursor
from flask import g
import config

def get_db():
    if 'db' not in g:
        try:
            # Prefer DATABASE_URL (Supabase connection string) if available
            if config.Config.DATABASE_URL:
                g.db = psycopg2.connect(
                    config.Config.DATABASE_URL,
                    cursor_factory=RealDictCursor
                )
            else:
                # Fallback to individual parameters
                g.db = psycopg2.connect(
                    host=config.Config.POSTGRES_HOST,
                    user=config.Config.POSTGRES_USER,
                    password=config.Config.POSTGRES_PASSWORD,
                    database=config.Config.POSTGRES_DB,
                    port=config.Config.POSTGRES_PORT,
                    cursor_factory=RealDictCursor
                )
            # PostgreSQL doesn't use autocommit by default, but we can set it
            g.db.autocommit = True
            print("✅ Database connection successful")
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