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
        
        # Pagination support
        if request.args.get('limit'):
            filters['limit'] = request.args.get('limit', type=int)
        if request.args.get('offset'):
            filters['offset'] = request.args.get('offset', type=int)
        
        transactions = TransactionModel.get_user_transactions(user_id, filters)
        
        # Get total count for pagination metadata (without limit/offset)
        total_count = len(TransactionModel.get_user_transactions(user_id, {k: v for k, v in filters.items() if k not in ['limit', 'offset']}))
        
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
            'count': len(formatted_transactions),
            'total': total_count,
            'limit': filters.get('limit'),
            'offset': filters.get('offset', 0),
            'has_more': (filters.get('offset', 0) + len(formatted_transactions)) < total_count
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
        error_msg = str(e)
        print(f"❌ Error deleting transaction: {error_msg}")
        import traceback
        traceback.print_exc()
        # Check if it's a MySQL error 3105 (trigger error)
        if '3105' in error_msg or 'trigger' in error_msg.lower():
            return jsonify({
                'error': 'Gagal menghapus transaksi. Pastikan trigger database sudah diterapkan dengan benar.',
                'details': error_msg
            }), 500
        return jsonify({'error': error_msg}), 500

@transaction_bp.route('/analytics/summary', methods=['GET'])
@jwt_required()
def get_monthly_summary():
    try:
        user_id = get_jwt_identity()
        year = request.args.get('year', datetime.now().year, type=int)
        month = request.args.get('month', datetime.now().month, type=int)

        print(f"Fetching summary for user {user_id}, year={year}, month={month}")

        summary = TransactionModel.get_monthly_summary(user_id, year, month)
        print(f"Raw summary from DB: {summary}")

        transformed_summary = []
        for item in summary:
            transaction_type = item['type_232143']
            if isinstance(transaction_type, str) and transaction_type.endswith('_232143'):
                transaction_type = transaction_type.replace('_232143', '')

            raw_amount = item['total_amount']
            try:
                total_amount = float(raw_amount) if raw_amount is not None else 0.0
            except (TypeError, ValueError):
                total_amount = 0.0

            transaction_count = int(item.get('transaction_count') or 0)

            transformed_summary.append({
                'type_232143': transaction_type,
                'total_amount_232143': total_amount,
                'transaction_count': transaction_count,
            })

        result = {
            'year': year,
            'month': month,
            'summary': transformed_summary,
        }
        print(f"Returning summary result: {result}")
        return jsonify(result), 200

    except Exception as e:
        print(f"Error in get_monthly_summary: {safe_str(e)}")
        from utils.encoding_utils import safe_print_exc
        safe_print_exc()
        return jsonify({'error': safe_str(e)}), 500


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

@transaction_bp.route('/categorize', methods=['POST'])
@jwt_required()
def categorize_transaction():
    """Use AI to categorize a transaction based on description"""
    try:
        # Check if categorization is enabled
        import config
        if not config.Config.LLM_ENABLE_CATEGORIZATION:
            return jsonify({
                'error': 'AI categorization is disabled',
                'category': None,
                'confidence': 0.0,
                'message': 'Fitur kategorisasi AI tidak tersedia saat ini'
            }), 503
        
        user_id = get_jwt_identity()
        data = request.get_json()
        
        if not data or 'description' not in data:
            return jsonify({'error': 'Description is required'}), 400
        
        description = data['description']
        amount = float(data.get('amount', 0))
        date = data.get('date')
        
        from services.gemini_service import gemini_service
        category_name, confidence, error = gemini_service.categorize_transaction(
            description, amount, date
        )
        
        if error:
            return jsonify({
                'error': error,
                'category': None,
                'confidence': 0.0
            }), 500
        
        return jsonify({
            'category': category_name,
            'confidence': confidence,
            'message': 'Success'
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@transaction_bp.route('/summarize', methods=['POST'])
@jwt_required()
def summarize_transactions():
    """Generate AI summary of transactions"""
    try:
        # Check if summarization is enabled
        import config
        if not config.Config.LLM_ENABLE_SUMMARIZATION:
            return jsonify({
                'error': 'AI summarization is disabled',
                'summary': None,
                'message': 'Fitur ringkasan AI tidak tersedia saat ini'
            }), 503
        
        user_id = get_jwt_identity()
        data = request.get_json()
        
        transactions = data.get('transactions', [])
        
        if not transactions:
            # Get recent transactions if none provided
            transactions = TransactionModel.get_recent_transactions(user_id, 30)
        
        from services.gemini_service import gemini_service
        summary_text, error = gemini_service.generate_transaction_summary(transactions)
        
        if error:
            return jsonify({
                'error': error,
                'summary': None
            }), 500
        
        return jsonify({
            'summary': summary_text,
            'transaction_count': len(transactions),
            'message': 'Success'
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500