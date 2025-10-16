-- ===============================================
-- ADD TOKEN COLUMNS TO CUSTOMER_ASSETS
-- Date: January 16, 2025
-- Purpose: Support authentication token management in customer_assets table
-- ===============================================

-- Add token management columns
ALTER TABLE customer_assets 
ADD COLUMN IF NOT EXISTS token_generated_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS token_last_used TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS token_revoked_at TIMESTAMPTZ;

-- Create performance indexes
CREATE INDEX IF NOT EXISTS idx_customer_assets_token_generated_at 
ON customer_assets(token_generated_at);

CREATE INDEX IF NOT EXISTS idx_customer_assets_token_last_used 
ON customer_assets(token_last_used);

CREATE INDEX IF NOT EXISTS idx_customer_assets_token_revoked_at 
ON customer_assets(token_revoked_at);

-- Add documentation comments
COMMENT ON COLUMN customer_assets.token_generated_at IS 'Timestamp when access token was generated';
COMMENT ON COLUMN customer_assets.token_last_used IS 'Timestamp when access token was last used for authentication';
COMMENT ON COLUMN customer_assets.token_revoked_at IS 'Timestamp when access token was revoked';

-- This migration is safe to run multiple times due to IF NOT EXISTS clauses
-- All new columns default to NULL, which is appropriate for existing records
