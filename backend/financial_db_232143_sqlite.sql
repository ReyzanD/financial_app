-- SQLite Database Schema for Financial App
-- Converted from PostgreSQL for local development
-- 
-- IMPORTANT: 
-- 1. UUIDs are generated in Python code (no DEFAULT in SQL)
-- 2. JSONB fields are stored as TEXT (use json.dumps/loads in Python)
-- 3. GENERATED ALWAYS AS columns are computed via triggers or Python
-- 4. Run this script via init_sqlite_db.py

-- ============================================================
-- Table: users_232143
-- ============================================================
CREATE TABLE IF NOT EXISTS users_232143 (
  user_id_232143 VARCHAR(36) NOT NULL,
  email_232143 VARCHAR(255) NOT NULL UNIQUE,
  password_hash_232143 VARCHAR(255) NOT NULL,
  full_name_232143 VARCHAR(255) NOT NULL,
  phone_number_232143 VARCHAR(20) DEFAULT NULL,
  date_of_birth_232143 DATE DEFAULT NULL,
  occupation_232143 VARCHAR(100) DEFAULT NULL,
  income_range_232143 VARCHAR(20) DEFAULT NULL CHECK (income_range_232143 IN ('0-3jt','3-5jt','5-10jt','10-20jt','20jt+')),
  family_size_232143 INTEGER DEFAULT 1,
  currency_232143 VARCHAR(10) DEFAULT 'IDR',
  base_location_232143 TEXT DEFAULT NULL,
  financial_goals_232143 TEXT DEFAULT '{"emergency_fund": 0, "vacation": 0, "investment": 0, "debt_payment": 0}',
  risk_tolerance_232143 INTEGER DEFAULT 3,
  notification_settings_232143 TEXT DEFAULT '{"budget_alerts": true, "goal_reminders": true, "spending_insights": true, "push_notifications": true}',
  created_at_232143 TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at_232143 TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  last_login_232143 TIMESTAMP DEFAULT NULL,
  is_active_232143 BOOLEAN DEFAULT 1,
  PRIMARY KEY (user_id_232143)
);

-- ============================================================
-- Table: categories_232143
-- ============================================================
CREATE TABLE IF NOT EXISTS categories_232143 (
  category_id_232143 VARCHAR(36) NOT NULL,
  user_id_232143 VARCHAR(36) DEFAULT NULL,
  name_232143 VARCHAR(100) NOT NULL,
  type_232143 VARCHAR(20) NOT NULL CHECK (type_232143 IN ('income','expense','transfer')),
  color_232143 VARCHAR(7) DEFAULT '#3498db',
  icon_232143 VARCHAR(50) DEFAULT 'receipt',
  budget_limit_232143 DECIMAL(15,2) DEFAULT NULL,
  budget_period_232143 VARCHAR(20) DEFAULT 'monthly' CHECK (budget_period_232143 IN ('daily','weekly','monthly','yearly')),
  is_fixed_232143 BOOLEAN DEFAULT 0,
  keywords_232143 TEXT DEFAULT NULL,
  location_patterns_232143 TEXT DEFAULT NULL,
  parent_category_id_232143 VARCHAR(36) DEFAULT NULL,
  display_order_232143 INTEGER DEFAULT 0,
  is_system_default_232143 BOOLEAN DEFAULT 0,
  created_at_232143 TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at_232143 TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (category_id_232143),
  FOREIGN KEY (user_id_232143) REFERENCES users_232143(user_id_232143) ON DELETE CASCADE,
  FOREIGN KEY (parent_category_id_232143) REFERENCES categories_232143(category_id_232143)
);

