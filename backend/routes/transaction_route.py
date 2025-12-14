from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from models.transaction_model import TransactionModel
from services.recommendation_service import RecommendationService
from datetime import datetime
from utils.encoding_utils import safe_print, safe_str
import json

transaction_bp = Blueprint('transactions_232143', __name__)

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

        # Filter by amount range
        if request.args.get('min_amount') is not None:
            filters['min_amount'] = request.args.get('min_amount', type=float)

        if request.args.get('max_amount') is not None:
            filters['max_amount'] = request.args.get('max_amount', type=float)

        # Search by description text
        if request.args.get('search'):
            filters['search'] = request.args.get('search')
        
        transactions = TransactionModel.get_user_transactions(user_id, filters)
        
        # Transform the data to match frontend expectations
        formatted_transactions = []
        for t in transactions:
            # Debug: Print first transaction to see structure
            if len(formatted_transactions) == 0:
                safe_print(f"Sample transaction from DB:")
                safe_print(f"  location_name: {t.get('location_name')}")
                safe_print(f"  latitude: {t.get('latitude')}")
                safe_print(f"  longitude: {t.get('longitude')}")
                safe_print(f"  location_data_232143: {t.get('location_data_232143')}")

            # Parse location data if it exists (return full object for map display)
            location_obj = None
            if t['location_data_232143']:
                try:
                    location_data = json.loads(t['location_data_232143'])
                    location_obj = {
                        'address': location_data.get('address'),
                        'latitude': location_data.get('latitude'),
                        'longitude': location_data.get('longitude'),
                        'place_name': location_data.get('place_name')
                    }
                except:
                    location_obj = None

            formatted_transaction = {
                'id': t['transaction_id_232143'],
                'amount': float(t['amount_232143']),
                'type': t['type_232143'],
                'description': t['description_232143'],
                'category': t['category_name'],
                'category_name': t['category_name'],  # Add category_name for frontend compatibility
                'category_id': t['category_id_232143'],
                'category_color': t['category_color'],
                'payment_method': t['payment_method_232143'],
                'date': t['transaction_date_232143'].isoformat() if t['transaction_date_232143'] else None,
                'created_at': t['created_at_232143'].isoformat() if t['created_at_232143'] else None,
                'location': location_obj,
                # Include individual location fields for location intelligence
                'location_name_232143': t.get('location_name'),
                'latitude_232143': float(t['latitude']) if t.get('latitude') else None,
                'longitude_232143': float(t['longitude']) if t.get('longitude') else None,
                'amount_232143': float(t['amount_232143']),
                'type_232143': t['type_232143'],
                'notes_232143': t.get('description_232143'),
                'transaction_date_232143': t['transaction_date_232143'].isoformat() if t['transaction_date_232143'] else None
            }
            formatted_transactions.append(formatted_transaction)
        
        return jsonify({
            'transactions': formatted_transactions,
            'count': len(formatted_transactions)
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@transaction_bp.route('', methods=['POST'])
@jwt_required()
def create_transaction():
    try:
        user_id = get_jwt_identity()
        data = request.get_json()
        
        safe_print(f"Creating transaction for user: {user_id}")
        safe_print(f"Request data: {data}")
        
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
        
        safe_print(f"Transaction data to save: {transaction_data}")
        safe_print(f"Category ID: {transaction_data['category_id']}")
        
        transaction_id = TransactionModel.create_transaction(transaction_data)
        
        safe_print(f"Transaction created with ID: {transaction_id}")
        
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
        
        # Transform the data to match frontend expectations
        # Parse location data if it exists
        location_address = None
        if transaction['location_data_232143']:
            try:
                location_data = json.loads(transaction['location_data_232143'])
                location_address = location_data.get('address')
            except:
                location_address = None

        formatted_transaction = {
            'id': transaction['transaction_id_232143'],
            'amount': float(transaction['amount_232143']),
            'type': transaction['type_232143'],
            'description': transaction['description_232143'],
            'category': transaction['category_name'],
            'category_name': transaction['category_name'],  # Add category_name for frontend compatibility
            'category_id': transaction['category_id_232143'],
            'category_color': transaction['category_color'],
            'payment_method': transaction['payment_method_232143'],
            'date': transaction['transaction_date_232143'].isoformat() if transaction['transaction_date_232143'] else None,
            'created_at': transaction['created_at_232143'].isoformat() if transaction['created_at_232143'] else None,
            'location': location_address
        }
        
        return jsonify({'transaction': formatted_transaction}), 200
        
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
        
        safe_print(f"Fetching summary for user {user_id}, year={year}, month={month}")
        
        summary = TransactionModel.get_monthly_summary(user_id, year, month)
        
        safe_print(f"Raw summary from DB: {summary}")
        
        # Transform the summary data to match frontend expectations
        transformed_summary = []
        for item in summary:
            # Get the type and remove suffix if present
            transaction_type = item['type_232143']
            if isinstance(transaction_type, str) and transaction_type.endswith('_232143'):
                transaction_type = transaction_type.replace('_232143', '')
            
            transformed_item = {
                'type_232143': transaction_type,  # This will be 'income' or 'expense'
                'total_amount_232143': str(item['total_amount']),
                'transaction_count': item['transaction_count']
            }
            transformed_summary.append(transformed_item)

        result = {
            'year': year,
            'month': month,
            'summary': transformed_summary
        }
        
        safe_print(f"Transformed summary: {transformed_summary}")
        safe_print(f"Returning summary: {result}")
        
        return jsonify(result), 200
        
    except Exception as e:
        safe_print(f"Error in get_monthly_summary: {safe_str(e)}")
        from utils.encoding_utils import safe_print_exc
        safe_print_exc()
        return jsonify({'error': safe_str(e)}), 500

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

@transaction_bp.route('/recommendations', methods=['GET'])
@jwt_required()
def get_ai_recommendations():
    """Get AI-powered financial recommendations based on user's spending patterns"""
    try:
        user_id = get_jwt_identity()
        recommendations = RecommendationService.generate_recommendations(user_id)
        return jsonify(recommendations), 200
        
    except Exception as e:
        safe_print(f'Error in get_ai_recommendations: {safe_str(e)}')
        from utils.encoding_utils import safe_print_exc
        safe_print_exc()
        return jsonify({
            'recommendation': 'Belum ada rekomendasi AI tersedia',
            'potential_savings': 0
        }), 200