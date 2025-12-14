from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity, create_access_token
from services.auth_service import AuthService
from models.user_model import UserModel
from utils.encoding_utils import safe_str

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
        return jsonify({'error': safe_str(e)}), 500

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
        return jsonify({'error': safe_str(e)}), 500

@auth_bp.route('/profile', methods=['GET'])
@jwt_required()
def get_profile():
    try:
        user_id = get_jwt_identity()
        
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
        }
        
        return jsonify({'user': user_data}), 200
        
    except Exception as e:
        return jsonify({'error': safe_str(e)}), 500

@auth_bp.route('/profile', methods=['PUT'])
@jwt_required()
def update_profile():
    try:
        user_id = get_jwt_identity()
        data = request.get_json()
        
        if not data:
            return jsonify({'error': 'No data provided'}), 400
        
        update_data = {}
        field_mapping = {
            'full_name': 'full_name_232143',
            'phone_number': 'phone_number_232143',
            'income_range': 'income_range_232143',
            'family_size': 'family_size_232143',
            'base_location': 'base_location_232143',
        }
        
        for frontend_field, backend_field in field_mapping.items():
            if frontend_field in data:
                update_data[backend_field] = data[frontend_field]
        
        if not update_data:
            return jsonify({'error': 'No valid fields to update'}), 400
        
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
        return jsonify({'error': safe_str(e)}), 500

@auth_bp.route('/account', methods=['DELETE'])
@jwt_required()
def delete_account():
    """Delete the currently authenticated user's account and all related data."""
    try:
        user_id = get_jwt_identity()

        user = UserModel.get_user_by_id(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404

        success = UserModel.delete_user(user_id)
        if not success:
            return jsonify({'error': 'Failed to delete account'}), 400

        # Related data is removed via ON DELETE CASCADE constraints in the database
        return jsonify({'message': 'Account and all related data deleted successfully'}), 200

    except Exception as e:
        return jsonify({'error': safe_str(e)}), 500