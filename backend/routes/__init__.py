# Import all blueprints here for easy access
from .auth_routes import auth_bp
from .transaction_route import transaction_bp
from .obligation_routes import obligation_bp

__all__ = ['auth_bp', 'transaction_bp', 'obligation_bp']
