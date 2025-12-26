-- SiteLedger Database Schema Update
-- Sync with iOS app structure
-- Run this migration on the backend database

-- 1. Create workers table (NEW)
CREATE TABLE IF NOT EXISTS workers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255),
  phone VARCHAR(50),
  hourly_rate DECIMAL(10,2) NOT NULL,
  role VARCHAR(100),
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_by VARCHAR(255)
);

CREATE INDEX IF NOT EXISTS idx_workers_active ON workers(active);
CREATE INDEX IF NOT EXISTS idx_workers_created_by ON workers(created_by);

-- 2. Create client_payments table (NEW)
CREATE TABLE IF NOT EXISTS client_payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  job_id UUID REFERENCES jobs(id) ON DELETE CASCADE,
  amount DECIMAL(10,2) NOT NULL,
  method VARCHAR(50) CHECK (method IN ('cash', 'check', 'bank_transfer', 'credit_card', 'other')),
  date DATE NOT NULL,
  reference VARCHAR(255),
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_by VARCHAR(255)
);

CREATE INDEX IF NOT EXISTS idx_client_payments_job ON client_payments(job_id);
CREATE INDEX IF NOT EXISTS idx_client_payments_date ON client_payments(date);

-- 3. Create ai_insights table (NEW)
CREATE TABLE IF NOT EXISTS ai_insights (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  job_id UUID REFERENCES jobs(id) ON DELETE CASCADE,
  job_name VARCHAR(255),
  type VARCHAR(50) CHECK (type IN ('cost_analysis', 'timeline_prediction', 'risk_assessment', 'optimization')),
  title VARCHAR(255) NOT NULL,
  summary TEXT NOT NULL,
  details TEXT,
  confidence INTEGER CHECK (confidence >= 0 AND confidence <= 100),
  recommendations TEXT[],
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_ai_insights_job ON ai_insights(job_id);
CREATE INDEX IF NOT EXISTS idx_ai_insights_type ON ai_insights(type);

-- 4. Update jobs table
ALTER TABLE jobs 
  ADD COLUMN IF NOT EXISTS location VARCHAR(500),
  ADD COLUMN IF NOT EXISTS client_payments_total DECIMAL(10,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS remaining_balance DECIMAL(10,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS total_cost DECIMAL(10,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS profit DECIMAL(10,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS assigned_workers TEXT[];

-- Update status column constraint if exists
ALTER TABLE jobs DROP CONSTRAINT IF EXISTS jobs_status_check;
ALTER TABLE jobs ADD CONSTRAINT jobs_status_check 
  CHECK (status IN ('planned', 'active', 'completed'));

-- 5. Update receipts table
ALTER TABLE receipts 
  ADD COLUMN IF NOT EXISTS ai_parsed_fields JSONB;

-- Update category constraint
ALTER TABLE receipts DROP CONSTRAINT IF EXISTS receipts_category_check;
ALTER TABLE receipts ADD CONSTRAINT receipts_category_check 
  CHECK (category IN ('materials', 'fuel', 'equipment', 'subcontractors', 'misc'));

-- 6. Update timesheets table
ALTER TABLE timesheets 
  RENAME COLUMN IF EXISTS user_id TO worker_id;

ALTER TABLE timesheets
  ADD COLUMN IF NOT EXISTS worker_name VARCHAR(255),
  ADD COLUMN IF NOT EXISTS job_name VARCHAR(255),
  ADD COLUMN IF NOT EXISTS duration_hours DECIMAL(5,2),
  ADD COLUMN IF NOT EXISTS labor_cost DECIMAL(10,2);

-- 7. Update alerts table severity constraint
ALTER TABLE alerts DROP CONSTRAINT IF EXISTS alerts_severity_check;
ALTER TABLE alerts ADD CONSTRAINT alerts_severity_check 
  CHECK (severity IN ('low', 'medium', 'high'));

ALTER TABLE alerts DROP CONSTRAINT IF EXISTS alerts_type_check;
ALTER TABLE alerts ADD CONSTRAINT alerts_type_check 
  CHECK (type IN ('budget', 'payment', 'timesheet', 'anomaly', 'info'));

-- 8. Create function to calculate job totals (auto-update on payment/receipt/timesheet changes)
CREATE OR REPLACE FUNCTION update_job_financials()
RETURNS TRIGGER AS $$
BEGIN
  -- Calculate client payments total
  UPDATE jobs SET client_payments_total = COALESCE((
    SELECT SUM(amount) FROM client_payments WHERE job_id = NEW.job_id
  ), 0) WHERE id = NEW.job_id;
  
  -- Calculate remaining balance
  UPDATE jobs SET remaining_balance = project_value - client_payments_total
  WHERE id = NEW.job_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for client_payments
DROP TRIGGER IF EXISTS update_job_on_payment ON client_payments;
CREATE TRIGGER update_job_on_payment
AFTER INSERT OR UPDATE OR DELETE ON client_payments
FOR EACH ROW EXECUTE FUNCTION update_job_financials();

-- Grant permissions (adjust role as needed)
GRANT ALL ON workers TO postgres;
GRANT ALL ON client_payments TO postgres;
GRANT ALL ON ai_insights TO postgres;

-- Migration complete
SELECT 'Database schema updated successfully!' as message;
