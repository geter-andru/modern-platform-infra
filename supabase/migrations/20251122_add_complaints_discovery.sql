-- ===============================================
-- COMPLAINTS DISCOVERY TABLES
-- Date: 2025-11-22
-- Purpose: Store and analyze user complaints from Reddit, Quora, Twitter
--          for ICP discovery and demand validation
-- ===============================================

-- ===============================================
-- 1. COMPLAINTS TABLE - Raw complaint data
-- ===============================================

CREATE TABLE IF NOT EXISTS complaints (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,

    -- Source information
    platform TEXT NOT NULL CHECK (platform IN ('reddit', 'quora', 'twitter', 'linkedin', 'indie_hackers', 'hacker_news')),
    subreddit TEXT,
    post_url TEXT NOT NULL,
    post_id TEXT,
    author TEXT,

    -- Content
    title TEXT,
    raw_text TEXT NOT NULL,

    -- AI-extracted data
    extracted_problem TEXT,
    exact_phrases JSONB DEFAULT '[]'::jsonb,
    pain_score INTEGER CHECK (pain_score >= 1 AND pain_score <= 10),
    category TEXT CHECK (category IN ('validation', 'sales', 'product', 'hiring', 'marketing', 'fundraising', 'operations', 'other')),

    -- Engagement metrics
    upvotes INTEGER DEFAULT 0,
    comments_count INTEGER DEFAULT 0,

    -- Processing status
    is_processed BOOLEAN DEFAULT false,
    is_relevant BOOLEAN DEFAULT true,

    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb,

    -- Timestamps
    post_date TIMESTAMPTZ,
    scraped_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Constraints
    CONSTRAINT unique_post_url UNIQUE (post_url)
);

-- ===============================================
-- 2. COMPLAINT_PATTERNS TABLE - Aggregated patterns
-- ===============================================

CREATE TABLE IF NOT EXISTS complaint_patterns (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,

    -- Pattern identification
    problem_statement TEXT NOT NULL,
    category TEXT CHECK (category IN ('validation', 'sales', 'product', 'hiring', 'marketing', 'fundraising', 'operations', 'other')),

    -- Frequency tracking
    frequency_count INTEGER DEFAULT 1,
    first_seen_at TIMESTAMPTZ DEFAULT NOW(),
    last_seen_at TIMESTAMPTZ DEFAULT NOW(),

    -- Key phrases (exact language used)
    key_phrases JSONB DEFAULT '[]'::jsonb,

    -- Aggregate pain score
    avg_pain_score DECIMAL(3,1),

    -- Related complaints
    complaint_ids JSONB DEFAULT '[]'::jsonb,

    -- Platforms where this pattern appears
    platforms JSONB DEFAULT '[]'::jsonb,

    -- Actionability
    is_actionable BOOLEAN DEFAULT true,
    action_notes TEXT,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Constraints
    CONSTRAINT unique_problem_statement UNIQUE (problem_statement)
);

-- ===============================================
-- 3. SCRAPE_RUNS TABLE - Track scraping history
-- ===============================================

CREATE TABLE IF NOT EXISTS complaint_scrape_runs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,

    -- Run information
    platform TEXT NOT NULL,
    search_terms JSONB DEFAULT '[]'::jsonb,
    subreddits_scraped JSONB DEFAULT '[]'::jsonb,

    -- Results
    posts_found INTEGER DEFAULT 0,
    complaints_identified INTEGER DEFAULT 0,
    new_complaints INTEGER DEFAULT 0,

    -- Status
    status TEXT DEFAULT 'running' CHECK (status IN ('running', 'completed', 'failed')),
    error_message TEXT,

    -- Timestamps
    started_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ===============================================
-- 4. INDEXES
-- ===============================================

