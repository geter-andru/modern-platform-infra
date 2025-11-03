-- ===============================================
-- BUYER_PERSONAS TABLE
-- Date: 2025-10-27
-- Purpose: AI-generated buyer personas for ICP
-- Reference: SUPABASE_SCHEMA_SYNTAX_REFERENCE.md
-- ===============================================

-- 1. CREATE TABLE
CREATE TABLE IF NOT EXISTS buyer_personas (
  -- Primary identification
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Core data
  personas JSONB NOT NULL DEFAULT '[]'::jsonb,  -- Array of persona objects

  -- Context metadata (used in AI generation)
  company_context TEXT,
  industry TEXT,
  target_market TEXT,

  -- Audit timestamps (CRITICAL: Use TIMESTAMPTZ not TIMESTAMP)
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Constraints
  CONSTRAINT personas_not_empty CHECK (jsonb_array_length(personas) > 0),
  CONSTRAINT valid_industry CHECK (char_length(industry) >= 2)
);

-- 2. CREATE INDEXES (CRITICAL: Separate CREATE INDEX statements, use IF NOT EXISTS)
CREATE INDEX IF NOT EXISTS idx_buyer_personas_user_id ON buyer_personas(user_id);
CREATE INDEX IF NOT EXISTS idx_buyer_personas_industry ON buyer_personas(industry);
CREATE INDEX IF NOT EXISTS idx_buyer_personas_created_at ON buyer_personas(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_buyer_personas_personas_gin ON buyer_personas USING GIN (personas);

-- 3. CREATE TRIGGER (CRITICAL: DROP first, then CREATE)
DROP TRIGGER IF EXISTS set_timestamp_buyer_personas ON buyer_personas;
CREATE TRIGGER set_timestamp_buyer_personas
    BEFORE UPDATE ON buyer_personas
    FOR EACH ROW EXECUTE FUNCTION public.tg_set_timestamp();

-- 4. ENABLE RLS
ALTER TABLE buyer_personas ENABLE ROW LEVEL SECURITY;

-- 5. CREATE RLS POLICIES (CRITICAL: DROP first, then CREATE)
DROP POLICY IF EXISTS "Users can view their own personas" ON buyer_personas;
CREATE POLICY "Users can view their own personas" ON buyer_personas
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own personas" ON buyer_personas;
CREATE POLICY "Users can insert their own personas" ON buyer_personas
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own personas" ON buyer_personas;
CREATE POLICY "Users can update their own personas" ON buyer_personas
    FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own personas" ON buyer_personas;
CREATE POLICY "Users can delete their own personas" ON buyer_personas
    FOR DELETE USING (auth.uid() = user_id);

-- 6. ENABLE REALTIME (CRITICAL: After table creation)
ALTER PUBLICATION supabase_realtime ADD TABLE buyer_personas;

-- 7. GRANT PERMISSIONS
GRANT ALL ON buyer_personas TO authenticated;

-- 8. ADD COMMENTS
COMMENT ON TABLE buyer_personas IS 'AI-generated buyer personas linked to customer ICP frameworks';
COMMENT ON COLUMN buyer_personas.user_id IS 'User who owns this persona set';
COMMENT ON COLUMN buyer_personas.personas IS 'JSONB array containing persona objects with title, demographics, psychographics, buyingBehavior';
COMMENT ON COLUMN buyer_personas.company_context IS 'User-provided company context used to generate personas';
