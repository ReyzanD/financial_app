import numpy as np
from datetime import datetime, timedelta
from models.transaction_model import TransactionModel

class AnomalyDetector:
    """Service for detecting anomalous transactions and spending patterns"""
    
    @staticmethod
    def detect_fraud(user_id, transactions=None, z_score_threshold=2.5):
        """
        Detect potentially fraudulent transactions using z-score analysis
        
        Args:
            user_id: The user's ID
            transactions: Optional list of transactions (if None, fetches recent)
            z_score_threshold: Z-score threshold for flagging anomalies (default 2.5)
            
        Returns:
            list: List of flagged transactions with anomaly scores
        """
        try:
            if transactions is None:
                # Get last 90 days of transactions
                transactions = TransactionModel.get_recent_transactions(user_id, 90)
            
            if len(transactions) < 5:
                return []  # Need at least 5 transactions for meaningful analysis
            
            # Extract amounts
            amounts = [float(t.get('amount_232143', 0)) for t in transactions]
            
            if not amounts:
                return []
            
            # Calculate mean and standard deviation
            mean = np.mean(amounts)
            std = np.std(amounts)
            
            if std == 0:
                return []  # No variance, can't detect anomalies
            
            # Calculate z-scores
            anomalies = []
            for i, transaction in enumerate(transactions):
                amount = float(transaction.get('amount_232143', 0))
                z_score = abs((amount - mean) / std)
                
                if z_score > z_score_threshold:
                    anomalies.append({
                        'transaction_id': transaction.get('id_232143'),
                        'amount': amount,
                        'z_score': float(z_score),
                        'date': transaction.get('transaction_date_232143'),
                        'description': transaction.get('description_232143'),
                        'category': transaction.get('category_name', 'Unknown'),
                        'severity': 'high' if z_score > 3.5 else 'medium',
                        'reason': f'Amount ({amount:,.0f}) is {z_score:.2f} standard deviations from mean ({mean:,.0f})'
                    })
            
            # Sort by z-score (highest first)
            anomalies.sort(key=lambda x: x['z_score'], reverse=True)
            
            return anomalies
            
        except Exception as e:
            print(f'Error detecting fraud: {e}')
            import traceback
            traceback.print_exc()
            return []
    
    @staticmethod
    def detect_spending_spikes(user_id, days=30):
        """
        Detect sudden spikes in spending by category
        
        Args:
            user_id: The user's ID
            days: Number of days to analyze
            
        Returns:
            list: Categories with detected spikes
        """
        try:
            now = datetime.now()
            start_date = (now - timedelta(days=days)).date()
            
            # Get category spending for the period
            category_spending = TransactionModel.get_category_spending(
                user_id,
                start_date.isoformat(),
                now.date().isoformat()
            )
            
            if len(category_spending) < 2:
                return []
            
            # Calculate average spending per category
            total = sum(float(c.get('total_amount', 0)) for c in category_spending)
            avg_per_category = total / len(category_spending) if category_spending else 0
            
            spikes = []
            for category in category_spending:
                amount = float(category.get('total_amount', 0))
                name = category.get('category_name', 'Unknown')
                
                # Flag if category is 2x the average
                if amount > avg_per_category * 2 and avg_per_category > 0:
                    spikes.append({
                        'category': name,
                        'amount': amount,
                        'average': avg_per_category,
                        'multiplier': amount / avg_per_category if avg_per_category > 0 else 0,
                        'message': f'{name} spending ({amount:,.0f}) is {amount/avg_per_category:.1f}x the average'
                    })
            
            return spikes
            
        except Exception as e:
            print(f'Error detecting spending spikes: {e}')
            return []
    
    @staticmethod
    def flag_anomalies_in_recommendations(user_id):
        """
        Flag anomalies and return them as recommendation-style alerts
        
        Returns:
            list: Anomaly recommendations
        """
        recommendations = []
        
        try:
            # Detect fraud
            fraud_transactions = AnomalyDetector.detect_fraud(user_id)
            for fraud in fraud_transactions[:3]:  # Top 3 anomalies
                recommendations.append({
                    'type': 'warning' if fraud['severity'] == 'medium' else 'danger',
                    'title': f'Transaksi Tidak Biasa: {fraud["category"]}',
                    'message': f'Transaksi Rp {fraud["amount"]:,.0f} pada {fraud["date"]} terdeteksi tidak biasa. {fraud["reason"]}',
                    'priority': 9 if fraud['severity'] == 'high' else 7,
                    'potential_savings': 0,
                    'anomaly_score': fraud['z_score']
                })
            
            # Detect spending spikes
            spikes = AnomalyDetector.detect_spending_spikes(user_id)
            for spike in spikes[:2]:  # Top 2 spikes
                recommendations.append({
                    'type': 'alert',
                    'title': f'Peningkatan Pengeluaran {spike["category"]}',
                    'message': spike['message'],
                    'priority': 6,
                    'potential_savings': spike['amount'] * 0.2,  # Suggest 20% reduction
                })
            
        except Exception as e:
            print(f'Error flagging anomalies: {e}')
        
        return recommendations

