from .database import get_db
import uuid
from datetime import datetime, timedelta
import json

class ObligationModel:
    @staticmethod
    def create_obligation(obligation_data):
        db = get_db()
        with db.cursor() as cursor:
            obligation_id = str(uuid.uuid4())
            
            sql = """
            INSERT INTO financial_obligations_232143 (
                obligation_id_232143, user_id_232143, name_232143, type_232143,
                category_232143, monthly_amount_232143, due_date_232143,
                original_amount_232143, current_balance_232143, interest_rate_232143,
                is_subscription_232143, subscription_cycle_232143,
                minimum_payment_232143, payoff_strategy_232143
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """
            
            cursor.execute(sql, (
                obligation_id,
                obligation_data['user_id'],
                obligation_data['name'],
                obligation_data['type'],
                obligation_data['category'],
                obligation_data['monthly_amount'],
                obligation_data.get('due_date'),
                obligation_data.get('original_amount'),
                obligation_data.get('current_balance'),
                obligation_data.get('interest_rate'),
                obligation_data.get('is_subscription', False),
                obligation_data.get('subscription_cycle'),
                obligation_data.get('minimum_payment'),
                obligation_data.get('payoff_strategy')
            ))
            db.commit()
            
            return obligation_id

    @staticmethod
    def get_user_obligations(user_id, obligation_type=None):
        db = get_db()
        with db.cursor() as cursor:
            sql = """
            SELECT * FROM financial_obligations_232143 
            WHERE user_id_232143 = %s AND status_232143 = 'active'
            """
            params = [user_id]
            
            if obligation_type:
                sql += " AND type_232143 = %s"
                params.append(obligation_type)
            
            sql += " ORDER BY due_date_232143 ASC"
            cursor.execute(sql, params)
            return cursor.fetchall()

    @staticmethod
    def get_upcoming_obligations(user_id, days=7):
        db = get_db()
        with db.cursor() as cursor:
            try:
                sql = """
                SELECT *,
                       DATEDIFF(
                           DATE_ADD(
                               CURDATE(),
                               INTERVAL (due_date_232143 - DAY(CURDATE())) DAY
                           ),
                           CURDATE()
                       ) as days_until_due
                FROM financial_obligations_232143 
                WHERE user_id_232143 = %s 
                AND status_232143 = 'active'
                AND due_date_232143 IS NOT NULL
                AND due_date_232143 BETWEEN 1 AND 31
                HAVING days_until_due BETWEEN 0 AND %s
                ORDER BY days_until_due ASC
                """
                cursor.execute(sql, (user_id, days))
                return cursor.fetchall()
            except Exception as e:
                print(f'Error in get_upcoming_obligations: {e}')
                # Return basic query without days calculation as fallback
                sql_fallback = """
                SELECT *
                FROM financial_obligations_232143 
                WHERE user_id_232143 = %s 
                AND status_232143 = 'active'
                AND due_date_232143 IS NOT NULL
                ORDER BY due_date_232143 ASC
                LIMIT 10
                """
                cursor.execute(sql_fallback, (user_id,))
                return cursor.fetchall()

    @staticmethod
    def record_payment(payment_data):
        db = get_db()
        with db.cursor() as cursor:
            payment_id = str(uuid.uuid4())
            
            sql = """
            INSERT INTO obligation_payments_232143 (
                payment_id_232143, obligation_id_232143, user_id_232143,
                amount_paid_232143, payment_date_232143, payment_method_232143,
                principal_paid_232143, interest_paid_232143
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            """
            
            cursor.execute(sql, (
                payment_id,
                payment_data['obligation_id'],
                payment_data['user_id'],
                payment_data['amount_paid'],
                payment_data['payment_date'],
                payment_data.get('payment_method'),
                payment_data.get('principal_paid'),
                payment_data.get('interest_paid')
            ))
            
            # Update debt balance if principal was paid
            if payment_data.get('principal_paid'):
                update_sql = """
                UPDATE financial_obligations_232143 
                SET current_balance_232143 = current_balance_232143 - %s
                WHERE obligation_id_232143 = %s
                """
                cursor.execute(update_sql, (payment_data['principal_paid'], payment_data['obligation_id']))
            
            db.commit()
            return payment_id

    @staticmethod
    def update_obligation(obligation_id, user_id, update_data):
        db = get_db()
        with db.cursor() as cursor:
            # Check if obligation exists and belongs to user
            check_sql = """
            SELECT obligation_id_232143 FROM financial_obligations_232143
            WHERE obligation_id_232143 = %s AND user_id_232143 = %s
            """
            cursor.execute(check_sql, (obligation_id, user_id))
            if not cursor.fetchone():
                return False

            # Build update query dynamically
            set_parts = []
            values = []
            for field, value in update_data.items():
                set_parts.append(f"{field} = %s")
                values.append(value)

            if not set_parts:
                return False

            sql = f"""
            UPDATE financial_obligations_232143
            SET {', '.join(set_parts)}
            WHERE obligation_id_232143 = %s AND user_id_232143 = %s
            """
            values.extend([obligation_id, user_id])

            cursor.execute(sql, values)
            db.commit()

            return cursor.rowcount > 0

    @staticmethod
    def delete_obligation(obligation_id, user_id):
        db = get_db()
        with db.cursor() as cursor:
            sql = """
            UPDATE financial_obligations_232143
            SET status_232143 = 'inactive'
            WHERE obligation_id_232143 = %s AND user_id_232143 = %s
            """
            cursor.execute(sql, (obligation_id, user_id))
            db.commit()

            return cursor.rowcount > 0
