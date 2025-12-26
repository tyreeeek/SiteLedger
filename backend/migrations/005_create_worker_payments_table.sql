-- Migration: Create Worker Payments Table
-- Date: 2024-12-22
-- Description: Creates worker_payments table for tracking payroll and worker compensation

-- Create enum type for payment methods
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'payment_method_enum') THEN
        CREATE TYPE payment_method_enum AS ENUM (
            'cash',
            'check',
            'bank_transfer',
            'paypal',
            'venmo',
            'zelle',
            'other'
        );
        RAISE NOTICE 'Created payment_method_enum type';
    END IF;
END $$;

-- Create worker_payments table
CREATE TABLE IF NOT EXISTS worker_payments (
    id VARCHAR(255) PRIMARY KEY,
    owner_id VARCHAR(255) NOT NULL,
    worker_id VARCHAR(255) NOT NULL,
    worker_name VARCHAR(255) NOT NULL,
    amount DECIMAL(10,2) NOT NULL CHECK (amount >= 0),
    payment_date TIMESTAMP NOT NULL,
    period_start TIMESTAMP NOT NULL,
    period_end TIMESTAMP NOT NULL,
    hours_worked DECIMAL(10,2) NOT NULL CHECK (hours_worked >= 0),
    hourly_rate DECIMAL(10,2) NOT NULL CHECK (hourly_rate >= 0),
    calculated_earnings DECIMAL(10,2) NOT NULL CHECK (calculated_earnings >= 0),
    payment_method payment_method_enum NOT NULL DEFAULT 'cash',
    notes TEXT,
    reference_number VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Add comments for documentation
COMMENT ON TABLE worker_payments IS 'Tracks worker payroll and compensation payments';
COMMENT ON COLUMN worker_payments.id IS 'Unique payment record ID';
COMMENT ON COLUMN worker_payments.owner_id IS 'ID of owner making the payment';
COMMENT ON COLUMN worker_payments.worker_id IS 'ID of worker receiving payment';
COMMENT ON COLUMN worker_payments.worker_name IS 'Name of worker (denormalized for quick display)';
COMMENT ON COLUMN worker_payments.amount IS 'Actual amount paid to worker';
COMMENT ON COLUMN worker_payments.payment_date IS 'Date payment was issued';
COMMENT ON COLUMN worker_payments.period_start IS 'Start of pay period';
COMMENT ON COLUMN worker_payments.period_end IS 'End of pay period';
COMMENT ON COLUMN worker_payments.hours_worked IS 'Total hours worked in this pay period';
COMMENT ON COLUMN worker_payments.hourly_rate IS 'Hourly rate for this payment period';
COMMENT ON COLUMN worker_payments.calculated_earnings IS 'hours_worked × hourly_rate (may differ from amount if adjustments made)';
COMMENT ON COLUMN worker_payments.payment_method IS 'Method used to pay worker: cash, check, bank_transfer, paypal, venmo, zelle, other';
COMMENT ON COLUMN worker_payments.notes IS 'Additional notes about payment (adjustments, bonuses, deductions)';
COMMENT ON COLUMN worker_payments.reference_number IS 'Check number, transaction ID, or other payment reference';
COMMENT ON COLUMN worker_payments.created_at IS 'When this payment record was created';

-- Create foreign key constraints
DO $$
BEGIN
    -- FK to users table for owner_id
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'fk_worker_payments_owner' AND table_name = 'worker_payments'
    ) THEN
        ALTER TABLE worker_payments 
        ADD CONSTRAINT fk_worker_payments_owner 
        FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE;
        
        RAISE NOTICE 'Foreign key constraint fk_worker_payments_owner created';
    END IF;
    
    -- FK to users table for worker_id
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'fk_worker_payments_worker' AND table_name = 'worker_payments'
    ) THEN
        ALTER TABLE worker_payments 
        ADD CONSTRAINT fk_worker_payments_worker 
        FOREIGN KEY (worker_id) REFERENCES users(id) ON DELETE CASCADE;
        
        RAISE NOTICE 'Foreign key constraint fk_worker_payments_worker created';
    END IF;
END $$;

-- Create indexes for common queries
CREATE INDEX IF NOT EXISTS idx_worker_payments_owner_id ON worker_payments(owner_id);
CREATE INDEX IF NOT EXISTS idx_worker_payments_worker_id ON worker_payments(worker_id);
CREATE INDEX IF NOT EXISTS idx_worker_payments_payment_date ON worker_payments(payment_date);
CREATE INDEX IF NOT EXISTS idx_worker_payments_period ON worker_payments(period_start, period_end);
CREATE INDEX IF NOT EXISTS idx_worker_payments_method ON worker_payments(payment_method);

-- Create composite index for owner filtering and date sorting (common query pattern)
CREATE INDEX IF NOT EXISTS idx_worker_payments_owner_date ON worker_payments(owner_id, payment_date DESC);

-- Create composite index for worker payment history
CREATE INDEX IF NOT EXISTS idx_worker_payments_worker_date ON worker_payments(worker_id, payment_date DESC);

-- Verify migration
DO $$
DECLARE
    table_exists BOOLEAN;
    column_count INTEGER;
    index_count INTEGER;
    fk_count INTEGER;
BEGIN
    -- Check if table exists
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'worker_payments'
    ) INTO table_exists;
    
    -- Count columns
    SELECT COUNT(*) INTO column_count
    FROM information_schema.columns
    WHERE table_name = 'worker_payments';
    
    -- Count indexes
    SELECT COUNT(*) INTO index_count
    FROM pg_indexes
    WHERE tablename = 'worker_payments';
    
    -- Count foreign keys
    SELECT COUNT(*) INTO fk_count
    FROM information_schema.table_constraints
    WHERE table_name = 'worker_payments' AND constraint_type = 'FOREIGN KEY';
    
    -- Report results
    IF table_exists THEN
        RAISE NOTICE 'Migration successful: worker_payments table created';
        RAISE NOTICE 'Columns: % | Indexes: % | Foreign Keys: %', column_count, index_count, fk_count;
        
        IF column_count < 15 THEN
            RAISE WARNING 'Expected 15 columns, found %', column_count;
        END IF;
        
        IF fk_count < 2 THEN
            RAISE WARNING 'Expected 2 foreign keys (owner_id, worker_id), found %', fk_count;
        END IF;
    ELSE
        RAISE EXCEPTION 'Migration failed: worker_payments table not created';
    END IF;
END $$;

-- ROLLBACK SCRIPT (save for reference, do not execute):
-- DROP TABLE IF EXISTS worker_payments CASCADE;
-- DROP TYPE IF EXISTS payment_method_enum CASCADE;
