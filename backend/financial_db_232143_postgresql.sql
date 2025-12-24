-- PostgreSQL Database Schema for Financial App
-- Converted from MySQL to PostgreSQL for Supabase
-- 
-- IMPORTANT: Before running this script:
-- 1. Enable UUID extension: CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
-- 2. This script creates tables without data (INSERT statements removed for clarity)
-- 3. Run this in your Supabase SQL editor

-- Enable UUID extension (required for gen_random_uuid())
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- Table: ai_recommendations_232143
-- ============================================================
CREATE TABLE ai_recommendations_232143 (
  recommendation_id_232143 VARCHAR(36) NOT NULL DEFAULT gen_random_uuid()::text,
  user_id_232143 VARCHAR(36) NOT NULL,
  type_232143 VARCHAR(50) NOT NULL CHECK (type_232143 IN ('budget_optimization','saving_opportunity','spending_alert','investment_suggestion','debt_management','location_saving')),
  title_232143 VARCHAR(255) NOT NULL,
  description_232143 TEXT NOT NULL,
  action_items_232143 JSONB DEFAULT NULL,
  estimated_savings_232143 DECIMAL(15,2) DEFAULT NULL,
  impact_score_232143 INTEGER DEFAULT NULL,
  urgency_232143 VARCHAR(20) DEFAULT 'medium' CHECK (urgency_232143 IN ('low','medium','high','critical')),
  related_categories_232143 JSONB DEFAULT NULL,
  related_locations_232143 JSONB DEFAULT NULL,
  data_sources_232143 JSONB DEFAULT NULL,
  is_read_232143 BOOLEAN DEFAULT FALSE,
  is_applied_232143 BOOLEAN DEFAULT FALSE,
  applied_date_232143 TIMESTAMP NULL DEFAULT NULL,
  user_feedback_232143 INTEGER DEFAULT NULL,
  model_version_232143 VARCHAR(50) DEFAULT NULL,
  confidence_score_232143 DECIMAL(3,2) DEFAULT NULL,
  created_at_232143 TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  expires_at_232143 TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (recommendation_id_232143)
);

-- ============================================================
-- Table: bill_payments_232143
-- ============================================================
CREATE TABLE bill_payments_232143 (
  payment_id_232143 VARCHAR(36) NOT NULL DEFAULT gen_random_uuid()::text,
  bill_id_232143 VARCHAR(36) NOT NULL,
  user_id_232143 VARCHAR(36) NOT NULL,
  amount_paid_232143 DECIMAL(15,2) NOT NULL,
  payment_date_232143 DATE NOT NULL,
  payment_method_232143 VARCHAR(50) DEFAULT NULL,
  transaction_id_232143 VARCHAR(36) DEFAULT NULL,
  status_232143 VARCHAR(20) DEFAULT 'paid' CHECK (status_232143 IN ('paid','pending','failed')),
  created_at_232143 TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (payment_id_232143)
);

-- ============================================================
-- Table: budgets_232143
-- ============================================================
CREATE TABLE budgets_232143 (
  budget_id_232143 VARCHAR(36) NOT NULL DEFAULT gen_random_uuid()::text,
  user_id_232143 VARCHAR(36) NOT NULL,
  category_id_232143 VARCHAR(36) DEFAULT NULL,
  amount_232143 DECIMAL(15,2) NOT NULL,
  period_232143 VARCHAR(20) NOT NULL CHECK (period_232143 IN ('daily','weekly','monthly','yearly')),
  period_start_232143 DATE NOT NULL,
  period_end_232143 DATE NOT NULL,
  spent_amount_232143 DECIMAL(15,2) DEFAULT 0.00,
  rollover_enabled_232143 BOOLEAN DEFAULT FALSE,
  alert_threshold_232143 INTEGER DEFAULT 80,
  is_active_232143 BOOLEAN DEFAULT TRUE,
  recommended_amount_232143 DECIMAL(15,2) DEFAULT NULL,
  recommendation_reason_232143 TEXT,
  created_at_232143 TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at_232143 TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  remaining_amount_232143 DECIMAL(15,2) GENERATED ALWAYS AS (amount_232143 - spent_amount_232143) STORED,
  PRIMARY KEY (budget_id_232143)
);

