-- Migration: Update Alert Types Enum
-- Date: 2024-12-22
-- Description: Updates alert type enum to remove 'general' and add 'labor', 'receipt', 'document' types

-- PostgreSQL doesn't support ALTER TYPE ... ADD VALUE in a transaction that uses the type
-- So we'll use a different approach: create new enum, update column, drop old enum

-- STEP 1: Create new enum type with updated values
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'alert_type_new') THEN
        CREATE TYPE alert_type_new AS ENUM (
            'budget',
            'payment',
            'labor',
            'receipt',
            'document'
        );
        RAISE NOTICE 'Created alert_type_new enum';
    END IF;
END $$;

-- STEP 2: Add temporary column with new enum type
ALTER TABLE alerts 
ADD COLUMN IF NOT EXISTS type_new alert_type_new;

-- STEP 3: Migrate existing data, mapping old values to new values
-- 'general' → 'budget' (most common fallback)
-- All other types remain the same if they exist in new enum
UPDATE alerts
SET type_new = CASE 
    WHEN type::text = 'general' THEN 'budget'::alert_type_new
    WHEN type::text = 'budget' THEN 'budget'::alert_type_new
    WHEN type::text = 'payment' THEN 'payment'::alert_type_new
    ELSE 'budget'::alert_type_new  -- Fallback for any unknown types
END
WHERE type_new IS NULL;

-- STEP 4: Drop old type column (if it exists and is not being used)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'alerts' AND column_name = 'type') THEN
        -- Check if column uses old enum type
        ALTER TABLE alerts DROP COLUMN type CASCADE;
        RAISE NOTICE 'Dropped old type column';
    END IF;
END $$;

-- STEP 5: Rename new column to 'type'
ALTER TABLE alerts 
RENAME COLUMN type_new TO type;

-- STEP 6: Drop old enum type (if exists)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'alert_type') THEN
        DROP TYPE alert_type CASCADE;
        RAISE NOTICE 'Dropped old alert_type enum';
    END IF;
END $$;

-- STEP 7: Rename new enum type to original name
ALTER TYPE alert_type_new RENAME TO alert_type;

-- STEP 8: Set NOT NULL constraint on type column
ALTER TABLE alerts 
ALTER COLUMN type SET NOT NULL;

-- Add comment for documentation
COMMENT ON COLUMN alerts.type IS 'Alert type: budget, payment, labor (timesheet anomalies), receipt (expense issues), document (missing/invalid docs)';

-- Create index for filtering by type
CREATE INDEX IF NOT EXISTS idx_alerts_type ON alerts(type);

-- Verify migration
DO $$
DECLARE
    has_type_column BOOLEAN;
    type_enum_values TEXT[];
    expected_values TEXT[] := ARRAY['budget', 'payment', 'labor', 'receipt', 'document'];
    enum_correct BOOLEAN;
BEGIN
    -- Check if type column exists
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'alerts' AND column_name = 'type'
    ) INTO has_type_column;
    
    -- Get enum values
    SELECT array_agg(e.enumlabel ORDER BY e.enumsortorder) INTO type_enum_values
    FROM pg_type t
    JOIN pg_enum e ON t.oid = e.enumtypid
    WHERE t.typname = 'alert_type';
    
    -- Check if enum values match expected
    enum_correct := (type_enum_values = expected_values);
    
    -- Report results
    IF has_type_column AND enum_correct THEN
        RAISE NOTICE 'Migration successful: alert_type enum updated';
        RAISE NOTICE 'Current values: %', array_to_string(type_enum_values, ', ');
    ELSE
        IF NOT has_type_column THEN
            RAISE EXCEPTION 'Migration failed: type column not found in alerts table';
        END IF;
        IF NOT enum_correct THEN
            RAISE WARNING 'Enum values mismatch. Expected: % | Found: %', 
                array_to_string(expected_values, ', '), 
                array_to_string(type_enum_values, ', ');
        END IF;
    END IF;
END $$;

-- ROLLBACK SCRIPT (save for reference, do not execute):
-- This rollback is complex because we're changing enum values
-- You would need to:
-- 1. Create old enum with 'general' type
-- 2. Add temporary column with old enum
-- 3. Migrate data back (labor/receipt/document → general)
-- 4. Drop current type column
-- 5. Rename temp column to type
-- 6. Drop new enum, rename old enum
