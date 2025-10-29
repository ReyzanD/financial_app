from flask import jsonify
from flask_jwt_extended import create_access_token, get_jwt_identity
from models.user_model import UserModel
from datetime import datetime

class AuthService:
    @staticmethod
    def login_user(email, password):
        user = UserModel.get_user_by_email(email)
        
        if not user:
            return None, "User not found"
        
        if not UserModel.verify_password(user['password_hash_232143'], password):
            return None, "Invalid password"
        
        # Update last login
        UserModel.update_user_profile(user['user_id_232143'], {
            'last_login_232143': datetime.now()
        })
        
        # Create access token
        access_token = create_access_token(identity=user['user_id_232143'])
        
        user_data = {
            'user_id': user['user_id_232143'],
            'email': user['email_232143'],
            'full_name': user['full_name_232143'],
            'phone_number': user['phone_number_232143'],
            'income_range': user['income_range_232143'],
        }
        
        return {
            'access_token': access_token,
            'user': user_data
        }, None

    @staticmethod
    def register_user(email, password, full_name, phone_number=None):
        # Check if user already exists
        existing_user = UserModel.get_user_by_email(email)
        if existing_user:
            return None, "User already exists"
        
        try:
            user_id = UserModel.create_user(email, password, full_name, phone_number)
            
            # Create default categories for the user
            AuthService._create_default_categories(user_id)
            
            return {
                'user_id': user_id,
                'email': email,
                'full_name': full_name
            }, None
            
        except Exception as e:
            return None, str(e)

    @staticmethod
    def _create_default_categories(user_id):
        from models.database import get_db
        
        default_categories = [
            # Income Categories
            ('Gaji', 'income', '#2ecc71', 'work'),
            ('Investasi', 'income', '#27ae60', 'trending_up'),
            ('Freelance', 'income', '#1abc9c', 'computer'),
            
            # Expense Categories
            ('Makanan & Minuman', 'expense', '#e74c3c', 'restaurant'),
            ('Transportasi', 'expense', '#f39c12', 'directions_car'),
            ('Belanja', 'expense', '#9b59b6', 'shopping_cart'),
            ('Hiburan', 'expense', '#34495e', 'movie'),
            ('Kesehatan', 'expense', '#e67e22', 'local_hospital'),
            ('Pendidikan', 'expense', '#2980b9', 'school'),
            ('Tabungan', 'expense', '#16a085', 'savings'),
            ('Tagihan & Utilitas', 'expense', '#95a5a6', 'receipt'),
        ]
        
        db = get_db()
        with db.cursor() as cursor:
            for name, type, color, icon in default_categories:
                category_id = str(uuid.uuid4())
                sql = """
                INSERT INTO categories_232143 (
                    category_id_232143, user_id_232143, name_232143, 
                    type_232143, color_232143, icon_232143, is_system_default_232143
                ) VALUES (%s, %s, %s, %s, %s, %s, %s)
                """
                cursor.execute(sql, (category_id, user_id, name, type, color, icon, True))
            
            db.commit()