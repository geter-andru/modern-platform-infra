-- ===============================================
-- ICP_FRAMEWORKS TABLE
-- Date: 2025-10-27
-- Purpose: Core ICP framework data from Product Details widget
-- Reference: SUPABASE_SCHEMA_SYNTAX_REFERENCE.md
-- NOTE: This is migration 000 - must be applied FIRST
-- ===============================================

-- 1. CREATE TABLE
CREATE TABLE IF NOT EXISTS icp_frameworks (
  -- Primary identification
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Product information
  product_name TEXT NOT NULL,
  product_description TEXT,
  value_proposition TEXT,

  -- Core ICP framework data (JSONB)
  framework JSONB NOT NULL DEFAULT '{}'::jsonb,

  -- Audit timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Constraints
  CONSTRAINT product_name_not_empty CHECK (char_length(product_name) >= 2)
);

-- 2. CREATE INDEXES
CREATE INDEX IF NOT EXISTS idx_icp_frameworks_user_id ON icp_frameworks(user_id);
CREATE INDEX IF NOT EXISTS idx_icp_frameworks_created_at ON icp_frameworks(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_icp_frameworks_product_name ON icp_frameworks(product_name);
CREATE INDEX IF NOT EXISTS idx_icp_frameworks_framework_gin ON icp_frameworks USING GIN (framework);
CREATE INDEX IF NOT EXISTS idx_icp_frameworks_description_fts ON icp_frameworks
  USING GIN (to_tsvector('english', product_description));

-- 3. CREATE TRIGGER
DROP TRIGGER IF EXISTS set_timestamp_icp_frameworks ON icp_frameworks;
CREATE TRIGGER set_timestamp_icp_frameworks
    BEFORE UPDATE ON icp_frameworks
    FOR EACH ROW EXECUTE FUNCTION public.tg_set_timestamp();

-- 4. ENABLE RLS
ALTER TABLE icp_frameworks ENABLE ROW LEVEL SECURITY;

-- 5. CREATE RLS POLICIES
DROP POLICY IF EXISTS "Users can view their own frameworks" ON icp_frameworks;
CREATE POLICY "Users can view their own frameworks" ON icp_frameworks
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own frameworks" ON icp_frameworks;
CREATE POLICY "Users can insert their own frameworks" ON icp_frameworks
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own frameworks" ON icp_frameworks;
CREATE POLICY "Users can update their own frameworks" ON icp_frameworks
    FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own frameworks" ON icp_frameworks;
CREATE POLICY "Users can delete their own frameworks" ON icp_frameworks
    FOR DELETE USING (auth.uid() = user_id);

-- 6. ENABLE REALTIME
ALTER PUBLICATION supabase_realtime ADD TABLE icp_frameworks;

-- 7. GRANT PERMISSIONS
GRANT ALL ON icp_frameworks TO authenticated;

-- 8. ADD COMMENTS
COMMENT ON TABLE icp_frameworks IS 'Core ICP frameworks generated from Product Details widget';
COMMENT ON COLUMN icp_frameworks.user_id IS 'User who created this framework';
COMMENT ON COLUMN icp_frameworks.framework IS 'JSONB containing buyerPersonas, valueCommunication, painPoints';
COMMENT ON COLUMN icp_frameworks.product_name IS 'Name of product being sold';
COMMENT ON COLUMN icp_frameworks.value_proposition IS 'Core value proposition for the product';
