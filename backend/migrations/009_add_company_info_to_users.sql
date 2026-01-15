-- Migration: Add company information fields to users table
-- Date: 2026-01-15
-- Description: Adds company branding and address fields to support multi-tenant company profiles

ALTER TABLE users 
ADD COLUMN IF NOT EXISTS company_name VARCHAR(255),
ADD COLUMN IF NOT EXISTS company_logo TEXT,
ADD COLUMN IF NOT EXISTS address_street VARCHAR(255),
ADD COLUMN IF NOT EXISTS address_city VARCHAR(100),
ADD COLUMN IF NOT EXISTS address_state VARCHAR(50),
ADD COLUMN IF NOT EXISTS address_zip VARCHAR(20),
ADD COLUMN IF NOT EXISTS company_phone VARCHAR(50),
ADD COLUMN IF NOT EXISTS company_email VARCHAR(255),
ADD COLUMN IF NOT EXISTS company_website TEXT,
ADD COLUMN IF NOT EXISTS company_tax_id VARCHAR(100);

-- Create index for company name searches
CREATE INDEX IF NOT EXISTS idx_users_company_name ON users(company_name);

COMMENT ON COLUMN users.company_name IS 'Company/business name for this user (owner branding)';
COMMENT ON COLUMN users.company_logo IS 'URL to company logo image';
COMMENT ON COLUMN users.address_street IS 'Street address (line 1)';
COMMENT ON COLUMN users.address_city IS 'City';
COMMENT ON COLUMN users.address_state IS 'State/Province';
COMMENT ON COLUMN users.address_zip IS 'ZIP/Postal code';
COMMENT ON COLUMN users.company_phone IS 'Company phone number';
COMMENT ON COLUMN users.company_email IS 'Company email address';
COMMENT ON COLUMN users.company_website IS 'Company website URL';
COMMENT ON COLUMN users.company_tax_id IS 'Tax ID/EIN for company';
