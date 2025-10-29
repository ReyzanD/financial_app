import pymysql
from flask import g
import config

def get_db():
    if 'db' not in g:
        g.db = pymysql.connect(
            host=config.Config.MYSQL_HOST,
            user=config.Config.MYSQL_USER,
            password=config.Config.MYSQL_PASSWORD,
            database=config.Config.MYSQL_DB,
            port=config.Config.MYSQL_PORT,
            charset='utf8mb4',
            cursorclass=pymysql.cursors.DictCursor
        )
    return g.db

def close_db(e=None):
    db = g.pop('db', None)
    if db is not None:
        db.close()

def init_app(app):
    app.teardown_appcontext(close_db)