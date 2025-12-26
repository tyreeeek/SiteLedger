-- SiteLedger PostgreSQL Schema
-- Designed for DigitalOcean Managed PostgreSQL
-- Run this file to create all tables

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- ENUM TYPES
-- =====================================================

CREATE TYPE user_role AS ENUM ('owner', 'worker');
CREATE TYPE job_status AS ENUM ('active', 'completed', 'on_hold');
CREATE TYPE timesheet_status AS ENUM ('working', 'completed', 'flagged');
CREATE TYPE document_type AS ENUM ('pdf', 'image', 'other');
CREATE TYPE document_category AS ENUM ('contract', 'invoice', 'estimate', 'permit', 'receipt', 'photo', 'blueprint', 'other');
CREATE TYPE alert_severity AS ENUM ('info', 'warning', 'critical');
CREATE TYPE alert_type AS ENUM ('budget', 'labor', 'receipt', 'document', 'timesheet', 'payment');
CREATE TYPE payment_method AS ENUM ('cash', 'check', 'direct_deposit', 'venmo', 'zelle', 'paypal', 'other');

-- =====================================================
-- USERS TABLE
-- =====================================================

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255),  -- NULL for Apple Sign-In users
    name VARCHAR(255) NOT NULL,
    role user_role NOT NULL DEFAULT 'owner',
    active BOOLEAN NOT NULL DEFAULT true,
    hourly_rate DECIMAL(10, 2),
    phone VARCHAR(50),
    photo_url TEXT,
    apple_user_id VARCHAR(255) UNIQUE,  -- For Apple Sign-In
    owner_id UUID REFERENCES users(id) ON DELETE SET NULL,  -- For workers, who manages them
    worker_permissions JSONB DEFAULT '{
        "canViewFinancials": false,
        "canUploadReceipts": true,
        "canApproveTimesheets": false,
        "canSeeAIInsights": false,
        "canViewAllJobs": false
    }'::jsonb,  -- Role-based permissions for workers
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Index for fast lookups
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_owner_id ON users(owner_id);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_apple_user_id ON users(apple_user_id);
CREATE INDEX idx_users_worker_permissions ON users USING GIN (worker_permissions);

-- =====================================================
-- JOBS TABLE
-- =====================================================

CREATE TABLE jobs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    job_name VARCHAR(255) NOT NULL,
    client_name VARCHAR(255) NOT NULL,
    address TEXT NOT NULL,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    start_date DATE NOT NULL,
    end_date DATE,
    status job_status NOT NULL DEFAULT 'active',
    notes TEXT DEFAULT '',
    project_value DECIMAL(12, 2) NOT NULL,
    amount_paid DECIMAL(12, 2) NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT positive_project_value CHECK (project_value > 0),
    CONSTRAINT non_negative_amount_paid CHECK (amount_paid >= 0),
    CONSTRAINT amount_paid_not_exceed_value CHECK (amount_paid <= project_value),
    CONSTRAINT valid_date_range CHECK (end_date IS NULL OR end_date >= start_date)
);

-- Indexes for common queries
CREATE INDEX idx_jobs_owner_id ON jobs(owner_id);
CREATE INDEX idx_jobs_status ON jobs(status);
CREATE INDEX idx_jobs_created_at ON jobs(created_at DESC);

-- =====================================================
-- WORKER ASSIGNMENTS (Junction table for many-to-many)
-- =====================================================

CREATE TABLE worker_job_assignments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    worker_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    job_id UUID NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
    assigned_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE(worker_id, job_id)
);

-- Indexes for assignments
CREATE INDEX idx_worker_job_assignments_worker_id ON worker_job_assignments(worker_id);
CREATE INDEX idx_worker_job_assignments_job_id ON worker_job_assignments(job_id);

-- =====================================================
-- RECEIPTS TABLE (Document storage only - NO financial impact)
-- =====================================================

CREATE TABLE receipts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    job_id UUID REFERENCES jobs(id) ON DELETE SET NULL,
    amount DECIMAL(12, 2) NOT NULL,  -- Display only, does NOT affect job finances
    vendor VARCHAR(255) NOT NULL,
    category VARCHAR(100),
    receipt_date DATE NOT NULL,
    image_url TEXT,
    notes TEXT DEFAULT '',
    
    -- AI Processing Fields
    ai_processed BOOLEAN NOT NULL DEFAULT false,
    ai_confidence DECIMAL(3, 2),  -- 0.00 to 1.00
    ai_flags TEXT[],  -- Array of flags like 'duplicate', 'unusual_amount'
    ai_suggested_category VARCHAR(100),
    
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_receipts_owner_id ON receipts(owner_id);
CREATE INDEX idx_receipts_job_id ON receipts(job_id);
CREATE INDEX idx_receipts_created_at ON receipts(created_at DESC);

-- =====================================================
-- TIMESHEETS TABLE
-- =====================================================

CREATE TABLE timesheets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    worker_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    job_id UUID NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
    clock_in TIMESTAMP WITH TIME ZONE NOT NULL,
    clock_out TIMESTAMP WITH TIME ZONE,
    hours DECIMAL(6, 2),  -- Can be null, calculated from clock_in/clock_out
    status timesheet_status NOT NULL DEFAULT 'working',
    notes TEXT DEFAULT '',
    
    -- Location tracking
    clock_in_location TEXT,
    clock_out_location TEXT,
    clock_in_latitude DECIMAL(10, 8),
    clock_in_longitude DECIMAL(11, 8),
    clock_out_latitude DECIMAL(10, 8),
    clock_out_longitude DECIMAL(11, 8),
    distance_from_job_site DECIMAL(10, 2),  -- In meters
    is_location_valid BOOLEAN,
    
    -- AI Flags
    ai_flags TEXT[],
    
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT valid_clock_times CHECK (clock_out IS NULL OR clock_out >= clock_in)
);

