-- Add split address fields to jobs table
ALTER TABLE jobs 
ADD COLUMN IF NOT EXISTS street VARCHAR(255),
ADD COLUMN IF NOT EXISTS city VARCHAR(100),
ADD COLUMN IF NOT EXISTS state VARCHAR(50),
ADD COLUMN IF NOT EXISTS zip VARCHAR(20);

-- Optional: Populate existing data (best effort)
-- This is a simple split, assuming comma separation. 
-- In production, might need more robust logic or leave as is.
-- UPDATE jobs 
-- SET 
--     street = split_part(address, ',', 1),
--     city = trim(split_part(address, ',', 2)),
--     state = trim(split_part(address, ',', 3))
-- WHERE address IS NOT NULL AND street IS NULL;
