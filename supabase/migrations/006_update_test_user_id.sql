-- ============================================================================
-- UPDATE TEST USER ID FROM CUST_02 TO dru9K2L7M8N4P5Q6
-- This updates all references across all tables
-- ============================================================================

-- First, temporarily disable foreign key constraints to allow updates
ALTER TABLE assessment_results DROP CONSTRAINT IF EXISTS fk_assessment_customer;
ALTER TABLE customer_actions DROP CONSTRAINT IF EXISTS fk_actions_customer;

-- Update customer_assets table (primary table)
UPDATE customer_assets 
SET customer_id = 'dru9K2L7M8N4P5Q6' 
WHERE customer_id = 'CUST_02';

-- Update assessment_results table
UPDATE assessment_results 
SET customer_id = 'dru9K2L7M8N4P5Q6' 
WHERE customer_id = 'CUST_02';

-- Update customer_actions table
UPDATE customer_actions 
SET customer_id = 'dru9K2L7M8N4P5Q6' 
WHERE customer_id = 'CUST_02';

-- Re-add foreign key constraints
ALTER TABLE assessment_results 
ADD CONSTRAINT fk_assessment_customer 
FOREIGN KEY (customer_id) REFERENCES customer_assets(customer_id) ON DELETE CASCADE;

ALTER TABLE customer_actions 
ADD CONSTRAINT fk_actions_customer 
FOREIGN KEY (customer_id) REFERENCES customer_assets(customer_id) ON DELETE CASCADE;

-- Verify the update was successful
DO $$
DECLARE
    customer_count INTEGER;
    assessment_count INTEGER;
    action_count INTEGER;
BEGIN
    -- Check customer_assets
    SELECT COUNT(*) INTO customer_count 
    FROM customer_assets 
    WHERE customer_id = 'dru9K2L7M8N4P5Q6';
    
    -- Check assessment_results
    SELECT COUNT(*) INTO assessment_count 
    FROM assessment_results 
    WHERE customer_id = 'dru9K2L7M8N4P5Q6';
    
    -- Check customer_actions
    SELECT COUNT(*) INTO action_count 
    FROM customer_actions 
    WHERE customer_id = 'dru9K2L7M8N4P5Q6';
    
    -- Report results
    RAISE NOTICE 'Update Complete:';
    RAISE NOTICE '  - Customer Assets: % record(s) updated', customer_count;
    RAISE NOTICE '  - Assessment Results: % record(s) updated', assessment_count;
    RAISE NOTICE '  - Customer Actions: % record(s) updated', action_count;
    
    IF customer_count = 0 THEN
        RAISE WARNING 'No customer record found with new ID. Update may have failed.';
    END IF;
END $$;

-- Final verification query
SELECT 
    'Customer ID Update Summary' as status,
    customer_id,
    customer_name,
    email,
    access_token
FROM customer_assets 
WHERE customer_id = 'dru9K2L7M8N4P5Q6';