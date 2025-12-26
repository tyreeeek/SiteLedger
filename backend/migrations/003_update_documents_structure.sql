-- Migration: Rename file_name to title and Add AI Fields to Documents Table
-- Date: 2024-12-22
-- Description: Renames file_name column to title and adds AI processing metadata for document analysis

-- STEP 1: Rename file_name to title
ALTER TABLE documents 
RENAME COLUMN file_name TO title;

-- STEP 2: Add AI processing fields
ALTER TABLE documents 
ADD COLUMN IF NOT EXISTS ai_processed BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS ai_summary TEXT,
ADD COLUMN IF NOT EXISTS ai_extracted_data JSONB,
ADD COLUMN IF NOT EXISTS ai_confidence DECIMAL(3,2),
ADD COLUMN IF NOT EXISTS ai_flags TEXT[];

-- STEP 3: Add document category field
ALTER TABLE documents 
ADD COLUMN IF NOT EXISTS document_category VARCHAR(50);

-- STEP 4: Create enum type for document categories (if not exists)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'document_category_enum') THEN
        CREATE TYPE document_category_enum AS ENUM (
            'contract',
            'invoice',
            'estimate',
            'permit',
            'receipt',
            'photo',
            'blueprint',
            'other'
        );
        
        -- Update column to use enum
        ALTER TABLE documents 
        ALTER COLUMN document_category TYPE document_category_enum 
        USING document_category::document_category_enum;
        
        RAISE NOTICE 'Created document_category_enum type';
    END IF;
END $$;

-- Add comments for documentation
COMMENT ON COLUMN documents.title IS 'Document title (renamed from file_name)';
COMMENT ON COLUMN documents.ai_processed IS 'Whether AI has analyzed this document';
COMMENT ON COLUMN documents.ai_summary IS 'AI-generated summary of document contents';
COMMENT ON COLUMN documents.ai_extracted_data IS 'Structured data extracted by AI (key-value pairs in JSON)';
COMMENT ON COLUMN documents.ai_confidence IS 'AI confidence score from 0.00 to 1.00';
COMMENT ON COLUMN documents.ai_flags IS 'AI-detected issues: low_quality, missing_signature, incomplete, etc.';
COMMENT ON COLUMN documents.document_category IS 'AI-detected document type';

-- Create indexes for common queries
CREATE INDEX IF NOT EXISTS idx_documents_ai_processed ON documents(ai_processed) WHERE ai_processed = false;
CREATE INDEX IF NOT EXISTS idx_documents_category ON documents(document_category);
CREATE INDEX IF NOT EXISTS idx_documents_low_confidence ON documents(ai_confidence) WHERE ai_confidence < 0.70;

-- Create GIN index for JSONB extracted data (allows querying within JSON)
CREATE INDEX IF NOT EXISTS idx_documents_extracted_data ON documents USING GIN (ai_extracted_data);

-- Verify migration
DO $$
DECLARE
    has_title BOOLEAN;
    has_ai_fields BOOLEAN;
BEGIN
    -- Check if title column exists
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'documents' AND column_name = 'title'
    ) INTO has_title;
    
    -- Check if all AI fields exist
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'documents' 
        AND column_name IN ('ai_processed', 'ai_summary', 'ai_extracted_data', 'ai_confidence', 'ai_flags', 'document_category')
        GROUP BY table_name
        HAVING COUNT(*) = 6
    ) INTO has_ai_fields;
    
    IF has_title AND has_ai_fields THEN
        RAISE NOTICE 'Migration successful: file_name renamed to title and AI fields added to documents table';
    ELSE
        IF NOT has_title THEN
            RAISE EXCEPTION 'Migration failed: title column not found (file_name not renamed)';
        END IF;
        IF NOT has_ai_fields THEN
            RAISE EXCEPTION 'Migration failed: Not all AI fields added to documents table';
        END IF;
    END IF;
END $$;

-- ROLLBACK SCRIPT (save for reference, do not execute):
-- ALTER TABLE documents RENAME COLUMN title TO file_name;
-- ALTER TABLE documents DROP COLUMN IF EXISTS ai_processed, DROP COLUMN IF EXISTS ai_summary, 
--     DROP COLUMN IF EXISTS ai_extracted_data, DROP COLUMN IF EXISTS ai_confidence, 
--     DROP COLUMN IF EXISTS ai_flags, DROP COLUMN IF EXISTS document_category;
-- DROP TYPE IF EXISTS document_category_enum CASCADE;
