from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from models.obligation_model import ObligationModel
from datetime import datetime

obligation_bp = Blueprint('obligations', __name__)

@obligation_bp.route('', methods=['GET'])
@jwt_required()
def get_obligations():
    try:
        user_id = get_jwt_identity()
        
        obligation_type = request.args.get('type')
        
        obligations = ObligationModel.get_user_obligations(user_id, obligation_type)
        
        return jsonify({
            'obligations': obligations,
            'count': len(obligations)
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@obligation_bp.route('', methods=['POST'])
@jwt_required()
def create_obligation():
    try:
        user_id = get_jwt_identity()
        data = request.get_json()
        
        if not data or not data.get('name') or not data.get('type') or not data.get('monthly_amount'):
            return jsonify({'error': 'Name, type, and monthly amount are required'}), 400
        
        obligation_data = {
            'user_id': user_id,
            'name': data['name'],
            'type': data['type'],
            'category': data.get('category', 'other'),
            'monthly_amount': float(data['monthly_amount']),
            'due_date': data.get('due_date'),
            'original_amount': data.get('original_amount'),
            'current_balance': data.get('current_balance'),
            'interest_rate': data.get('interest_rate'),
            'is_subscription': data.get('is_subscription', False),
            'subscription_cycle': data.get('subscription_cycle'),
            'minimum_payment': data.get('minimum_payment'),
            'payoff_strategy': data.get('payoff_strategy')
        }
        
        obligation_id = ObligationModel.create_obligation(obligation_data)
        
        return jsonify({
            'message': 'Obligation created successfully',
            'obligation_id': obligation_id
        }), 201
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@obligation_bp.route('/upcoming', methods=['GET'])
@jwt_required()
def get_upcoming_obligations():
    try:
        user_id = get_jwt_identity()

        obligations = ObligationModel.get_upcoming_obligations(user_id)

        return jsonify({
            'obligations': obligations,
            'count': len(obligations)
        }), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500

@obligation_bp.route('/<obligation_id>', methods=['PUT'])
@jwt_required()
def update_obligation(obligation_id):
    try:
        user_id = get_jwt_identity()
        data = request.get_json()

        if not data:
            return jsonify({'error': 'No data provided'}), 400

        update_data = {}
        field_mapping = {
            'name': 'name_232143',
            'type': 'type_232143',
            'category': 'category_232143',
            'monthly_amount': 'monthly_amount_232143',
            'due_date': 'due_date_232143',
            'original_amount': 'original_amount_232143',
            'current_balance': 'current_balance_232143',
            'interest_rate': 'interest_rate_232143',
            'is_subscription': 'is_subscription_232143',
            'subscription_cycle': 'subscription_cycle_232143',
            'minimum_payment': 'minimum_payment_232143',
            'payoff_strategy': 'payoff_strategy_232143'
        }

        for frontend_field, backend_field in field_mapping.items():
            if frontend_field in data:
                update_data[backend_field] = data[frontend_field]

        if not update_data:
            return jsonify({'error': 'No valid fields to update'}), 400

        success = ObligationModel.update_obligation(obligation_id, user_id, update_data)

        if not success:
            return jsonify({'error': 'Obligation not found or update failed'}), 404

        return jsonify({'message': 'Obligation updated successfully'}), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500

@obligation_bp.route('/<obligation_id>', methods=['DELETE'])
@jwt_required()
def delete_obligation(obligation_id):
    try:
        user_id = get_jwt_identity()

        success = ObligationModel.delete_obligation(obligation_id, user_id)

        if not success:
            return jsonify({'error': 'Obligation not found'}), 404

        return jsonify({'message': 'Obligation deleted successfully'}), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500

@obligation_bp.route('/<obligation_id>/payments', methods=['POST'])
@jwt_required()
def record_payment(obligation_id):
    try:
        user_id = get_jwt_identity()
        data = request.get_json()

        if not data or not data.get('amount_paid'):
            return jsonify({'error': 'Amount paid is required'}), 400

        payment_data = {
            'obligation_id': obligation_id,
            'user_id': user_id,
            'amount_paid': float(data['amount_paid']),
            'payment_date': data.get('payment_date', datetime.now().date().isoformat()),
            'payment_method': data.get('payment_method'),
            'principal_paid': data.get('principal_paid'),
            'interest_paid': data.get('interest_paid')
        }

        payment_id = ObligationModel.record_payment(payment_data)

        return jsonify({
            'message': 'Payment recorded successfully',
            'payment_id': payment_id
        }), 201

    except Exception as e:
        return jsonify({'error': str(e)}), 500
