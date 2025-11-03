-- ===============================================
-- ADD BRAND_ASSETS COLUMN TO CUSTOMER_ASSETS TABLE
-- Date: 2025-11-02
-- Purpose: Store extracted brand assets (logo + colors) for branded PDF exports
-- ===============================================

-- Add brand_assets JSONB column to customer_assets table
ALTER TABLE customer_assets
ADD COLUMN IF NOT EXISTS brand_assets JSONB DEFAULT NULL;

-- Add column comment
COMMENT ON COLUMN customer_assets.brand_assets IS 'Extracted brand assets (logo URL, primary/secondary colors) for branded PDF exports. Structure: {"logo": "https://...", "colors": {"primary": "#3b82f6", "secondary": "#10b981"}, "extractedAt": "2025-11-02T04:00:00Z", "fallback": false}';

-- Note: No index needed - brand_assets is only retrieved with customer record, not queried independently
-- Note: No trigger needed - updated_at trigger already exists on customer_assets table
-- Note: No RLS policies needed - inherits existing customer_assets table policies
