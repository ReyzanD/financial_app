from flask import Flask, jsonify
from flask_cors import CORS
from flask_jwt_extended import JWTManager
import config
from models.database import init_app as init_db
from routes.auth_routes import auth_bp
from routes.transaction_route import transaction_bp
from routes.obligation_routes import obligation_bp
from routes.category_routes import category_bp

def create_app():
    app = Flask(__name__)
    app.config.from_object(config.Config)
    
    # Initialize extensions
    CORS(app)
    JWTManager(app)
    init_db(app)
    
    # Register blueprints
    app.register_blueprint(auth_bp, url_prefix=f"{config.Config.API_PREFIX}/auth")
    app.register_blueprint(transaction_bp, url_prefix=f"{config.Config.API_PREFIX}/transactions_232143")
    app.register_blueprint(obligation_bp, url_prefix=f"{config.Config.API_PREFIX}/obligations")
    app.register_blueprint(category_bp, url_prefix=f"{config.Config.API_PREFIX}/categories_232143")
    
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