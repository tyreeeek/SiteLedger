-- Add 'cancelled' value to job_status enum if it doesn't exist
-- Run this on the production PostgreSQL database

DO $$ 
BEGIN
    -- Check if 'cancelled' already exists in the enum
    IF NOT EXISTS (
        SELECT 1 
        FROM pg_enum e
        JOIN pg_type t ON e.enumtypid = t.oid
        WHERE t.typname = 'job_status' AND e.enumlabel = 'cancelled'
    ) THEN
        -- Add the new enum value
        ALTER TYPE job_status ADD VALUE 'cancelled';
        RAISE NOTICE 'Successfully added "cancelled" to job_status enum';
    ELSE
        RAISE NOTICE '"cancelled" already exists in job_status enum';
    END IF;
END $$;

-- Verify the enum values
SELECT enumlabel 
FROM pg_enum e
JOIN pg_type t ON e.enumtypid = t.oid
WHERE t.typname = 'job_status'
ORDER BY enumlabel;