-- ============================================================
-- Table: categories_232143
-- ============================================================
CREATE TABLE categories_232143 (
  category_id_232143 VARCHAR(36) NOT NULL DEFAULT gen_random_uuid()::text,
  user_id_232143 VARCHAR(36) DEFAULT NULL,
  name_232143 VARCHAR(100) NOT NULL,
  type_232143 VARCHAR(20) NOT NULL CHECK (type_232143 IN ('income','expense','transfer')),
  color_232143 VARCHAR(7) DEFAULT '#3498db',
  icon_232143 VARCHAR(50) DEFAULT 'receipt',
  budget_limit_232143 DECIMAL(15,2) DEFAULT NULL,
  budget_period_232143 VARCHAR(20) DEFAULT 'monthly' CHECK (budget_period_232143 IN ('daily','weekly','monthly','yearly')),
  is_fixed_232143 BOOLEAN DEFAULT FALSE,
  keywords_232143 JSONB DEFAULT NULL,
  location_patterns_232143 JSONB DEFAULT NULL,
  parent_category_id_232143 VARCHAR(36) DEFAULT NULL,
  display_order_232143 INTEGER DEFAULT 0,
  is_system_default_232143 BOOLEAN DEFAULT FALSE,
  created_at_232143 TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at_232143 TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (category_id_232143)
);

-- ============================================================
-- Table: financial_goals_232143
-- ============================================================
CREATE TABLE financial_goals_232143 (
  goal_id_232143 VARCHAR(36) NOT NULL DEFAULT gen_random_uuid()::text,
  user_id_232143 VARCHAR(36) NOT NULL,
  name_232143 VARCHAR(255) NOT NULL,
  description_232143 TEXT,
  goal_type_232143 VARCHAR(50) NOT NULL CHECK (goal_type_232143 IN ('emergency_fund','vacation','investment','debt_payment','education','vehicle','house','wedding','other')),
  target_amount_232143 DECIMAL(15,2) NOT NULL,
  current_amount_232143 DECIMAL(15,2) DEFAULT 0.00,
  start_date_232143 DATE DEFAULT CURRENT_DATE,
  target_date_232143 DATE NOT NULL,
  is_completed_232143 BOOLEAN DEFAULT FALSE,
  completed_date_232143 DATE DEFAULT NULL,
  priority_232143 INTEGER DEFAULT 3,
  monthly_target_232143 DECIMAL(15,2) DEFAULT NULL,
  auto_deduct_232143 BOOLEAN DEFAULT FALSE,
  deduct_percentage_232143 DECIMAL(5,2) DEFAULT NULL,
  recommended_monthly_saving_232143 DECIMAL(15,2) DEFAULT NULL,
  feasibility_score_232143 DECIMAL(3,2) DEFAULT NULL,
  created_at_232143 TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at_232143 TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  progress_percentage_232143 DECIMAL(5,2) GENERATED ALWAYS AS (
    CASE 
      WHEN target_amount_232143 > 0 THEN ROUND((current_amount_232143 / target_amount_232143) * 100, 2)
      ELSE 0
    END
  ) STORED,
  PRIMARY KEY (goal_id_232143)
);

-- ============================================================
-- Table: financial_obligations_232143
-- ============================================================
CREATE TABLE financial_obligations_232143 (
  obligation_id_232143 VARCHAR(36) NOT NULL DEFAULT gen_random_uuid()::text,
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
  is_auto_pay_232143 BOOLEAN DEFAULT FALSE,
  is_subscription_232143 BOOLEAN DEFAULT FALSE,
  subscription_cycle_232143 VARCHAR(20) DEFAULT NULL CHECK (subscription_cycle_232143 IN ('monthly','quarterly','yearly')),
  status_232143 VARCHAR(20) DEFAULT 'active' CHECK (status_232143 IN ('active','paid_off','cancelled','overdue')),
  priority_232143 VARCHAR(20) DEFAULT 'medium' CHECK (priority_232143 IN ('high','medium','low')),
  reminder_days_before_232143 INTEGER DEFAULT 3,
  created_at_232143 TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at_232143 TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (obligation_id_232143)
);

