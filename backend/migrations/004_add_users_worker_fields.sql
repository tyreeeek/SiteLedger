-- Migration: Add Worker-Related Fields to Users Table
-- Date: 2024-12-22
-- Description: Adds fields needed for worker management, permissions, and owner-worker relationships

-- STEP 1: Add owner_id field for workers who belong to an owner
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS owner_id VARCHAR(255);

-- STEP 2: Add contact and profile fields
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS phone VARCHAR(20),
ADD COLUMN IF NOT EXISTS photo_url TEXT;

-- STEP 3: Add job assignment tracking
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS assigned_job_ids TEXT[] DEFAULT ARRAY[]::TEXT[];

-- STEP 4: Add worker permissions JSON object
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS worker_permissions JSONB DEFAULT '{"canViewFinancials": false, "canEditTimesheets": false, "canUploadReceipts": true, "canViewDocuments": true, "canChatWithAI": false}'::jsonb;

-- STEP 5: Add password status flag
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS has_password BOOLEAN DEFAULT true;

-- Add comments for documentation
COMMENT ON COLUMN users.owner_id IS 'ID of the owner this worker belongs to (null for owner accounts)';
COMMENT ON COLUMN users.phone IS 'Phone number for SMS notifications and contact';
COMMENT ON COLUMN users.photo_url IS 'Profile photo URL in storage bucket';
COMMENT ON COLUMN users.assigned_job_ids IS 'Array of job IDs this worker is assigned to';
COMMENT ON COLUMN users.worker_permissions IS 'JSON object with permission flags: canViewFinancials, canEditTimesheets, canUploadReceipts, canViewDocuments, canChatWithAI';
COMMENT ON COLUMN users.has_password IS 'Whether user has set up a password (false for workers created by owner without password)';

-- Create foreign key constraint for owner_id
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'owner_id') THEN
        -- Only add constraint if it doesn't already exist
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.table_constraints 
            WHERE constraint_name = 'fk_users_owner' AND table_name = 'users'
        ) THEN
            ALTER TABLE users 
            ADD CONSTRAINT fk_users_owner 
            FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE;
            
            RAISE NOTICE 'Foreign key constraint fk_users_owner created';
        END IF;
    END IF;
END $$;

-- Create indexes for common queries
CREATE INDEX IF NOT EXISTS idx_users_owner_id ON users(owner_id) WHERE owner_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone) WHERE phone IS NOT NULL;

-- Create GIN index for assigned_job_ids array (enables efficient array queries)
CREATE INDEX IF NOT EXISTS idx_users_assigned_jobs ON users USING GIN (assigned_job_ids);

-- Create GIN index for worker_permissions JSONB (enables querying within JSON)
CREATE INDEX IF NOT EXISTS idx_users_worker_permissions ON users USING GIN (worker_permissions);

-- Verify migration
DO $$
DECLARE
    missing_columns TEXT[];
    expected_columns TEXT[] := ARRAY['owner_id', 'phone', 'photo_url', 'assigned_job_ids', 'worker_permissions', 'has_password'];
    col TEXT;
BEGIN
    -- Check for missing columns
    FOREACH col IN ARRAY expected_columns
    LOOP
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'users' AND column_name = col
        ) THEN
            missing_columns := array_append(missing_columns, col);
        END IF;
    END LOOP;
    
    -- Report results
    IF array_length(missing_columns, 1) IS NULL THEN
        RAISE NOTICE 'Migration successful: All worker fields added to users table';
        RAISE NOTICE 'Added fields: owner_id, phone, photo_url, assigned_job_ids, worker_permissions, has_password';
    ELSE
        RAISE EXCEPTION 'Migration failed: Missing columns in users table: %', array_to_string(missing_columns, ', ');
    END IF;
END $$;

-- ROLLBACK SCRIPT (save for reference, do not execute):
-- ALTER TABLE users DROP CONSTRAINT IF EXISTS fk_users_owner;
-- ALTER TABLE users DROP COLUMN IF EXISTS owner_id, DROP COLUMN IF EXISTS phone, 
--     DROP COLUMN IF EXISTS photo_url, DROP COLUMN IF EXISTS assigned_job_ids, 
--     DROP COLUMN IF EXISTS worker_permissions, DROP COLUMN IF EXISTS has_password;
-- DROP INDEX IF EXISTS idx_users_owner_id, idx_users_phone, idx_users_assigned_jobs, idx_users_worker_permissions;
