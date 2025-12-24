from .database import get_db
import uuid
from datetime import datetime, timedelta
import json

class TransactionModel:
    @staticmethod
    def create_transaction(transaction_data):
        db = get_db()
        with db.cursor() as cursor:
            transaction_id = str(uuid.uuid4())
            
            sql = """
            INSERT INTO transactions_232143 (
                transaction_id_232143, user_id_232143, amount_232143, 
                type_232143, category_id_232143, description_232143,
                location_name_232143, latitude_232143, longitude_232143,
                location_data_232143, payment_method_232143, 
                transaction_date_232143, created_at_232143
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """
            
            # Extract location fields from transaction data
            location_data = None
            location_name = None
            latitude = None
            longitude = None
            
            if transaction_data.get('location_data'):
                loc_data = transaction_data['location_data']
                location_data = json.dumps(loc_data)
                # Extract individual fields from location_data for querying
                location_name = loc_data.get('place_name') or loc_data.get('address')
                latitude = loc_data.get('latitude')
                longitude = loc_data.get('longitude')
            
            cursor.execute(sql, (
                transaction_id,
                transaction_data['user_id'],
                transaction_data['amount'],
                transaction_data['type'],
                transaction_data.get('category_id'),
                transaction_data['description'],
                location_name,
                latitude,
                longitude,
                location_data,
                transaction_data.get('payment_method', 'cash'),
                transaction_data.get('transaction_date', datetime.now().date()),
                datetime.now()
            ))
            db.commit()
            
            return transaction_id

    @staticmethod
    def get_user_transactions(user_id, filters=None):
        db = get_db()
        with db.cursor() as cursor:
            sql = """
            SELECT 
                t.*,
                t.location_name_232143 as location_name,
                t.latitude_232143 as latitude,
                t.longitude_232143 as longitude,
                COALESCE(c.name_232143, 'Uncategorized') as category_name,
                COALESCE(c.color_232143, '#808080') as category_color
            FROM transactions_232143 t
            LEFT JOIN categories_232143 c ON t.category_id_232143 = c.category_id_232143
            WHERE t.user_id_232143 = %s
            """
            params = [user_id]
            
            if filters:
                if filters.get('type'):
                    sql += " AND t.type_232143 = %s"
                    params.append(filters['type'])
                
                if filters.get('start_date'):
                    sql += " AND t.transaction_date_232143 >= %s"
                    params.append(filters['start_date'])
                
                if filters.get('end_date'):
                    sql += " AND t.transaction_date_232143 <= %s"
                    params.append(filters['end_date'])
                
                if filters.get('category_id'):
                    sql += " AND t.category_id_232143 = %s"
                    params.append(filters['category_id'])
                
                # Filter by amount range
                if filters.get('min_amount') is not None:
                    sql += " AND t.amount_232143 >= %s"
                    params.append(filters['min_amount'])
                
                if filters.get('max_amount') is not None:
                    sql += " AND t.amount_232143 <= %s"
                    params.append(filters['max_amount'])
                
                # Search by description text
                if filters.get('search'):
                    sql += " AND t.description_232143 LIKE %s"
                    params.append(f"%{filters['search']}%")
            
            sql += " ORDER BY t.transaction_date_232143 DESC, t.created_at_232143 DESC"
            
            # Add pagination support
            if filters and filters.get('limit') is not None:
                limit = int(filters.get('limit', 10))
                offset = int(filters.get('offset', 0))
                sql += " LIMIT %s OFFSET %s"
                params.extend([limit, offset])
            
            cursor.execute(sql, params)
            return cursor.fetchall()

    @staticmethod
    def get_transaction_by_id(transaction_id, user_id):
        db = get_db()
        with db.cursor() as cursor:
            sql = """
            SELECT 
                t.*,
                COALESCE(c.name_232143, 'Uncategorized') as category_name,
                COALESCE(c.color_232143, '#808080') as category_color
            FROM transactions_232143 t
            LEFT JOIN categories_232143 c ON t.category_id_232143 = c.category_id_232143
            WHERE t.transaction_id_232143 = %s AND t.user_id_232143 = %s
            """
            cursor.execute(sql, (transaction_id, user_id))
            return cursor.fetchone()

    @staticmethod
    def update_transaction(transaction_id, user_id, update_data):
        db = get_db()
        with db.cursor() as cursor:
            if not update_data:
                return False
                
            set_clause = ", ".join([f"{key} = %s" for key in update_data.keys()])
            sql = f"""
            UPDATE transactions_232143 
            SET {set_clause}, updated_at_232143 = %s
            WHERE transaction_id_232143 = %s AND user_id_232143 = %s
            """
            
            values = list(update_data.values())
            values.extend([datetime.now(), transaction_id, user_id])
            
            cursor.execute(sql, values)
            db.commit()
            
            return cursor.rowcount > 0

    @staticmethod
    def delete_transaction(transaction_id, user_id):
        db = get_db()
        with db.cursor() as cursor:
            sql = """
            DELETE FROM transactions_232143 
            WHERE transaction_id_232143 = %s AND user_id_232143 = %s
            """
            cursor.execute(sql, (transaction_id, user_id))
            db.commit()
            
            return cursor.rowcount > 0

    @staticmethod
    def get_monthly_summary(user_id, year, month):
        from calendar import monthrange
        db = get_db()
        with db.cursor() as cursor:
            # Get the correct last day of the month
            last_day_num = monthrange(year, month)[1]
            first_day = f"{year}-{month:02d}-01"
            last_day = f"{year}-{month:02d}-{last_day_num}"
            
            sql = """
            SELECT 
                type_232143,
                SUM(amount_232143) as total_amount,
                COUNT(*) as transaction_count
            FROM transactions_232143 
            WHERE user_id_232143 = %s 
                AND DATE(transaction_date_232143) BETWEEN %s AND %s
            GROUP BY type_232143
            """
            cursor.execute(sql, (user_id, first_day, last_day))
            return cursor.fetchall()

    @staticmethod
    def get_category_spending(user_id, start_date, end_date):
        db = get_db()
        with db.cursor() as cursor:
            sql = """
            SELECT 
                c.name_232143 as category_name,
                c.color_232143 as category_color,
                SUM(t.amount_232143) as total_amount,
                COUNT(*) as transaction_count
            FROM transactions_232143 t
            JOIN categories_232143 c ON t.category_id_232143 = c.category_id_232143
            WHERE t.user_id_232143 = %s 
                AND t.type_232143 = 'expense'
                AND t.transaction_date_232143 BETWEEN %s AND %s
            GROUP BY c.category_id_232143, c.name_232143, c.color_232143
            ORDER BY total_amount DESC
            """
            cursor.execute(sql, (user_id, start_date, end_date))
            return cursor.fetchall()

    @staticmethod
    def get_recent_transactions(user_id, limit=10):
        db = get_db()
        with db.cursor() as cursor:
            sql = """
            SELECT 
                t.*,
                t.location_name_232143 as location_name,
                t.latitude_232143 as latitude,
                t.longitude_232143 as longitude,
                COALESCE(c.name_232143, 'Uncategorized') as category_name,
                COALESCE(c.color_232143, '#808080') as category_color
            FROM transactions_232143 t
            LEFT JOIN categories_232143 c ON t.category_id_232143 = c.category_id_232143
            WHERE t.user_id_232143 = %s
            ORDER BY t.transaction_date_232143 DESC, t.created_at_232143 DESC
            LIMIT %s
            """
            cursor.execute(sql, (user_id, limit))
            return cursor.fetchall()