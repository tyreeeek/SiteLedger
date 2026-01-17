-- Migration: Add Bank Information to Users Table
-- Description: Stores bank details for Direct Deposit

ALTER TABLE users 
ADD COLUMN IF NOT EXISTS bank_name VARCHAR(255),
ADD COLUMN IF NOT EXISTS account_holder_name VARCHAR(255),
ADD COLUMN IF NOT EXISTS account_number VARCHAR(255), -- Storing as plain text for MVP as per plan
ADD COLUMN IF NOT EXISTS routing_number VARCHAR(255),
ADD COLUMN IF NOT EXISTS account_type VARCHAR(50); -- checking, savings

COMMENT ON COLUMN users.account_number IS 'Direct Deposit Account Number';
COMMENT ON COLUMN users.routing_number IS 'Direct Deposit Routing Number';
