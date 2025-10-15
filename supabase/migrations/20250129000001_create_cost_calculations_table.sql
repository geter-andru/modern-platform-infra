-- ===============================================
-- COST CALCULATIONS TABLE
-- Date: January 29, 2025
-- Purpose: Store cost of inaction calculations with AI-generated insights
-- ===============================================

-- ============================================================================
-- TABLE CREATION
-- ============================================================================

CREATE TABLE IF NOT EXISTS cost_calculations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    -- Input Parameters
    current_revenue DECIMAL(15,2) NOT NULL,
    average_deal_size DECIMAL(10,2) NOT NULL,
    conversion_rate DECIMAL(5,2) NOT NULL,

    -- Optional Business Context
    sales_cycle_length INTEGER,
    customer_lifetime_value DECIMAL(15,2),
    churn_rate DECIMAL(5,2),
    market_size DECIMAL(15,2),
    competitive_pressure DECIMAL(5,2),

    -- Calculation Results (JSONB for flexibility)
    calculation JSONB NOT NULL DEFAULT '{
        "lostRevenue": 0,
        "inefficiencyLoss": 0,
        "opportunityCost": 0,
        "competitiveDisadvantage": 0,
        "totalAnnualCost": 0,
        "monthlyCost": 0,
        "dailyCost": 0,
        "costPerLead": 0,
        "costPerOpportunity": 0,
        "roiProjection": 0,
        "paybackPeriod": ""
    }'::jsonb,

    -- AI-Generated Insights (JSONB for flexible structure)
    insights JSONB DEFAULT '{
        "primaryDrivers": [],
        "recommendations": [],
        "riskFactors": [],
        "opportunityAreas": []
    }'::jsonb,

    -- Summary and Metadata
    total_cost DECIMAL(15,2) NOT NULL,
    calculation_method TEXT NOT NULL DEFAULT 'systematic_analysis' CHECK (
        calculation_method IN ('systematic_analysis', 'ai_enhanced_analysis', 'custom')
    ),
    confidence DECIMAL(5,2) CHECK (confidence >= 0 AND confidence <= 100),
    processing_time INTEGER,
    status TEXT NOT NULL DEFAULT 'completed' CHECK (
        status IN ('draft', 'processing', 'completed', 'failed')
    ),

    -- Timestamps
    generated_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- PERFORMANCE INDEXES
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_cost_calculations_user_id ON cost_calculations(user_id);
CREATE INDEX IF NOT EXISTS idx_cost_calculations_created_at ON cost_calculations(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_cost_calculations_status ON cost_calculations(status);
CREATE INDEX IF NOT EXISTS idx_cost_calculations_calculation_method ON cost_calculations(calculation_method);
CREATE INDEX IF NOT EXISTS idx_cost_calculations_user_created ON cost_calculations(user_id, created_at DESC);

-- GIN index for JSONB fields to support efficient querying
CREATE INDEX IF NOT EXISTS idx_cost_calculations_calculation_gin ON cost_calculations USING GIN (calculation);
CREATE INDEX IF NOT EXISTS idx_cost_calculations_insights_gin ON cost_calculations USING GIN (insights);

-- ============================================================================
-- TRIGGERS FOR UPDATED_AT TIMESTAMP
-- ============================================================================

DROP TRIGGER IF EXISTS update_cost_calculations_updated_at ON cost_calculations;
CREATE TRIGGER update_cost_calculations_updated_at
    BEFORE UPDATE ON cost_calculations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

ALTER TABLE cost_calculations ENABLE ROW LEVEL SECURITY;

-- Users can view their own cost calculations
DROP POLICY IF EXISTS "Users can view their own cost calculations" ON cost_calculations;
CREATE POLICY "Users can view their own cost calculations" ON cost_calculations
    FOR SELECT USING (auth.uid() = user_id);

-- Users can insert their own cost calculations
DROP POLICY IF EXISTS "Users can insert their own cost calculations" ON cost_calculations;
CREATE POLICY "Users can insert their own cost calculations" ON cost_calculations
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own cost calculations
DROP POLICY IF EXISTS "Users can update their own cost calculations" ON cost_calculations;
CREATE POLICY "Users can update their own cost calculations" ON cost_calculations
    FOR UPDATE USING (auth.uid() = user_id);

-- Users can delete their own cost calculations
DROP POLICY IF EXISTS "Users can delete their own cost calculations" ON cost_calculations;
CREATE POLICY "Users can delete their own cost calculations" ON cost_calculations
    FOR DELETE USING (auth.uid() = user_id);

-- Service role full access (for backend operations)
DROP POLICY IF EXISTS "Service role full access to cost calculations" ON cost_calculations;
CREATE POLICY "Service role full access to cost calculations" ON cost_calculations
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Get latest cost calculation for user
CREATE OR REPLACE FUNCTION get_latest_cost_calculation(p_user_id UUID)
RETURNS cost_calculations
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    latest_calculation cost_calculations;
BEGIN
    SELECT * INTO latest_calculation
    FROM cost_calculations
    WHERE user_id = p_user_id AND status = 'completed'
    ORDER BY created_at DESC
    LIMIT 1;

    RETURN latest_calculation;
END;
$$ LANGUAGE plpgsql;

-- Calculate average cost for user over time period
CREATE OR REPLACE FUNCTION get_average_cost_for_user(
    p_user_id UUID,
    p_days INTEGER DEFAULT 30
)
RETURNS DECIMAL(15,2)
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    avg_cost DECIMAL(15,2);
BEGIN
    SELECT AVG(total_cost) INTO avg_cost
    FROM cost_calculations
    WHERE user_id = p_user_id
      AND status = 'completed'
      AND created_at >= NOW() - (p_days || ' days')::INTERVAL;

    RETURN COALESCE(avg_cost, 0);
END;
$$ LANGUAGE plpgsql;

-- Get cost trend (comparing recent vs older calculations)
CREATE OR REPLACE FUNCTION get_cost_trend(
    p_user_id UUID,
    p_recent_days INTEGER DEFAULT 7,
    p_comparison_days INTEGER DEFAULT 30
)
RETURNS TABLE(
    recent_avg DECIMAL(15,2),
    comparison_avg DECIMAL(15,2),
    trend_percentage DECIMAL(10,2),
    trend_direction TEXT
)
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_recent_avg DECIMAL(15,2);
    v_comparison_avg DECIMAL(15,2);
    v_trend_pct DECIMAL(10,2);
    v_direction TEXT;
BEGIN
    -- Get recent average
    SELECT AVG(total_cost) INTO v_recent_avg
    FROM cost_calculations
    WHERE user_id = p_user_id
      AND status = 'completed'
      AND created_at >= NOW() - (p_recent_days || ' days')::INTERVAL;

    -- Get comparison period average
    SELECT AVG(total_cost) INTO v_comparison_avg
    FROM cost_calculations
    WHERE user_id = p_user_id
      AND status = 'completed'
      AND created_at BETWEEN
          NOW() - (p_comparison_days || ' days')::INTERVAL
          AND NOW() - (p_recent_days || ' days')::INTERVAL;

    -- Calculate trend
    IF v_comparison_avg > 0 THEN
        v_trend_pct := ((v_recent_avg - v_comparison_avg) / v_comparison_avg) * 100;

        IF v_trend_pct > 5 THEN
            v_direction := 'increasing';
        ELSIF v_trend_pct < -5 THEN
            v_direction := 'decreasing';
        ELSE
            v_direction := 'stable';
        END IF;
    ELSE
        v_trend_pct := 0;
        v_direction := 'insufficient_data';
    END IF;

    RETURN QUERY SELECT
        COALESCE(v_recent_avg, 0),
        COALESCE(v_comparison_avg, 0),
        COALESCE(v_trend_pct, 0),
        v_direction;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- ENABLE REALTIME (with idempotent handling)
-- ============================================================================

DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE cost_calculations;
EXCEPTION
    WHEN duplicate_object THEN
        RAISE NOTICE 'Table cost_calculations already in supabase_realtime publication';
END $$;

-- ============================================================================
-- GRANT PERMISSIONS
-- ============================================================================

GRANT ALL ON cost_calculations TO authenticated;
GRANT EXECUTE ON FUNCTION get_latest_cost_calculation(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_average_cost_for_user(UUID, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_cost_trend(UUID, INTEGER, INTEGER) TO authenticated;

-- ============================================================================
-- DOCUMENTATION COMMENTS
-- ============================================================================

COMMENT ON TABLE cost_calculations IS 'Stores cost of inaction calculations with AI-generated insights and recommendations';
COMMENT ON COLUMN cost_calculations.user_id IS 'User who owns this calculation';
COMMENT ON COLUMN cost_calculations.calculation IS 'Detailed breakdown of cost components (JSONB)';
COMMENT ON COLUMN cost_calculations.insights IS 'AI-generated insights including drivers, recommendations, and opportunities (JSONB)';
COMMENT ON COLUMN cost_calculations.calculation_method IS 'Method used: systematic_analysis or ai_enhanced_analysis';
COMMENT ON COLUMN cost_calculations.confidence IS 'Confidence score (0-100) for the calculation accuracy';

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '✅ Cost calculations table migration completed successfully';
    RAISE NOTICE '📊 Table created: cost_calculations';
    RAISE NOTICE '🔒 RLS policies enabled';
    RAISE NOTICE '⚡ Performance indexes created (including GIN indexes for JSONB)';
    RAISE NOTICE '🔧 Helper functions created: get_latest_cost_calculation, get_average_cost_for_user, get_cost_trend';
    RAISE NOTICE '🔄 Real-time enabled';
END $$;
