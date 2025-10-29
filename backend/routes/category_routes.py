from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from models.category_model import CategoryModel

category_bp = Blueprint('categories', __name__)

@category_bp.route('', methods=['GET'])
@jwt_required()
def get_categories():
    try:
        user_id = get_jwt_identity()
        
        categories = CategoryModel.get_user_categories(user_id)
        
        return jsonify({
            'categories': categories,
            'count': len(categories)
        }), 200
        
    except Exception as e:
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