-- ============================================================
-- Table: transactions_232143
-- ============================================================
CREATE TABLE IF NOT EXISTS transactions_232143 (
  transaction_id_232143 VARCHAR(36) NOT NULL,
  user_id_232143 VARCHAR(36) NOT NULL,
  amount_232143 DECIMAL(15,2) NOT NULL,
  type_232143 VARCHAR(20) NOT NULL CHECK (type_232143 IN ('income','expense','transfer')),
  category_id_232143 VARCHAR(36) DEFAULT NULL,
  description_232143 VARCHAR(500) NOT NULL,
  location_name_232143 TEXT DEFAULT NULL,
  latitude_232143 DECIMAL(10,8) DEFAULT NULL,
  longitude_232143 DECIMAL(11,8) DEFAULT NULL,
  location_data_232143 TEXT DEFAULT NULL,
  payment_method_232143 VARCHAR(20) DEFAULT 'cash' CHECK (payment_method_232143 IN ('cash','debit_card','credit_card','e_wallet','bank_transfer')),
  receipt_image_url_232143 VARCHAR(500) DEFAULT NULL,
  is_recurring_232143 BOOLEAN DEFAULT 0,
  recurring_pattern_232143 TEXT DEFAULT NULL,
  predicted_category_id_232143 VARCHAR(36) DEFAULT NULL,
  confidence_score_232143 DECIMAL(3,2) DEFAULT NULL,
  is_verified_232143 BOOLEAN DEFAULT 1,
  tags_232143 TEXT DEFAULT NULL,
  transaction_date_232143 DATE NOT NULL,
  transaction_time_232143 TIME DEFAULT NULL,
  created_at_232143 TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at_232143 TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (transaction_id_232143),
  FOREIGN KEY (user_id_232143) REFERENCES users_232143(user_id_232143) ON DELETE CASCADE,
  FOREIGN KEY (category_id_232143) REFERENCES categories_232143(category_id_232143),
  FOREIGN KEY (predicted_category_id_232143) REFERENCES categories_232143(category_id_232143)
);

-- ============================================================
-- Table: budgets_232143
-- ============================================================
CREATE TABLE IF NOT EXISTS budgets_232143 (
  budget_id_232143 VARCHAR(36) NOT NULL,
  user_id_232143 VARCHAR(36) NOT NULL,
  category_id_232143 VARCHAR(36) DEFAULT NULL,
  amount_232143 DECIMAL(15,2) NOT NULL,
  period_232143 VARCHAR(20) NOT NULL CHECK (period_232143 IN ('daily','weekly','monthly','yearly')),
  period_start_232143 DATE NOT NULL,
  period_end_232143 DATE NOT NULL,
  spent_amount_232143 DECIMAL(15,2) DEFAULT 0.00,
  rollover_enabled_232143 BOOLEAN DEFAULT 0,
  alert_threshold_232143 INTEGER DEFAULT 80,
  is_active_232143 BOOLEAN DEFAULT 1,
  recommended_amount_232143 DECIMAL(15,2) DEFAULT NULL,
  recommendation_reason_232143 TEXT,
  created_at_232143 TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at_232143 TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  remaining_amount_232143 DECIMAL(15,2) DEFAULT 0.00,
  PRIMARY KEY (budget_id_232143),
  FOREIGN KEY (user_id_232143) REFERENCES users_232143(user_id_232143) ON DELETE CASCADE,
  FOREIGN KEY (category_id_232143) REFERENCES categories_232143(category_id_232143)
);

-- ============================================================
-- Table: financial_goals_232143
-- ============================================================
CREATE TABLE IF NOT EXISTS financial_goals_232143 (
  goal_id_232143 VARCHAR(36) NOT NULL,
  user_id_232143 VARCHAR(36) NOT NULL,
  name_232143 VARCHAR(255) NOT NULL,
  description_232143 TEXT,
  goal_type_232143 VARCHAR(50) NOT NULL CHECK (goal_type_232143 IN ('emergency_fund','vacation','investment','debt_payment','education','vehicle','house','wedding','other')),
  target_amount_232143 DECIMAL(15,2) NOT NULL,
  current_amount_232143 DECIMAL(15,2) DEFAULT 0.00,
  start_date_232143 DATE DEFAULT CURRENT_DATE,
  target_date_232143 DATE NOT NULL,
  is_completed_232143 BOOLEAN DEFAULT 0,
  completed_date_232143 DATE DEFAULT NULL,
  priority_232143 INTEGER DEFAULT 3,
  monthly_target_232143 DECIMAL(15,2) DEFAULT NULL,
  auto_deduct_232143 BOOLEAN DEFAULT 0,
  deduct_percentage_232143 DECIMAL(5,2) DEFAULT NULL,
  recommended_monthly_saving_232143 DECIMAL(15,2) DEFAULT NULL,
  feasibility_score_232143 DECIMAL(3,2) DEFAULT NULL,
  created_at_232143 TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at_232143 TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  progress_percentage_232143 DECIMAL(5,2) DEFAULT 0.00,
  PRIMARY KEY (goal_id_232143),
  FOREIGN KEY (user_id_232143) REFERENCES users_232143(user_id_232143) ON DELETE CASCADE
);

