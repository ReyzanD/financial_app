-- Add missing triggers to update budget spent_amount when transactions are updated or deleted
-- PostgreSQL version

-- Drop existing triggers if they exist
DROP TRIGGER IF EXISTS after_transaction_insert_232143 ON transactions_232143;
DROP TRIGGER IF EXISTS after_transaction_update_232143 ON transactions_232143;
DROP TRIGGER IF EXISTS after_transaction_delete_232143 ON transactions_232143;

-- Function for INSERT trigger
CREATE OR REPLACE FUNCTION update_budget_spent_amount_insert()
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

-- Function for UPDATE trigger
CREATE OR REPLACE FUNCTION update_budget_spent_amount_update()
RETURNS TRIGGER AS $$
BEGIN
    -- Update budget for old category if it changed or if amount/date changed
    IF OLD.category_id_232143 IS NOT NULL AND OLD.type_232143 = 'expense' THEN
        UPDATE budgets_232143 
        SET spent_amount_232143 = (
            SELECT COALESCE(SUM(amount_232143), 0)
            FROM transactions_232143 t
            WHERE t.category_id_232143 = OLD.category_id_232143
            AND t.transaction_date_232143 BETWEEN budgets_232143.period_start_232143 AND budgets_232143.period_end_232143
            AND t.type_232143 = 'expense'
        )
        WHERE category_id_232143 = OLD.category_id_232143
        AND period_start_232143 <= OLD.transaction_date_232143 
        AND period_end_232143 >= OLD.transaction_date_232143;
    END IF;
    
    -- Update budget for new category
    IF NEW.category_id_232143 IS NOT NULL AND NEW.type_232143 = 'expense' THEN
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

-- Function for DELETE trigger
CREATE OR REPLACE FUNCTION update_budget_spent_amount_delete()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.type_232143 = 'expense' AND OLD.category_id_232143 IS NOT NULL THEN
        UPDATE budgets_232143 
        SET spent_amount_232143 = (
            SELECT COALESCE(SUM(amount_232143), 0)
            FROM transactions_232143 t
            WHERE t.category_id_232143 = OLD.category_id_232143
            AND t.transaction_date_232143 BETWEEN budgets_232143.period_start_232143 AND budgets_232143.period_end_232143
            AND t.type_232143 = 'expense'
        )
        WHERE category_id_232143 = OLD.category_id_232143
        AND period_start_232143 <= OLD.transaction_date_232143 
        AND period_end_232143 >= OLD.transaction_date_232143;
    END IF;
    RETURN OLD;
END;
$$ language 'plpgsql';

-- Create triggers
CREATE TRIGGER after_transaction_insert_232143 
    AFTER INSERT ON transactions_232143
    FOR EACH ROW EXECUTE FUNCTION update_budget_spent_amount_insert();

CREATE TRIGGER after_transaction_update_232143 
    AFTER UPDATE ON transactions_232143
    FOR EACH ROW EXECUTE FUNCTION update_budget_spent_amount_update();

CREATE TRIGGER after_transaction_delete_232143 
    AFTER DELETE ON transactions_232143
    FOR EACH ROW EXECUTE FUNCTION update_budget_spent_amount_delete();

