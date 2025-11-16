from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from models.category_model import CategoryModel
import uuid

category_bp = Blueprint('categories', __name__)

@category_bp.route('', methods=['GET'])
@jwt_required()
def get_categories():
    try:
        user_id = get_jwt_identity()
        print(f" Fetching categories for user: {user_id}")
        
        categories = CategoryModel.get_user_categories(user_id)
        print(f" Found {len(categories)} categories")
        
        if len(categories) == 0:
            print(f" WARNING: No categories found for user {user_id}!")
        
        return jsonify({
            'categories': categories,
            'count': len(categories)
        }), 200
        
    except Exception as e:
        print(f" Error in get_categories: {str(e)}")
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500

@category_bp.route('', methods=['POST'])
@jwt_required()
def create_category():
    try:
        user_id = get_jwt_identity()
        data = request.get_json()
        
        if not data or not data.get('name') or not data.get('type'):
            return jsonify({'error': 'Name and type are required'}), 400
        
        category_data = {
            'name': data['name'],
            'type': data['type'],
            'color': data.get('color', '#3498db'),
            'icon': data.get('icon', 'receipt'),
            'budget_limit': data.get('budget_limit'),
            'budget_period': data.get('budget_period', 'monthly')
        }
        
        category_id = CategoryModel.create_category(user_id, category_data)
        
        return jsonify({
            'message': 'Category created successfully',
            'category_id': category_id
        }), 201
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@category_bp.route('/setup-defaults', methods=['POST'])
@jwt_required()
def setup_default_categories():
    """Create default categories for users who don't have any"""
    try:
        user_id = get_jwt_identity()
        
        # Check if user already has categories
        existing = CategoryModel.get_user_categories(user_id)
        if existing:
            return jsonify({
                'message': 'You already have categories',
                'count': len(existing)
            }), 200
        
        # Create default categories
        CategoryModel.create_default_categories(user_id)
        
        return jsonify({
            'message': 'Default categories created successfully',
            'count': 11
        }), 201
        
    except Exception as e:
        print(f'Error creating default categories: {e}')
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500