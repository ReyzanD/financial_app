from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from models.budget_model import BudgetModel
from datetime import datetime

budget_bp = Blueprint('budgets', __name__)

@budget_bp.route('', methods=['GET'])
@jwt_required()
def get_budgets():
    """Get all budgets for the authenticated user"""
    try:
        user_id = get_jwt_identity()
        active_only = request.args.get('active_only', 'true').lower() == 'true'
        
        print(f"💰 Fetching budgets for user: {user_id}, active_only={active_only}")
        budgets = BudgetModel.get_user_budgets(user_id, active_only)
        print(f"📊 Raw budgets from DB: {budgets}")
        
        # Format response
        formatted_budgets = []
        for budget in budgets:
            formatted_budget = {
                'id': budget['budget_id_232143'],
                'category_id': budget['category_id_232143'],
                'amount': float(budget['amount_232143']),
                'period': budget['period_232143'],
                'period_start': budget['period_start_232143'].isoformat() if budget['period_start_232143'] else None,
                'period_end': budget['period_end_232143'].isoformat() if budget['period_end_232143'] else None,
                'spent': float(budget['spent_amount_232143']) if budget['spent_amount_232143'] else 0,
                'remaining': float(budget['remaining_amount_232143']) if budget['remaining_amount_232143'] else 0,
                'rollover_enabled': bool(budget['rollover_enabled_232143']),
                'alert_threshold': budget['alert_threshold_232143'],
                'is_active': bool(budget['is_active_232143']),
                'recommended_amount': float(budget['recommended_amount_232143']) if budget['recommended_amount_232143'] else None,
                'recommendation_reason': budget['recommendation_reason_232143'],
                'created_at': budget['created_at_232143'].isoformat() if budget['created_at_232143'] else None,
            }
            formatted_budgets.append(formatted_budget)
        
        print(f"✅ Formatted budgets: {formatted_budgets}")
        return jsonify({
            'budgets': formatted_budgets,
            'count': len(formatted_budgets)
        }), 200
        
    except Exception as e:
        print(f"❌ Error in get_budgets: {str(e)}")
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500

@budget_bp.route('/<budget_id>', methods=['GET'])
@jwt_required()
def get_budget(budget_id):
    """Get a specific budget"""
    try:
        user_id = get_jwt_identity()
        budget = BudgetModel.get_budget_by_id(budget_id, user_id)
        
        if not budget:
            return jsonify({'error': 'Budget not found'}), 404
        
        formatted_budget = {
            'id': budget['budget_id_232143'],
            'category_id': budget['category_id_232143'],
            'amount': float(budget['amount_232143']),
            'period': budget['period_232143'],
            'period_start': budget['period_start_232143'].isoformat() if budget['period_start_232143'] else None,
            'period_end': budget['period_end_232143'].isoformat() if budget['period_end_232143'] else None,
            'spent': float(budget['spent_amount_232143']) if budget['spent_amount_232143'] else 0,
            'remaining': float(budget['remaining_amount_232143']) if budget['remaining_amount_232143'] else 0,
            'rollover_enabled': bool(budget['rollover_enabled_232143']),
            'alert_threshold': budget['alert_threshold_232143'],
            'is_active': bool(budget['is_active_232143']),
            'recommended_amount': float(budget['recommended_amount_232143']) if budget['recommended_amount_232143'] else None,
            'recommendation_reason': budget['recommendation_reason_232143'],
        }
        
        return jsonify({'budget': formatted_budget}), 200
        
    except Exception as e:
        print(f"❌ Error in get_budget: {str(e)}")
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500

@budget_bp.route('', methods=['POST'])
@jwt_required()
def create_budget():
    """Create a new budget"""
    try:
        user_id = get_jwt_identity()
        data = request.get_json()
        
        print(f"📥 Received budget data: {data}")
        print(f"👤 User ID: {user_id}")
        
        # Validate required fields
        required_fields = ['amount', 'period']
        for field in required_fields:
            if field not in data:
                return jsonify({'error': f'{field} is required'}), 400
        
        budget_data = {
            'user_id': user_id,
            'category_id': data.get('category_id'),
            'amount': float(data['amount']),
            'period': data['period'],
            'period_start': data.get('period_start'),
            'rollover_enabled': data.get('rollover_enabled', False),
            'alert_threshold': data.get('alert_threshold', 80),
            'is_active': data.get('is_active', True)
        }
        
        print(f"💾 Creating budget with data: {budget_data}")
        
        budget_id = BudgetModel.create_budget(budget_data)
        
        print(f"✅ Budget created with ID: {budget_id}")
        
        return jsonify({
            'message': 'Budget created successfully',
            'budget_id': budget_id
        }), 201
        
    except Exception as e:
        print(f"❌ Error in create_budget: {str(e)}")
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500

@budget_bp.route('/<budget_id>', methods=['PUT'])
@jwt_required()
def update_budget(budget_id):
    """Update an existing budget"""
    try:
        user_id = get_jwt_identity()
        data = request.get_json()
        
        if not data:
            return jsonify({'error': 'No data provided'}), 400
        
        update_data = {}
        field_mapping = {
            'category_id': 'category_id_232143',
            'amount': 'amount_232143',
            'period': 'period_232143',
            'period_start': 'period_start_232143',
            'period_end': 'period_end_232143',
            'rollover_enabled': 'rollover_enabled_232143',
            'alert_threshold': 'alert_threshold_232143',
            'is_active': 'is_active_232143'
        }
        
        for frontend_field, backend_field in field_mapping.items():
            if frontend_field in data:
                update_data[backend_field] = data[frontend_field]
        
        if not update_data:
            return jsonify({'error': 'No valid fields to update'}), 400
        
        success = BudgetModel.update_budget(budget_id, user_id, update_data)
        
        if not success:
            return jsonify({'error': 'Budget not found or update failed'}), 404
        
        return jsonify({'message': 'Budget updated successfully'}), 200
        
    except Exception as e:
        print(f"❌ Error in update_budget: {str(e)}")
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500

@budget_bp.route('/<budget_id>', methods=['DELETE'])
@jwt_required()
def delete_budget(budget_id):
    """Delete a budget"""
    try:
        user_id = get_jwt_identity()
        
        success = BudgetModel.delete_budget(budget_id, user_id)
        
        if not success:
            return jsonify({'error': 'Budget not found'}), 404
        
        return jsonify({'message': 'Budget deleted successfully'}), 200
        
    except Exception as e:
        print(f"❌ Error in delete_budget: {str(e)}")
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500

@budget_bp.route('/summary', methods=['GET'])
@jwt_required()
def get_budgets_summary():
    """Get summary statistics for all budgets"""
    try:
        user_id = get_jwt_identity()
        summary = BudgetModel.get_budgets_summary(user_id)
        
        if not summary:
            return jsonify({
                'total_budgets': 0,
                'total_budget': 0,
                'total_spent': 0,
                'total_remaining': 0,
                'avg_usage_percentage': 0
            }), 200
        
        return jsonify({
            'total_budgets': int(summary['total_budgets']) if summary['total_budgets'] else 0,
            'total_budget': float(summary['total_budget']) if summary['total_budget'] else 0,
            'total_spent': float(summary['total_spent']) if summary['total_spent'] else 0,
            'total_remaining': float(summary['total_remaining']) if summary['total_remaining'] else 0,
            'avg_usage_percentage': float(summary['avg_usage_percentage']) if summary['avg_usage_percentage'] else 0
        }), 200
        
    except Exception as e:
        print(f" Error in get_budgets_summary: {str(e)}")
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500