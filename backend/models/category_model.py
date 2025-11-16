from .database import get_db
import uuid
from datetime import datetime

class CategoryModel:
    @staticmethod
    def get_user_categories(user_id):
        db = get_db()
        with db.cursor() as cursor:
            sql = """
            SELECT * FROM categories_232143 
            WHERE user_id_232143 = %s
            ORDER BY type_232143, display_order_232143
            """
            cursor.execute(sql, (user_id,))
            return cursor.fetchall()

    @staticmethod
    def create_category(user_id, category_data):
        db = get_db()
        with db.cursor() as cursor:
            category_id = str(uuid.uuid4())
            
            sql = """
            INSERT INTO categories_232143 (
                category_id_232143, user_id_232143, name_232143, 
                type_232143, color_232143, icon_232143,
                budget_limit_232143, budget_period_232143
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            """
            
            cursor.execute(sql, (
                category_id,
                user_id,
                category_data['name'],
                category_data['type'],
                category_data.get('color', '#3498db'),
                category_data.get('icon', 'receipt'),
                category_data.get('budget_limit'),
                category_data.get('budget_period', 'monthly')
            ))
            db.commit()
            
            return category_id

    @staticmethod
    def create_default_categories(user_id):
        db = get_db()
        with db.cursor() as cursor:
            default_categories = [
                # Income Categories
                ('Gaji', 'income', '#2ecc71', 'work', 1),
                ('Investasi', 'income', '#27ae60', 'trending_up', 2),
                ('Freelance', 'income', '#1abc9c', 'computer', 3),
                
                # Expense Categories
                ('Makanan & Minuman', 'expense', '#e74c3c', 'restaurant', 1),
                ('Transportasi', 'expense', '#f39c12', 'directions_car', 2),
                ('Belanja', 'expense', '#9b59b6', 'shopping_cart', 3),
                ('Hiburan', 'expense', '#34495e', 'movie', 4),
                ('Kesehatan', 'expense', '#e67e22', 'local_hospital', 5),
                ('Pendidikan', 'expense', '#2980b9', 'school', 6),
                ('Tabungan', 'expense', '#16a085', 'savings', 7),
                ('Tagihan & Utilitas', 'expense', '#95a5a6', 'receipt', 8),
            ]
            
            for name, type, color, icon, order in default_categories:
                category_id = str(uuid.uuid4())
                sql = """
                INSERT INTO categories_232143 (
                    category_id_232143, user_id_232143, name_232143, 
                    type_232143, color_232143, icon_232143, 
                    display_order_232143, is_system_default_232143
                ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                """
                cursor.execute(sql, (category_id, user_id, name, type, color, icon, order, True))
            
            db.commit()