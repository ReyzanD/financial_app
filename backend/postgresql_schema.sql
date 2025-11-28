
-- PostgreSQL Schema for Financial App
-- Generated from MySQL migration

-- Users Table
CREATE TABLE IF NOT EXISTS users_232143 (
    user_id_232143 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name_232143 VARCHAR(255) NOT NULL,
    email_232143 VARCHAR(255) UNIQUE NOT NULL,
    password_hash_232143 VARCHAR(255) NOT NULL,
    created_at_232143 TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at_232143 TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Categories Table
CREATE TABLE IF NOT EXISTS categories_232143 (
    category_id_232143 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id_232143 UUID REFERENCES users_232143(user_id_232143) ON DELETE CASCADE,
    name_232143 VARCHAR(100) NOT NULL,
    type_232143 VARCHAR(20) NOT NULL CHECK (type_232143 IN ('income', 'expense')),
    color_232143 VARCHAR(20) DEFAULT '#808080',
    icon_232143 VARCHAR(50),
    is_default_232143 BOOLEAN DEFAULT FALSE,
    created_at_232143 TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Transactions Table
CREATE TABLE IF NOT EXISTS transactions_232143 (
    transaction_id_232143 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id_232143 UUID REFERENCES users_232143(user_id_232143) ON DELETE CASCADE,
    amount_232143 DECIMAL(15, 2) NOT NULL,
    type_232143 VARCHAR(20) NOT NULL CHECK (type_232143 IN ('income', 'expense')),
    category_id_232143 UUID REFERENCES categories_232143(category_id_232143) ON DELETE SET NULL,
    description_232143 TEXT,
    location_name_232143 TEXT,
    latitude_232143 DECIMAL(10, 8),
    longitude_232143 DECIMAL(11, 8),
    location_data_232143 JSONB,
    payment_method_232143 VARCHAR(50) DEFAULT 'cash',
    transaction_date_232143 DATE NOT NULL,
    created_at_232143 TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at_232143 TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Budgets Table
CREATE TABLE IF NOT EXISTS budgets_232143 (
    budget_id_232143 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id_232143 UUID REFERENCES users_232143(user_id_232143) ON DELETE CASCADE,
    category_id_232143 UUID REFERENCES categories_232143(category_id_232143) ON DELETE CASCADE,
    amount_232143 DECIMAL(15, 2) NOT NULL,
    period_232143 VARCHAR(20) DEFAULT 'monthly',
    period_start_232143 DATE NOT NULL,
    period_end_232143 DATE NOT NULL,
    spent_amount_232143 DECIMAL(15, 2) DEFAULT 0,
    remaining_amount_232143 DECIMAL(15, 2),
    rollover_enabled_232143 BOOLEAN DEFAULT FALSE,
    alert_threshold_232143 INTEGER DEFAULT 80,
    is_active_232143 BOOLEAN DEFAULT TRUE,
    recommended_amount_232143 DECIMAL(15, 2),
    recommendation_reason_232143 TEXT,
    created_at_232143 TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at_232143 TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Goals Table
CREATE TABLE IF NOT EXISTS goals_232143 (
    goal_id_232143 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id_232143 UUID REFERENCES users_232143(user_id_232143) ON DELETE CASCADE,
    name_232143 VARCHAR(255) NOT NULL,
    target_amount_232143 DECIMAL(15, 2) NOT NULL,
    current_amount_232143 DECIMAL(15, 2) DEFAULT 0,
    deadline_232143 DATE,
    category_232143 VARCHAR(100),
    description_232143 TEXT,
    status_232143 VARCHAR(20) DEFAULT 'active',
    created_at_232143 TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at_232143 TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Goal Contributions Table
CREATE TABLE IF NOT EXISTS goal_contributions_232143 (
    contribution_id_232143 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    goal_id_232143 UUID REFERENCES goals_232143(goal_id_232143) ON DELETE CASCADE,
    amount_232143 DECIMAL(15, 2) NOT NULL,
    contribution_date_232143 TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notes_232143 TEXT
);

-- Subscriptions Table
CREATE TABLE IF NOT EXISTS subscriptions_232143 (
    subscription_id_232143 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id_232143 UUID REFERENCES users_232143(user_id_232143) ON DELETE CASCADE,
    name_232143 VARCHAR(255) NOT NULL,
    amount_232143 DECIMAL(15, 2) NOT NULL,
    billing_cycle_232143 VARCHAR(20) DEFAULT 'monthly',
    next_billing_date_232143 DATE NOT NULL,
    category_id_232143 UUID REFERENCES categories_232143(category_id_232143),
    is_active_232143 BOOLEAN DEFAULT TRUE,
    notes_232143 TEXT,
    created_at_232143 TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at_232143 TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Debts Table
CREATE TABLE IF NOT EXISTS debts_232143 (
    debt_id_232143 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id_232143 UUID REFERENCES users_232143(user_id_232143) ON DELETE CASCADE,
    creditor_name_232143 VARCHAR(255) NOT NULL,
    total_amount_232143 DECIMAL(15, 2) NOT NULL,
    remaining_amount_232143 DECIMAL(15, 2) NOT NULL,
    interest_rate_232143 DECIMAL(5, 2) DEFAULT 0,
    due_date_232143 DATE,
    minimum_payment_232143 DECIMAL(15, 2),
    status_232143 VARCHAR(20) DEFAULT 'active',
    notes_232143 TEXT,
    created_at_232143 TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at_232143 TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create Indexes
CREATE INDEX IF NOT EXISTS idx_transactions_user ON transactions_232143(user_id_232143);
CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions_232143(transaction_date_232143);
CREATE INDEX IF NOT EXISTS idx_transactions_category ON transactions_232143(category_id_232143);
CREATE INDEX IF NOT EXISTS idx_transactions_location ON transactions_232143(location_name_232143);
CREATE INDEX IF NOT EXISTS idx_budgets_user ON budgets_232143(user_id_232143);
CREATE INDEX IF NOT EXISTS idx_goals_user ON goals_232143(user_id_232143);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at_232143 = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users_232143 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_transactions_updated_at BEFORE UPDATE ON transactions_232143 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_budgets_updated_at BEFORE UPDATE ON budgets_232143 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_goals_updated_at BEFORE UPDATE ON goals_232143 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
