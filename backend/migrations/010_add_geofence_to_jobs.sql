-- Migration: Add geofence fields to jobs table
-- Date: 2026-01-15
-- Description: Adds geofence toggle and radius for time tracking validation
-- Note: Uses existing latitude/longitude from job address, not separate coordinates

ALTER TABLE jobs 
ADD COLUMN IF NOT EXISTS geofence_enabled BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS geofence_radius DECIMAL(10, 2) DEFAULT 100.0;

COMMENT ON COLUMN jobs.geofence_enabled IS 'Whether geofence validation is enabled for this job (uses job address coordinates)';
COMMENT ON COLUMN jobs.geofence_radius IS 'Geofence radius in meters (default 100m)';

-- Add index for geofence queries
CREATE INDEX IF NOT EXISTS idx_jobs_geofence_enabled ON jobs(geofence_enabled) WHERE geofence_enabled = true;