-- ============================================================
-- Table: location_intelligence_232143
-- ============================================================
CREATE TABLE location_intelligence_232143 (
  location_id_232143 VARCHAR(36) NOT NULL DEFAULT gen_random_uuid()::text,
  latitude_232143 DECIMAL(10,8) NOT NULL,
  longitude_232143 DECIMAL(11,8) NOT NULL,
  place_name_232143 VARCHAR(255) NOT NULL,
  place_type_232143 VARCHAR(100) NOT NULL,
  address_232143 TEXT,
  city_232143 VARCHAR(100) DEFAULT NULL,
  country_232143 VARCHAR(100) DEFAULT 'Indonesia',
  average_prices_232143 JSONB NOT NULL,
  price_ranges_232143 JSONB DEFAULT NULL,
  user_rating_232143 DECIMAL(3,2) DEFAULT NULL,
  popularity_score_232143 INTEGER DEFAULT 0,
  total_reviews_232143 INTEGER DEFAULT 0,
  opening_hours_232143 JSONB DEFAULT NULL,
  price_level_232143 INTEGER DEFAULT NULL,
  total_transactions_232143 INTEGER DEFAULT 0,
  last_updated_232143 TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  data_confidence_232143 DECIMAL(3,2) DEFAULT 0.70,
  created_at_232143 TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (location_id_232143)
);

-- ============================================================
-- Table: notifications_232143
-- ============================================================
CREATE TABLE notifications_232143 (
  notification_id_232143 VARCHAR(36) NOT NULL DEFAULT gen_random_uuid()::text,
  user_id_232143 VARCHAR(36) NOT NULL,
  type_232143 VARCHAR(50) NOT NULL CHECK (type_232143 IN ('budget_alert','goal_progress','bill_reminder','spending_insight','system_announcement','security_alert')),
  title_232143 VARCHAR(255) NOT NULL,
  message_232143 TEXT NOT NULL,
  action_url_232143 VARCHAR(500) DEFAULT NULL,
  action_label_232143 VARCHAR(100) DEFAULT NULL,
  is_read_232143 BOOLEAN DEFAULT FALSE,
  is_sent_232143 BOOLEAN DEFAULT FALSE,
  sent_at_232143 TIMESTAMP NULL DEFAULT NULL,
  read_at_232143 TIMESTAMP NULL DEFAULT NULL,
  priority_232143 VARCHAR(20) DEFAULT 'normal' CHECK (priority_232143 IN ('low','normal','high')),
  category_232143 VARCHAR(100) DEFAULT NULL,
  created_at_232143 TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (notification_id_232143)
);

-- ============================================================
-- Table: obligation_payments_232143
-- ============================================================
CREATE TABLE obligation_payments_232143 (
  payment_id_232143 VARCHAR(36) NOT NULL DEFAULT gen_random_uuid()::text,
  obligation_id_232143 VARCHAR(36) NOT NULL,
  user_id_232143 VARCHAR(36) NOT NULL,
  amount_paid_232143 DECIMAL(15,2) NOT NULL,
  payment_date_232143 DATE NOT NULL,
  payment_method_232143 VARCHAR(50) DEFAULT NULL,
  principal_paid_232143 DECIMAL(15,2) DEFAULT NULL,
  interest_paid_232143 DECIMAL(15,2) DEFAULT NULL,
  transaction_id_232143 VARCHAR(36) DEFAULT NULL,
  status_232143 VARCHAR(20) DEFAULT 'completed' CHECK (status_232143 IN ('completed','pending','failed')),
  created_at_232143 TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (payment_id_232143)
);

