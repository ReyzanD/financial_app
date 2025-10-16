from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from services.auth_service import AuthService

auth_bp = Blueprint('auth', __name__)

@auth_bp.route('/register', methods=['POST'])
def register():
    try:
        data = request.get_json()
        
        if not data or not data.get('email') or not data.get('password'):
            return jsonify({'error': 'Email and password are required'}), 400
        
        result, error = AuthService.register_user(
            email=data['email'],
            password=data['password'],
            full_name=data.get('full_name', ''),
            phone_number=data.get('phone_number')
        )
        
        if error:
            return jsonify({'error': error}), 400
        
        return jsonify({
            'message': 'User registered successfully',
            'user': result
        }), 201
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@auth_bp.route('/login', methods=['POST'])
def login():
    try:
        data = request.get_json()
        
        if not data or not data.get('email') or not data.get('password'):
            return jsonify({'error': 'Email and password are required'}), 400
        
        result, error = AuthService.login_user(data['email'], data['password'])
        
        if error:
            return jsonify({'error': error}), 401
        
        return jsonify(result), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@auth_bp.route('/profile', methods=['GET'])
@jwt_required()
def get_profile():
    try:
        user_id = get_jwt_identity()
        from models.user_model import UserModel
        
        user = UserModel.get_user_by_id(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        user_data = {
            'user_id': user['user_id_232143'],
            'email': user['email_232143'],
            'full_name': user['full_name_232143'],
            'phone_number': user['phone_number_232143'],
            'income_range': user['income_range_232143'],
            'family_size': user['family_size_232143'],
            'base_location': user['base_location_232143'],
            'financial_goals': user['financial_goals_232143'],
        }
        
        return jsonify({'user': user_data}), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@auth_bp.route('/profile', methods=['PUT'])
@jwt_required()
def update_profile():
    try:
        user_id = get_jwt_identity()
        data = request.get_json()
        
        from models.user_model import UserModel
        
        update_data = {}
        allowed_fields = [
            'full_name_232143', 'phone_number_232143', 'income_range_232143',
            'family_size_232143', 'base_location_232143', 'financial_goals_232143'
        ]
        
        for field in allowed_fields:
            if field.replace('_232143', '') in data:
                update_data[field] = data[field.replace('_232143', '')]
        
        if update_data:
            success = UserModel.update_user_profile(user_id, update_data)
            if not success:
                return jsonify({'error': 'Failed to update profile'}), 400
        
        user = UserModel.get_user_by_id(user_id)
        user_data = {
            'user_id': user['user_id_232143'],
            'email': user['email_232143'],
            'full_name': user['full_name_232143'],
            'phone_number': user['phone_number_232143'],
            'income_range': user['income_range_232143'],
            'family_size': user['family_size_232143'],
        }
        
        return jsonify({
            'message': 'Profile updated successfully',
            'user': user_data
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500