-- Migration: Update AI Insights Structure
-- Date: 2024-12-22
-- Description: Restructures ai_insights table to remove job-specific fields and make it more flexible

-- STEP 1: Add new columns (add before dropping old ones to preserve data)
ALTER TABLE ai_insights 
ADD COLUMN IF NOT EXISTS insight TEXT,
ADD COLUMN IF NOT EXISTS actionable BOOLEAN DEFAULT false;

-- STEP 2: Migrate existing data from old structure to new structure
-- Concatenate title and message into insight field
UPDATE ai_insights
SET insight = COALESCE(title, '') || 
    CASE 
        WHEN title IS NOT NULL AND message IS NOT NULL THEN ': ' 
        ELSE '' 
    END || 
    COALESCE(message, '')
WHERE insight IS NULL AND (title IS NOT NULL OR message IS NOT NULL);

-- STEP 3: Set actionable based on category (if exists)
-- Insights with categories like 'warning', 'alert', 'action_required' should be actionable
UPDATE ai_insights
SET actionable = CASE 
    WHEN category IN ('warning', 'alert', 'action_required', 'budget', 'payment') THEN true
    ELSE false
END
WHERE actionable = false;

-- STEP 4: Drop old columns that are no longer needed
DO $$
BEGIN
    -- Drop title column
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ai_insights' AND column_name = 'title') THEN
        ALTER TABLE ai_insights DROP COLUMN title;
        RAISE NOTICE 'Dropped title column';
    END IF;
    
    -- Drop message column
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ai_insights' AND column_name = 'message') THEN
        ALTER TABLE ai_insights DROP COLUMN message;
        RAISE NOTICE 'Dropped message column';
    END IF;
    
    -- Drop job_id column (making insights not job-specific)
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ai_insights' AND column_name = 'job_id') THEN
        ALTER TABLE ai_insights DROP COLUMN job_id;
        RAISE NOTICE 'Dropped job_id column';
    END IF;
END $$;

-- STEP 5: Update category column to be freeform VARCHAR instead of enum
-- First, check if category is an enum type
DO $$
DECLARE
    category_type_name TEXT;
BEGIN
    -- Get the data type of category column
    SELECT udt_name INTO category_type_name
    FROM information_schema.columns
    WHERE table_name = 'ai_insights' AND column_name = 'category';
    
    -- If it's an enum, convert to VARCHAR
    IF category_type_name LIKE '%enum%' THEN
        ALTER TABLE ai_insights 
        ALTER COLUMN category TYPE VARCHAR(100) USING category::text;
        RAISE NOTICE 'Converted category from enum to VARCHAR(100)';
    ELSE
        -- Just ensure it's VARCHAR(100)
        ALTER TABLE ai_insights 
        ALTER COLUMN category TYPE VARCHAR(100);
        RAISE NOTICE 'Updated category to VARCHAR(100)';
    END IF;
END $$;

-- STEP 6: Set NOT NULL constraint on insight column
ALTER TABLE ai_insights 
ALTER COLUMN insight SET NOT NULL;

-- Add comments for documentation
COMMENT ON COLUMN ai_insights.insight IS 'AI-generated insight text (replaces title + message)';
COMMENT ON COLUMN ai_insights.actionable IS 'Whether this insight requires user action';
COMMENT ON COLUMN ai_insights.category IS 'Freeform category string (budget, labor, efficiency, risk, opportunity, etc.)';

-- Create index for actionable insights (common filter)
CREATE INDEX IF NOT EXISTS idx_ai_insights_actionable ON ai_insights(actionable) WHERE actionable = true;

-- Create index for category filtering
CREATE INDEX IF NOT EXISTS idx_ai_insights_category ON ai_insights(category);

-- Verify migration
DO $$
DECLARE
    has_new_columns BOOLEAN;
    missing_old_columns BOOLEAN;
    category_is_varchar BOOLEAN;
    category_type TEXT;
BEGIN
    -- Check if new columns exist
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'ai_insights' 
        AND column_name IN ('insight', 'actionable')
        GROUP BY table_name
        HAVING COUNT(*) = 2
    ) INTO has_new_columns;
    
    -- Check if old columns are removed
    SELECT NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'ai_insights' 
        AND column_name IN ('title', 'message', 'job_id')
    ) INTO missing_old_columns;
    
    -- Check if category is VARCHAR
    SELECT data_type INTO category_type
    FROM information_schema.columns
    WHERE table_name = 'ai_insights' AND column_name = 'category';
    
    category_is_varchar := (category_type = 'character varying');
    
    -- Report results
    IF has_new_columns AND missing_old_columns AND category_is_varchar THEN
        RAISE NOTICE 'Migration successful: AI Insights structure updated';
        RAISE NOTICE 'New structure: insight (TEXT), category (VARCHAR), actionable (BOOLEAN)';
        RAISE NOTICE 'Removed: title, message, job_id';
    ELSE
        IF NOT has_new_columns THEN
            RAISE EXCEPTION 'Migration failed: New columns (insight, actionable) not found';
        END IF;
        IF NOT missing_old_columns THEN
            RAISE WARNING 'Old columns (title, message, job_id) still exist';
        END IF;
        IF NOT category_is_varchar THEN
            RAISE WARNING 'Category column type is % instead of VARCHAR', category_type;
        END IF;
    END IF;
END $$;

-- ROLLBACK SCRIPT (save for reference, do not execute):
-- This rollback is destructive because we're dropping columns with data
-- ALTER TABLE ai_insights ADD COLUMN title VARCHAR(255);
-- ALTER TABLE ai_insights ADD COLUMN message TEXT;
-- ALTER TABLE ai_insights ADD COLUMN job_id VARCHAR(255);
-- -- Would need to parse insight field to recreate title/message (data loss likely)
-- ALTER TABLE ai_insights DROP COLUMN insight;
-- ALTER TABLE ai_insights DROP COLUMN actionable;
-- -- Would need to recreate category enum and migrate data back