-- ============================================================
-- Table: spending_patterns_232143
-- ============================================================
CREATE TABLE spending_patterns_232143 (
  pattern_id_232143 VARCHAR(36) NOT NULL DEFAULT gen_random_uuid()::text,
  user_id_232143 VARCHAR(36) NOT NULL,
  pattern_type_232143 VARCHAR(50) NOT NULL CHECK (pattern_type_232143 IN ('weekly','monthly','seasonal','location_based','category_based')),
  category_id_232143 VARCHAR(36) DEFAULT NULL,
  location_id_232143 VARCHAR(36) DEFAULT NULL,
  pattern_data_232143 JSONB NOT NULL,
  average_amount_232143 DECIMAL(15,2) NOT NULL,
  frequency_per_month_232143 DECIMAL(5,2) DEFAULT NULL,
  total_occurrences_232143 INTEGER DEFAULT 0,
  last_occurrence_232143 DATE DEFAULT NULL,
  confidence_score_232143 DECIMAL(3,2) DEFAULT NULL,
  is_active_232143 BOOLEAN DEFAULT TRUE,
  detected_at_232143 TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  model_version_232143 VARCHAR(50) DEFAULT NULL,
  created_at_232143 TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at_232143 TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (pattern_id_232143)
);

-- ============================================================
-- Table: transactions_232143
-- ============================================================
CREATE TABLE transactions_232143 (
  transaction_id_232143 VARCHAR(36) NOT NULL DEFAULT gen_random_uuid()::text,
  user_id_232143 VARCHAR(36) NOT NULL,
  amount_232143 DECIMAL(15,2) NOT NULL,
  type_232143 VARCHAR(20) NOT NULL CHECK (type_232143 IN ('income','expense','transfer')),
  category_id_232143 VARCHAR(36) DEFAULT NULL,
  description_232143 VARCHAR(500) NOT NULL,
  location_data_232143 JSONB DEFAULT NULL,
  payment_method_232143 VARCHAR(20) DEFAULT 'cash' CHECK (payment_method_232143 IN ('cash','debit_card','credit_card','e_wallet','bank_transfer')),
  receipt_image_url_232143 VARCHAR(500) DEFAULT NULL,
  is_recurring_232143 BOOLEAN DEFAULT FALSE,
  recurring_pattern_232143 JSONB DEFAULT NULL,
  predicted_category_id_232143 VARCHAR(36) DEFAULT NULL,
  confidence_score_232143 DECIMAL(3,2) DEFAULT NULL,
  is_verified_232143 BOOLEAN DEFAULT TRUE,
  tags_232143 JSONB DEFAULT NULL,
  transaction_date_232143 DATE NOT NULL,
  transaction_time_232143 TIME DEFAULT NULL,
  created_at_232143 TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at_232143 TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (transaction_id_232143)
);

-- ============================================================
-- Table: users_232143
-- ============================================================
CREATE TABLE users_232143 (
  user_id_232143 VARCHAR(36) NOT NULL DEFAULT gen_random_uuid()::text,
  email_232143 VARCHAR(255) NOT NULL,
  password_hash_232143 VARCHAR(255) NOT NULL,
  full_name_232143 VARCHAR(255) NOT NULL,
  phone_number_232143 VARCHAR(20) DEFAULT NULL,
  date_of_birth_232143 DATE DEFAULT NULL,
  occupation_232143 VARCHAR(100) DEFAULT NULL,
  income_range_232143 VARCHAR(20) DEFAULT NULL CHECK (income_range_232143 IN ('0-3jt','3-5jt','5-10jt','10-20jt','20jt+')),
  family_size_232143 INTEGER DEFAULT 1,
  currency_232143 VARCHAR(10) DEFAULT 'IDR',
  base_location_232143 JSONB DEFAULT NULL,
  financial_goals_232143 JSONB DEFAULT '{"emergency_fund": 0, "vacation": 0, "investment": 0, "debt_payment": 0}'::jsonb,
  risk_tolerance_232143 INTEGER DEFAULT 3,
  notification_settings_232143 JSONB DEFAULT '{"budget_alerts": true, "goal_reminders": true, "spending_insights": true, "push_notifications": true}'::jsonb,
  created_at_232143 TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at_232143 TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  last_login_232143 TIMESTAMP NULL DEFAULT NULL,
  is_active_232143 BOOLEAN DEFAULT TRUE,
  PRIMARY KEY (user_id_232143),
  UNIQUE (email_232143)
);