-- ============================================================
-- Table: financial_obligations_232143
-- ============================================================
CREATE TABLE IF NOT EXISTS financial_obligations_232143 (
  obligation_id_232143 VARCHAR(36) NOT NULL,
  user_id_232143 VARCHAR(36) NOT NULL,
  name_232143 VARCHAR(255) NOT NULL,
  type_232143 VARCHAR(20) NOT NULL CHECK (type_232143 IN ('bill','debt','subscription')),
  category_232143 VARCHAR(50) NOT NULL CHECK (category_232143 IN ('utility','internet','phone','insurance','credit_card','personal_loan','mortgage','car_loan','student_loan','subscription','other')),
  original_amount_232143 DECIMAL(15,2) DEFAULT NULL,
  current_balance_232143 DECIMAL(15,2) DEFAULT NULL,
  monthly_amount_232143 DECIMAL(15,2) NOT NULL,
  due_date_232143 INTEGER DEFAULT NULL,
  start_date_232143 DATE DEFAULT NULL,
  end_date_232143 DATE DEFAULT NULL,
  next_payment_date_232143 DATE DEFAULT NULL,
  interest_rate_232143 DECIMAL(5,2) DEFAULT NULL,
  minimum_payment_232143 DECIMAL(15,2) DEFAULT NULL,
  payoff_strategy_232143 VARCHAR(20) DEFAULT NULL CHECK (payoff_strategy_232143 IN ('snowball','avalanche','minimum')),
  is_auto_pay_232143 BOOLEAN DEFAULT 0,
  is_subscription_232143 BOOLEAN DEFAULT 0,
  subscription_cycle_232143 VARCHAR(20) DEFAULT NULL CHECK (subscription_cycle_232143 IN ('monthly','quarterly','yearly')),
  status_232143 VARCHAR(20) DEFAULT 'active' CHECK (status_232143 IN ('active','paid_off','cancelled','overdue')),
  priority_232143 VARCHAR(20) DEFAULT 'medium' CHECK (priority_232143 IN ('high','medium','low')),
  reminder_days_before_232143 INTEGER DEFAULT 3,
  created_at_232143 TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at_232143 TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (obligation_id_232143),
  FOREIGN KEY (user_id_232143) REFERENCES users_232143(user_id_232143) ON DELETE CASCADE
);

-- ============================================================
-- Table: obligation_payments_232143
-- ============================================================
CREATE TABLE IF NOT EXISTS obligation_payments_232143 (
  payment_id_232143 VARCHAR(36) NOT NULL,
  obligation_id_232143 VARCHAR(36) NOT NULL,
  user_id_232143 VARCHAR(36) NOT NULL,
  amount_paid_232143 DECIMAL(15,2) NOT NULL,
  payment_date_232143 DATE NOT NULL,
  payment_method_232143 VARCHAR(50) DEFAULT NULL,
  principal_paid_232143 DECIMAL(15,2) DEFAULT NULL,
  interest_paid_232143 DECIMAL(15,2) DEFAULT NULL,
  transaction_id_232143 VARCHAR(36) DEFAULT NULL,
  status_232143 VARCHAR(20) DEFAULT 'completed' CHECK (status_232143 IN ('completed','pending','failed')),
  created_at_232143 TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (payment_id_232143),
  FOREIGN KEY (obligation_id_232143) REFERENCES financial_obligations_232143(obligation_id_232143),
  FOREIGN KEY (user_id_232143) REFERENCES users_232143(user_id_232143),
  FOREIGN KEY (transaction_id_232143) REFERENCES transactions_232143(transaction_id_232143)
);

