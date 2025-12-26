-- Migration: Add User Preferences (AI Automation, Notifications, Theme)
-- Description: Adds columns to users table for storing user preferences
-- Date: December 23, 2025

-- Add AI Automation preferences
ALTER TABLE users ADD COLUMN IF NOT EXISTS ai_automation_settings JSONB DEFAULT '{
  "automationLevel": "assist",
  "autoFillReceipts": true,
  "autoAssignJobs": true,
  "autoCalculateLaborCosts": true,
  "autoGenerateSummaries": false,
  "autoGenerateInsights": true
}'::jsonb;

-- Add Notifications preferences
ALTER TABLE users ADD COLUMN IF NOT EXISTS notification_preferences JSONB DEFAULT '{
  "email": {
    "enabled": true,
    "newJobs": true,
    "completedJobs": true,
    "budgetAlerts": true,
    "timesheetReminders": true,
    "paymentReminders": true
  },
  "push": {
    "enabled": false,
    "newJobs": false,
    "completedJobs": false,
    "budgetAlerts": false,
    "timesheetReminders": false,
    "paymentReminders": false
  }
}'::jsonb;

-- Add Theme preference
ALTER TABLE users ADD COLUMN IF NOT EXISTS theme VARCHAR(20) DEFAULT 'light' CHECK (theme IN ('light', 'dark', 'system'));

-- Add Data Retention preferences
ALTER TABLE users ADD COLUMN IF NOT EXISTS data_retention_settings JSONB DEFAULT '{
  "completedJobs": 365,
  "oldReceipts": 730,
  "timesheets": 1095,
  "documents": 1825,
  "autoArchive": true
}'::jsonb;

-- Create indexes for JSONB fields
CREATE INDEX IF NOT EXISTS idx_users_ai_automation_settings ON users USING GIN (ai_automation_settings);
CREATE INDEX IF NOT EXISTS idx_users_notification_preferences ON users USING GIN (notification_preferences);
CREATE INDEX IF NOT EXISTS idx_users_data_retention_settings ON users USING GIN (data_retention_settings);
CREATE INDEX IF NOT EXISTS idx_users_theme ON users(theme);

-- Update timestamp trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Ensure trigger exists
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Comments
COMMENT ON COLUMN users.ai_automation_settings IS 'User AI automation preferences and settings';
COMMENT ON COLUMN users.notification_preferences IS 'User notification preferences for email and push';
COMMENT ON COLUMN users.theme IS 'User interface theme preference (light, dark, system)';
COMMENT ON COLUMN users.data_retention_settings IS 'User data retention and archival preferences';