-- Complaints indexes
CREATE INDEX IF NOT EXISTS idx_complaints_platform ON complaints(platform);
CREATE INDEX IF NOT EXISTS idx_complaints_category ON complaints(category);
CREATE INDEX IF NOT EXISTS idx_complaints_pain_score ON complaints(pain_score DESC);
CREATE INDEX IF NOT EXISTS idx_complaints_is_processed ON complaints(is_processed);
CREATE INDEX IF NOT EXISTS idx_complaints_created_at ON complaints(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_complaints_scraped_at ON complaints(scraped_at DESC);
CREATE INDEX IF NOT EXISTS idx_complaints_subreddit ON complaints(subreddit);

-- Patterns indexes
CREATE INDEX IF NOT EXISTS idx_complaint_patterns_category ON complaint_patterns(category);
CREATE INDEX IF NOT EXISTS idx_complaint_patterns_frequency ON complaint_patterns(frequency_count DESC);
CREATE INDEX IF NOT EXISTS idx_complaint_patterns_pain_score ON complaint_patterns(avg_pain_score DESC);
CREATE INDEX IF NOT EXISTS idx_complaint_patterns_created_at ON complaint_patterns(created_at DESC);

-- Scrape runs indexes
CREATE INDEX IF NOT EXISTS idx_complaint_scrape_runs_platform ON complaint_scrape_runs(platform);
CREATE INDEX IF NOT EXISTS idx_complaint_scrape_runs_status ON complaint_scrape_runs(status);
CREATE INDEX IF NOT EXISTS idx_complaint_scrape_runs_created_at ON complaint_scrape_runs(created_at DESC);

-- ===============================================
-- 5. TRIGGERS
-- ===============================================

-- Update complaints updated_at
DROP TRIGGER IF EXISTS update_complaints_updated_at ON complaints;
CREATE TRIGGER update_complaints_updated_at
    BEFORE UPDATE ON complaints
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Update complaint_patterns updated_at
DROP TRIGGER IF EXISTS update_complaint_patterns_updated_at ON complaint_patterns;
CREATE TRIGGER update_complaint_patterns_updated_at
    BEFORE UPDATE ON complaint_patterns
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ===============================================
-- 6. RLS - Service role only (automated system)
-- ===============================================

ALTER TABLE complaints ENABLE ROW LEVEL SECURITY;
ALTER TABLE complaint_patterns ENABLE ROW LEVEL SECURITY;
ALTER TABLE complaint_scrape_runs ENABLE ROW LEVEL SECURITY;

-- Service role full access for automated workflows
DROP POLICY IF EXISTS "Service role full access on complaints" ON complaints;
CREATE POLICY "Service role full access on complaints" ON complaints
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

DROP POLICY IF EXISTS "Service role full access on complaint_patterns" ON complaint_patterns;
CREATE POLICY "Service role full access on complaint_patterns" ON complaint_patterns
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

DROP POLICY IF EXISTS "Service role full access on complaint_scrape_runs" ON complaint_scrape_runs;
CREATE POLICY "Service role full access on complaint_scrape_runs" ON complaint_scrape_runs
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- Authenticated users can view (for admin dashboard)
DROP POLICY IF EXISTS "Authenticated users can view complaints" ON complaints;
CREATE POLICY "Authenticated users can view complaints" ON complaints
    FOR SELECT
    TO authenticated
    USING (true);

DROP POLICY IF EXISTS "Authenticated users can view complaint_patterns" ON complaint_patterns;
CREATE POLICY "Authenticated users can view complaint_patterns" ON complaint_patterns
    FOR SELECT
    TO authenticated
    USING (true);

DROP POLICY IF EXISTS "Authenticated users can view complaint_scrape_runs" ON complaint_scrape_runs;
CREATE POLICY "Authenticated users can view complaint_scrape_runs" ON complaint_scrape_runs
    FOR SELECT
    TO authenticated
    USING (true);

-- ===============================================
-- 7. REALTIME
-- ===============================================

ALTER PUBLICATION supabase_realtime ADD TABLE complaints;
ALTER PUBLICATION supabase_realtime ADD TABLE complaint_patterns;

-- ===============================================
-- 8. PERMISSIONS
-- ===============================================

GRANT ALL ON complaints TO service_role;
GRANT SELECT ON complaints TO authenticated;

GRANT ALL ON complaint_patterns TO service_role;
GRANT SELECT ON complaint_patterns TO authenticated;

GRANT ALL ON complaint_scrape_runs TO service_role;
GRANT SELECT ON complaint_scrape_runs TO authenticated;

-- ===============================================
-- 9. COMMENTS
-- ===============================================

COMMENT ON TABLE complaints IS 'Raw complaints scraped from Reddit, Quora, Twitter for ICP discovery';
COMMENT ON COLUMN complaints.platform IS 'Source platform (reddit, quora, twitter, etc.)';
COMMENT ON COLUMN complaints.exact_phrases IS 'Array of exact phrases used by the poster - critical for messaging';
COMMENT ON COLUMN complaints.pain_score IS 'AI-assigned pain intensity score 1-10';
COMMENT ON COLUMN complaints.category IS 'Problem category for grouping';

COMMENT ON TABLE complaint_patterns IS 'Aggregated complaint patterns with frequency tracking';
COMMENT ON COLUMN complaint_patterns.problem_statement IS 'Normalized problem statement';
COMMENT ON COLUMN complaint_patterns.key_phrases IS 'Most common exact phrases for this problem';
COMMENT ON COLUMN complaint_patterns.frequency_count IS 'How many times this pattern has been seen';

COMMENT ON TABLE complaint_scrape_runs IS 'History of scraping runs for tracking and debugging';