-- ============================================================
-- Table: ai_recommendations_232143
-- ============================================================
CREATE TABLE IF NOT EXISTS ai_recommendations_232143 (
  recommendation_id_232143 VARCHAR(36) NOT NULL,
  user_id_232143 VARCHAR(36) NOT NULL,
  type_232143 VARCHAR(50) NOT NULL CHECK (type_232143 IN ('budget_optimization','saving_opportunity','spending_alert','investment_suggestion','debt_management','location_saving')),
  title_232143 VARCHAR(255) NOT NULL,
  description_232143 TEXT NOT NULL,
  action_items_232143 TEXT DEFAULT NULL,
  estimated_savings_232143 DECIMAL(15,2) DEFAULT NULL,
  impact_score_232143 INTEGER DEFAULT NULL,
  urgency_232143 VARCHAR(20) DEFAULT 'medium' CHECK (urgency_232143 IN ('low','medium','high','critical')),
  related_categories_232143 TEXT DEFAULT NULL,
  related_locations_232143 TEXT DEFAULT NULL,
  data_sources_232143 TEXT DEFAULT NULL,
  is_read_232143 BOOLEAN DEFAULT 0,
  is_applied_232143 BOOLEAN DEFAULT 0,
  applied_date_232143 TIMESTAMP DEFAULT NULL,
  user_feedback_232143 INTEGER DEFAULT NULL,
  model_version_232143 VARCHAR(50) DEFAULT NULL,
  confidence_score_232143 DECIMAL(3,2) DEFAULT NULL,
  created_at_232143 TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  expires_at_232143 TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (recommendation_id_232143),
  FOREIGN KEY (user_id_232143) REFERENCES users_232143(user_id_232143) ON DELETE CASCADE
);

-- ============================================================
-- Table: notifications_232143
-- ============================================================
CREATE TABLE IF NOT EXISTS notifications_232143 (
  notification_id_232143 VARCHAR(36) NOT NULL,
  user_id_232143 VARCHAR(36) NOT NULL,
  type_232143 VARCHAR(50) NOT NULL CHECK (type_232143 IN ('budget_alert','goal_progress','bill_reminder','spending_insight','system_announcement','security_alert')),
  title_232143 VARCHAR(255) NOT NULL,
  message_232143 TEXT NOT NULL,
  action_url_232143 VARCHAR(500) DEFAULT NULL,
  action_label_232143 VARCHAR(100) DEFAULT NULL,
  is_read_232143 BOOLEAN DEFAULT 0,
  is_sent_232143 BOOLEAN DEFAULT 0,
  sent_at_232143 TIMESTAMP DEFAULT NULL,
  read_at_232143 TIMESTAMP DEFAULT NULL,
  priority_232143 VARCHAR(20) DEFAULT 'normal' CHECK (priority_232143 IN ('low','normal','high')),
  category_232143 VARCHAR(100) DEFAULT NULL,
  created_at_232143 TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (notification_id_232143),
  FOREIGN KEY (user_id_232143) REFERENCES users_232143(user_id_232143) ON DELETE CASCADE
);

-- ============================================================
-- Table: location_intelligence_232143
-- ============================================================
CREATE TABLE IF NOT EXISTS location_intelligence_232143 (
  location_id_232143 VARCHAR(36) NOT NULL,
  latitude_232143 DECIMAL(10,8) NOT NULL,
  longitude_232143 DECIMAL(11,8) NOT NULL,
  place_name_232143 VARCHAR(255) NOT NULL,
  place_type_232143 VARCHAR(100) NOT NULL,
  address_232143 TEXT,
  city_232143 VARCHAR(100) DEFAULT NULL,
  country_232143 VARCHAR(100) DEFAULT 'Indonesia',
  average_prices_232143 TEXT NOT NULL,
  price_ranges_232143 TEXT DEFAULT NULL,
  user_rating_232143 DECIMAL(3,2) DEFAULT NULL,
  popularity_score_232143 INTEGER DEFAULT 0,
  total_reviews_232143 INTEGER DEFAULT 0,
  opening_hours_232143 TEXT DEFAULT NULL,
  price_level_232143 INTEGER DEFAULT NULL,
  total_transactions_232143 INTEGER DEFAULT 0,
  last_updated_232143 TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  data_confidence_232143 DECIMAL(3,2) DEFAULT 0.70,
  created_at_232143 TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (location_id_232143)
);

