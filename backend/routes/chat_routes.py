from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from services.gemini_service import gemini_service
import config

chat_bp = Blueprint('chat_232143', __name__)

@chat_bp.route('', methods=['POST'])
@jwt_required()
def send_message():
    """Send a message to the AI chat assistant"""
    try:
        # Check if chat is enabled
        if not config.Config.LLM_ENABLE_CHAT:
            return jsonify({
                'error': 'Chat feature is disabled',
                'message': 'Fitur chat AI tidak tersedia saat ini'
            }), 503
        
        user_id = get_jwt_identity()
        data = request.get_json()
        
        if not data or 'message' not in data:
            return jsonify({'error': 'Message is required'}), 400
        
        message = data['message']
        
        # Early validation - check if message is financial-related (only if strict mode is enabled)
        if not config.Config.LLM_ALLOW_NON_FINANCIAL:
            if not gemini_service._is_financial_question(message):
                # Detect language for appropriate error message
                message_lower = message.lower()
                if any(word in message_lower for word in ['how', 'what', 'why', 'when', 'where', 'can', 'should', 'do']):
                    error_msg = "Sorry, I can only help with personal finance questions. Please ask about budget, expenses, savings, or your financial planning."
                else:
                    error_msg = "Maaf, saya hanya dapat membantu dengan pertanyaan tentang keuangan pribadi. Silakan tanyakan tentang budget, pengeluaran, tabungan, atau perencanaan keuangan Anda."
                
                return jsonify({
                    'error': 'Non-financial question',
                    'message': error_msg
                }), 400
        
        conversation_history = data.get('conversation_history')
        
        response_text, error = gemini_service.generate_chat_response(
            user_id, 
            message, 
            conversation_history
        )
        
        if error:
            return jsonify({
                'error': error,
                'message': 'Gagal mendapatkan respons dari asisten AI'
            }), 500
        
        return jsonify({
            'response': response_text,
            'message': 'Success'
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@chat_bp.route('/history', methods=['GET'])
@jwt_required()
def get_history():
    """Get conversation history for the current user"""
    try:
        user_id = get_jwt_identity()
        history = gemini_service.get_conversation_history(user_id)
        
        return jsonify({
            'history': history,
            'count': len(history)
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@chat_bp.route('/history', methods=['DELETE'])
@jwt_required()
def clear_history():
    """Clear conversation history for the current user"""
    try:
        user_id = get_jwt_identity()
        gemini_service.clear_conversation_history(user_id)
        
        return jsonify({
            'message': 'Conversation history cleared successfully'
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

