-- ===============================================
-- BUSINESS CASES TABLE
-- Date: January 29, 2025
-- Purpose: Store AI-generated business cases with comprehensive analysis and recommendations
-- ===============================================

-- ============================================================================
-- TABLE CREATION
-- ============================================================================

CREATE TABLE IF NOT EXISTS business_cases (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    -- Business Case Configuration
    template TEXT NOT NULL CHECK (
        template IN (
            'revenue-optimization',
            'operational-efficiency',
            'digital-transformation',
            'market-expansion',
            'customer-experience'
        )
    ),

    -- Customer/Company Data (JSONB for flexibility)
    customer_data JSONB NOT NULL DEFAULT '{
        "companyName": "",
        "industry": "",
        "companySize": "",
        "currentRevenue": 0
    }'::jsonb,

    -- Generated Business Case Content (JSONB for complex nested structure)
    business_case JSONB NOT NULL DEFAULT '{
        "executiveSummary": "",
        "problemStatement": "",
        "proposedSolution": "",
        "financialAnalysis": {
            "investment": 0,
            "expectedROI": 0,
            "paybackPeriod": "",
            "netPresentValue": 0,
            "internalRateOfReturn": 0
        },
        "riskAssessment": {
            "technicalRisks": [],
            "businessRisks": [],
            "mitigationStrategies": []
        },
        "implementationPlan": {
            "phases": [],
            "timeline": "",
            "resources": []
        },
        "successMetrics": {
            "kpis": [],
            "measurementMethods": [],
            "targets": []
        }
    }'::jsonb,

    -- Recommendations (JSONB array)
    recommendations JSONB DEFAULT '[]'::jsonb,

    -- Metadata and Analysis
    confidence DECIMAL(5,2) CHECK (confidence >= 0 AND confidence <= 100),
    source TEXT NOT NULL DEFAULT 'ai_generated' CHECK (
        source IN ('ai_generated', 'manual', 'hybrid', 'imported')
    ),
    template_version TEXT DEFAULT '1.0',
    analysis_method TEXT DEFAULT 'ai_enhanced_analysis',
    processing_time INTEGER,
    status TEXT NOT NULL DEFAULT 'completed' CHECK (
        status IN ('draft', 'processing', 'completed', 'failed', 'archived')
    ),

    -- Timestamps
    generated_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- PERFORMANCE INDEXES
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_business_cases_user_id ON business_cases(user_id);
CREATE INDEX IF NOT EXISTS idx_business_cases_created_at ON business_cases(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_business_cases_template ON business_cases(template);
CREATE INDEX IF NOT EXISTS idx_business_cases_status ON business_cases(status);
CREATE INDEX IF NOT EXISTS idx_business_cases_source ON business_cases(source);
CREATE INDEX IF NOT EXISTS idx_business_cases_user_template ON business_cases(user_id, template);
CREATE INDEX IF NOT EXISTS idx_business_cases_user_created ON business_cases(user_id, created_at DESC);

-- GIN indexes for JSONB fields to support efficient querying
CREATE INDEX IF NOT EXISTS idx_business_cases_customer_data_gin ON business_cases USING GIN (customer_data);
CREATE INDEX IF NOT EXISTS idx_business_cases_business_case_gin ON business_cases USING GIN (business_case);
CREATE INDEX IF NOT EXISTS idx_business_cases_recommendations_gin ON business_cases USING GIN (recommendations);

-- ============================================================================
-- TRIGGERS FOR UPDATED_AT TIMESTAMP
-- ============================================================================

DROP TRIGGER IF EXISTS update_business_cases_updated_at ON business_cases;
CREATE TRIGGER update_business_cases_updated_at
    BEFORE UPDATE ON business_cases
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

ALTER TABLE business_cases ENABLE ROW LEVEL SECURITY;

-- Users can view their own business cases
DROP POLICY IF EXISTS "Users can view their own business cases" ON business_cases;
CREATE POLICY "Users can view their own business cases" ON business_cases
    FOR SELECT USING (auth.uid() = user_id);

-- Users can insert their own business cases
DROP POLICY IF EXISTS "Users can insert their own business cases" ON business_cases;
CREATE POLICY "Users can insert their own business cases" ON business_cases
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own business cases
DROP POLICY IF EXISTS "Users can update their own business cases" ON business_cases;
CREATE POLICY "Users can update their own business cases" ON business_cases
    FOR UPDATE USING (auth.uid() = user_id);

-- Users can delete their own business cases
DROP POLICY IF EXISTS "Users can delete their own business cases" ON business_cases;
CREATE POLICY "Users can delete their own business cases" ON business_cases
    FOR DELETE USING (auth.uid() = user_id);

-- Service role full access (for backend operations)
DROP POLICY IF EXISTS "Service role full access to business cases" ON business_cases;
CREATE POLICY "Service role full access to business cases" ON business_cases
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Get latest business case for user
CREATE OR REPLACE FUNCTION get_latest_business_case(p_user_id UUID)
RETURNS business_cases
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    latest_case business_cases;
BEGIN
    SELECT * INTO latest_case
    FROM business_cases
    WHERE user_id = p_user_id AND status = 'completed'
    ORDER BY created_at DESC
    LIMIT 1;

    RETURN latest_case;
END;
$$ LANGUAGE plpgsql;

-- Get business cases by template type
CREATE OR REPLACE FUNCTION get_business_cases_by_template(
    p_user_id UUID,
    p_template TEXT
)
RETURNS SETOF business_cases
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT *
    FROM business_cases
    WHERE user_id = p_user_id
      AND template = p_template
      AND status = 'completed'
    ORDER BY created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Get business case statistics for user
CREATE OR REPLACE FUNCTION get_business_case_stats(p_user_id UUID)
RETURNS TABLE(
    total_cases INTEGER,
    cases_by_template JSONB,
    average_confidence DECIMAL(5,2),
    most_recent_case TIMESTAMPTZ
)
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(*)::INTEGER as total_cases,
        jsonb_object_agg(
            template,
            template_count
        ) as cases_by_template,
        AVG(confidence)::DECIMAL(5,2) as average_confidence,
        MAX(created_at) as most_recent_case
    FROM (
        SELECT
            template,
            COUNT(*)::INTEGER as template_count,
            confidence,
            created_at
        FROM business_cases
        WHERE user_id = p_user_id AND status = 'completed'
        GROUP BY template, confidence, created_at
    ) template_stats;
END;
$$ LANGUAGE plpgsql;

-- Search business cases by company name
CREATE OR REPLACE FUNCTION search_business_cases_by_company(
    p_user_id UUID,
    p_company_name TEXT
)
RETURNS SETOF business_cases
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT *
    FROM business_cases
    WHERE user_id = p_user_id
      AND status = 'completed'
      AND customer_data->>'companyName' ILIKE '%' || p_company_name || '%'
    ORDER BY created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- ENABLE REALTIME (with idempotent handling)
-- ============================================================================

DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE business_cases;
EXCEPTION
    WHEN duplicate_object THEN
        RAISE NOTICE 'Table business_cases already in supabase_realtime publication';
END $$;

-- ============================================================================
-- GRANT PERMISSIONS
-- ============================================================================

GRANT ALL ON business_cases TO authenticated;
GRANT EXECUTE ON FUNCTION get_latest_business_case(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_business_cases_by_template(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION get_business_case_stats(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION search_business_cases_by_company(UUID, TEXT) TO authenticated;

-- ============================================================================
-- DOCUMENTATION COMMENTS
-- ============================================================================

COMMENT ON TABLE business_cases IS 'Stores AI-generated business cases with comprehensive analysis, financial projections, and implementation plans';
COMMENT ON COLUMN business_cases.user_id IS 'User who owns this business case';
COMMENT ON COLUMN business_cases.template IS 'Business case template type (revenue-optimization, operational-efficiency, etc.)';
COMMENT ON COLUMN business_cases.customer_data IS 'Company and customer context data (JSONB)';
COMMENT ON COLUMN business_cases.business_case IS 'Complete business case content including financial analysis, risk assessment, and implementation plan (JSONB)';
COMMENT ON COLUMN business_cases.recommendations IS 'AI-generated strategic recommendations (JSONB array)';
COMMENT ON COLUMN business_cases.confidence IS 'Confidence score (0-100) for the business case accuracy';
COMMENT ON COLUMN business_cases.source IS 'Source of business case: ai_generated, manual, hybrid, or imported';

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '✅ Business cases table migration completed successfully';
    RAISE NOTICE '📊 Table created: business_cases';
    RAISE NOTICE '🔒 RLS policies enabled';
    RAISE NOTICE '⚡ Performance indexes created (including GIN indexes for JSONB)';
    RAISE NOTICE '🔧 Helper functions created: get_latest_business_case, get_business_cases_by_template, get_business_case_stats, search_business_cases_by_company';
    RAISE NOTICE '🔄 Real-time enabled';
END $$;
