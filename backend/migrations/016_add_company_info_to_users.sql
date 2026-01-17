-- Add company info columns to users table
ALTER TABLE users 
ADD COLUMN company_name VARCHAR(255),
ADD COLUMN company_address TEXT,
ADD COLUMN company_logo_url TEXT;
