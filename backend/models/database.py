import psycopg2
import psycopg2.extras
from flask import g
import config

def get_db():
    if 'db' not in g:
        try:
            g.db = psycopg2.connect(
                host=config.Config.DB_HOST,
                user=config.Config.DB_USER,
                password=config.Config.DB_PASSWORD,
                database=config.Config.DB_NAME,
                port=config.Config.DB_PORT
            )
            g.db.autocommit = True
            print("✅ Database connection successful")
        except Exception as e:
            print(f"❌ Database connection failed: {e}")
            raise e
    return g.db

def get_cursor():
    """Get a cursor that returns results as dictionaries"""
    db = get_db()
    return db.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

def close_db(e=None):
    db = g.pop('db', None)
    if db is not None:
        db.close()

def init_app(app):
    app.teardown_appcontext(close_db)