-- Migration: Add worker_permissions column to users table
-- Date: 2025-12-13
-- Purpose: Enable role-based permissions for worker accounts

-- Add worker_permissions column (JSONB for flexible permission storage)
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS worker_permissions JSONB DEFAULT '{
    "canViewFinancials": false,
    "canUploadReceipts": true,
    "canApproveTimesheets": false,
    "canSeeAIInsights": false,
    "canViewAllJobs": false
}'::jsonb;

-- Add index for faster JSONB queries
CREATE INDEX IF NOT EXISTS idx_users_worker_permissions ON users USING GIN (worker_permissions);

-- Update existing users with default permissions if NULL
UPDATE users 
SET worker_permissions = '{
    "canViewFinancials": false,
    "canUploadReceipts": true,
    "canApproveTimesheets": false,
    "canSeeAIInsights": false,
    "canViewAllJobs": false
}'::jsonb
WHERE worker_permissions IS NULL;

-- Verification query (uncomment to check)
-- SELECT id, name, role, worker_permissions FROM users;
