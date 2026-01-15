-- Add password reset token fields to users table
-- Migration: 1000_password_reset_tokens.sql

ALTER TABLE users ADD COLUMN IF NOT EXISTS reset_token TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS reset_token_expires TIMESTAMP;

CREATE INDEX IF NOT EXISTS idx_users_reset_token_expires ON users(reset_token_expires) WHERE reset_token IS NOT NULL;

-- Log migration
DO $$
BEGIN
    RAISE NOTICE 'Migration 1000: Added password reset token fields';
END $$;
