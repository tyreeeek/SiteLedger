-- Add geofence columns to jobs table
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS geofence_enabled BOOLEAN DEFAULT false;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS geofence_radius INTEGER DEFAULT 100;
