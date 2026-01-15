-- Migration 008: Add user preferences columns
-- Adds AI automation settings, notification preferences, and theme preference

ALTER TABLE users ADD COLUMN IF NOT EXISTS ai_automation_settings JSONB DEFAULT '{
    "automationLevel": "assist",
    "autoFillReceipts": true,
    "autoAssignJobs": true,
    "autoCalculateLaborCosts": true,
    "autoGenerateSummaries": false,
    "autoGenerateInsights": true
}'::jsonb;

ALTER TABLE users ADD COLUMN IF NOT EXISTS notification_preferences JSONB DEFAULT '{
    "emailNotifications": true,
    "pushNotifications": true,
    "timesheetReminders": true,
    "jobUpdates": true,
    "workerMessages": true,
    "aiInsights": true
}'::jsonb;

ALTER TABLE users ADD COLUMN IF NOT EXISTS theme_preference VARCHAR(20) DEFAULT 'system';

-- Create indexes for JSONB columns
CREATE INDEX IF NOT EXISTS idx_users_ai_automation ON users USING GIN (ai_automation_settings);
CREATE INDEX IF NOT EXISTS idx_users_notifications ON users USING GIN (notification_preferences);