-- ============================================================
-- Table: spending_patterns_232143
-- ============================================================
CREATE TABLE IF NOT EXISTS spending_patterns_232143 (
  pattern_id_232143 VARCHAR(36) NOT NULL,
  user_id_232143 VARCHAR(36) NOT NULL,
  pattern_type_232143 VARCHAR(50) NOT NULL CHECK (pattern_type_232143 IN ('weekly','monthly','seasonal','location_based','category_based')),
  category_id_232143 VARCHAR(36) DEFAULT NULL,
  location_id_232143 VARCHAR(36) DEFAULT NULL,
  pattern_data_232143 TEXT NOT NULL,
  average_amount_232143 DECIMAL(15,2) NOT NULL,
  frequency_per_month_232143 DECIMAL(5,2) DEFAULT NULL,
  total_occurrences_232143 INTEGER DEFAULT 0,
  last_occurrence_232143 DATE DEFAULT NULL,
  confidence_score_232143 DECIMAL(3,2) DEFAULT NULL,
  is_active_232143 BOOLEAN DEFAULT 1,
  detected_at_232143 TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  model_version_232143 VARCHAR(50) DEFAULT NULL,
  created_at_232143 TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at_232143 TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (pattern_id_232143),
  FOREIGN KEY (user_id_232143) REFERENCES users_232143(user_id_232143) ON DELETE CASCADE,
  FOREIGN KEY (category_id_232143) REFERENCES categories_232143(category_id_232143),
  FOREIGN KEY (location_id_232143) REFERENCES location_intelligence_232143(location_id_232143)
);

-- ============================================================
-- Table: bill_payments_232143
-- ============================================================
CREATE TABLE IF NOT EXISTS bill_payments_232143 (
  payment_id_232143 VARCHAR(36) NOT NULL,
  bill_id_232143 VARCHAR(36) NOT NULL,
  user_id_232143 VARCHAR(36) NOT NULL,
  amount_paid_232143 DECIMAL(15,2) NOT NULL,
  payment_date_232143 DATE NOT NULL,
  payment_method_232143 VARCHAR(50) DEFAULT NULL,
  transaction_id_232143 VARCHAR(36) DEFAULT NULL,
  status_232143 VARCHAR(20) DEFAULT 'paid' CHECK (status_232143 IN ('paid','pending','failed')),
  created_at_232143 TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (payment_id_232143)
);

-- ============================================================
-- Indexes
-- ============================================================

-- users_232143 indexes
CREATE INDEX IF NOT EXISTS idx_users_email_232143 ON users_232143(email_232143);
CREATE INDEX IF NOT EXISTS idx_users_created_at_232143 ON users_232143(created_at_232143);
CREATE INDEX IF NOT EXISTS idx_users_active_232143 ON users_232143(is_active_232143);

-- categories_232143 indexes
CREATE INDEX IF NOT EXISTS idx_categories_parent_232143 ON categories_232143(parent_category_id_232143);
CREATE INDEX IF NOT EXISTS idx_categories_user_id_232143 ON categories_232143(user_id_232143);
CREATE INDEX IF NOT EXISTS idx_categories_type_232143 ON categories_232143(type_232143);
CREATE INDEX IF NOT EXISTS idx_categories_system_232143 ON categories_232143(is_system_default_232143);

-- transactions_232143 indexes
CREATE INDEX IF NOT EXISTS idx_transactions_user_id_232143 ON transactions_232143(user_id_232143);
CREATE INDEX IF NOT EXISTS idx_transactions_date_232143 ON transactions_232143(transaction_date_232143);
CREATE INDEX IF NOT EXISTS idx_transactions_category_232143 ON transactions_232143(category_id_232143);
CREATE INDEX IF NOT EXISTS idx_transactions_type_232143 ON transactions_232143(type_232143);
CREATE INDEX IF NOT EXISTS idx_transactions_recurring_232143 ON transactions_232143(is_recurring_232143);
CREATE INDEX IF NOT EXISTS idx_transactions_created_232143 ON transactions_232143(created_at_232143);
CREATE INDEX IF NOT EXISTS idx_transaction_date_user ON transactions_232143(user_id_232143, transaction_date_232143);
CREATE INDEX IF NOT EXISTS idx_type_date ON transactions_232143(type_232143, transaction_date_232143);
CREATE INDEX IF NOT EXISTS idx_transactions_predicted_category_232143 ON transactions_232143(predicted_category_id_232143);

