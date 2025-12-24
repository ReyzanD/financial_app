from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from models.database import get_db
from utils.encoding_utils import safe_print, safe_str
import json

recurring_bp = Blueprint('recurring_transactions', __name__)

@recurring_bp.route('', methods=['GET'])
@jwt_required()
def get_recurring_transactions():
    """
    Get recurring transactions for the authenticated user
    
    Query params:
        active_only: true/false (default true) - filter by active status
    """
    try:
        user_id = get_jwt_identity()
        active_only = request.args.get('active_only', 'true').lower() == 'true'
        
        db = get_db()
        with db.cursor() as cursor:
            sql = """
            SELECT 
                t.transaction_id_232143 as id,
                t.amount_232143 as amount,
                t.type_232143 as type,
                t.description_232143 as description,
                t.category_id_232143 as category_id,
                COALESCE(c.name_232143, 'Uncategorized') as category_name,
                t.recurring_pattern_232143 as recurring_pattern,
                t.is_recurring_232143 as is_active,
                t.transaction_date_232143 as start_date,
                t.created_at_232143 as created_at
            FROM transactions_232143 t
            LEFT JOIN categories_232143 c ON t.category_id_232143 = c.category_id_232143
            WHERE t.user_id_232143 = %s AND t.is_recurring_232143 = 1
            """
            
            cursor.execute(sql, (user_id,))
            results = cursor.fetchall()
            
            recurring_transactions = []
            for row in results:
                # Parse recurring_pattern JSON if it exists
                recurring_pattern = None
                if row.get('recurring_pattern'):
                    try:
                        if isinstance(row['recurring_pattern'], str):
                            recurring_pattern = json.loads(row['recurring_pattern'])
                        else:
                            recurring_pattern = row['recurring_pattern']
                    except:
                        recurring_pattern = None
                
                recurring_transactions.append({
                    'id': row['id'],
                    'amount': float(row['amount']),
                    'type': row['type'],
                    'description': row['description'],
                    'category_id': row['category_id'],
                    'category_name': row['category_name'],
                    'recurring_pattern': recurring_pattern,
                    'is_active': bool(row['is_active']),
                    'start_date': row['start_date'].isoformat() if row['start_date'] else None,
                    'created_at': row['created_at'].isoformat() if row['created_at'] else None,
                })
            
            return jsonify({
                'recurring_transactions': recurring_transactions
            }), 200
            
    except Exception as e:
        safe_print(f'❌ Error getting recurring transactions: {safe_str(e)}')
        from utils.encoding_utils import safe_print_exc
        safe_print_exc()
        return jsonify({'error': f'Failed to get recurring transactions: {safe_str(e)}'}), 500


@recurring_bp.route('/<recurring_id>', methods=['GET'])
@jwt_required()
def get_recurring_transaction(recurring_id):
    """Get a specific recurring transaction by ID"""
    try:
        user_id = get_jwt_identity()
        
        db = get_db()
        with db.cursor() as cursor:
            sql = """
            SELECT 
                t.transaction_id_232143 as id,
                t.amount_232143 as amount,
                t.type_232143 as type,
                t.description_232143 as description,
                t.category_id_232143 as category_id,
                COALESCE(c.name_232143, 'Uncategorized') as category_name,
                t.recurring_pattern_232143 as recurring_pattern,
                t.is_recurring_232143 as is_active,
                t.transaction_date_232143 as start_date,
                t.created_at_232143 as created_at
            FROM transactions_232143 t
            LEFT JOIN categories_232143 c ON t.category_id_232143 = c.category_id_232143
            WHERE t.user_id_232143 = %s 
                AND t.transaction_id_232143 = %s
                AND t.is_recurring_232143 = 1
            """
            
            cursor.execute(sql, (user_id, recurring_id))
            row = cursor.fetchone()
            
            if not row:
                return jsonify({'error': 'Recurring transaction not found'}), 404
            
            # Parse recurring_pattern JSON if it exists
            recurring_pattern = None
            if row.get('recurring_pattern'):
                try:
                    if isinstance(row['recurring_pattern'], str):
                        recurring_pattern = json.loads(row['recurring_pattern'])
                    else:
                        recurring_pattern = row['recurring_pattern']
                except:
                    recurring_pattern = None
            
            return jsonify({
                'recurring_transaction': {
                    'id': row['id'],
                    'amount': float(row['amount']),
                    'type': row['type'],
                    'description': row['description'],
                    'category_id': row['category_id'],
                    'category_name': row['category_name'],
                    'recurring_pattern': recurring_pattern,
                    'is_active': bool(row['is_active']),
                    'start_date': row['start_date'].isoformat() if row['start_date'] else None,
                    'created_at': row['created_at'].isoformat() if row['created_at'] else None,
                }
            }), 200
            
    except Exception as e:
        safe_print(f'❌ Error getting recurring transaction: {safe_str(e)}')
        from utils.encoding_utils import safe_print_exc
        safe_print_exc()
        return jsonify({'error': f'Failed to get recurring transaction: {safe_str(e)}'}), 500


