from .database import get_db
import uuid
from datetime import datetime, date, timedelta
from decimal import Decimal
import json
import time

class BudgetModel:
    @staticmethod
    def get_user_budgets(user_id, active_only=True):
        """Get all budgets for a user"""
        # #region agent log
        try:
            with open(r'd:\CODE\Project\FinancialApp\financial_app\.cursor\debug.log', 'a', encoding='utf-8') as f:
                f.write(json.dumps({"id":f"log_{int(time.time()*1000)}_get_budgets_start","timestamp":int(time.time()*1000),"location":"budget_model.py:8","message":"get_user_budgets called","data":{"user_id":user_id,"active_only":active_only},"sessionId":"debug-session","runId":"run1","hypothesisId":"A"}) + "\n")
        except: pass
        # #endregion
        db = get_db()
        with db.cursor() as cursor:
            if active_only:
                sql = """
                SELECT 
                    budget_id_232143,
                    user_id_232143,
                    category_id_232143,
                    amount_232143,
                    period_232143,
                    period_start_232143,
                    period_end_232143,
                    spent_amount_232143,
                    remaining_amount_232143,
                    rollover_enabled_232143,
                    alert_threshold_232143,
                    is_active_232143,
                    recommended_amount_232143,
                    recommendation_reason_232143,
                    created_at_232143,
                    updated_at_232143
                FROM budgets_232143 
                WHERE user_id_232143 = %s AND is_active_232143 = TRUE
                ORDER BY period_start_232143 DESC
                """
            else:
                sql = """
                SELECT 
                    budget_id_232143,
                    user_id_232143,
                    category_id_232143,
                    amount_232143,
                    period_232143,
                    period_start_232143,
                    period_end_232143,
                    spent_amount_232143,
                    remaining_amount_232143,
                    rollover_enabled_232143,
                    alert_threshold_232143,
                    is_active_232143,
                    recommended_amount_232143,
                    recommendation_reason_232143,
                    created_at_232143,
                    updated_at_232143
                FROM budgets_232143 
                WHERE user_id_232143 = %s
                ORDER BY period_start_232143 DESC
                """
            # #region agent log
            try:
                with open(r'd:\CODE\Project\FinancialApp\financial_app\.cursor\debug.log', 'a', encoding='utf-8') as f:
                    f.write(json.dumps({"id":f"log_{int(time.time()*1000)}_before_execute","timestamp":int(time.time()*1000),"location":"budget_model.py:58","message":"Before executing SQL query","data":{"active_only":active_only,"sql_has_true":"TRUE" in sql},"sessionId":"debug-session","runId":"run1","hypothesisId":"A"}) + "\n")
            except: pass
            # #endregion
            cursor.execute(sql, (user_id,))
            # #region agent log
            try:
                results = cursor.fetchall()
                with open(r'd:\CODE\Project\FinancialApp\financial_app\.cursor\debug.log', 'a', encoding='utf-8') as f:
                    f.write(json.dumps({"id":f"log_{int(time.time()*1000)}_after_execute","timestamp":int(time.time()*1000),"location":"budget_model.py:60","message":"After executing SQL query","data":{"result_count":len(results)},"sessionId":"debug-session","runId":"run1","hypothesisId":"A"}) + "\n")
            except: pass
            # #endregion
            return results
    
    @staticmethod
    def get_budget_by_id(budget_id, user_id):
        """Get a specific budget by ID"""
        db = get_db()
        with db.cursor() as cursor:
            sql = """
            SELECT 
                budget_id_232143,
                user_id_232143,
                category_id_232143,
                amount_232143,
                period_232143,
                period_start_232143,
                period_end_232143,
                spent_amount_232143,
                remaining_amount_232143,
                rollover_enabled_232143,
                alert_threshold_232143,
                is_active_232143,
                recommended_amount_232143,
                recommendation_reason_232143,
                created_at_232143,
                updated_at_232143
            FROM budgets_232143 
            WHERE budget_id_232143 = %s AND user_id_232143 = %s
            """
            cursor.execute(sql, (budget_id, user_id))
            return cursor.fetchone()
    
    @staticmethod
    def create_budget(budget_data):
        """Create a new budget"""
        db = get_db()
        with db.cursor() as cursor:
            budget_id = str(uuid.uuid4())
            
            # Calculate period dates if not provided
            period = budget_data['period']
            start_date = budget_data.get('period_start')
            
            if start_date is None:
                start_date = date.today()
            elif isinstance(start_date, str):
                start_date = datetime.strptime(start_date, '%Y-%m-%d').date()
            
            # Calculate end date based on period
            if period == 'daily':
                end_date = start_date
            elif period == 'weekly':
                end_date = start_date + timedelta(days=6)
            elif period == 'monthly':
                # Get last day of month
                if start_date.month == 12:
                    end_date = date(start_date.year + 1, 1, 1) - timedelta(days=1)
                else:
                    end_date = date(start_date.year, start_date.month + 1, 1) - timedelta(days=1)
            elif period == 'yearly':
                end_date = date(start_date.year, 12, 31)
            else:
                end_date = start_date + timedelta(days=30)
            
            sql = """
            INSERT INTO budgets_232143 (
                budget_id_232143,
                user_id_232143,
                category_id_232143,
                amount_232143,
                period_232143,
                period_start_232143,
                period_end_232143,
                rollover_enabled_232143,
                alert_threshold_232143,
                is_active_232143
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """
            
            cursor.execute(sql, (
                budget_id,
                budget_data['user_id'],
                budget_data.get('category_id'),
                budget_data['amount'],
                period,
                start_date,
                end_date,
                budget_data.get('rollover_enabled', False),
                budget_data.get('alert_threshold', 80),
                budget_data.get('is_active', True)
            ))
            db.commit()
            return budget_id
    
    @staticmethod
    def update_budget(budget_id, user_id, update_data):
        """Update an existing budget"""
        db = get_db()
        with db.cursor() as cursor:
            set_clauses = []
            values = []
            
            for field, value in update_data.items():
                set_clauses.append(f"{field} = %s")
                values.append(value)
            
            if not set_clauses:
                return False
            
            values.extend([budget_id, user_id])
            
            sql = f"""
            UPDATE budgets_232143
            SET {', '.join(set_clauses)}
            WHERE budget_id_232143 = %s AND user_id_232143 = %s
            """
            
            cursor.execute(sql, values)
            db.commit()
            return cursor.rowcount > 0
    
    @staticmethod
    def delete_budget(budget_id, user_id):
        """Delete a budget"""
        db = get_db()
        with db.cursor() as cursor:
            sql = """
            DELETE FROM budgets_232143
            WHERE budget_id_232143 = %s AND user_id_232143 = %s
            """
            cursor.execute(sql, (budget_id, user_id))
            db.commit()
            return cursor.rowcount > 0
    
    @staticmethod
    def get_budgets_summary(user_id):
        """Get summary statistics for user's budgets"""
        db = get_db()
        with db.cursor() as cursor:
            sql = """
            SELECT 
                COUNT(*) as total_budgets,
                SUM(amount_232143) as total_budget,
                SUM(spent_amount_232143) as total_spent,
                SUM(remaining_amount_232143) as total_remaining,
                AVG(CASE WHEN amount_232143 > 0 
                    THEN (spent_amount_232143 / amount_232143) * 100 
                    ELSE 0 END) as avg_usage_percentage
            FROM budgets_232143
            WHERE user_id_232143 = %s AND is_active_232143 = TRUE
            """
            cursor.execute(sql, (user_id,))
            return cursor.fetchone()