-- ============================================================
-- Indexes
-- ============================================================

-- ai_recommendations_232143 indexes
CREATE INDEX idx_recommendations_user_232143 ON ai_recommendations_232143(user_id_232143);
CREATE INDEX idx_recommendations_type_232143 ON ai_recommendations_232143(type_232143);
CREATE INDEX idx_recommendations_urgency_232143 ON ai_recommendations_232143(urgency_232143);
CREATE INDEX idx_recommendations_unread_232143 ON ai_recommendations_232143(is_read_232143);
CREATE INDEX idx_recommendations_created_232143 ON ai_recommendations_232143(created_at_232143);

-- bill_payments_232143 indexes
CREATE INDEX idx_bill_payments_bill_232143 ON bill_payments_232143(bill_id_232143);
CREATE INDEX idx_bill_payments_user_232143 ON bill_payments_232143(user_id_232143);
CREATE INDEX idx_bill_payments_transaction_232143 ON bill_payments_232143(transaction_id_232143);

-- budgets_232143 indexes
CREATE INDEX idx_budgets_user_id_232143 ON budgets_232143(user_id_232143);
CREATE INDEX idx_budgets_period_232143 ON budgets_232143(period_start_232143, period_end_232143);
CREATE INDEX idx_budgets_active_232143 ON budgets_232143(is_active_232143);
CREATE INDEX idx_budgets_category_232143 ON budgets_232143(category_id_232143);

-- categories_232143 indexes
CREATE INDEX idx_categories_parent_232143 ON categories_232143(parent_category_id_232143);
CREATE INDEX idx_categories_user_id_232143 ON categories_232143(user_id_232143);
CREATE INDEX idx_categories_type_232143 ON categories_232143(type_232143);
CREATE INDEX idx_categories_system_232143 ON categories_232143(is_system_default_232143);

-- financial_goals_232143 indexes
CREATE INDEX idx_goals_user_id_232143 ON financial_goals_232143(user_id_232143);
CREATE INDEX idx_goals_target_date_232143 ON financial_goals_232143(target_date_232143);
CREATE INDEX idx_goals_completed_232143 ON financial_goals_232143(is_completed_232143);
CREATE INDEX idx_goals_type_232143 ON financial_goals_232143(goal_type_232143);

-- financial_obligations_232143 indexes
CREATE INDEX idx_obligations_user_232143 ON financial_obligations_232143(user_id_232143);

-- location_intelligence_232143 indexes
CREATE INDEX idx_location_coords_232143 ON location_intelligence_232143(latitude_232143, longitude_232143);
CREATE INDEX idx_location_type_232143 ON location_intelligence_232143(place_type_232143);
CREATE INDEX idx_location_city_232143 ON location_intelligence_232143(city_232143);
CREATE INDEX idx_location_confidence_232143 ON location_intelligence_232143(data_confidence_232143);

-- notifications_232143 indexes
CREATE INDEX idx_notifications_user_232143 ON notifications_232143(user_id_232143);
CREATE INDEX idx_notifications_type_232143 ON notifications_232143(type_232143);
CREATE INDEX idx_notifications_unread_232143 ON notifications_232143(is_read_232143);
CREATE INDEX idx_notifications_created_232143 ON notifications_232143(created_at_232143);
CREATE INDEX idx_notifications_priority_232143 ON notifications_232143(priority_232143);

-- obligation_payments_232143 indexes
CREATE INDEX idx_obligation_payments_obligation_232143 ON obligation_payments_232143(obligation_id_232143);
CREATE INDEX idx_obligation_payments_user_232143 ON obligation_payments_232143(user_id_232143);
CREATE INDEX idx_obligation_payments_transaction_232143 ON obligation_payments_232143(transaction_id_232143);

-- spending_patterns_232143 indexes
CREATE INDEX idx_patterns_location_232143 ON spending_patterns_232143(location_id_232143);
CREATE INDEX idx_patterns_user_232143 ON spending_patterns_232143(user_id_232143);
CREATE INDEX idx_patterns_type_232143 ON spending_patterns_232143(pattern_type_232143);
CREATE INDEX idx_patterns_active_232143 ON spending_patterns_232143(is_active_232143);
CREATE INDEX idx_patterns_category_232143 ON spending_patterns_232143(category_id_232143);

