-- ===============================================
-- COMPANY_RESEARCH TABLE
-- Date: 2025-10-27
-- Purpose: Cached company research data from web scraping
-- Reference: SUPABASE_SCHEMA_SYNTAX_REFERENCE.md
-- ===============================================

-- 1. CREATE TABLE
CREATE TABLE IF NOT EXISTS company_research (
  -- Primary identification
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Company identification
  company_name TEXT,
  company_url TEXT NOT NULL,

  -- Research data (JSONB contains all scraped/searched data)
  research_data JSONB DEFAULT '{}'::jsonb,

  -- Cache metadata
  cached_at TIMESTAMPTZ DEFAULT NOW(),

  -- Audit timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Constraints
  CONSTRAINT valid_company_url CHECK (company_url ~* '^https?://')
);

-- 2. CREATE INDEXES
CREATE INDEX IF NOT EXISTS idx_company_research_user_id ON company_research(user_id);
CREATE INDEX IF NOT EXISTS idx_company_research_url ON company_research(company_url);
CREATE INDEX IF NOT EXISTS idx_company_research_cached_at ON company_research(cached_at DESC);
CREATE INDEX IF NOT EXISTS idx_company_research_data_gin ON company_research USING GIN (research_data);
CREATE INDEX IF NOT EXISTS idx_company_research_name_fts ON company_research
  USING GIN (to_tsvector('english', company_name));

-- 3. CREATE TRIGGER
DROP TRIGGER IF EXISTS set_timestamp_company_research ON company_research;
CREATE TRIGGER set_timestamp_company_research
    BEFORE UPDATE ON company_research
    FOR EACH ROW EXECUTE FUNCTION public.tg_set_timestamp();

-- 4. ENABLE RLS
ALTER TABLE company_research ENABLE ROW LEVEL SECURITY;

-- 5. CREATE RLS POLICIES
DROP POLICY IF EXISTS "Users can view their own research" ON company_research;
CREATE POLICY "Users can view their own research" ON company_research
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own research" ON company_research;
CREATE POLICY "Users can insert their own research" ON company_research
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own research" ON company_research;
CREATE POLICY "Users can update their own research" ON company_research
    FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own research" ON company_research;
CREATE POLICY "Users can delete their own research" ON company_research
    FOR DELETE USING (auth.uid() = user_id);

-- 6. ENABLE REALTIME
ALTER PUBLICATION supabase_realtime ADD TABLE company_research;

-- 7. GRANT PERMISSIONS
GRANT ALL ON company_research TO authenticated;

-- 8. ADD COMMENTS
COMMENT ON TABLE company_research IS 'Cached company research data from web scraping and search';
COMMENT ON COLUMN company_research.user_id IS 'User who initiated this research';
COMMENT ON COLUMN company_research.research_data IS 'JSONB containing all scraped/searched company data';
COMMENT ON COLUMN company_research.cached_at IS 'When this research data was last refreshed';
