#!/usr/bin/env python3
"""
Script to create a test user and sample data for API testing
"""
import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app import create_app
from models.user_model import UserModel
from models.transaction_model import TransactionModel
from models.obligation_model import ObligationModel
from models.category_model import CategoryModel
from datetime import datetime, timedelta
import uuid

def create_test_user():
    """Create a test user for API testing"""
    app = create_app()

    with app.app_context():
        # Check if test user already exists
        existing_user = UserModel.get_user_by_email('test@example.com')
        if existing_user:
            print("✅ Test user already exists")
            return existing_user['user_id_232143']

        # Create test user
        user_id = UserModel.create_user(
            email='test@example.com',
            password='password123',
            full_name='Test User',
            phone_number='+1234567890'
        )

        print(f"✅ Created test user with ID: {user_id}")
        return user_id

def create_sample_categories(user_id):
    """Create sample categories"""
    app = create_app()

    with app.app_context():
        categories = [
            {'name': 'Food & Dining', 'type': 'expense', 'color': '#FF6B6B'},
            {'name': 'Transportation', 'type': 'expense', 'color': '#4ECDC4'},
            {'name': 'Entertainment', 'type': 'expense', 'color': '#45B7D1'},
            {'name': 'Utilities', 'type': 'expense', 'color': '#96CEB4'},
            {'name': 'Salary', 'type': 'income', 'color': '#FFEAA7'},
            {'name': 'Freelance', 'type': 'income', 'color': '#DDA0DD'}
        ]

        category_ids = []
        for cat in categories:
            cat_id = CategoryModel.create_category(user_id, cat)
            category_ids.append(cat_id)
            print(f"✅ Created category: {cat['name']}")

        return category_ids

def create_sample_transactions(user_id, category_ids):
    """Create sample transactions"""
    app = create_app()

    with app.app_context():
        transactions = [
            {
                'amount': 25.50,
                'type': 'expense',
                'description': 'Lunch at restaurant',
                'category_id': category_ids[0],  # Food & Dining
                'payment_method': 'debit_card',
                'transaction_date': (datetime.now() - timedelta(days=1)).date().isoformat()
            },
            {
                'amount': 150.00,
                'type': 'expense',
                'description': 'Gas station',
                'category_id': category_ids[1],  # Transportation
                'payment_method': 'debit_card',
                'transaction_date': (datetime.now() - timedelta(days=2)).date().isoformat()
            },
            {
                'amount': 3000.00,
                'type': 'income',
                'description': 'Monthly salary',
                'category_id': category_ids[4],  # Salary
                'payment_method': 'bank_transfer',
                'transaction_date': (datetime.now() - timedelta(days=5)).date().isoformat()
            },
            {
                'amount': 45.00,
                'type': 'expense',
                'description': 'Movie tickets',
                'category_id': category_ids[2],  # Entertainment
                'payment_method': 'debit_card',
                'transaction_date': (datetime.now() - timedelta(days=3)).date().isoformat()
            }
        ]

        for tx in transactions:
            tx['user_id'] = user_id
            transaction_id = TransactionModel.create_transaction(tx)
            print(f"✅ Created transaction: {tx['description']} - ${tx['amount']}")

def create_sample_obligations(user_id):
    """Create sample financial obligations"""
    app = create_app()

    with app.app_context():
        obligations = [
            {
                'name': 'Credit Card Debt',
                'type': 'debt',
                'category': 'credit_card',
                'monthly_amount': 250.00,
                'original_amount': 5000.00,
                'current_balance': 3500.00,
                'interest_rate': 18.5,
                'due_date': 15,
                'minimum_payment': 125.00,
                'payoff_strategy': 'avalanche'
            },
            {
                'name': 'Netflix Subscription',
                'type': 'subscription',
                'category': 'subscription',
                'monthly_amount': 15.99,
                'is_subscription': True,
                'subscription_cycle': 'monthly',
                'due_date': 1
            },
            {
                'name': 'Car Loan',
                'type': 'debt',
                'category': 'car_loan',
                'monthly_amount': 350.00,
                'original_amount': 15000.00,
                'current_balance': 8500.00,
                'interest_rate': 5.5,
                'due_date': 20,
                'minimum_payment': 350.00,
                'payoff_strategy': 'snowball'
            }
        ]

        for obl in obligations:
            obl['user_id'] = user_id
            obligation_id = ObligationModel.create_obligation(obl)
            print(f"✅ Created obligation: {obl['name']} - ${obl['monthly_amount']}/month")

if __name__ == '__main__':
    print("🚀 Creating test data for Financial App API...")

    try:
        # Create test user
        user_id = create_test_user()

        # Create categories
        category_ids = create_sample_categories(user_id)

        # Create transactions
        create_sample_transactions(user_id, category_ids)

        # Create obligations
        create_sample_obligations(user_id)

        print("\n🎉 Test data created successfully!")
        print("\n📋 Test User Credentials:")
        print("Email: test@example.com")
        print("Password: password123")
        print("\n🔗 API Endpoints to test:")
        print("POST /api/v1/auth/login - Login to get JWT token")
        print("GET /api/v1/transactions_232143 - Get transactions")
        print("GET /api/v1/obligations - Get obligations")
        print("GET /api/v1/transactions_232143/analytics/summary - Get analytics")

    except Exception as e:
        print(f"❌ Error creating test data: {e}")
        sys.exit(1)
