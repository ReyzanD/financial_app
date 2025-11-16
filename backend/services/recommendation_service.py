from datetime import datetime, timedelta
from models.transaction_model import TransactionModel
from models.budget_model import BudgetModel
from models.goal_model import GoalModel

class RecommendationService:
    """Service for generating AI-powered financial recommendations"""
    
    @staticmethod
    def generate_recommendations(user_id, limit=5):
        """
        Generate smart financial recommendations based on comprehensive analysis
        
        Args:
            user_id: The user's ID
            limit: Maximum number of recommendations to return
            
        Returns:
            list: List of recommendation objects with text, type, priority, and data
        """
        try:
            recommendations = []
            
            # 1. Analyze budgets
            budget_recs = RecommendationService._analyze_budgets(user_id)
            recommendations.extend(budget_recs)
            
            # 2. Analyze goals
            goal_recs = RecommendationService._analyze_goals(user_id)
            recommendations.extend(goal_recs)
            
            # 3. Analyze spending trends
            trend_recs = RecommendationService._analyze_trends(user_id)
            recommendations.extend(trend_recs)
            
            # 4. Analyze savings rate
            savings_recs = RecommendationService._analyze_savings(user_id)
            recommendations.extend(savings_recs)
            
            # 5. Detect anomalies
            anomaly_recs = RecommendationService._detect_anomalies(user_id)
            recommendations.extend(anomaly_recs)
            
            # Sort by priority and return top recommendations
            recommendations.sort(key=lambda x: x['priority'], reverse=True)
            
            return recommendations[:limit] if recommendations else [{
                'type': 'info',
                'title': 'Belum Ada Data',
                'message': 'Tambahkan lebih banyak transaksi untuk mendapatkan rekomendasi AI',
                'priority': 1,
                'potential_savings': 0
            }]
            
        except Exception as e:
            print(f'❌ Error generating recommendations: {str(e)}')
            import traceback
            traceback.print_exc()
            return [{
                'type': 'error',
                'title': 'Rekomendasi Tidak Tersedia',
                'message': 'Terjadi kesalahan saat menganalisis data Anda',
                'priority': 1,
                'potential_savings': 0
            }]
    
    @staticmethod
    def _analyze_budgets(user_id):
        """Analyze budget usage and generate alerts"""
        recommendations = []
        try:
            budgets = BudgetModel.get_user_budgets(user_id)
            
            for budget in budgets:
                if not budget.get('is_active_232143'):
                    continue
                    
                limit = float(budget.get('limit_amount_232143', 0))
                spent = float(budget.get('spent_amount_232143', 0))
                category = budget.get('category_name', 'Unknown')
                
                if limit > 0:
                    usage_percent = (spent / limit) * 100
                    
                    if usage_percent >= 90:
                        recommendations.append({
                            'type': 'warning',
                            'title': f'Budget {category} Hampir Habis',
                            'message': f'Anda telah menggunakan {usage_percent:.0f}% dari budget {category}. Sisa Rp {limit - spent:,.0f}.',
                            'priority': 10,
                            'potential_savings': 0
                        })
                    elif usage_percent >= 75:
                        recommendations.append({
                            'type': 'alert',
                            'title': f'Perhatian Budget {category}',
                            'message': f'Budget {category} sudah terpakai {usage_percent:.0f}%. Pertimbangkan mengurangi pengeluaran.',
                            'priority': 7,
                            'potential_savings': 0
                        })
                    elif usage_percent < 50:
                        recommendations.append({
                            'type': 'success',
                            'title': f'Budget {category} Terkendali',
                            'message': f'Bagus! Anda baru menggunakan {usage_percent:.0f}% budget {category}.',
                            'priority': 3,
                            'potential_savings': 0
                        })
        except Exception as e:
            print(f'Error analyzing budgets: {e}')
        
        return recommendations
    
    @staticmethod
    def _analyze_goals(user_id):
        """Analyze financial goals and suggest actions"""
        recommendations = []
        try:
            goals = GoalModel.get_user_goals(user_id)
            
            for goal in goals:
                if goal.get('is_completed_232143'):
                    continue
                    
                target = float(goal.get('target_amount_232143', 0))
                current = float(goal.get('current_amount_232143', 0))
                name = goal.get('name_232143', 'Goal')
                target_date = goal.get('target_date_232143')
                
                if target > 0:
                    progress = (current / target) * 100
                    remaining = target - current
                    
                    # Calculate monthly contribution needed
                    if target_date:
                        days_left = (target_date - datetime.now().date()).days
                        if days_left > 0:
                            months_left = days_left / 30
                            monthly_needed = remaining / months_left if months_left > 0 else remaining
                            
                            if monthly_needed > 0:
                                recommendations.append({
                                    'type': 'goal',
                                    'title': f'Target {name}',
                                    'message': f'Sisihkan Rp {monthly_needed:,.0f}/bulan untuk mencapai target {name} ({progress:.0f}% tercapai).',
                                    'priority': 6,
                                    'potential_savings': 0
                                })
                    
                    if progress < 25:
                        recommendations.append({
                            'type': 'reminder',
                            'title': f'Tingkatkan Tabungan {name}',
                            'message': f'Progress {name} baru {progress:.0f}%. Mulai sisihkan uang secara rutin!',
                            'priority': 5,
                            'potential_savings': 0
                        })
        except Exception as e:
            print(f'Error analyzing goals: {e}')
        
        return recommendations
    
    @staticmethod
    def _analyze_trends(user_id):
        """Analyze spending trends month-over-month"""
        recommendations = []
        try:
            # Compare this month vs last month
            now = datetime.now()
            this_month_start = now.replace(day=1)
            last_month_start = (this_month_start - timedelta(days=1)).replace(day=1)
            
            this_month_summary = TransactionModel.get_monthly_summary(user_id, now.year, now.month)
            last_month_summary = TransactionModel.get_monthly_summary(
                user_id, 
                last_month_start.year, 
                last_month_start.month
            )
            
            this_expenses = sum(float(s.get('total_amount', 0)) for s in this_month_summary if s.get('type_232143') == 'expense')
            last_expenses = sum(float(s.get('total_amount', 0)) for s in last_month_summary if s.get('type_232143') == 'expense')
            
            if last_expenses > 0:
                change_percent = ((this_expenses - last_expenses) / last_expenses) * 100
                
                if change_percent > 20:
                    recommendations.append({
                        'type': 'warning',
                        'title': 'Pengeluaran Meningkat',
                        'message': f'Pengeluaran bulan ini naik {change_percent:.0f}% dibanding bulan lalu. Periksa kategori pengeluaran Anda.',
                        'priority': 8,
                        'potential_savings': this_expenses - last_expenses
                    })
                elif change_percent < -10:
                    recommendations.append({
                        'type': 'success',
                        'title': 'Penghematan Berhasil',
                        'message': f'Hebat! Pengeluaran turun {abs(change_percent):.0f}% bulan ini. Pertahankan!',
                        'priority': 4,
                        'potential_savings': 0
                    })
        except Exception as e:
            print(f'Error analyzing trends: {e}')
        
        return recommendations
    
    @staticmethod
    def _analyze_savings(user_id):
        """Analyze savings rate"""
        recommendations = []
        try:
            transactions = TransactionModel.get_recent_transactions(user_id, 30)
            
            total_income = sum(float(t.get('amount_232143', 0)) for t in transactions if t.get('type_232143') == 'income')
            total_expenses = sum(float(t.get('amount_232143', 0)) for t in transactions if t.get('type_232143') == 'expense')
            
            if total_income > 0:
                savings_rate = ((total_income - total_expenses) / total_income) * 100
                
                if savings_rate < 0:
                    recommendations.append({
                        'type': 'danger',
                        'title': 'Pengeluaran Melebihi Pendapatan',
                        'message': 'Pendapatan Anda tidak cukup menutupi pengeluaran. Segera kurangi pengeluaran tidak penting!',
                        'priority': 10,
                        'potential_savings': abs(total_income - total_expenses)
                    })
                elif savings_rate < 10:
                    target_savings = total_income * 0.2
                    recommendations.append({
                        'type': 'warning',
                        'title': 'Tingkat Tabungan Rendah',
                        'message': f'Tabungan Anda hanya {savings_rate:.1f}%. Target minimal 20%. Coba hemat Rp {target_savings - (total_income - total_expenses):,.0f}.',
                        'priority': 7,
                        'potential_savings': target_savings - (total_income - total_expenses)
                    })
                elif savings_rate >= 30:
                    recommendations.append({
                        'type': 'success',
                        'title': 'Tabungan Luar Biasa',
                        'message': f'Tingkat tabungan {savings_rate:.1f}%! Pertimbangkan investasi untuk mengembangkan uang Anda.',
                        'priority': 2,
                        'potential_savings': 0
                    })
        except Exception as e:
            print(f'Error analyzing savings: {e}')
        
        return recommendations
    
    @staticmethod
    def _detect_anomalies(user_id):
        """Detect unusual spending patterns"""
        recommendations = []
        try:
            # Get category spending for this month
            now = datetime.now()
            category_spending = TransactionModel.get_category_spending(
                user_id,
                now.replace(day=1).date().isoformat(),
                now.date().isoformat()
            )
            
            total = sum(float(c.get('total_amount', 0)) for c in category_spending)
            
            if total > 0:
                for category in category_spending:
                    amount = float(category.get('total_amount', 0))
                    name = category.get('category_name', 'Unknown')
                    percentage = (amount / total) * 100
                    
                    # Alert if one category is >50% of spending
                    if percentage > 50:
                        recommendations.append({
                            'type': 'alert',
                            'title': f'Dominasi {name}',
                            'message': f'{name} menghabiskan {percentage:.0f}% total pengeluaran. Diversifikasi pengeluaran Anda.',
                            'priority': 6,
                            'potential_savings': amount * 0.3
                        })
        except Exception as e:
            print(f'Error detecting anomalies: {e}')
        
        return recommendations