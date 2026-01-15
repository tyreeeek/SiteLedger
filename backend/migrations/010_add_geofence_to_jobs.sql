-- Migration: Add geofence fields to jobs table
-- Date: 2026-01-15
-- Description: Adds geofence location and radius for time tracking validation

ALTER TABLE jobs 
ADD COLUMN IF NOT EXISTS geofence_enabled BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS geofence_latitude DECIMAL(10, 8),
ADD COLUMN IF NOT EXISTS geofence_longitude DECIMAL(11, 8),
ADD COLUMN IF NOT EXISTS geofence_radius DECIMAL(10, 2) DEFAULT 100.0;

COMMENT ON COLUMN jobs.geofence_enabled IS 'Whether geofence validation is enabled for this job';
COMMENT ON COLUMN jobs.geofence_latitude IS 'Latitude of job location for geofence center';
COMMENT ON COLUMN jobs.geofence_longitude IS 'Longitude of job location for geofence center';
COMMENT ON COLUMN jobs.geofence_radius IS 'Geofence radius in meters (default 100m)';

-- Add index for geofence queries
CREATE INDEX IF NOT EXISTS idx_jobs_geofence_enabled ON jobs(geofence_enabled) WHERE geofence_enabled = true;
