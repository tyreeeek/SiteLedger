-- Migration: Add AI Processing Fields to Receipts Table
-- Date: 2024-12-22
-- Description: Adds AI processing metadata fields to support receipt OCR and categorization

-- Add AI processing fields
ALTER TABLE receipts 
ADD COLUMN IF NOT EXISTS ai_processed BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS ai_confidence DECIMAL(3,2),
ADD COLUMN IF NOT EXISTS ai_flags TEXT[],
ADD COLUMN IF NOT EXISTS ai_suggested_category VARCHAR(50);

-- Add comments for documentation
COMMENT ON COLUMN receipts.ai_processed IS 'Whether AI has analyzed this receipt';
COMMENT ON COLUMN receipts.ai_confidence IS 'AI confidence score from 0.00 to 1.00';
COMMENT ON COLUMN receipts.ai_flags IS 'Array of AI-detected issues: duplicate, unusual_amount, missing_info, etc.';
COMMENT ON COLUMN receipts.ai_suggested_category IS 'AI-suggested category for the receipt';

-- Create index for querying unprocessed receipts
CREATE INDEX IF NOT EXISTS idx_receipts_ai_processed ON receipts(ai_processed) WHERE ai_processed = false;

-- Create index for low confidence receipts (needs human review)
CREATE INDEX IF NOT EXISTS idx_receipts_low_confidence ON receipts(ai_confidence) WHERE ai_confidence < 0.70;

-- Verify migration
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'receipts' 
        AND column_name IN ('ai_processed', 'ai_confidence', 'ai_flags', 'ai_suggested_category')
    ) THEN
        RAISE NOTICE 'Migration successful: AI fields added to receipts table';
    ELSE
        RAISE EXCEPTION 'Migration failed: AI fields not found in receipts table';
    END IF;
END $$;