-- transactions_232143 indexes
CREATE INDEX idx_transactions_predicted_category_232143 ON transactions_232143(predicted_category_id_232143);
CREATE INDEX idx_transactions_user_id_232143 ON transactions_232143(user_id_232143);
CREATE INDEX idx_transactions_date_232143 ON transactions_232143(transaction_date_232143);
CREATE INDEX idx_transactions_category_232143 ON transactions_232143(category_id_232143);
CREATE INDEX idx_transactions_type_232143 ON transactions_232143(type_232143);
CREATE INDEX idx_transactions_recurring_232143 ON transactions_232143(is_recurring_232143);
CREATE INDEX idx_transactions_created_232143 ON transactions_232143(created_at_232143);
CREATE INDEX idx_transaction_date_user ON transactions_232143(user_id_232143, transaction_date_232143);
CREATE INDEX idx_type_date ON transactions_232143(type_232143, transaction_date_232143);

-- users_232143 indexes
CREATE INDEX idx_users_email_232143 ON users_232143(email_232143);
CREATE INDEX idx_users_created_at_232143 ON users_232143(created_at_232143);
CREATE INDEX idx_users_active_232143 ON users_232143(is_active_232143);

-- ============================================================
-- Foreign Key Constraints
-- ============================================================

ALTER TABLE ai_recommendations_232143
  ADD CONSTRAINT ai_recommendations_232143_fk_user FOREIGN KEY (user_id_232143) 
  REFERENCES users_232143(user_id_232143) ON DELETE CASCADE;

ALTER TABLE budgets_232143
  ADD CONSTRAINT budgets_232143_fk_user FOREIGN KEY (user_id_232143) 
  REFERENCES users_232143(user_id_232143) ON DELETE CASCADE,
  ADD CONSTRAINT budgets_232143_fk_category FOREIGN KEY (category_id_232143) 
  REFERENCES categories_232143(category_id_232143);

ALTER TABLE categories_232143
  ADD CONSTRAINT categories_232143_fk_user FOREIGN KEY (user_id_232143) 
  REFERENCES users_232143(user_id_232143) ON DELETE CASCADE,
  ADD CONSTRAINT categories_232143_fk_parent FOREIGN KEY (parent_category_id_232143) 
  REFERENCES categories_232143(category_id_232143);

ALTER TABLE financial_goals_232143
  ADD CONSTRAINT financial_goals_232143_fk_user FOREIGN KEY (user_id_232143) 
  REFERENCES users_232143(user_id_232143) ON DELETE CASCADE;

ALTER TABLE financial_obligations_232143
  ADD CONSTRAINT financial_obligations_232143_fk_user FOREIGN KEY (user_id_232143) 
  REFERENCES users_232143(user_id_232143) ON DELETE CASCADE;

ALTER TABLE notifications_232143
  ADD CONSTRAINT notifications_232143_fk_user FOREIGN KEY (user_id_232143) 
  REFERENCES users_232143(user_id_232143) ON DELETE CASCADE;

ALTER TABLE obligation_payments_232143
  ADD CONSTRAINT obligation_payments_232143_fk_obligation FOREIGN KEY (obligation_id_232143) 
  REFERENCES financial_obligations_232143(obligation_id_232143),
  ADD CONSTRAINT obligation_payments_232143_fk_user FOREIGN KEY (user_id_232143) 
  REFERENCES users_232143(user_id_232143),
  ADD CONSTRAINT obligation_payments_232143_fk_transaction FOREIGN KEY (transaction_id_232143) 
  REFERENCES transactions_232143(transaction_id_232143);

ALTER TABLE spending_patterns_232143
  ADD CONSTRAINT spending_patterns_232143_fk_user FOREIGN KEY (user_id_232143) 
  REFERENCES users_232143(user_id_232143) ON DELETE CASCADE,
  ADD CONSTRAINT spending_patterns_232143_fk_category FOREIGN KEY (category_id_232143) 
  REFERENCES categories_232143(category_id_232143),
  ADD CONSTRAINT spending_patterns_232143_fk_location FOREIGN KEY (location_id_232143) 
  REFERENCES location_intelligence_232143(location_id_232143);

