-- Migration: Create Client Payments Table
-- Description: Tracks payments received from clients for specific jobs

-- Create client_payments table
CREATE TABLE IF NOT EXISTS client_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    job_id UUID NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
    amount DECIMAL(12, 2) NOT NULL CHECK (amount > 0),
    method VARCHAR(50) NOT NULL, -- cash, check, wire, etc.
    date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    reference VARCHAR(255), -- check number, transaction ID
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id)
);

-- Index for faster lookups
CREATE INDEX IF NOT EXISTS idx_client_payments_job_id ON client_payments(job_id);

-- Add comment
COMMENT ON TABLE client_payments IS 'Tracks payments received from clients for jobs';