-- budgets_232143 indexes
CREATE INDEX IF NOT EXISTS idx_budgets_user_id_232143 ON budgets_232143(user_id_232143);
CREATE INDEX IF NOT EXISTS idx_budgets_period_232143 ON budgets_232143(period_start_232143, period_end_232143);
CREATE INDEX IF NOT EXISTS idx_budgets_active_232143 ON budgets_232143(is_active_232143);
CREATE INDEX IF NOT EXISTS idx_budgets_category_232143 ON budgets_232143(category_id_232143);

-- financial_goals_232143 indexes
CREATE INDEX IF NOT EXISTS idx_goals_user_id_232143 ON financial_goals_232143(user_id_232143);
CREATE INDEX IF NOT EXISTS idx_goals_target_date_232143 ON financial_goals_232143(target_date_232143);
CREATE INDEX IF NOT EXISTS idx_goals_completed_232143 ON financial_goals_232143(is_completed_232143);
CREATE INDEX IF NOT EXISTS idx_goals_type_232143 ON financial_goals_232143(goal_type_232143);

-- financial_obligations_232143 indexes
CREATE INDEX IF NOT EXISTS idx_obligations_user_232143 ON financial_obligations_232143(user_id_232143);

-- obligation_payments_232143 indexes
CREATE INDEX IF NOT EXISTS idx_obligation_payments_obligation_232143 ON obligation_payments_232143(obligation_id_232143);
CREATE INDEX IF NOT EXISTS idx_obligation_payments_user_232143 ON obligation_payments_232143(user_id_232143);
CREATE INDEX IF NOT EXISTS idx_obligation_payments_transaction_232143 ON obligation_payments_232143(transaction_id_232143);

-- ai_recommendations_232143 indexes
CREATE INDEX IF NOT EXISTS idx_recommendations_user_232143 ON ai_recommendations_232143(user_id_232143);
CREATE INDEX IF NOT EXISTS idx_recommendations_type_232143 ON ai_recommendations_232143(type_232143);
CREATE INDEX IF NOT EXISTS idx_recommendations_urgency_232143 ON ai_recommendations_232143(urgency_232143);
CREATE INDEX IF NOT EXISTS idx_recommendations_unread_232143 ON ai_recommendations_232143(is_read_232143);
CREATE INDEX IF NOT EXISTS idx_recommendations_created_232143 ON ai_recommendations_232143(created_at_232143);

-- notifications_232143 indexes
CREATE INDEX IF NOT EXISTS idx_notifications_user_232143 ON notifications_232143(user_id_232143);
CREATE INDEX IF NOT EXISTS idx_notifications_type_232143 ON notifications_232143(type_232143);
CREATE INDEX IF NOT EXISTS idx_notifications_unread_232143 ON notifications_232143(is_read_232143);
CREATE INDEX IF NOT EXISTS idx_notifications_created_232143 ON notifications_232143(created_at_232143);
CREATE INDEX IF NOT EXISTS idx_notifications_priority_232143 ON notifications_232143(priority_232143);

-- location_intelligence_232143 indexes
CREATE INDEX IF NOT EXISTS idx_location_coords_232143 ON location_intelligence_232143(latitude_232143, longitude_232143);
CREATE INDEX IF NOT EXISTS idx_location_type_232143 ON location_intelligence_232143(place_type_232143);
CREATE INDEX IF NOT EXISTS idx_location_city_232143 ON location_intelligence_232143(city_232143);
CREATE INDEX IF NOT EXISTS idx_location_confidence_232143 ON location_intelligence_232143(data_confidence_232143);

-- spending_patterns_232143 indexes
CREATE INDEX IF NOT EXISTS idx_patterns_location_232143 ON spending_patterns_232143(location_id_232143);
CREATE INDEX IF NOT EXISTS idx_patterns_user_232143 ON spending_patterns_232143(user_id_232143);
CREATE INDEX IF NOT EXISTS idx_patterns_type_232143 ON spending_patterns_232143(pattern_type_232143);
CREATE INDEX IF NOT EXISTS idx_patterns_active_232143 ON spending_patterns_232143(is_active_232143);
CREATE INDEX IF NOT EXISTS idx_patterns_category_232143 ON spending_patterns_232143(category_id_232143);