ALTER TABLE transactions_232143
  ADD CONSTRAINT transactions_232143_fk_user FOREIGN KEY (user_id_232143) 
  REFERENCES users_232143(user_id_232143) ON DELETE CASCADE,
  ADD CONSTRAINT transactions_232143_fk_category FOREIGN KEY (category_id_232143) 
  REFERENCES categories_232143(category_id_232143),
  ADD CONSTRAINT transactions_232143_fk_predicted_category FOREIGN KEY (predicted_category_id_232143) 
  REFERENCES categories_232143(category_id_232143);

-- ============================================================
-- Functions and Triggers for updated_at
-- ============================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at_232143 = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for tables with updated_at
CREATE TRIGGER update_budgets_updated_at BEFORE UPDATE ON budgets_232143
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_categories_updated_at BEFORE UPDATE ON categories_232143
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_financial_goals_updated_at BEFORE UPDATE ON financial_goals_232143
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_financial_obligations_updated_at BEFORE UPDATE ON financial_obligations_232143
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_spending_patterns_updated_at BEFORE UPDATE ON spending_patterns_232143
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_transactions_updated_at BEFORE UPDATE ON transactions_232143
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users_232143
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- Trigger for budget spent_amount update (PostgreSQL version)
-- ============================================================

CREATE OR REPLACE FUNCTION update_budget_spent_amount()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.type_232143 = 'expense' AND NEW.category_id_232143 IS NOT NULL THEN
        UPDATE budgets_232143 
        SET spent_amount_232143 = (
            SELECT COALESCE(SUM(amount_232143), 0)
            FROM transactions_232143 t
            WHERE t.category_id_232143 = NEW.category_id_232143
            AND t.transaction_date_232143 BETWEEN budgets_232143.period_start_232143 AND budgets_232143.period_end_232143
            AND t.type_232143 = 'expense'
        )
        WHERE category_id_232143 = NEW.category_id_232143
        AND period_start_232143 <= NEW.transaction_date_232143 
        AND period_end_232143 >= NEW.transaction_date_232143;
    END IF;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER after_transaction_insert_232143 
    AFTER INSERT ON transactions_232143
    FOR EACH ROW EXECUTE FUNCTION update_budget_spent_amount();

-- ============================================================
-- View: user_financial_summary_232143
-- ============================================================

CREATE OR REPLACE VIEW user_financial_summary_232143 AS
SELECT 
    u.user_id_232143,
    u.full_name_232143,
    u.income_range_232143,
    COALESCE((
        SELECT SUM(t.amount_232143)
        FROM transactions_232143 t
        WHERE t.user_id_232143 = u.user_id_232143
        AND t.type_232143 = 'income'
        AND t.transaction_date_232143 >= (CURRENT_DATE - INTERVAL '30 days')
    ), 0) AS monthly_income_232143,
    COALESCE((
        SELECT SUM(t.amount_232143)
        FROM transactions_232143 t
        WHERE t.user_id_232143 = u.user_id_232143
        AND t.type_232143 = 'expense'
        AND t.transaction_date_232143 >= (CURRENT_DATE - INTERVAL '30 days')
    ), 0) AS monthly_expenses_232143,
    (
        SELECT COUNT(*)
        FROM budgets_232143 b
        WHERE b.user_id_232143 = u.user_id_232143
        AND b.is_active_232143 = TRUE
        AND CURRENT_DATE BETWEEN b.period_start_232143 AND b.period_end_232143
    ) AS active_budgets_count_232143,
    (
        SELECT AVG(fg.progress_percentage_232143)
        FROM financial_goals_232143 fg
        WHERE fg.user_id_232143 = u.user_id_232143
        AND fg.is_completed_232143 = FALSE
    ) AS average_goal_progress_232143
FROM users_232143 u
WHERE u.is_active_232143 = TRUE;

