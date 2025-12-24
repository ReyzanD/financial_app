-- Migration: Add location fields to transactions table (PostgreSQL)
-- Date: 2025-11-27
-- Purpose: Add location_name, latitude, longitude columns for location-based recommendations

-- Note: These columns are already included in the main schema
-- This migration is for adding them to existing databases

ALTER TABLE transactions_232143
ADD COLUMN IF NOT EXISTS location_name_232143 TEXT,
ADD COLUMN IF NOT EXISTS latitude_232143 DECIMAL(10, 7),
ADD COLUMN IF NOT EXISTS longitude_232143 DECIMAL(10, 7);

-- Create index for location-based queries (PostgreSQL syntax)
CREATE INDEX IF NOT EXISTS idx_transactions_location 
ON transactions_232143(location_name_232143) 
WHERE location_name_232143 IS NOT NULL;

-- Display confirmation
SELECT 'Location fields migration completed successfully!' as status;
