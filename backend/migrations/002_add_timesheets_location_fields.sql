-- Migration: Add Location Tracking and AI Fields to Timesheets Table
-- Date: 2024-12-22
-- Description: Adds GPS location tracking, distance validation, and AI anomaly detection to timesheets

-- Add owner tracking
ALTER TABLE timesheets 
ADD COLUMN IF NOT EXISTS owner_id VARCHAR(255);

-- Add job name for denormalization
ALTER TABLE timesheets 
ADD COLUMN IF NOT EXISTS job_name VARCHAR(255);

-- Add timesheet status
ALTER TABLE timesheets 
ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'completed';

-- Add location tracking fields
ALTER TABLE timesheets 
ADD COLUMN IF NOT EXISTS clock_in_location TEXT,
ADD COLUMN IF NOT EXISTS clock_out_location TEXT;

-- Add GPS coordinates for clock-in
ALTER TABLE timesheets 
ADD COLUMN IF NOT EXISTS clock_in_latitude DECIMAL(10,8),
ADD COLUMN IF NOT EXISTS clock_in_longitude DECIMAL(11,8);

-- Add GPS coordinates for clock-out
ALTER TABLE timesheets 
ADD COLUMN IF NOT EXISTS clock_out_latitude DECIMAL(10,8),
ADD COLUMN IF NOT EXISTS clock_out_longitude DECIMAL(11,8);

-- Add distance validation
ALTER TABLE timesheets 
ADD COLUMN IF NOT EXISTS distance_from_job_site DECIMAL(10,2),
ADD COLUMN IF NOT EXISTS is_location_valid BOOLEAN;

-- Add AI flags for anomaly detection
ALTER TABLE timesheets 
ADD COLUMN IF NOT EXISTS ai_flags TEXT[];

-- Add comments for documentation
COMMENT ON COLUMN timesheets.owner_id IS 'Owner who manages this timesheet';
COMMENT ON COLUMN timesheets.job_name IS 'Denormalized job name for quick display';
COMMENT ON COLUMN timesheets.status IS 'Timesheet status: working, completed, flagged';
COMMENT ON COLUMN timesheets.clock_in_location IS 'Address or coordinates where worker clocked in';
COMMENT ON COLUMN timesheets.clock_out_location IS 'Address or coordinates where worker clocked out';
COMMENT ON COLUMN timesheets.clock_in_latitude IS 'GPS latitude at clock-in';
COMMENT ON COLUMN timesheets.clock_in_longitude IS 'GPS longitude at clock-in';
COMMENT ON COLUMN timesheets.clock_out_latitude IS 'GPS latitude at clock-out';
COMMENT ON COLUMN timesheets.clock_out_longitude IS 'GPS longitude at clock-out';
COMMENT ON COLUMN timesheets.distance_from_job_site IS 'Distance in meters from job site at clock-in';
COMMENT ON COLUMN timesheets.is_location_valid IS 'Whether clock-in location is within acceptable radius of job site';
COMMENT ON COLUMN timesheets.ai_flags IS 'AI-detected anomalies: auto_checkout, unusual_hours, location_mismatch, etc.';

-- Create indexes for common queries
CREATE INDEX IF NOT EXISTS idx_timesheets_owner_id ON timesheets(owner_id);
CREATE INDEX IF NOT EXISTS idx_timesheets_status ON timesheets(status);
CREATE INDEX IF NOT EXISTS idx_timesheets_flagged ON timesheets(status) WHERE status = 'flagged';
CREATE INDEX IF NOT EXISTS idx_timesheets_invalid_location ON timesheets(is_location_valid) WHERE is_location_valid = false;

-- Add foreign key constraint if users table exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users') THEN
        ALTER TABLE timesheets 
        ADD CONSTRAINT fk_timesheets_owner 
        FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE;
        
        RAISE NOTICE 'Foreign key constraint added for owner_id';
    END IF;
END $$;

-- Verify migration
DO $$
DECLARE
    missing_columns TEXT[];
    expected_columns TEXT[] := ARRAY[
        'owner_id', 'job_name', 'status', 
        'clock_in_location', 'clock_out_location',
        'clock_in_latitude', 'clock_in_longitude',
        'clock_out_latitude', 'clock_out_longitude',
        'distance_from_job_site', 'is_location_valid',
        'ai_flags'
    ];
    col TEXT;
BEGIN
    FOREACH col IN ARRAY expected_columns
    LOOP
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'timesheets' AND column_name = col
        ) THEN
            missing_columns := array_append(missing_columns, col);
        END IF;
    END LOOP;
    
    IF array_length(missing_columns, 1) IS NULL THEN
        RAISE NOTICE 'Migration successful: All location and AI fields added to timesheets table';
    ELSE
        RAISE EXCEPTION 'Migration failed: Missing columns: %', array_to_string(missing_columns, ', ');
    END IF;
END $$;
