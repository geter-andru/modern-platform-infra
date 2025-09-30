-- ===============================================
-- CREATE MISSING TABLES - CLEAN IMPLEMENTATION
-- Date: January 25, 2025
-- ===============================================

-- This migration creates only the 3 missing tables that don't exist yet:
-- - export_history
-- - agent_executions  
-- - product_details

-- ============================================================================
-- EXPORT HISTORY TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS export_history (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    export_type TEXT NOT NULL CHECK (export_type IN ('assessment', 'competency', 'progress', 'analytics', 'custom')),
    export_format TEXT NOT NULL DEFAULT 'pdf' CHECK (export_format IN ('pdf', 'excel', 'csv', 'json')),
    
    -- Export configuration
    export_config JSONB DEFAULT '{}'::jsonb,
    filters JSONB DEFAULT '{}'::jsonb,
    date_range JSONB DEFAULT '{}'::jsonb,
    
    -- Export results
    file_name TEXT,
    file_size INTEGER,
    download_url TEXT,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
    
    -- Metadata
    requested_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- AGENT EXECUTIONS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS agent_executions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    agent_type TEXT NOT NULL CHECK (agent_type IN ('assessment', 'analysis', 'recommendation', 'automation', 'custom')),
    execution_id TEXT NOT NULL,
    
    -- Execution details
    input_data JSONB DEFAULT '{}'::jsonb,
    output_data JSONB DEFAULT '{}'::jsonb,
    configuration JSONB DEFAULT '{}'::jsonb,
    
    -- Execution status and results
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'running', 'completed', 'failed', 'cancelled')),
    progress INTEGER DEFAULT 0 CHECK (progress >= 0 AND progress <= 100),
    error_message TEXT,
    execution_time_ms INTEGER,
    
    -- Business context
    business_context JSONB DEFAULT '{}'::jsonb,
    customer_context JSONB DEFAULT '{}'::jsonb,
    product_context JSONB DEFAULT '{}'::jsonb,
    
    -- Metadata
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT unique_user_execution UNIQUE (user_id, execution_id)
);

