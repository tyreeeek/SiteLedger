-- Migration: Add Google Sign-In support
-- Date: 2026-01-01
-- Description: Add google_user_id column to users table for Google OAuth

ALTER TABLE users 
ADD COLUMN IF NOT EXISTS google_user_id TEXT UNIQUE;

CREATE INDEX IF NOT EXISTS idx_users_google_user_id ON users(google_user_id);
