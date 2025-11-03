-- ===============================================
-- COMPANY_RATINGS TABLE
-- Date: 2025-10-27
-- Purpose: AI-generated ratings of companies vs ICP
-- Reference: SUPABASE_SCHEMA_SYNTAX_REFERENCE.md
-- ===============================================

-- 1. CREATE TABLE
CREATE TABLE IF NOT EXISTS company_ratings (
  -- Primary identification
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Foreign key to ICP framework (optional - can rate without framework)
  icp_framework_id UUID REFERENCES icp_frameworks(id) ON DELETE SET NULL,

  -- Company identification
  company_url TEXT NOT NULL,
  company_name TEXT,

  -- Rating data
  rating INTEGER NOT NULL CHECK (rating >= 0 AND rating <= 100),
  reasoning TEXT NOT NULL,  -- AI explanation of rating

  -- Cached company data (to avoid re-scraping)
  company_data JSONB DEFAULT '{}'::jsonb,

  -- Metadata
  rating_version TEXT DEFAULT 'v1',  -- Track rating algorithm versions

  -- Audit timestamps (CRITICAL: Use TIMESTAMPTZ)
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Constraints
  CONSTRAINT valid_company_url CHECK (company_url ~* '^https?://'),
  CONSTRAINT reasoning_not_empty CHECK (char_length(reasoning) >= 10)
);

-- 2. CREATE INDEXES (CRITICAL: Use IF NOT EXISTS)
CREATE INDEX IF NOT EXISTS idx_company_ratings_user_id ON company_ratings(user_id);
CREATE INDEX IF NOT EXISTS idx_company_ratings_framework ON company_ratings(icp_framework_id);
CREATE INDEX IF NOT EXISTS idx_company_ratings_url ON company_ratings(company_url);
CREATE INDEX IF NOT EXISTS idx_company_ratings_rating ON company_ratings(rating DESC);
CREATE INDEX IF NOT EXISTS idx_company_ratings_created_at ON company_ratings(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_company_ratings_data_gin ON company_ratings USING GIN (company_data);

-- Full-text search on company names
CREATE INDEX IF NOT EXISTS idx_company_ratings_name_fts ON company_ratings
  USING GIN (to_tsvector('english', company_name));

-- 3. CREATE TRIGGER (CRITICAL: DROP first)
DROP TRIGGER IF EXISTS set_timestamp_company_ratings ON company_ratings;
CREATE TRIGGER set_timestamp_company_ratings
    BEFORE UPDATE ON company_ratings
    FOR EACH ROW EXECUTE FUNCTION public.tg_set_timestamp();

-- 4. ENABLE RLS
ALTER TABLE company_ratings ENABLE ROW LEVEL SECURITY;

-- 5. CREATE RLS POLICIES (CRITICAL: DROP first)
DROP POLICY IF EXISTS "Users can view their own ratings" ON company_ratings;
CREATE POLICY "Users can view their own ratings" ON company_ratings
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own ratings" ON company_ratings;
CREATE POLICY "Users can insert their own ratings" ON company_ratings
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own ratings" ON company_ratings;
CREATE POLICY "Users can update their own ratings" ON company_ratings
    FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own ratings" ON company_ratings;
CREATE POLICY "Users can delete their own ratings" ON company_ratings
    FOR DELETE USING (auth.uid() = user_id);

-- 6. ENABLE REALTIME (after table creation)
ALTER PUBLICATION supabase_realtime ADD TABLE company_ratings;

-- 7. GRANT PERMISSIONS
GRANT ALL ON company_ratings TO authenticated;

-- 8. ADD COMMENTS
COMMENT ON TABLE company_ratings IS 'AI-generated ratings of companies against ICP frameworks';
COMMENT ON COLUMN company_ratings.user_id IS 'User who created this rating';
COMMENT ON COLUMN company_ratings.rating IS 'Integer 0-100 representing ICP fit score';
COMMENT ON COLUMN company_ratings.reasoning IS 'AI-generated explanation of why this rating was given';
COMMENT ON COLUMN company_ratings.company_data IS 'Cached company research data to avoid re-scraping';