-- ============================================================================
-- PRODUCT DETAILS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS product_details (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    product_name TEXT NOT NULL,
    product_description TEXT NOT NULL,
    distinguishing_feature TEXT NOT NULL,
    business_model TEXT NOT NULL CHECK (business_model IN ('b2b-subscription', 'b2b-one-time', 'b2c-subscription', 'b2c-one-time', 'marketplace', 'freemium')),
    
    -- Product context
    industry TEXT,
    target_market TEXT,
    value_proposition TEXT,
    competitive_advantages JSONB DEFAULT '[]'::jsonb,
    
    -- Business metrics
    revenue_model TEXT,
    pricing_strategy TEXT,
    market_size DECIMAL(15,2),
    growth_potential TEXT CHECK (growth_potential IN ('low', 'medium', 'high', 'exponential')),
    
    -- Metadata
    is_primary BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- PERFORMANCE INDEXES
-- ============================================================================

-- Export history indexes
CREATE INDEX IF NOT EXISTS idx_export_history_user_id ON export_history(user_id);
CREATE INDEX IF NOT EXISTS idx_export_history_export_type ON export_history(export_type);
CREATE INDEX IF NOT EXISTS idx_export_history_status ON export_history(status);
CREATE INDEX IF NOT EXISTS idx_export_history_requested_at ON export_history(requested_at);

-- Agent executions indexes
CREATE INDEX IF NOT EXISTS idx_agent_executions_user_id ON agent_executions(user_id);
CREATE INDEX IF NOT EXISTS idx_agent_executions_agent_type ON agent_executions(agent_type);
CREATE INDEX IF NOT EXISTS idx_agent_executions_status ON agent_executions(status);
CREATE INDEX IF NOT EXISTS idx_agent_executions_created_at ON agent_executions(created_at);

-- Product details indexes
CREATE INDEX IF NOT EXISTS idx_product_details_user_id ON product_details(user_id);
CREATE INDEX IF NOT EXISTS idx_product_details_business_model ON product_details(business_model);
CREATE INDEX IF NOT EXISTS idx_product_details_created_at ON product_details(created_at);

-- ============================================================================
-- TRIGGERS FOR UPDATED_AT TIMESTAMPS
-- ============================================================================

-- Export history trigger
DROP TRIGGER IF EXISTS update_export_history_updated_at ON export_history;
CREATE TRIGGER update_export_history_updated_at 
    BEFORE UPDATE ON export_history 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Agent executions trigger
DROP TRIGGER IF EXISTS update_agent_executions_updated_at ON agent_executions;
CREATE TRIGGER update_agent_executions_updated_at 
    BEFORE UPDATE ON agent_executions 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Product details trigger
DROP TRIGGER IF EXISTS update_product_details_updated_at ON product_details;
CREATE TRIGGER update_product_details_updated_at 
    BEFORE UPDATE ON product_details 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

-- Enable RLS on all new tables
ALTER TABLE export_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE agent_executions ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_details ENABLE ROW LEVEL SECURITY;

-- Export history policies
DROP POLICY IF EXISTS "Users can view their own export history" ON export_history;
DROP POLICY IF EXISTS "Users can insert their own export history" ON export_history;
DROP POLICY IF EXISTS "Users can update their own export history" ON export_history;
DROP POLICY IF EXISTS "Users can delete their own export history" ON export_history;

CREATE POLICY "Users can view their own export history" ON export_history
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own export history" ON export_history
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own export history" ON export_history
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own export history" ON export_history
    FOR DELETE USING (auth.uid() = user_id);

-- Agent executions policies
DROP POLICY IF EXISTS "Users can view their own agent executions" ON agent_executions;
DROP POLICY IF EXISTS "Users can insert their own agent executions" ON agent_executions;
DROP POLICY IF EXISTS "Users can update their own agent executions" ON agent_executions;
DROP POLICY IF EXISTS "Users can delete their own agent executions" ON agent_executions;

CREATE POLICY "Users can view their own agent executions" ON agent_executions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own agent executions" ON agent_executions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own agent executions" ON agent_executions
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own agent executions" ON agent_executions
    FOR DELETE USING (auth.uid() = user_id);

-- Product details policies
DROP POLICY IF EXISTS "Users can view their own product details" ON product_details;
DROP POLICY IF EXISTS "Users can insert their own product details" ON product_details;
DROP POLICY IF EXISTS "Users can update their own product details" ON product_details;
DROP POLICY IF EXISTS "Users can delete their own product details" ON product_details;

CREATE POLICY "Users can view their own product details" ON product_details
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own product details" ON product_details
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own product details" ON product_details
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own product details" ON product_details
    FOR DELETE USING (auth.uid() = user_id);

-- ============================================================================
-- ENABLE REALTIME FOR NEW TABLES
-- ============================================================================

-- Enable realtime for all new tables
ALTER PUBLICATION supabase_realtime ADD TABLE export_history;
ALTER PUBLICATION supabase_realtime ADD TABLE agent_executions;
ALTER PUBLICATION supabase_realtime ADD TABLE product_details;

-- ============================================================================
-- GRANT PERMISSIONS
-- ============================================================================

-- Grant permissions to authenticated users
GRANT ALL ON export_history TO authenticated;
GRANT ALL ON agent_executions TO authenticated;
GRANT ALL ON product_details TO authenticated;

-- ============================================================================
-- DOCUMENTATION COMMENTS
-- ============================================================================

COMMENT ON TABLE export_history IS 'Manages export requests and file generation history';
COMMENT ON TABLE agent_executions IS 'Tracks AI agent execution history and results';
COMMENT ON TABLE product_details IS 'Stores user product information and business context';

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================

-- Log successful migration
DO $$
BEGIN
    RAISE NOTICE '✅ Missing tables migration completed successfully';
    RAISE NOTICE '📊 Tables created: export_history, agent_executions, product_details';
    RAISE NOTICE '🔒 RLS policies enabled on all tables';
    RAISE NOTICE '⚡ Performance indexes created';
    RAISE NOTICE '🔄 Real-time enabled for live updates';
END $$;
