-- ===============================================
-- PUBLIC PAGE VISITS TRACKING
-- Date: 2025-11-12
-- Purpose: Track anonymous visitor funnel from public pages → assessment → signup → payment
-- ===============================================

-- ===============================================
-- 1. CREATE TABLE
-- ===============================================

CREATE TABLE IF NOT EXISTS public_page_visits (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,

    -- Session & User Tracking
    anonymous_session_id TEXT NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,

    -- Page Information
    page_path TEXT NOT NULL,
    page_title TEXT,
    referrer_url TEXT,

    -- UTM Parameters (Marketing Attribution)
    utm_source TEXT,
    utm_medium TEXT,
    utm_campaign TEXT,
    utm_term TEXT,
    utm_content TEXT,

    -- Device & Browser Information
    device_type TEXT CHECK (device_type IN ('desktop', 'mobile', 'tablet', 'unknown')),
    browser TEXT,
    user_agent TEXT,
    screen_width INTEGER,
    screen_height INTEGER,

    -- Engagement Metrics
    time_on_page INTEGER DEFAULT 0,
    scroll_depth INTEGER DEFAULT 0 CHECK (scroll_depth >= 0 AND scroll_depth <= 100),

    -- CTA Tracking
    clicked_cta BOOLEAN DEFAULT FALSE,
    cta_text TEXT,
    cta_location TEXT,

    -- Attribution Flags
    first_touch BOOLEAN DEFAULT FALSE,
    last_touch BOOLEAN DEFAULT FALSE,
    attributed_conversion BOOLEAN DEFAULT FALSE,

    -- IP & Location (optional)
    ip_address TEXT,
    country_code TEXT,

    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ===============================================
-- 2. CREATE INDEXES
-- ===============================================

-- Session-based queries (most common)
CREATE INDEX IF NOT EXISTS idx_public_page_visits_anonymous_session ON public_page_visits(anonymous_session_id);

-- User-based queries (after linking)
CREATE INDEX IF NOT EXISTS idx_public_page_visits_user_id ON public_page_visits(user_id);

-- Time-based analytics
CREATE INDEX IF NOT EXISTS idx_public_page_visits_created_at ON public_page_visits(created_at DESC);

-- Page path analytics
CREATE INDEX IF NOT EXISTS idx_public_page_visits_page_path ON public_page_visits(page_path);

-- UTM attribution analytics
CREATE INDEX IF NOT EXISTS idx_public_page_visits_utm_source ON public_page_visits(utm_source);
CREATE INDEX IF NOT EXISTS idx_public_page_visits_utm_campaign ON public_page_visits(utm_campaign);

-- Attribution queries
CREATE INDEX IF NOT EXISTS idx_public_page_visits_first_touch ON public_page_visits(first_touch) WHERE first_touch = true;
CREATE INDEX IF NOT EXISTS idx_public_page_visits_attributed_conversion ON public_page_visits(attributed_conversion) WHERE attributed_conversion = true;

-- Composite indexes for funnel analytics
CREATE INDEX IF NOT EXISTS idx_public_page_visits_session_created ON public_page_visits(anonymous_session_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_public_page_visits_user_created ON public_page_visits(user_id, created_at DESC) WHERE user_id IS NOT NULL;

-- ===============================================
-- 3. CREATE TRIGGER
-- ===============================================

DROP TRIGGER IF EXISTS update_public_page_visits_updated_at ON public_page_visits;
CREATE TRIGGER update_public_page_visits_updated_at
    BEFORE UPDATE ON public_page_visits
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ===============================================
-- 4. ENABLE RLS
-- ===============================================

ALTER TABLE public_page_visits ENABLE ROW LEVEL SECURITY;

-- ===============================================
-- 5. CREATE RLS POLICIES
-- ===============================================

-- Policy 1: Anonymous users can INSERT (pre-auth tracking)
DROP POLICY IF EXISTS "Anonymous can track page visits" ON public_page_visits;
CREATE POLICY "Anonymous can track page visits" ON public_page_visits
    FOR INSERT
    TO anon
    WITH CHECK (user_id IS NULL);

-- Policy 2: Authenticated users can view their own data
DROP POLICY IF EXISTS "Users can view their own page visits" ON public_page_visits;
CREATE POLICY "Users can view their own page visits" ON public_page_visits
    FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

-- Policy 3: Authenticated users can update their own data (for linking sessions)
DROP POLICY IF EXISTS "Users can update their own page visits" ON public_page_visits;
CREATE POLICY "Users can update their own page visits" ON public_page_visits
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id);

-- Policy 4: Service role full access (for backend operations)
DROP POLICY IF EXISTS "Service role full access to page visits" ON public_page_visits;
CREATE POLICY "Service role full access to page visits" ON public_page_visits
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- Policy 5: Authenticated users can INSERT with their user_id (post-auth tracking)
DROP POLICY IF EXISTS "Authenticated users can track their page visits" ON public_page_visits;
CREATE POLICY "Authenticated users can track their page visits" ON public_page_visits
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

-- ===============================================
-- 6. CREATE HELPER FUNCTION (Link Anonymous Sessions)
-- ===============================================

CREATE OR REPLACE FUNCTION link_anonymous_sessions_to_user(
    p_anonymous_session_id TEXT,
    p_user_id UUID
)
RETURNS INTEGER
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_updated_count INTEGER;
BEGIN
    -- Update all anonymous page visits to link them to the user
    UPDATE public_page_visits
    SET
        user_id = p_user_id,
        updated_at = NOW()
    WHERE
        anonymous_session_id = p_anonymous_session_id
        AND user_id IS NULL;

    GET DIAGNOSTICS v_updated_count = ROW_COUNT;

    -- Mark first touch attribution (earliest page visit for this session)
    UPDATE public_page_visits
    SET first_touch = true
    WHERE id = (
        SELECT id
        FROM public_page_visits
        WHERE anonymous_session_id = p_anonymous_session_id
        ORDER BY created_at ASC
        LIMIT 1
    );

    -- Mark last touch attribution (latest page visit before conversion)
    UPDATE public_page_visits
    SET last_touch = true
    WHERE id = (
        SELECT id
        FROM public_page_visits
        WHERE anonymous_session_id = p_anonymous_session_id
        ORDER BY created_at DESC
        LIMIT 1
    );

    RETURN v_updated_count;
END;
$$ LANGUAGE plpgsql;

-- ===============================================
-- 7. CREATE CONVERSION ATTRIBUTION FUNCTION
-- ===============================================

CREATE OR REPLACE FUNCTION mark_session_conversion(
    p_anonymous_session_id TEXT,
    p_user_id UUID
)
RETURNS BOOLEAN
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Mark all page visits in this session as attributed to conversion
    UPDATE public_page_visits
    SET
        attributed_conversion = true,
        updated_at = NOW()
    WHERE
        anonymous_session_id = p_anonymous_session_id
        AND user_id = p_user_id;

    RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

-- ===============================================
-- 8. ENABLE REALTIME
-- ===============================================

ALTER PUBLICATION supabase_realtime ADD TABLE public_page_visits;

-- ===============================================
-- 9. GRANT PERMISSIONS
-- ===============================================

GRANT ALL ON public_page_visits TO authenticated;
GRANT INSERT ON public_page_visits TO anon;
GRANT SELECT ON public_page_visits TO service_role;

-- ===============================================
-- 10. ADD COMMENTS
-- ===============================================

COMMENT ON TABLE public_page_visits IS 'Tracks anonymous visitor funnel from public pages through conversion to founding member';
COMMENT ON COLUMN public_page_visits.anonymous_session_id IS 'Client-side generated session ID (localStorage) for tracking pre-auth visitors';
COMMENT ON COLUMN public_page_visits.user_id IS 'Linked user after signup (NULL for anonymous visitors)';
COMMENT ON COLUMN public_page_visits.page_path IS 'URL path visited (e.g., /, /pricing, /about)';
COMMENT ON COLUMN public_page_visits.utm_source IS 'Marketing source (e.g., google, linkedin, twitter)';
COMMENT ON COLUMN public_page_visits.first_touch IS 'First page visit in conversion funnel (attribution)';
COMMENT ON COLUMN public_page_visits.last_touch IS 'Last page visit before conversion (attribution)';
COMMENT ON COLUMN public_page_visits.attributed_conversion IS 'True if this session led to founding member conversion';
COMMENT ON COLUMN public_page_visits.time_on_page IS 'Seconds spent on page';
COMMENT ON COLUMN public_page_visits.scroll_depth IS 'Percentage of page scrolled (0-100)';