-- bill_payments_232143 indexes
CREATE INDEX IF NOT EXISTS idx_bill_payments_bill_232143 ON bill_payments_232143(bill_id_232143);
CREATE INDEX IF NOT EXISTS idx_bill_payments_user_232143 ON bill_payments_232143(user_id_232143);
CREATE INDEX IF NOT EXISTS idx_bill_payments_transaction_232143 ON bill_payments_232143(transaction_id_232143);

-- ============================================================
-- Triggers for updated_at columns
-- ============================================================

CREATE TRIGGER IF NOT EXISTS update_budgets_updated_at 
    AFTER UPDATE ON budgets_232143
    FOR EACH ROW
    BEGIN
        UPDATE budgets_232143 
        SET updated_at_232143 = CURRENT_TIMESTAMP 
        WHERE budget_id_232143 = NEW.budget_id_232143;
    END;

CREATE TRIGGER IF NOT EXISTS update_categories_updated_at 
    AFTER UPDATE ON categories_232143
    FOR EACH ROW
    BEGIN
        UPDATE categories_232143 
        SET updated_at_232143 = CURRENT_TIMESTAMP 
        WHERE category_id_232143 = NEW.category_id_232143;
    END;

CREATE TRIGGER IF NOT EXISTS update_financial_goals_updated_at 
    AFTER UPDATE ON financial_goals_232143
    FOR EACH ROW
    BEGIN
        UPDATE financial_goals_232143 
        SET updated_at_232143 = CURRENT_TIMESTAMP 
        WHERE goal_id_232143 = NEW.goal_id_232143;
    END;

CREATE TRIGGER IF NOT EXISTS update_financial_obligations_updated_at 
    AFTER UPDATE ON financial_obligations_232143
    FOR EACH ROW
    BEGIN
        UPDATE financial_obligations_232143 
        SET updated_at_232143 = CURRENT_TIMESTAMP 
        WHERE obligation_id_232143 = NEW.obligation_id_232143;
    END;

CREATE TRIGGER IF NOT EXISTS update_spending_patterns_updated_at 
    AFTER UPDATE ON spending_patterns_232143
    FOR EACH ROW
    BEGIN
        UPDATE spending_patterns_232143 
        SET updated_at_232143 = CURRENT_TIMESTAMP 
        WHERE pattern_id_232143 = NEW.pattern_id_232143;
    END;

CREATE TRIGGER IF NOT EXISTS update_transactions_updated_at 
    AFTER UPDATE ON transactions_232143
    FOR EACH ROW
    BEGIN
        UPDATE transactions_232143 
        SET updated_at_232143 = CURRENT_TIMESTAMP 
        WHERE transaction_id_232143 = NEW.transaction_id_232143;
    END;

CREATE TRIGGER IF NOT EXISTS update_users_updated_at 
    AFTER UPDATE ON users_232143
    FOR EACH ROW
    BEGIN
        UPDATE users_232143 
        SET updated_at_232143 = CURRENT_TIMESTAMP 
        WHERE user_id_232143 = NEW.user_id_232143;
    END;

-- ============================================================
-- Triggers for computed columns
-- ============================================================

-- Trigger to update remaining_amount_232143 in budgets_232143
CREATE TRIGGER IF NOT EXISTS update_budget_remaining_amount 
    AFTER UPDATE OF amount_232143, spent_amount_232143 ON budgets_232143
    FOR EACH ROW
    BEGIN
        UPDATE budgets_232143 
        SET remaining_amount_232143 = amount_232143 - spent_amount_232143 
        WHERE budget_id_232143 = NEW.budget_id_232143;
    END;

-- Trigger to update progress_percentage_232143 in financial_goals_232143
CREATE TRIGGER IF NOT EXISTS update_goal_progress_percentage 
    AFTER UPDATE OF current_amount_232143, target_amount_232143 ON financial_goals_232143
    FOR EACH ROW
    BEGIN
        UPDATE financial_goals_232143 
        SET progress_percentage_232143 = CASE 
            WHEN target_amount_232143 > 0 THEN ROUND((current_amount_232143 * 100.0 / target_amount_232143), 2)
            ELSE 0
        END
        WHERE goal_id_232143 = NEW.goal_id_232143;
    END;