-- Indexes
CREATE INDEX idx_timesheets_owner_id ON timesheets(owner_id);
CREATE INDEX idx_timesheets_worker_id ON timesheets(worker_id);
CREATE INDEX idx_timesheets_job_id ON timesheets(job_id);
CREATE INDEX idx_timesheets_status ON timesheets(status);
CREATE INDEX idx_timesheets_created_at ON timesheets(created_at DESC);

-- =====================================================
-- DOCUMENTS TABLE
-- =====================================================

CREATE TABLE documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    job_id UUID REFERENCES jobs(id) ON DELETE SET NULL,
    file_url TEXT NOT NULL,
    file_type document_type NOT NULL,
    title VARCHAR(255) NOT NULL,
    notes TEXT DEFAULT '',
    
    -- AI Processing Fields
    ai_processed BOOLEAN NOT NULL DEFAULT false,
    ai_summary TEXT,
    ai_extracted_data JSONB,  -- Key-value pairs extracted by AI
    ai_confidence DECIMAL(3, 2),
    ai_flags TEXT[],
    document_category document_category,
    
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_documents_owner_id ON documents(owner_id);
CREATE INDEX idx_documents_job_id ON documents(job_id);
CREATE INDEX idx_documents_created_at ON documents(created_at DESC);

-- =====================================================
-- ALERTS TABLE
-- =====================================================

CREATE TABLE alerts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    job_id UUID REFERENCES jobs(id) ON DELETE SET NULL,
    type alert_type NOT NULL,
    severity alert_severity NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    action_url TEXT,
    read BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_alerts_owner_id ON alerts(owner_id);
CREATE INDEX idx_alerts_read ON alerts(read);
CREATE INDEX idx_alerts_created_at ON alerts(created_at DESC);

-- =====================================================
-- WORKER PAYMENTS TABLE
-- =====================================================

CREATE TABLE worker_payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    worker_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    worker_name VARCHAR(255) NOT NULL,  -- Denormalized for display
    amount DECIMAL(12, 2) NOT NULL,
    payment_date DATE NOT NULL,
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    hours_worked DECIMAL(8, 2) NOT NULL,
    hourly_rate DECIMAL(10, 2) NOT NULL,
    calculated_earnings DECIMAL(12, 2) NOT NULL,
    payment_method payment_method NOT NULL,
    notes TEXT,
    reference_number VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT positive_payment_amount CHECK (amount > 0),
    CONSTRAINT valid_period CHECK (period_end >= period_start)
);

-- Indexes
CREATE INDEX idx_worker_payments_owner_id ON worker_payments(owner_id);
CREATE INDEX idx_worker_payments_worker_id ON worker_payments(worker_id);
CREATE INDEX idx_worker_payments_payment_date ON worker_payments(payment_date DESC);

-- =====================================================
-- REFRESH TOKENS TABLE (for auth)
-- =====================================================

CREATE TABLE refresh_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    revoked BOOLEAN NOT NULL DEFAULT false
);

CREATE INDEX idx_refresh_tokens_user_id ON refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_token_hash ON refresh_tokens(token_hash);

-- =====================================================
-- HELPER FUNCTIONS
-- =====================================================

-- Function to calculate effective hours for a timesheet
CREATE OR REPLACE FUNCTION calculate_effective_hours(t timesheets)
RETURNS DECIMAL AS $$
BEGIN
    IF t.hours IS NOT NULL AND t.hours > 0 THEN
        RETURN t.hours;
    ELSIF t.clock_out IS NOT NULL THEN
        RETURN EXTRACT(EPOCH FROM (t.clock_out - t.clock_in)) / 3600.0;
    ELSE
        RETURN 0;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate labor cost for a job
CREATE OR REPLACE FUNCTION calculate_job_labor_cost(p_job_id UUID)
RETURNS DECIMAL AS $$
DECLARE
    total_cost DECIMAL := 0;
BEGIN
    SELECT COALESCE(SUM(
        calculate_effective_hours(t) * COALESCE(u.hourly_rate, 0)
    ), 0)
    INTO total_cost
    FROM timesheets t
    JOIN users u ON t.worker_id = u.id
    WHERE t.job_id = p_job_id;
    
    RETURN total_cost;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate job profit
CREATE OR REPLACE FUNCTION calculate_job_profit(p_job_id UUID)
RETURNS DECIMAL AS $$
DECLARE
    job_record jobs%ROWTYPE;
    labor_cost DECIMAL;
BEGIN
    SELECT * INTO job_record FROM jobs WHERE id = p_job_id;
    labor_cost := calculate_job_labor_cost(p_job_id);
    RETURN job_record.project_value - labor_cost;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- AUTO-UPDATE TIMESTAMPS TRIGGER
-- =====================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply to all tables with updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_jobs_updated_at BEFORE UPDATE ON jobs FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_receipts_updated_at BEFORE UPDATE ON receipts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_timesheets_updated_at BEFORE UPDATE ON timesheets FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_documents_updated_at BEFORE UPDATE ON documents FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
