-- Add 'approved' and 'rejected' values to timesheet_status enum if it exists
-- Or just ensure the application can use these values
-- Run this on the production PostgreSQL database

DO $$ 
BEGIN
    -- Check if 'timesheet_status' type exists
    IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'timesheet_status') THEN
        
        -- Check if 'approved' exists in the enum
        IF NOT EXISTS (
            SELECT 1 
            FROM pg_enum e
            JOIN pg_type t ON e.enumtypid = t.oid
            WHERE t.typname = 'timesheet_status' AND e.enumlabel = 'approved'
        ) THEN
            ALTER TYPE timesheet_status ADD VALUE 'approved';
            RAISE NOTICE 'Added "approved" to timesheet_status enum';
        END IF;

        -- Check if 'rejected' exists in the enum
        IF NOT EXISTS (
            SELECT 1 
            FROM pg_enum e
            JOIN pg_type t ON e.enumtypid = t.oid
            WHERE t.typname = 'timesheet_status' AND e.enumlabel = 'rejected'
        ) THEN
            ALTER TYPE timesheet_status ADD VALUE 'rejected';
            RAISE NOTICE 'Added "rejected" to timesheet_status enum';
        END IF;

    ELSE
        RAISE NOTICE 'timesheet_status enum does not exist, assuming text column';
    END IF;
END $$;
