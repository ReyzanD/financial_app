from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from models.goal_model import GoalModel
from datetime import datetime

goal_bp = Blueprint('goals', __name__)

@goal_bp.route('', methods=['GET'])
@jwt_required()
def get_goals():
    """Get all goals for the authenticated user"""
    try:
        user_id = get_jwt_identity()
        include_completed = request.args.get('include_completed', 'false').lower() == 'true'
        
        goals = GoalModel.get_user_goals(user_id, include_completed)
        
        # Format response
        formatted_goals = []
        for goal in goals:
            formatted_goal = {
                'id': goal['goal_id_232143'],
                'name': goal['name_232143'],
                'description': goal['description_232143'],
                'type': goal['goal_type_232143'],
                'target': float(goal['target_amount_232143']),
                'saved': float(goal['current_amount_232143']),
                'start_date': goal['start_date_232143'].isoformat() if goal['start_date_232143'] else None,
                'deadline': goal['target_date_232143'].isoformat() if goal['target_date_232143'] else None,
                'is_completed': bool(goal['is_completed_232143']),
                'completed_date': goal['completed_date_232143'].isoformat() if goal['completed_date_232143'] else None,
                'priority': goal['priority_232143'],
                'monthly_target': float(goal['monthly_target_232143']) if goal['monthly_target_232143'] else None,
                'recommended_monthly_saving': float(goal['recommended_monthly_saving_232143']) if goal['recommended_monthly_saving_232143'] else None,
                'progress': float(goal['progress_percentage_232143']) if goal['progress_percentage_232143'] else 0,
                'created_at': goal['created_at_232143'].isoformat() if goal['created_at_232143'] else None,
            }
            formatted_goals.append(formatted_goal)
        
        return jsonify({
            'goals': formatted_goals,
            'count': len(formatted_goals)
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@goal_bp.route('/<goal_id>', methods=['GET'])
@jwt_required()
def get_goal(goal_id):
    """Get a specific goal"""
    try:
        user_id = get_jwt_identity()
        goal = GoalModel.get_goal_by_id(goal_id, user_id)
        
        if not goal:
            return jsonify({'error': 'Goal not found'}), 404
        
        formatted_goal = {
            'id': goal['goal_id_232143'],
            'name': goal['name_232143'],
            'description': goal['description_232143'],
            'type': goal['goal_type_232143'],
            'target': float(goal['target_amount_232143']),
            'saved': float(goal['current_amount_232143']),
            'start_date': goal['start_date_232143'].isoformat() if goal['start_date_232143'] else None,
            'deadline': goal['target_date_232143'].isoformat() if goal['target_date_232143'] else None,
            'is_completed': bool(goal['is_completed_232143']),
            'completed_date': goal['completed_date_232143'].isoformat() if goal['completed_date_232143'] else None,
            'priority': goal['priority_232143'],
            'monthly_target': float(goal['monthly_target_232143']) if goal['monthly_target_232143'] else None,
            'recommended_monthly_saving': float(goal['recommended_monthly_saving_232143']) if goal['recommended_monthly_saving_232143'] else None,
            'progress': float(goal['progress_percentage_232143']) if goal['progress_percentage_232143'] else 0,
        }
        
        return jsonify({'goal': formatted_goal}), 200
        
    except Exception as e:
        print(f"❌ Error in get_goal: {str(e)}")
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500

@goal_bp.route('', methods=['POST'])
@jwt_required()
def create_goal():
    """Create a new goal"""
    try:
        user_id = get_jwt_identity()
        data = request.get_json()
        
        print(f"📥 Received goal data: {data}")
        print(f"👤 User ID: {user_id}")
        
        # Validate required fields
        required_fields = ['name', 'goal_type', 'target_amount', 'target_date']
        for field in required_fields:
            if field not in data:
                return jsonify({'error': f'{field} is required'}), 400
        
        goal_data = {
            'user_id': user_id,
            'name': data['name'],
            'description': data.get('description'),
            'goal_type': data['goal_type'],
            'target_amount': float(data['target_amount']),
            'current_amount': float(data.get('current_amount', 0)),
            'start_date': data.get('start_date'),
            'target_date': data['target_date'],
            'priority': data.get('priority', 3),
            'monthly_target': data.get('monthly_target'),
            'auto_deduct': data.get('auto_deduct', False),
            'deduct_percentage': data.get('deduct_percentage')
        }
        
        print(f"💾 Creating goal with data: {goal_data}")
        
        goal_id = GoalModel.create_goal(goal_data)
        
        print(f"✅ Goal created with ID: {goal_id}")
        
        return jsonify({
            'message': 'Goal created successfully',
            'goal_id': goal_id
        }), 201
        
    except Exception as e:
        print(f"❌ Error in create_goal: {str(e)}")
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500

@goal_bp.route('/<goal_id>', methods=['PUT'])
@jwt_required()
def update_goal(goal_id):
    """Update an existing goal"""
    try:
        user_id = get_jwt_identity()
        data = request.get_json()
        
        if not data:
            return jsonify({'error': 'No data provided'}), 400
        
        update_data = {}
        field_mapping = {
            'name': 'name_232143',
            'description': 'description_232143',
            'goal_type': 'goal_type_232143',
            'target_amount': 'target_amount_232143',
            'current_amount': 'current_amount_232143',
            'target_date': 'target_date_232143',
            'priority': 'priority_232143',
            'monthly_target': 'monthly_target_232143',
            'auto_deduct': 'auto_deduct_232143',
            'deduct_percentage': 'deduct_percentage_232143'
        }
        
        for frontend_field, backend_field in field_mapping.items():
            if frontend_field in data:
                update_data[backend_field] = data[frontend_field]
        
        if not update_data:
            return jsonify({'error': 'No valid fields to update'}), 400
        
        success = GoalModel.update_goal(goal_id, user_id, update_data)
        
        if not success:
            return jsonify({'error': 'Goal not found or update failed'}), 404
        
        return jsonify({'message': 'Goal updated successfully'}), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@goal_bp.route('/<goal_id>', methods=['DELETE'])
@jwt_required()
def delete_goal(goal_id):
    """Delete a goal"""
    try:
        user_id = get_jwt_identity()
        
        success = GoalModel.delete_goal(goal_id, user_id)
        
        if not success:
            return jsonify({'error': 'Goal not found'}), 404
        
        return jsonify({'message': 'Goal deleted successfully'}), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@goal_bp.route('/<goal_id>/contribute', methods=['POST'])
@jwt_required()
def add_contribution(goal_id):
    """Add money to a goal"""
    try:
        user_id = get_jwt_identity()
        data = request.get_json()
        
        if not data or 'amount' not in data:
            return jsonify({'error': 'Amount is required'}), 400
        
        amount = float(data['amount'])
        
        if amount <= 0:
            return jsonify({'error': 'Amount must be positive'}), 400
        
        result = GoalModel.add_contribution(goal_id, user_id, amount)
        
        if not result:
            return jsonify({'error': 'Goal not found'}), 404
        
        return jsonify({
            'message': 'Contribution added successfully',
            'new_amount': result['new_amount'],
            'is_completed': result['is_completed'],
            'progress': result['progress_percentage']
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@goal_bp.route('/summary', methods=['GET'])
@jwt_required()
def get_goals_summary():
    """Get summary statistics for all goals"""
    try:
        user_id = get_jwt_identity()
        summary = GoalModel.get_goals_summary(user_id)
        
        if not summary:
            return jsonify({
                'total_goals': 0,
                'completed_goals': 0,
                'total_target': 0,
                'total_saved': 0,
                'avg_progress': 0
            }), 200
        
        return jsonify({
            'total_goals': int(summary['total_goals']) if summary['total_goals'] else 0,
            'completed_goals': int(summary['completed_goals']) if summary['completed_goals'] else 0,
            'total_target': float(summary['total_target']) if summary['total_target'] else 0,
            'total_saved': float(summary['total_saved']) if summary['total_saved'] else 0,
            'avg_progress': float(summary['avg_progress']) if summary['avg_progress'] else 0
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500