-- ============================================================
-- Trigger for budget spent_amount update (SQLite version)
-- ============================================================

CREATE TRIGGER IF NOT EXISTS after_transaction_insert_232143 
    AFTER INSERT ON transactions_232143
    FOR EACH ROW
    WHEN NEW.type_232143 = 'expense' AND NEW.category_id_232143 IS NOT NULL
    BEGIN
        UPDATE budgets_232143 
        SET spent_amount_232143 = (
            SELECT COALESCE(SUM(amount_232143), 0)
            FROM transactions_232143 t
            WHERE t.category_id_232143 = NEW.category_id_232143
            AND t.transaction_date_232143 BETWEEN budgets_232143.period_start_232143 AND budgets_232143.period_end_232143
            AND t.type_232143 = 'expense'
        ),
        remaining_amount_232143 = amount_232143 - (
            SELECT COALESCE(SUM(amount_232143), 0)
            FROM transactions_232143 t
            WHERE t.category_id_232143 = NEW.category_id_232143
            AND t.transaction_date_232143 BETWEEN budgets_232143.period_start_232143 AND budgets_232143.period_end_232143
            AND t.type_232143 = 'expense'
        )
        WHERE category_id_232143 = NEW.category_id_232143
        AND period_start_232143 <= NEW.transaction_date_232143 
        AND period_end_232143 >= NEW.transaction_date_232143;
    END;

CREATE TRIGGER IF NOT EXISTS after_transaction_update_232143 
    AFTER UPDATE ON transactions_232143
    FOR EACH ROW
    WHEN NEW.type_232143 = 'expense' AND NEW.category_id_232143 IS NOT NULL
    BEGIN
        UPDATE budgets_232143 
        SET spent_amount_232143 = (
            SELECT COALESCE(SUM(amount_232143), 0)
            FROM transactions_232143 t
            WHERE t.category_id_232143 = NEW.category_id_232143
            AND t.transaction_date_232143 BETWEEN budgets_232143.period_start_232143 AND budgets_232143.period_end_232143
            AND t.type_232143 = 'expense'
        ),
        remaining_amount_232143 = amount_232143 - (
            SELECT COALESCE(SUM(amount_232143), 0)
            FROM transactions_232143 t
            WHERE t.category_id_232143 = NEW.category_id_232143
            AND t.transaction_date_232143 BETWEEN budgets_232143.period_start_232143 AND budgets_232143.period_end_232143
            AND t.type_232143 = 'expense'
        )
        WHERE category_id_232143 = NEW.category_id_232143
        AND period_start_232143 <= NEW.transaction_date_232143 
        AND period_end_232143 >= NEW.transaction_date_232143;
    END;

CREATE TRIGGER IF NOT EXISTS after_transaction_delete_232143 
    AFTER DELETE ON transactions_232143
    FOR EACH ROW
    WHEN OLD.type_232143 = 'expense' AND OLD.category_id_232143 IS NOT NULL
    BEGIN
        UPDATE budgets_232143 
        SET spent_amount_232143 = (
            SELECT COALESCE(SUM(amount_232143), 0)
            FROM transactions_232143 t
            WHERE t.category_id_232143 = OLD.category_id_232143
            AND t.transaction_date_232143 BETWEEN budgets_232143.period_start_232143 AND budgets_232143.period_end_232143
            AND t.type_232143 = 'expense'
        ),
        remaining_amount_232143 = amount_232143 - (
            SELECT COALESCE(SUM(amount_232143), 0)
            FROM transactions_232143 t
            WHERE t.category_id_232143 = OLD.category_id_232143
            AND t.transaction_date_232143 BETWEEN budgets_232143.period_start_232143 AND budgets_232143.period_end_232143
            AND t.type_232143 = 'expense'
        )
        WHERE category_id_232143 = OLD.category_id_232143
        AND period_start_232143 <= OLD.transaction_date_232143 
        AND period_end_232143 >= OLD.transaction_date_232143;
    END;