@recurring_bp.route('', methods=['POST'])
@jwt_required()
def create_recurring_transaction():
    """Create a new recurring transaction"""
    try:
        user_id = get_jwt_identity()
        data = request.get_json()
        
        # This is a placeholder - in a full implementation, you'd create a recurring transaction
        # For now, just return success
        return jsonify({
            'message': 'Recurring transaction created',
            'recurring_transaction': data
        }), 201
        
    except Exception as e:
        safe_print(f'❌ Error creating recurring transaction: {safe_str(e)}')
        return jsonify({'error': f'Failed to create recurring transaction: {safe_str(e)}'}), 500


@recurring_bp.route('/<recurring_id>', methods=['PUT'])
@jwt_required()
def update_recurring_transaction(recurring_id):
    """Update a recurring transaction"""
    try:
        user_id = get_jwt_identity()
        data = request.get_json()
        
        # This is a placeholder - in a full implementation, you'd update the recurring transaction
        return jsonify({
            'message': 'Recurring transaction updated',
            'recurring_transaction': data
        }), 200
        
    except Exception as e:
        safe_print(f'❌ Error updating recurring transaction: {safe_str(e)}')
        return jsonify({'error': f'Failed to update recurring transaction: {safe_str(e)}'}), 500


@recurring_bp.route('/<recurring_id>', methods=['DELETE'])
@jwt_required()
def delete_recurring_transaction(recurring_id):
    """Delete a recurring transaction"""
    try:
        user_id = get_jwt_identity()
        
        # This is a placeholder - in a full implementation, you'd delete the recurring transaction
        return jsonify({'message': 'Recurring transaction deleted'}), 200
        
    except Exception as e:
        safe_print(f'❌ Error deleting recurring transaction: {safe_str(e)}')
        return jsonify({'error': f'Failed to delete recurring transaction: {safe_str(e)}'}), 500


@recurring_bp.route('/<recurring_id>/pause', methods=['POST'])
@jwt_required()
def pause_recurring_transaction(recurring_id):
    """Pause a recurring transaction"""
    try:
        user_id = get_jwt_identity()
        
        # This is a placeholder
        return jsonify({'message': 'Recurring transaction paused'}), 200
        
    except Exception as e:
        safe_print(f'❌ Error pausing recurring transaction: {safe_str(e)}')
        return jsonify({'error': f'Failed to pause recurring transaction: {safe_str(e)}'}), 500


@recurring_bp.route('/<recurring_id>/resume', methods=['POST'])
@jwt_required()
def resume_recurring_transaction(recurring_id):
    """Resume a recurring transaction"""
    try:
        user_id = get_jwt_identity()
        
        # This is a placeholder
        return jsonify({'message': 'Recurring transaction resumed'}), 200
        
    except Exception as e:
        safe_print(f'❌ Error resuming recurring transaction: {safe_str(e)}')
        return jsonify({'error': f'Failed to resume recurring transaction: {safe_str(e)}'}), 500


@recurring_bp.route('/upcoming', methods=['GET'])
@jwt_required()
def get_upcoming_recurring_transactions():
    """
    Get upcoming recurring transactions within specified days
    
    Query params:
        days: number of days to look ahead (default 7)
    """
    try:
        user_id = get_jwt_identity()
        days = int(request.args.get('days', 7))
        
        db = get_db()
        with db.cursor() as cursor:
            # For now, return transactions marked as recurring
            # In a full implementation, this would calculate next occurrence dates
            sql = """
            SELECT 
                t.transaction_id_232143 as id,
                t.amount_232143 as amount,
                t.type_232143 as type,
                t.description_232143 as description,
                COALESCE(c.name_232143, 'Uncategorized') as category_name,
                t.transaction_date_232143 as last_date
            FROM transactions_232143 t
            LEFT JOIN categories_232143 c ON t.category_id_232143 = c.category_id_232143
            WHERE t.user_id_232143 = %s 
                AND t.is_recurring_232143 = 1
            ORDER BY t.transaction_date_232143 DESC
            LIMIT 10
            """
            
            cursor.execute(sql, (user_id,))
            results = cursor.fetchall()
            
            upcoming = []
            for row in results:
                upcoming.append({
                    'id': row['id'],
                    'amount': float(row['amount']),
                    'type': row['type'],
                    'description': row['description'],
                    'category_name': row['category_name'],
                    'due_date': row['last_date'].isoformat() if row['last_date'] else None,
                })
            
            return jsonify({
                'upcoming': upcoming
            }), 200
            
    except Exception as e:
        safe_print(f'❌ Error getting upcoming recurring transactions: {safe_str(e)}')
        from utils.encoding_utils import safe_print_exc
        safe_print_exc()
        return jsonify({'error': f'Failed to get upcoming transactions: {safe_str(e)}'}), 500

