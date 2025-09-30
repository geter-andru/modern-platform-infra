-- ===============================================
-- ADAPT CUSTOMER_ACTIONS TO EXISTING SCHEMA
-- Date: January 25, 2025
-- ===============================================

-- This migration adapts our schema to work with the existing customer_actions table
-- by adding missing columns that our API expects

-- ============================================================================
-- ADD MISSING COLUMNS TO EXISTING CUSTOMER_ACTIONS TABLE
-- ============================================================================

-- Add user_id column (critical for RLS and user association)
ALTER TABLE customer_actions 
ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- Add missing columns that our API expects
ALTER TABLE customer_actions 
ADD COLUMN IF NOT EXISTS action_title TEXT;

ALTER TABLE customer_actions 
ADD COLUMN IF NOT EXISTS customer_name TEXT;

ALTER TABLE customer_actions 
ADD COLUMN IF NOT EXISTS product_context TEXT;

ALTER TABLE customer_actions 
ADD COLUMN IF NOT EXISTS business_context TEXT;

ALTER TABLE customer_actions 
ADD COLUMN IF NOT EXISTS competency_impact JSONB DEFAULT '{}'::jsonb;

ALTER TABLE customer_actions 
ADD COLUMN IF NOT EXISTS revenue_impact DECIMAL(10,2);

ALTER TABLE customer_actions 
ADD COLUMN IF NOT EXISTS customer_satisfaction INTEGER CHECK (customer_satisfaction >= 1 AND customer_satisfaction <= 5);

ALTER TABLE customer_actions 
ADD COLUMN IF NOT EXISTS business_outcome TEXT;

-- ============================================================================
-- CREATE INDEXES FOR NEW COLUMNS
-- ============================================================================

-- Create index for user_id (critical for RLS performance)
CREATE INDEX IF NOT EXISTS idx_customer_actions_user_id ON customer_actions(user_id);

-- Create index for action_title for search functionality
CREATE INDEX IF NOT EXISTS idx_customer_actions_action_title ON customer_actions(action_title);

-- Create index for customer_name for filtering
CREATE INDEX IF NOT EXISTS idx_customer_actions_customer_name ON customer_actions(customer_name);

-- ============================================================================
-- UPDATE RLS POLICIES FOR CUSTOMER_ACTIONS
-- ============================================================================

-- Drop existing policies (if any)
DROP POLICY IF EXISTS "Users can view their own customer actions" ON customer_actions;
DROP POLICY IF EXISTS "Users can insert their own customer actions" ON customer_actions;
DROP POLICY IF EXISTS "Users can update their own customer actions" ON customer_actions;
DROP POLICY IF EXISTS "Users can delete their own customer actions" ON customer_actions;

-- Create new RLS policies that work with user_id
CREATE POLICY "Users can view their own customer actions" ON customer_actions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own customer actions" ON customer_actions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own customer actions" ON customer_actions
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own customer actions" ON customer_actions
    FOR DELETE USING (auth.uid() = user_id);

-- ============================================================================
-- DATA MIGRATION (if needed)
-- ============================================================================

-- Note: If there's existing data in customer_actions, we may need to:
-- 1. Set user_id for existing records (if we can determine the user)
-- 2. Populate action_title from action_description if needed
-- 3. Set other default values

-- For now, we'll leave existing data as-is and let the application handle new records

-- ============================================================================
-- GRANT PERMISSIONS
-- ============================================================================

-- Ensure authenticated users have proper permissions
GRANT ALL ON customer_actions TO authenticated;

-- ============================================================================
-- DOCUMENTATION
-- ============================================================================

COMMENT ON COLUMN customer_actions.user_id IS 'User who performed this action (required for RLS)';
COMMENT ON COLUMN customer_actions.action_title IS 'Short title/name for the action';
COMMENT ON COLUMN customer_actions.customer_name IS 'Name of the customer involved';
COMMENT ON COLUMN customer_actions.product_context IS 'Product-related context for the action';
COMMENT ON COLUMN customer_actions.business_context IS 'Business context and background';
COMMENT ON COLUMN customer_actions.competency_impact IS 'Impact on competency scores (JSON)';
COMMENT ON COLUMN customer_actions.revenue_impact IS 'Revenue impact in dollars';
COMMENT ON COLUMN customer_actions.customer_satisfaction IS 'Customer satisfaction rating (1-5)';
COMMENT ON COLUMN customer_actions.business_outcome IS 'Description of business outcome achieved';

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================

-- Log successful migration
DO $$
BEGIN
    RAISE NOTICE '✅ Customer actions schema adaptation completed successfully';
    RAISE NOTICE '📊 Added missing columns: user_id, action_title, customer_name, product_context, business_context, competency_impact, revenue_impact, customer_satisfaction, business_outcome';
    RAISE NOTICE '🔒 Updated RLS policies for user_id-based access control';
    RAISE NOTICE '⚡ Created performance indexes for new columns';
END $$;
