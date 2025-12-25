from .database import get_db
import bcrypt
import uuid
from datetime import datetime
import json

class UserModel:
    @staticmethod
    def create_user(cursor, email, password, full_name, phone_number=None):
        password_hash = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
        
        sql = """
        INSERT INTO users_232143 (
            email_232143, password_hash_232143, 
            full_name_232143, phone_number_232143, created_at_232143
        ) VALUES (%s, %s, %s, %s, %s)
        """
        
        cursor.execute(sql, (email, password_hash, full_name, phone_number, datetime.now()))

    @staticmethod
    def get_user_by_email(email):
        db = get_db()
        with db.cursor() as cursor:
            sql = "SELECT * FROM users_232143 WHERE email_232143 = %s"
            cursor.execute(sql, (email,))
            return cursor.fetchone()

    @staticmethod
    def get_user_by_id(user_id):
        db = get_db()
        with db.cursor() as cursor:
            sql = "SELECT * FROM users_232143 WHERE user_id_232143 = %s"
            cursor.execute(sql, (user_id,))
            return cursor.fetchone()

    @staticmethod
    def verify_password(stored_hash, password):
        try:
            return bcrypt.checkpw(password.encode('utf-8'), stored_hash.encode('utf-8'))
        except Exception:
            return False

    @staticmethod
    def update_user_profile(user_id, update_data):
        import json
        import time
        # #region agent log
        try:
            with open(r'd:\CODE\Project\FinancialApp\financial_app\.cursor\debug.log', 'a', encoding='utf-8') as f:
                f.write(json.dumps({"id":f"log_{int(time.time()*1000)}_update_start","timestamp":int(time.time()*1000),"location":"user_model.py:45","message":"update_user_profile called","data":{"user_id":user_id,"has_update_data":bool(update_data)},"sessionId":"debug-session","runId":"run1","hypothesisId":"D"}) + "\n")
        except: pass
        # #endregion
        db = get_db()
        # #region agent log
        try:
            with open(r'd:\CODE\Project\FinancialApp\financial_app\.cursor\debug.log', 'a', encoding='utf-8') as f:
                f.write(json.dumps({"id":f"log_{int(time.time()*1000)}_update_db_state","timestamp":int(time.time()*1000),"location":"user_model.py:47","message":"DB state in update_user_profile","data":{"autocommit":getattr(db,'autocommit',None)},"sessionId":"debug-session","runId":"run1","hypothesisId":"D"}) + "\n")
        except: pass
        # #endregion
        with db.cursor() as cursor:
            if not update_data:
                return False
                
            set_clause = ", ".join([f"{key} = %s" for key in update_data.keys()])
            sql = f"UPDATE users_232143 SET {set_clause}, updated_at_232143 = %s WHERE user_id_232143 = %s"
            
            values = list(update_data.values())
            values.extend([datetime.now(), user_id])
            
            # #region agent log
            try:
                with open(r'd:\CODE\Project\FinancialApp\financial_app\.cursor\debug.log', 'a', encoding='utf-8') as f:
                    f.write(json.dumps({"id":f"log_{int(time.time()*1000)}_before_execute","timestamp":int(time.time()*1000),"location":"user_model.py:57","message":"Before execute UPDATE","data":{"autocommit":getattr(db,'autocommit',None)},"sessionId":"debug-session","runId":"run1","hypothesisId":"D"}) + "\n")
            except: pass
            # #endregion
            cursor.execute(sql, values)
            # #region agent log
            try:
                with open(r'd:\CODE\Project\FinancialApp\financial_app\.cursor\debug.log', 'a', encoding='utf-8') as f:
                    f.write(json.dumps({"id":f"log_{int(time.time()*1000)}_before_commit","timestamp":int(time.time()*1000),"location":"user_model.py:58","message":"Before db.commit()","data":{"autocommit":getattr(db,'autocommit',None)},"sessionId":"debug-session","runId":"run1","hypothesisId":"D"}) + "\n")
            except: pass
            # #endregion
            db.commit()
            # #region agent log
            try:
                with open(r'd:\CODE\Project\FinancialApp\financial_app\.cursor\debug.log', 'a', encoding='utf-8') as f:
                    f.write(json.dumps({"id":f"log_{int(time.time()*1000)}_after_commit","timestamp":int(time.time()*1000),"location":"user_model.py:59","message":"After db.commit()","data":{"rowcount":cursor.rowcount},"sessionId":"debug-session","runId":"run1","hypothesisId":"D"}) + "\n")
            except: pass
            # #endregion
            
            return cursor.rowcount > 0

    @staticmethod
    def delete_user(user_id):
        db = get_db()
        with db.cursor() as cursor:
            sql = "DELETE FROM users_232143 WHERE user_id_232143 = %s"
            cursor.execute(sql, (user_id,))
            db.commit()
            return cursor.rowcount > 0