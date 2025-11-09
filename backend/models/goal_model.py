from .database import get_db
import uuid
from datetime import datetime, date, timedelta
from decimal import Decimal

class GoalModel:
    @staticmethod
    def get_user_goals(user_id, include_completed=False):
        """Get all goals for a user"""
        db = get_db()
        with db.cursor() as cursor:
            if include_completed:
                sql = """
                SELECT 
                    goal_id_232143,
                    user_id_232143,
                    name_232143,
                    description_232143,
                    goal_type_232143,
                    target_amount_232143,
                    current_amount_232143,
                    start_date_232143,
                    target_date_232143,
                    is_completed_232143,
                    completed_date_232143,
                    priority_232143,
                    monthly_target_232143,
                    auto_deduct_232143,
                    deduct_percentage_232143,
                    recommended_monthly_saving_232143,
                    feasibility_score_232143,
                    progress_percentage_232143,
                    created_at_232143,
                    updated_at_232143
                FROM financial_goals_232143 
                WHERE user_id_232143 = %s
                ORDER BY priority_232143 DESC, target_date_232143 ASC
                """
            else:
                sql = """
                SELECT 
                    goal_id_232143,
                    user_id_232143,
                    name_232143,
                    description_232143,
                    goal_type_232143,
                    target_amount_232143,
                    current_amount_232143,
                    start_date_232143,
                    target_date_232143,
                    is_completed_232143,
                    completed_date_232143,
                    priority_232143,
                    monthly_target_232143,
                    auto_deduct_232143,
                    deduct_percentage_232143,
                    recommended_monthly_saving_232143,
                    feasibility_score_232143,
                    progress_percentage_232143,
                    created_at_232143,
                    updated_at_232143
                FROM financial_goals_232143 
                WHERE user_id_232143 = %s AND is_completed_232143 = 0
                ORDER BY priority_232143 DESC, target_date_232143 ASC
                """
            cursor.execute(sql, (user_id,))
            return cursor.fetchall()
        
    @staticmethod
    def get_goal_by_id(goal_id, user_id):
        """Get a specific goal by ID"""
        db = get_db()
        with db.cursor() as cursor:
            sql = """
            SELECT 
                goal_id_232143,
                user_id_232143,
                name_232143,
                description_232143,
                goal_type_232143,
                target_amount_232143,
                current_amount_232143,
                start_date_232143,
                target_date_232143,
                is_completed_232143,
                completed_date_232143,
                priority_232143,
                monthly_target_232143,
                auto_deduct_232143,
                deduct_percentage_232143,
                recommended_monthly_saving_232143,
                feasibility_score_232143,
                progress_percentage_232143,
                created_at_232143,
                updated_at_232143
            FROM financial_goals_232143 
            WHERE goal_id_232143 = %s AND user_id_232143 = %s
            """
            cursor.execute(sql, (goal_id, user_id))
            return cursor.fetchone()
        
    @staticmethod
    def create_goal(goal_data):
        """Create a new goal"""
        db = get_db()
        with db.cursor() as cursor:
            goal_id = str(uuid.uuid4())
            
            # Calculate recommended monthly saving 
            
            target_amount = Decimal(str(goal_data['target_amount']))
            start_date = goal_data.get('start_date')
            target_date = goal_data['target_date']

            #parse dates if they're strings or set default if None
            if start_date is None:
                start_date = date.today()
            elif isinstance(start_date, str):
                start_date = datetime.strptime(start_date, '%Y-%m-%d').date()
            
            if isinstance(target_date, str):
                target_date = datetime.strptime(target_date, '%Y-%m-%d').date()
                
            #calculate months between dates
            months_to_target = max(1, ((target_date.year - start_date.year) * 12 + target_date.month - start_date.month))
            recommended_monthly = target_amount / Decimal(str(months_to_target))

            sql = """
            INSERT INTO financial_goals_232143 (
                goal_id_232143,
                user_id_232143,
                name_232143,
                description_232143,
                goal_type_232143,
                target_amount_232143,
                current_amount_232143,
                start_date_232143,
                target_date_232143,
                priority_232143,
                monthly_target_232143,
                auto_deduct_232143,
                deduct_percentage_232143,
                recommended_monthly_saving_232143
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """
            cursor.execute(sql, (
                goal_id,
                goal_data['user_id'],
                goal_data['name'],
                goal_data.get('description'),
                goal_data['goal_type'],
                target_amount,
                goal_data.get('current_amount', 0),
                start_date,
                target_date,
                goal_data.get('priority', 3),
                goal_data.get('monthly_target', recommended_monthly),
                goal_data.get('auto_deduct', False),
                goal_data.get('deduct_percentage'),
                recommended_monthly
            ))
            db.commit()
            return goal_id
            
    @staticmethod
    def update_goal(goal_id, user_id, updated_data):
            """Update an existing goal"""
            db = get_db()
            with db.cursor() as cursor:
                #Build dynamic update query
                set_clauses = []
                values = []

                for field, value in updated_data.items():
                    set_clauses.append(f"{field} = %s")
                    values.append(value)

                if not set_clauses:
                    return False

                values.extend([goal_id, user_id])

                sql = f"""
                UPDATE financial_goals_232143
                SET {', '.join(set_clauses)}
                WHERE goal_id_232143 = %s AND user_id_232143 = %s
                """
                cursor.execute(sql, values)
                db.commit()
                return cursor.rowcount > 0

    @staticmethod
    def delete_goal(goal_id,user_id):
            """Delete a goal"""
            db = get_db()
            with db.cursor() as cursor:
                sql = """
                DELETE FROM financial_goals_232143
                WHERE goal_id_232143 = %s AND user_id_232143 = %s
                """
                cursor.execute(sql, (goal_id, user_id))
                db.commit()
                return cursor.rowcount > 0

    @staticmethod
    def add_contribution(goal_id, user_id, amount):
        """Add money to a goal, create transaction, and check if it's completed"""
        from .transaction_model import TransactionModel
        import uuid
        
        db = get_db()
        with db.cursor() as cursor:
            # Get current goal details
            goal = GoalModel.get_goal_by_id(goal_id, user_id)
            if not goal:
                return None

            new_amount = Decimal(str(goal['current_amount_232143'])) + Decimal(str(amount))
            target_amount = Decimal(str(goal['target_amount_232143']))
            goal_name = goal['name_232143']

            # Check if goal is now completed
            is_completed = new_amount >= target_amount
            completed_date = date.today() if is_completed else None

            # Update goal
            sql = """
            UPDATE financial_goals_232143
            SET current_amount_232143 = %s,
                is_completed_232143 = %s,
                completed_date_232143 = %s
            WHERE goal_id_232143 = %s AND user_id_232143 = %s
            """
            
            cursor.execute(sql, (
                new_amount,
                is_completed,
                completed_date,
                goal_id,
                user_id
            ))
            
            # Create transaction (expense) for the contribution
            # This will decrease the balance
            transaction_data = {
                'user_id': user_id,
                'amount': float(amount),
                'type': 'expense',  # Expense type to decrease balance
                'description': f'Kontribusi ke Goal: {goal_name}',
                'category_id': None,  # Will show as "Goal Savings" in frontend
                'payment_method': 'cash',  # Standard payment method
                'transaction_date': date.today().isoformat()
            }
            
            try:
                transaction_id = TransactionModel.create_transaction(transaction_data)
                print(f"✅ Created transaction {transaction_id} for goal contribution")
            except Exception as e:
                print(f"⚠️ Failed to create transaction for goal: {e}")
                # Continue even if transaction creation fails
            
            db.commit()
            
            return {
                'new_amount': float(new_amount),
                'is_completed': is_completed,
                'progress_percentage': float((new_amount / target_amount) * 100) if target_amount > 0 else 0,
                'transaction_created': True,
                'balance_decreased': float(amount)
            }
        
    @staticmethod
    def get_goals_summary(user_id):
        """Get summary statistics for user's goals"""
        db = get_db()
        with db.cursor() as cursor:
            sql = """
            SELECT 
                COUNT(*) as total_goals,
                SUM(CASE WHEN is_completed_232143 = 1 THEN 1 ELSE 0 END) as completed_goals,
                SUM(target_amount_232143) as total_target,
                SUM(current_amount_232143) as total_saved,
                AVG(progress_percentage_232143) as avg_progress
            FROM financial_goals_232143
            WHERE user_id_232143 = %s
            """
            cursor.execute(sql, (user_id,))
            return cursor.fetchone()