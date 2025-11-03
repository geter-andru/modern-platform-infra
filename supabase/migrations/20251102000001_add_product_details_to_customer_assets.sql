-- Migration: Add product_details column to customer_assets table
-- Date: 2025-11-02
-- Purpose: Store auto-extracted product information from company website
-- Related: Task 2.1 - Automatic Product Extraction

-- Add product_details JSONB column
ALTER TABLE customer_assets
ADD COLUMN IF NOT EXISTS product_details JSONB;

-- Add index for faster queries on product_details
CREATE INDEX IF NOT EXISTS idx_customer_assets_product_details
ON customer_assets USING GIN (product_details);

-- Add comment documenting the column
COMMENT ON COLUMN customer_assets.product_details IS
'Auto-extracted product information from company website. Schema: { productName, description, distinguishingFeature, businessModel, sourceUrl, extractedAt, fallback }';

-- Example data structure:
-- {
--   "productName": "Greptile",
--   "description": "AI-powered code search and navigation",
--   "distinguishingFeature": "Natural language code search across repositories",
--   "businessModel": "B2B SaaS",
--   "sourceUrl": "https://greptile.com",
--   "extractedAt": "2025-11-02T12:00:00.000Z",
--   "fallback": false
-- }
