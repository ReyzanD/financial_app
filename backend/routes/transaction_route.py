from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from models.transaction_model import TransactionModel
from datetime import datetime

transaction_bp = Blueprint('transactions', __name__)

@transaction_bp.route('', methods=['GET'])
@jwt_required()
def get_transactions():
    try:
        user_id = get_jwt_identity()
        
        filters = {}
        
        # Filter by type
        if request.args.get('type'):
            filters['type'] = request.args.get('type')
        
        # Filter by date range
        if request.args.get('start_date'):
            filters['start_date'] = request.args.get('start_date')
        if request.args.get('end_date'):
            filters['end_date'] = request.args.get('end_date')
        
        # Filter by category
        if request.args.get('category_id'):
            filters['category_id'] = request.args.get('category_id')
        
        transactions = TransactionModel.get_user_transactions(user_id, filters)
        
        return jsonify({
            'transactions': transactions,
            'count': len(transactions)
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@transaction_bp.route('', methods=['POST'])
@jwt_required()
def create_transaction():
    try:
        user_id = get_jwt_identity()
        data = request.get_json()
        
        # Validate required fields
        required_fields = ['amount', 'type', 'description']
        for field in required_fields:
            if field not in data:
                return jsonify({'error': f'{field} is required'}), 400
        
        transaction_data = {
            'user_id': user_id,
            'amount': float(data['amount']),
            'type': data['type'],
            'description': data['description'],
            'category_id': data.get('category_id'),
            'location_data': data.get('location_data'),
            'payment_method': data.get('payment_method', 'cash'),
            'transaction_date': data.get('transaction_date', datetime.now().date().isoformat())
        }
        
        transaction_id = TransactionModel.create_transaction(transaction_data)
        
        return jsonify({
            'message': 'Transaction created successfully',
            'transaction_id': transaction_id
        }), 201
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@transaction_bp.route('/<transaction_id>', methods=['GET'])
@jwt_required()
def get_transaction(transaction_id):
    try:
        user_id = get_jwt_identity()
        
        transaction = TransactionModel.get_transaction_by_id(transaction_id, user_id)
        if not transaction:
            return jsonify({'error': 'Transaction not found'}), 404
        
        return jsonify({'transaction': transaction}), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@transaction_bp.route('/<transaction_id>', methods=['PUT'])
@jwt_required()
def update_transaction(transaction_id):
    try:
        user_id = get_jwt_identity()
        data = request.get_json()
        
        if not data:
            return jsonify({'error': 'No data provided'}), 400
        
        update_data = {}
        field_mapping = {
            'amount': 'amount_232143',
            'type': 'type_232143',
            'category_id': 'category_id_232143',
            'description': 'description_232143',
            'payment_method': 'payment_method_232143',
        }
        
        for frontend_field, backend_field in field_mapping.items():
            if frontend_field in data:
                update_data[backend_field] = data[frontend_field]
        
        if not update_data:
            return jsonify({'error': 'No valid fields to update'}), 400
        
        success = TransactionModel.update_transaction(transaction_id, user_id, update_data)
        
        if not success:
            return jsonify({'error': 'Transaction not found or update failed'}), 404
        
        return jsonify({'message': 'Transaction updated successfully'}), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@transaction_bp.route('/<transaction_id>', methods=['DELETE'])
@jwt_required()
def delete_transaction(transaction_id):
    try:
        user_id = get_jwt_identity()
        
        success = TransactionModel.delete_transaction(transaction_id, user_id)
        
        if not success:
            return jsonify({'error': 'Transaction not found'}), 404
        
        return jsonify({'message': 'Transaction deleted successfully'}), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@transaction_bp.route('/analytics/summary', methods=['GET'])
@jwt_required()
def get_monthly_summary():
    try:
        user_id = get_jwt_identity()
        
        year = request.args.get('year', datetime.now().year, type=int)
        month = request.args.get('month', datetime.now().month, type=int)
        
        summary = TransactionModel.get_monthly_summary(user_id, year, month)
        
        return jsonify({
            'year': year,
            'month': month,
            'summary': summary
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@transaction_bp.route('/analytics/categories', methods=['GET'])
@jwt_required()
def get_category_spending():
    try:
        user_id = get_jwt_identity()
        
        start_date = request.args.get('start_date', datetime.now().replace(day=1).date().isoformat())
        end_date = request.args.get('end_date', datetime.now().date().isoformat())
        
        category_spending = TransactionModel.get_category_spending(user_id, start_date, end_date)
        
        return jsonify({
            'start_date': start_date,
            'end_date': end_date,
            'category_spending': category_spending
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@transaction_bp.route('/recent', methods=['GET'])
@jwt_required()
def get_recent_transactions():
    try:
        user_id = get_jwt_identity()
        limit = request.args.get('limit', 10, type=int)
        
        transactions = TransactionModel.get_recent_transactions(user_id, limit)
        
        return jsonify({
            'transactions': transactions,
            'count': len(transactions)
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500