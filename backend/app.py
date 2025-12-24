import sys
import io
from flask import Flask, jsonify
from flask_cors import CORS
from flask_jwt_extended import JWTManager
import config
from models.database import init_app as init_db
from routes.auth_routes import auth_bp
from routes.transaction_route import transaction_bp
from routes.obligation_routes import obligation_bp
from routes.category_routes import category_bp
from routes.goal_routes import goal_bp
from routes.budget_routes import budget_bp
from routes.data_routes import data_bp
from routes.recurring_transactions_routes import recurring_bp

# Fix encoding issues on Windows
if sys.platform == 'win32':
    # Set UTF-8 encoding for stdout and stderr
    if sys.stdout.encoding != 'utf-8':
        sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
    if sys.stderr.encoding != 'utf-8':
        sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')

def create_app():
    app = Flask(__name__)
    app.config.from_object(config.Config)
    
    # Initialize extensions
    CORS(app)
    jwt = JWTManager(app)
    init_db(app)
    
    # Helper function for safe printing with encoding handling
    def safe_print(message):
        """Safely print messages, handling encoding errors"""
        try:
            print(message)
        except UnicodeEncodeError:
            # Fallback: encode to ASCII with error handling
            safe_message = message.encode('ascii', errors='replace').decode('ascii')
            print(safe_message)
    
    # JWT Error Handlers
    @jwt.expired_token_loader
    def expired_token_callback(jwt_header, jwt_payload):
        safe_print("JWT token has expired")
        return jsonify({'error': 'Token has expired', 'message': 'Please login again'}), 401
    
    @jwt.invalid_token_loader
    def invalid_token_callback(error):
        try:
            error_str = str(error)
        except:
            error_str = "Unknown error"
        safe_print(f"Invalid JWT token: {error_str}")
        return jsonify({'error': 'Invalid token', 'message': 'Authentication failed'}), 422
    
    @jwt.unauthorized_loader
    def missing_token_callback(error):
        try:
            error_str = str(error)
        except:
            error_str = "Unknown error"
        safe_print(f"Missing JWT token: {error_str}")
        return jsonify({'error': 'Authorization required', 'message': 'Please login'}), 401
    
    @jwt.revoked_token_loader
    def revoked_token_callback(jwt_header, jwt_payload):
        safe_print("Token has been revoked")
        return jsonify({'error': 'Token revoked', 'message': 'Please login again'}), 401
    
    # Register blueprints
    app.register_blueprint(auth_bp, url_prefix=f"{config.Config.API_PREFIX}/auth")
    app.register_blueprint(transaction_bp, url_prefix=f"{config.Config.API_PREFIX}/transactions_232143")
    app.register_blueprint(obligation_bp, url_prefix=f"{config.Config.API_PREFIX}/obligations")
    app.register_blueprint(category_bp, url_prefix=f"{config.Config.API_PREFIX}/categories_232143")
    app.register_blueprint(goal_bp, url_prefix=f"{config.Config.API_PREFIX}/goals")
    app.register_blueprint(budget_bp, url_prefix=f"{config.Config.API_PREFIX}/budgets")
    app.register_blueprint(data_bp, url_prefix=f"{config.Config.API_PREFIX}/data")
    app.register_blueprint(recurring_bp, url_prefix=f"{config.Config.API_PREFIX}/recurring-transactions")
    
    # Health check route
    @app.route('/')
    def health_check():
        return jsonify({
            'status': 'healthy',
            'message': 'Finance Manager API is running',
            'version': '1.0.0'
        })
    
    # Error handlers
    @app.errorhandler(404)
    def not_found(error):
        return jsonify({'error': 'Endpoint not found'}), 404
    
    @app.errorhandler(500)
    def internal_error(error):
        return jsonify({'error': 'Internal server error'}), 500
    
    return app

if __name__ == '__main__':
    app = create_app()
    app.run(debug=True, host='0.0.0.0', port=5000)