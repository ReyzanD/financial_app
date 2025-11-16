from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from models.transaction_model import TransactionModel
from models.budget_model import BudgetModel
from models.goal_model import GoalModel
from models.category_model import CategoryModel
from models.obligation_model import ObligationModel
from models.user_model import UserModel
from datetime import datetime
import json

data_bp = Blueprint('data', __name__)

@data_bp.route('/export', methods=['GET'])
@jwt_required()
def export_user_data():
    """
    Export all user data as JSON for backup purposes
    
    Returns:
        JSON containing all user transactions, budgets, goals, categories, and obligations
    """
    try:
        user_id = get_jwt_identity()
        
        # Get user profile
        user = UserModel.get_user_by_id(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        # Get all user data
        transactions = TransactionModel.get_user_transactions(user_id)
        budgets = BudgetModel.get_user_budgets(user_id)
        goals = GoalModel.get_user_goals(user_id)
        categories = CategoryModel.get_user_categories(user_id)
        obligations = ObligationModel.get_user_obligations(user_id)
        
        # Format the export data
        export_data = {
            'version': '1.0',
            'exported_at': datetime.now().isoformat(),
            'user': {
                'email': user['email_232143'],
                'full_name': user['full_name_232143'],
                'phone_number': user['phone_number_232143'],
                'currency': user['currency_232143'],
            },
            'transactions': _format_transactions(transactions),
            'budgets': _format_budgets(budgets),
            'goals': _format_goals(goals),
            'categories': _format_categories(categories),
            'obligations': _format_obligations(obligations),
            'stats': {
                'total_transactions': len(transactions),
                'total_budgets': len(budgets),
                'total_goals': len(goals),
                'total_categories': len(categories),
                'total_obligations': len(obligations),
            }
        }
        
        return jsonify(export_data), 200
        
    except Exception as e:
        print(f'❌ Error exporting data: {str(e)}')
        import traceback
        traceback.print_exc()
        return jsonify({'error': 'Failed to export data'}), 500


@data_bp.route('/import', methods=['POST'])
@jwt_required()
def import_user_data():
    """
    Import user data from JSON backup
    
    Request body should contain the exported JSON data
    Options:
        - replace: true/false (default false) - Replace existing data or merge
    """
    try:
        user_id = get_jwt_identity()
        data = request.get_json()
        
        if not data:
            return jsonify({'error': 'No data provided'}), 400
        
        # Validate data format
        if 'version' not in data:
            return jsonify({'error': 'Invalid export format - missing version'}), 400
        
        replace_mode = request.args.get('replace', 'false').lower() == 'true'
        
        imported_counts = {
            'transactions': 0,
            'budgets': 0,
            'goals': 0,
            'categories': 0,
            'obligations': 0,
        }
        
        # Import categories first (other data depends on them)
        if 'categories' in data:
            imported_counts['categories'] = _import_categories(user_id, data['categories'], replace_mode)
        
        # Import budgets
        if 'budgets' in data:
            imported_counts['budgets'] = _import_budgets(user_id, data['budgets'], replace_mode)
        
        # Import goals
        if 'goals' in data:
            imported_counts['goals'] = _import_goals(user_id, data['goals'], replace_mode)
        
        # Import transactions
        if 'transactions' in data:
            imported_counts['transactions'] = _import_transactions(user_id, data['transactions'], replace_mode)
        
        # Import obligations
        if 'obligations' in data:
            imported_counts['obligations'] = _import_obligations(user_id, data['obligations'], replace_mode)
        
        return jsonify({
            'message': 'Data imported successfully',
            'imported': imported_counts,
            'mode': 'replace' if replace_mode else 'merge'
        }), 200
        
    except Exception as e:
        print(f'❌ Error importing data: {str(e)}')
        import traceback
        traceback.print_exc()
        return jsonify({'error': f'Failed to import data: {str(e)}'}), 500


# Helper functions for formatting export data
def _format_transactions(transactions):
    formatted = []
    for t in transactions:
        formatted.append({
            'amount': float(t['amount_232143']),
            'type': t['type_232143'],
            'category_id': t['category_id_232143'],
            'description': t['description_232143'],
            'payment_method': t['payment_method_232143'],
            'transaction_date': t['transaction_date_232143'].isoformat() if t['transaction_date_232143'] else None,
            'location_data': t['location_data_232143'],
        })
    return formatted


def _format_budgets(budgets):
    formatted = []
    for b in budgets:
        formatted.append({
            'category_id': b['category_id_232143'],
            'limit_amount': float(b['limit_amount_232143']),
            'period_start': b['period_start_232143'].isoformat() if b['period_start_232143'] else None,
            'period_end': b['period_end_232143'].isoformat() if b['period_end_232143'] else None,
            'is_active': bool(b['is_active_232143']),
        })
    return formatted


def _format_goals(goals):
    formatted = []
    for g in goals:
        formatted.append({
            'name': g['name_232143'],
            'target_amount': float(g['target_amount_232143']),
            'current_amount': float(g['current_amount_232143']),
            'target_date': g['target_date_232143'].isoformat() if g['target_date_232143'] else None,
            'goal_type': g['goal_type_232143'],
            'description': g['description_232143'],
        })
    return formatted


def _format_categories(categories):
    formatted = []
    for c in categories:
        # Only export user-created categories, not system defaults
        if not c.get('is_system_default_232143'):
            formatted.append({
                'name': c['name_232143'],
                'type': c['type_232143'],
                'color': c['color_232143'],
                'icon': c['icon_232143'],
            })
    return formatted


def _format_obligations(obligations):
    formatted = []
    for o in obligations:
        formatted.append({
            'name': o['name_232143'],
            'amount': float(o['amount_232143']),
            'due_date': o['due_date_232143'].isoformat() if o['due_date_232143'] else None,
            'frequency': o['frequency_232143'],
            'category': o['category_232143'],
            'is_paid': bool(o['is_paid_232143']),
        })
    return formatted


# Helper functions for importing data
def _import_categories(user_id, categories, replace_mode):
    count = 0
    for cat in categories:
        try:
            CategoryModel.create_category(
                user_id=user_id,
                name=cat.get('name'),
                category_type=cat.get('type', 'expense'),
                color=cat.get('color', '#8B5FBF'),
                icon=cat.get('icon', 'shopping_bag')
            )
            count += 1
        except Exception as e:
            print(f'Error importing category {cat.get("name")}: {e}')
    return count


def _import_budgets(user_id, budgets, replace_mode):
    count = 0
    for budget in budgets:
        try:
            BudgetModel.create_budget(
                user_id=user_id,
                category_id=budget.get('category_id'),
                limit_amount=budget.get('limit_amount'),
                period_start=budget.get('period_start'),
                period_end=budget.get('period_end')
            )
            count += 1
        except Exception as e:
            print(f'Error importing budget: {e}')
    return count


def _import_goals(user_id, goals, replace_mode):
    count = 0
    for goal in goals:
        try:
            GoalModel.create_goal(
                user_id=user_id,
                name=goal.get('name'),
                target_amount=goal.get('target_amount'),
                target_date=goal.get('target_date'),
                goal_type=goal.get('goal_type', 'savings'),
                description=goal.get('description', '')
            )
            count += 1
        except Exception as e:
            print(f'Error importing goal {goal.get("name")}: {e}')
    return count


def _import_transactions(user_id, transactions, replace_mode):
    count = 0
    for trans in transactions:
        try:
            TransactionModel.create_transaction({
                'user_id': user_id,
                'amount': trans.get('amount'),
                'type': trans.get('type'),
                'category_id': trans.get('category_id'),
                'description': trans.get('description'),
                'payment_method': trans.get('payment_method', 'cash'),
                'transaction_date': trans.get('transaction_date'),
                'location_data': trans.get('location_data'),
            })
            count += 1
        except Exception as e:
            print(f'Error importing transaction: {e}')
    return count


def _import_obligations(user_id, obligations, replace_mode):
    count = 0
    for obl in obligations:
        try:
            ObligationModel.create_obligation(
                user_id=user_id,
                name=obl.get('name'),
                amount=obl.get('amount'),
                due_date=obl.get('due_date'),
                frequency=obl.get('frequency', 'once'),
                category=obl.get('category', 'other')
            )
            count += 1
        except Exception as e:
            print(f'Error importing obligation {obl.get("name")}: {e}')
    return count
