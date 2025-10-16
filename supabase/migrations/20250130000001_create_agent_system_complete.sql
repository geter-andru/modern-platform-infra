-- ===============================================
-- AGENT SYSTEM COMPLETE MIGRATION
-- Date: 2025-01-30
-- Purpose: Create comprehensive agent data storage system with tables and views
-- ===============================================

-- ===============================================
-- AGENT_ORCHESTRATION_SESSIONS TABLE
-- ===============================================

CREATE TABLE IF NOT EXISTS agent_orchestration_sessions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Session identification
    session_name TEXT NOT NULL,
    session_type TEXT NOT NULL DEFAULT 'customer_value_optimization' 
        CHECK (session_type IN ('customer_value_optimization', 'dashboard_optimization', 'deal_value_optimization', 'prospect_qualification_optimization', 'sales_materials_optimization')),
    
    -- Session state
    status TEXT NOT NULL DEFAULT 'active' 
        CHECK (status IN ('active', 'paused', 'completed', 'failed', 'cancelled')),
    
    -- Session configuration
    configuration JSONB DEFAULT '{
        "monitoring_interval": 5000,
        "friction_threshold": 0.3,
        "optimization_threshold": 0.2,
        "max_concurrent_agents": 3,
        "auto_optimization": true
    }'::jsonb,
    
    -- Session data
    session_data JSONB DEFAULT '{}'::jsonb,
    friction_points JSONB DEFAULT '[]'::jsonb,
    optimization_history JSONB DEFAULT '[]'::jsonb,
    
    -- Performance metrics
    total_optimizations INTEGER DEFAULT 0,
    successful_optimizations INTEGER DEFAULT 0,
    average_optimization_time DECIMAL(10,2),
    session_score DECIMAL(5,2) CHECK (session_score >= 0 AND session_score <= 100),
    
    -- Timestamps
    started_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT unique_user_session_name UNIQUE (user_id, session_name)
);

-- ===============================================
-- AGENT_EXECUTIONS TABLE
-- ===============================================

CREATE TABLE IF NOT EXISTS agent_executions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    session_id UUID NOT NULL REFERENCES agent_orchestration_sessions(id) ON DELETE CASCADE,
    
    -- Agent identification
    agent_name TEXT NOT NULL 
        CHECK (agent_name IN ('CustomerValueOrchestrator', 'DashboardOptimizer', 'DealValueCalculatorOptimizer', 'ProspectQualificationOptimizer', 'SalesMaterialsOptimizer')),
    agent_type TEXT NOT NULL DEFAULT 'sub_agent' 
        CHECK (agent_type IN ('master_orchestrator', 'sub_agent')),
    
    -- Execution state
    status TEXT NOT NULL DEFAULT 'pending' 
        CHECK (status IN ('pending', 'running', 'completed', 'failed', 'cancelled')),
    
    -- Execution context
    context JSONB DEFAULT '{}'::jsonb,
    input_data JSONB DEFAULT '{}'::jsonb,
    output_data JSONB DEFAULT '{}'::jsonb,
    
    -- Performance metrics
    execution_time_ms INTEGER,
    memory_usage_mb DECIMAL(10,2),
    cpu_usage_percent DECIMAL(5,2),
    optimization_score DECIMAL(5,2) CHECK (optimization_score >= 0 AND optimization_score <= 100),
    
    -- Results
    optimizations_applied JSONB DEFAULT '[]'::jsonb,
    issues_detected JSONB DEFAULT '[]'::jsonb,
    recommendations JSONB DEFAULT '[]'::jsonb,
    
    -- Error handling
    error_message TEXT,
    error_stack TEXT,
    retry_count INTEGER DEFAULT 0,
    
    -- Timestamps
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ===============================================
-- AGENT_PERFORMANCE_METRICS TABLE
-- ===============================================

CREATE TABLE IF NOT EXISTS agent_performance_metrics (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    session_id UUID REFERENCES agent_orchestration_sessions(id) ON DELETE CASCADE,
    execution_id UUID REFERENCES agent_executions(id) ON DELETE CASCADE,
    
    -- Metric identification
    metric_name TEXT NOT NULL,
    metric_type TEXT NOT NULL DEFAULT 'performance' 
        CHECK (metric_type IN ('performance', 'optimization', 'friction', 'business_impact', 'user_satisfaction')),
    
    -- Metric data
    metric_value DECIMAL(15,4) NOT NULL,
    metric_unit TEXT,
    baseline_value DECIMAL(15,4),
    target_value DECIMAL(15,4),
    
    -- Context
    context JSONB DEFAULT '{}'::jsonb,
    metadata JSONB DEFAULT '{}'::jsonb,
    
    -- Aggregation
    aggregation_type TEXT DEFAULT 'single' 
        CHECK (aggregation_type IN ('single', 'average', 'sum', 'max', 'min', 'count')),
    time_window_minutes INTEGER DEFAULT 1,
    
    -- Timestamps
    recorded_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ===============================================
-- AGENT_OPTIMIZATION_HISTORY TABLE
-- ===============================================

CREATE TABLE IF NOT EXISTS agent_optimization_history (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    session_id UUID NOT NULL REFERENCES agent_orchestration_sessions(id) ON DELETE CASCADE,
    execution_id UUID REFERENCES agent_executions(id) ON DELETE CASCADE,
    
    -- Optimization identification
    optimization_type TEXT NOT NULL 
        CHECK (optimization_type IN ('dashboard_ui', 'deal_calculation', 'prospect_qualification', 'sales_materials', 'workflow_flow', 'friction_reduction')),
    optimization_category TEXT NOT NULL 
        CHECK (optimization_category IN ('ui_ux', 'calculation_logic', 'qualification_criteria', 'content_optimization', 'process_improvement', 'performance_enhancement')),
    
    -- Optimization details
    optimization_name TEXT NOT NULL,
    description TEXT,
    before_state JSONB DEFAULT '{}'::jsonb,
    after_state JSONB DEFAULT '{}'::jsonb,
    
    -- Impact metrics
    impact_score DECIMAL(5,2) CHECK (impact_score >= 0 AND impact_score <= 100),
    business_value_score DECIMAL(5,2) CHECK (business_value_score >= 0 AND business_value_score <= 100),
    user_satisfaction_score DECIMAL(5,2) CHECK (user_satisfaction_score >= 0 AND user_satisfaction_score <= 100),
    
    -- Implementation
    implementation_status TEXT NOT NULL DEFAULT 'pending' 
        CHECK (implementation_status IN ('pending', 'implemented', 'failed', 'rolled_back')),
    implementation_time_ms INTEGER,
    
    -- Results
    results JSONB DEFAULT '{}'::jsonb,
    feedback JSONB DEFAULT '{}'::jsonb,
    
    -- Timestamps
    applied_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ===============================================
-- SERIES_A_FOUNDER_CONTEXTS TABLE
-- ===============================================

CREATE TABLE IF NOT EXISTS series_a_founder_contexts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    session_id UUID REFERENCES agent_orchestration_sessions(id) ON DELETE CASCADE,
    
    -- Founder profile
    company_name TEXT NOT NULL,
    industry TEXT NOT NULL,
    company_stage TEXT NOT NULL DEFAULT 'series_a' 
        CHECK (company_stage IN ('late_seed', 'series_a', 'series_a_plus')),
    current_arr DECIMAL(12,2),
    target_arr DECIMAL(12,2),
    
    -- Business context
    business_model TEXT NOT NULL 
        CHECK (business_model IN ('b2b_saas', 'b2c_saas', 'marketplace', 'ecommerce', 'fintech', 'healthtech', 'edtech', 'other')),
    target_market TEXT NOT NULL,
    customer_segment TEXT NOT NULL,
    
    -- Pain points
    primary_pain_points JSONB DEFAULT '[]'::jsonb,
    secondary_pain_points JSONB DEFAULT '[]'::jsonb,
    friction_areas JSONB DEFAULT '[]'::jsonb,
    
    -- Goals and objectives
    primary_goals JSONB DEFAULT '[]'::jsonb,
    success_metrics JSONB DEFAULT '[]'::jsonb,
    kpis JSONB DEFAULT '{}'::jsonb,
    
    -- Behavioral data
    user_behavior_patterns JSONB DEFAULT '{}'::jsonb,
    interaction_preferences JSONB DEFAULT '{}'::jsonb,
    optimization_preferences JSONB DEFAULT '{}'::jsonb,
    
    -- Professional credibility
    professional_language_score DECIMAL(5,2) CHECK (professional_language_score >= 0 AND professional_language_score <= 100),
    gaming_terminology_detected JSONB DEFAULT '[]'::jsonb,
    professional_alternatives JSONB DEFAULT '[]'::jsonb,
    
    -- Context metadata
    context_version TEXT DEFAULT '1.0',
    last_updated_by TEXT DEFAULT 'agent_system',
    metadata JSONB DEFAULT '{}'::jsonb,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT unique_user_company UNIQUE (user_id, company_name)
);

-- ===============================================
-- INDEXES FOR PERFORMANCE OPTIMIZATION
-- ===============================================

-- Agent Orchestration Sessions Indexes
CREATE INDEX IF NOT EXISTS idx_agent_sessions_user_id ON agent_orchestration_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_agent_sessions_created_at ON agent_orchestration_sessions(created_at);
CREATE INDEX IF NOT EXISTS idx_agent_sessions_status ON agent_orchestration_sessions(status);
CREATE INDEX IF NOT EXISTS idx_agent_sessions_session_type ON agent_orchestration_sessions(session_type);
CREATE INDEX IF NOT EXISTS idx_agent_sessions_user_status ON agent_orchestration_sessions(user_id, status);
CREATE INDEX IF NOT EXISTS idx_agent_sessions_user_created ON agent_orchestration_sessions(user_id, created_at DESC);

-- Agent Executions Indexes
CREATE INDEX IF NOT EXISTS idx_agent_executions_user_id ON agent_executions(user_id);
CREATE INDEX IF NOT EXISTS idx_agent_executions_session_id ON agent_executions(session_id);
CREATE INDEX IF NOT EXISTS idx_agent_executions_created_at ON agent_executions(created_at);
CREATE INDEX IF NOT EXISTS idx_agent_executions_status ON agent_executions(status);
CREATE INDEX IF NOT EXISTS idx_agent_executions_agent_name ON agent_executions(agent_name);
CREATE INDEX IF NOT EXISTS idx_agent_executions_session_status ON agent_executions(session_id, status);

-- Agent Performance Metrics Indexes
CREATE INDEX IF NOT EXISTS idx_agent_metrics_user_id ON agent_performance_metrics(user_id);
CREATE INDEX IF NOT EXISTS idx_agent_metrics_session_id ON agent_performance_metrics(session_id);
CREATE INDEX IF NOT EXISTS idx_agent_metrics_execution_id ON agent_performance_metrics(execution_id);
CREATE INDEX IF NOT EXISTS idx_agent_metrics_recorded_at ON agent_performance_metrics(recorded_at);
CREATE INDEX IF NOT EXISTS idx_agent_metrics_metric_name ON agent_performance_metrics(metric_name);
CREATE INDEX IF NOT EXISTS idx_agent_metrics_metric_type ON agent_performance_metrics(metric_type);
CREATE INDEX IF NOT EXISTS idx_agent_metrics_user_recorded ON agent_performance_metrics(user_id, recorded_at DESC);

-- Agent Optimization History Indexes
CREATE INDEX IF NOT EXISTS idx_agent_optimization_user_id ON agent_optimization_history(user_id);
CREATE INDEX IF NOT EXISTS idx_agent_optimization_session_id ON agent_optimization_history(session_id);
CREATE INDEX IF NOT EXISTS idx_agent_optimization_execution_id ON agent_optimization_history(execution_id);
CREATE INDEX IF NOT EXISTS idx_agent_optimization_created_at ON agent_optimization_history(created_at);
CREATE INDEX IF NOT EXISTS idx_agent_optimization_type ON agent_optimization_history(optimization_type);
CREATE INDEX IF NOT EXISTS idx_agent_optimization_status ON agent_optimization_history(implementation_status);
CREATE INDEX IF NOT EXISTS idx_agent_optimization_user_created ON agent_optimization_history(user_id, created_at DESC);

-- Series A Founder Contexts Indexes
CREATE INDEX IF NOT EXISTS idx_founder_contexts_user_id ON series_a_founder_contexts(user_id);
CREATE INDEX IF NOT EXISTS idx_founder_contexts_session_id ON series_a_founder_contexts(session_id);
CREATE INDEX IF NOT EXISTS idx_founder_contexts_created_at ON series_a_founder_contexts(created_at);
CREATE INDEX IF NOT EXISTS idx_founder_contexts_company_stage ON series_a_founder_contexts(company_stage);
CREATE INDEX IF NOT EXISTS idx_founder_contexts_business_model ON series_a_founder_contexts(business_model);
CREATE INDEX IF NOT EXISTS idx_founder_contexts_user_created ON series_a_founder_contexts(user_id, created_at DESC);

-- ===============================================
-- TRIGGERS FOR AUTOMATED UPDATES
-- ===============================================

-- Agent Orchestration Sessions Trigger
DROP TRIGGER IF EXISTS update_agent_sessions_updated_at ON agent_orchestration_sessions;
CREATE TRIGGER update_agent_sessions_updated_at 
    BEFORE UPDATE ON agent_orchestration_sessions 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Agent Executions Trigger
DROP TRIGGER IF EXISTS update_agent_executions_updated_at ON agent_executions;
CREATE TRIGGER update_agent_executions_updated_at 
    BEFORE UPDATE ON agent_executions 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Agent Performance Metrics Trigger
DROP TRIGGER IF EXISTS update_agent_metrics_updated_at ON agent_performance_metrics;
CREATE TRIGGER update_agent_metrics_updated_at 
    BEFORE UPDATE ON agent_performance_metrics 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Agent Optimization History Trigger
DROP TRIGGER IF EXISTS update_agent_optimization_updated_at ON agent_optimization_history;
CREATE TRIGGER update_agent_optimization_updated_at 
    BEFORE UPDATE ON agent_optimization_history 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Series A Founder Contexts Trigger
DROP TRIGGER IF EXISTS update_founder_contexts_updated_at ON series_a_founder_contexts;
CREATE TRIGGER update_founder_contexts_updated_at 
    BEFORE UPDATE ON series_a_founder_contexts 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ===============================================
-- ROW LEVEL SECURITY (RLS) ENABLEMENT
-- ===============================================

ALTER TABLE agent_orchestration_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE agent_executions ENABLE ROW LEVEL SECURITY;
ALTER TABLE agent_performance_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE agent_optimization_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE series_a_founder_contexts ENABLE ROW LEVEL SECURITY;

-- ===============================================
-- RLS POLICIES FOR USER ACCESS
-- ===============================================

-- Agent Orchestration Sessions Policies
DROP POLICY IF EXISTS "Users can view their own agent sessions" ON agent_orchestration_sessions;
CREATE POLICY "Users can view their own agent sessions" ON agent_orchestration_sessions
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own agent sessions" ON agent_orchestration_sessions;
CREATE POLICY "Users can insert their own agent sessions" ON agent_orchestration_sessions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own agent sessions" ON agent_orchestration_sessions;
CREATE POLICY "Users can update their own agent sessions" ON agent_orchestration_sessions
    FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own agent sessions" ON agent_orchestration_sessions;
CREATE POLICY "Users can delete their own agent sessions" ON agent_orchestration_sessions
    FOR DELETE USING (auth.uid() = user_id);

-- Agent Executions Policies
DROP POLICY IF EXISTS "Users can view their own agent executions" ON agent_executions;
CREATE POLICY "Users can view their own agent executions" ON agent_executions
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own agent executions" ON agent_executions;
CREATE POLICY "Users can insert their own agent executions" ON agent_executions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own agent executions" ON agent_executions;
CREATE POLICY "Users can update their own agent executions" ON agent_executions
    FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own agent executions" ON agent_executions;
CREATE POLICY "Users can delete their own agent executions" ON agent_executions
    FOR DELETE USING (auth.uid() = user_id);

-- Agent Performance Metrics Policies
DROP POLICY IF EXISTS "Users can view their own agent metrics" ON agent_performance_metrics;
CREATE POLICY "Users can view their own agent metrics" ON agent_performance_metrics
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own agent metrics" ON agent_performance_metrics;
CREATE POLICY "Users can insert their own agent metrics" ON agent_performance_metrics
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own agent metrics" ON agent_performance_metrics;
CREATE POLICY "Users can update their own agent metrics" ON agent_performance_metrics
    FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own agent metrics" ON agent_performance_metrics;
CREATE POLICY "Users can delete their own agent metrics" ON agent_performance_metrics
    FOR DELETE USING (auth.uid() = user_id);

-- Agent Optimization History Policies
DROP POLICY IF EXISTS "Users can view their own optimization history" ON agent_optimization_history;
CREATE POLICY "Users can view their own optimization history" ON agent_optimization_history
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own optimization history" ON agent_optimization_history;
CREATE POLICY "Users can insert their own optimization history" ON agent_optimization_history
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own optimization history" ON agent_optimization_history;
CREATE POLICY "Users can update their own optimization history" ON agent_optimization_history
    FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own optimization history" ON agent_optimization_history;
CREATE POLICY "Users can delete their own optimization history" ON agent_optimization_history
    FOR DELETE USING (auth.uid() = user_id);

-- Series A Founder Contexts Policies
DROP POLICY IF EXISTS "Users can view their own founder contexts" ON series_a_founder_contexts;
CREATE POLICY "Users can view their own founder contexts" ON series_a_founder_contexts
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own founder contexts" ON series_a_founder_contexts;
CREATE POLICY "Users can insert their own founder contexts" ON series_a_founder_contexts
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own founder contexts" ON series_a_founder_contexts;
CREATE POLICY "Users can update their own founder contexts" ON series_a_founder_contexts
    FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own founder contexts" ON series_a_founder_contexts;
CREATE POLICY "Users can delete their own founder contexts" ON series_a_founder_contexts
    FOR DELETE USING (auth.uid() = user_id);

-- ===============================================
-- SERVICE ROLE POLICIES FOR SYSTEM ACCESS
-- ===============================================

-- Service role full access for all agent tables
DROP POLICY IF EXISTS "Service role full access to agent sessions" ON agent_orchestration_sessions;
CREATE POLICY "Service role full access to agent sessions" ON agent_orchestration_sessions
    FOR ALL 
    TO service_role
    USING (true)
    WITH CHECK (true);

DROP POLICY IF EXISTS "Service role full access to agent executions" ON agent_executions;
CREATE POLICY "Service role full access to agent executions" ON agent_executions
    FOR ALL 
    TO service_role
    USING (true)
    WITH CHECK (true);

DROP POLICY IF EXISTS "Service role full access to agent metrics" ON agent_performance_metrics;
CREATE POLICY "Service role full access to agent metrics" ON agent_performance_metrics
    FOR ALL 
    TO service_role
    USING (true)
    WITH CHECK (true);

DROP POLICY IF EXISTS "Service role full access to optimization history" ON agent_optimization_history;
CREATE POLICY "Service role full access to optimization history" ON agent_optimization_history
    FOR ALL 
    TO service_role
    USING (true)
    WITH CHECK (true);

DROP POLICY IF EXISTS "Service role full access to founder contexts" ON series_a_founder_contexts;
CREATE POLICY "Service role full access to founder contexts" ON series_a_founder_contexts
    FOR ALL 
    TO service_role
    USING (true)
    WITH CHECK (true);

-- ===============================================
-- REALTIME CONFIGURATION
-- ===============================================

-- Enable realtime for all agent tables
ALTER PUBLICATION supabase_realtime ADD TABLE agent_orchestration_sessions;
ALTER PUBLICATION supabase_realtime ADD TABLE agent_executions;
ALTER PUBLICATION supabase_realtime ADD TABLE agent_performance_metrics;
ALTER PUBLICATION supabase_realtime ADD TABLE agent_optimization_history;
ALTER PUBLICATION supabase_realtime ADD TABLE series_a_founder_contexts;

-- ===============================================
-- PERMISSIONS
-- ===============================================

-- Grant permissions to authenticated users
GRANT ALL ON agent_orchestration_sessions TO authenticated;
GRANT ALL ON agent_executions TO authenticated;
GRANT ALL ON agent_performance_metrics TO authenticated;
GRANT ALL ON agent_optimization_history TO authenticated;
GRANT ALL ON series_a_founder_contexts TO authenticated;

-- ===============================================
-- TABLE AND COLUMN COMMENTS
-- ===============================================

-- Agent Orchestration Sessions Comments
COMMENT ON TABLE agent_orchestration_sessions IS 'Master table for tracking agent orchestration sessions and their overall performance';
COMMENT ON COLUMN agent_orchestration_sessions.user_id IS 'User who owns this orchestration session';
COMMENT ON COLUMN agent_orchestration_sessions.session_type IS 'Type of orchestration session being conducted';
COMMENT ON COLUMN agent_orchestration_sessions.configuration IS 'Session configuration including monitoring intervals and thresholds';
COMMENT ON COLUMN agent_orchestration_sessions.friction_points IS 'Array of detected friction points during the session';
COMMENT ON COLUMN agent_orchestration_sessions.optimization_history IS 'History of all optimizations applied during the session';

-- Agent Executions Comments
COMMENT ON TABLE agent_executions IS 'Individual agent execution records with detailed performance metrics';
COMMENT ON COLUMN agent_executions.session_id IS 'Reference to the orchestration session this execution belongs to';
COMMENT ON COLUMN agent_executions.agent_name IS 'Name of the specific agent that was executed';
COMMENT ON COLUMN agent_executions.context IS 'Execution context and environment data';
COMMENT ON COLUMN agent_executions.optimizations_applied IS 'List of optimizations applied during this execution';

-- Agent Performance Metrics Comments
COMMENT ON TABLE agent_performance_metrics IS 'Real-time and historical performance metrics for agent system';
COMMENT ON COLUMN agent_performance_metrics.metric_name IS 'Name of the specific metric being tracked';
COMMENT ON COLUMN agent_performance_metrics.metric_value IS 'Current value of the metric';
COMMENT ON COLUMN agent_performance_metrics.baseline_value IS 'Baseline value for comparison';
COMMENT ON COLUMN agent_performance_metrics.target_value IS 'Target value for optimization';

-- Agent Optimization History Comments
COMMENT ON TABLE agent_optimization_history IS 'Complete history of all optimizations applied by the agent system';
COMMENT ON COLUMN agent_optimization_history.optimization_type IS 'Type of optimization applied';
COMMENT ON COLUMN agent_optimization_history.impact_score IS 'Measured impact of the optimization (0-100)';
COMMENT ON COLUMN agent_optimization_history.business_value_score IS 'Business value impact of the optimization (0-100)';
COMMENT ON COLUMN agent_optimization_history.implementation_status IS 'Current status of optimization implementation';

-- Series A Founder Contexts Comments
COMMENT ON TABLE series_a_founder_contexts IS 'Contextual data for Series A founders to optimize agent behavior';
COMMENT ON COLUMN series_a_founder_contexts.company_stage IS 'Current stage of the company (late_seed, series_a, series_a_plus)';
COMMENT ON COLUMN series_a_founder_contexts.business_model IS 'Primary business model of the company';
COMMENT ON COLUMN series_a_founder_contexts.primary_pain_points IS 'Array of primary pain points the founder is experiencing';
COMMENT ON COLUMN series_a_founder_contexts.professional_language_score IS 'Score indicating professional language usage (0-100)';
COMMENT ON COLUMN series_a_founder_contexts.gaming_terminology_detected IS 'Array of gaming terminology that was detected and flagged';

-- ===============================================
-- DATABASE VIEWS (CREATED AFTER TABLES)
-- ===============================================

-- ===============================================
-- AGENT_SESSION_SUMMARY VIEW
-- ===============================================

CREATE OR REPLACE VIEW agent_session_summary AS
SELECT 
    aos.id,
    aos.user_id,
    aos.session_name,
    aos.session_type,
    aos.status,
    aos.total_optimizations,
    aos.successful_optimizations,
    aos.session_score,
    aos.started_at,
    aos.completed_at,
    aos.created_at,
    aos.updated_at,
    
    -- Calculated fields
    CASE 
        WHEN aos.total_optimizations > 0 
        THEN ROUND((aos.successful_optimizations::DECIMAL / aos.total_optimizations) * 100, 2)
        ELSE 0 
    END AS success_rate_percent,
    
    CASE 
        WHEN aos.completed_at IS NOT NULL AND aos.started_at IS NOT NULL
        THEN EXTRACT(EPOCH FROM (aos.completed_at - aos.started_at)) / 60
        ELSE NULL
    END AS session_duration_minutes,
    
    -- Execution counts
    COALESCE(execution_stats.total_executions, 0) AS total_executions,
    COALESCE(execution_stats.completed_executions, 0) AS completed_executions,
    COALESCE(execution_stats.failed_executions, 0) AS failed_executions,
    
    -- Performance metrics
    COALESCE(performance_stats.avg_execution_time_ms, 0) AS avg_execution_time_ms,
    COALESCE(performance_stats.avg_optimization_score, 0) AS avg_optimization_score,
    
    -- Optimization history
    COALESCE(optimization_stats.total_optimizations_applied, 0) AS total_optimizations_applied,
    COALESCE(optimization_stats.avg_impact_score, 0) AS avg_impact_score,
    COALESCE(optimization_stats.avg_business_value_score, 0) AS avg_business_value_score

FROM agent_orchestration_sessions aos

-- Execution statistics
LEFT JOIN (
    SELECT 
        session_id,
        COUNT(*) AS total_executions,
        COUNT(*) FILTER (WHERE status = 'completed') AS completed_executions,
        COUNT(*) FILTER (WHERE status = 'failed') AS failed_executions
    FROM agent_executions
    GROUP BY session_id
) execution_stats ON aos.id = execution_stats.session_id

-- Performance statistics
LEFT JOIN (
    SELECT 
        session_id,
        AVG(execution_time_ms) AS avg_execution_time_ms,
        AVG(optimization_score) AS avg_optimization_score
    FROM agent_executions
    WHERE execution_time_ms IS NOT NULL
    GROUP BY session_id
) performance_stats ON aos.id = performance_stats.session_id

-- Optimization statistics
LEFT JOIN (
    SELECT 
        session_id,
        COUNT(*) AS total_optimizations_applied,
        AVG(impact_score) AS avg_impact_score,
        AVG(business_value_score) AS avg_business_value_score
    FROM agent_optimization_history
    WHERE implementation_status = 'implemented'
    GROUP BY session_id
) optimization_stats ON aos.id = optimization_stats.session_id;

-- ===============================================
-- AGENT_PERFORMANCE_DASHBOARD VIEW
-- ===============================================

CREATE OR REPLACE VIEW agent_performance_dashboard AS
SELECT 
    apm.user_id,
    apm.session_id,
    apm.metric_name,
    apm.metric_type,
    apm.metric_value,
    apm.metric_unit,
    apm.baseline_value,
    apm.target_value,
    apm.recorded_at,
    
    -- Calculated performance indicators
    CASE 
        WHEN apm.baseline_value IS NOT NULL AND apm.baseline_value > 0
        THEN ROUND(((apm.metric_value - apm.baseline_value) / apm.baseline_value) * 100, 2)
        ELSE NULL
    END AS improvement_percent,
    
    CASE 
        WHEN apm.target_value IS NOT NULL
        THEN ROUND((apm.metric_value / apm.target_value) * 100, 2)
        ELSE NULL
    END AS target_achievement_percent,
    
    -- Performance status
    CASE 
        WHEN apm.target_value IS NOT NULL AND apm.metric_value >= apm.target_value
        THEN 'target_achieved'
        WHEN apm.baseline_value IS NOT NULL AND apm.metric_value > apm.baseline_value
        THEN 'improving'
        WHEN apm.baseline_value IS NOT NULL AND apm.metric_value < apm.baseline_value
        THEN 'declining'
        ELSE 'neutral'
    END AS performance_status,
    
    -- Session context
    aos.session_name,
    aos.session_type,
    aos.status AS session_status

FROM agent_performance_metrics apm
LEFT JOIN agent_orchestration_sessions aos ON apm.session_id = aos.id
WHERE apm.recorded_at >= NOW() - INTERVAL '7 days'  -- Last 7 days for dashboard
ORDER BY apm.recorded_at DESC;

-- ===============================================
-- AGENT_OPTIMIZATION_IMPACT VIEW
-- ===============================================

CREATE OR REPLACE VIEW agent_optimization_impact AS
SELECT 
    aoh.id,
    aoh.user_id,
    aoh.session_id,
    aoh.optimization_type,
    aoh.optimization_category,
    aoh.optimization_name,
    aoh.impact_score,
    aoh.business_value_score,
    aoh.user_satisfaction_score,
    aoh.implementation_status,
    aoh.applied_at,
    aoh.created_at,
    
    -- Overall optimization score
    ROUND(
        (COALESCE(aoh.impact_score, 0) + 
         COALESCE(aoh.business_value_score, 0) + 
         COALESCE(aoh.user_satisfaction_score, 0)) / 3, 2
    ) AS overall_optimization_score,
    
    -- Session context
    aos.session_name,
    aos.session_type,
    
    -- Execution context
    ae.agent_name,
    ae.execution_time_ms,
    
    -- Time to implementation
    CASE 
        WHEN aoh.applied_at IS NOT NULL AND aoh.created_at IS NOT NULL
        THEN EXTRACT(EPOCH FROM (aoh.applied_at - aoh.created_at)) / 60
        ELSE NULL
    END AS time_to_implementation_minutes

FROM agent_optimization_history aoh
LEFT JOIN agent_orchestration_sessions aos ON aoh.session_id = aos.id
LEFT JOIN agent_executions ae ON aoh.execution_id = ae.id
ORDER BY aoh.created_at DESC;

-- ===============================================
-- SERIES_A_FOUNDER_INSIGHTS VIEW
-- ===============================================

CREATE OR REPLACE VIEW series_a_founder_insights AS
SELECT 
    safc.id,
    safc.user_id,
    safc.company_name,
    safc.industry,
    safc.company_stage,
    safc.current_arr,
    safc.target_arr,
    safc.business_model,
    safc.target_market,
    safc.customer_segment,
    safc.professional_language_score,
    safc.created_at,
    safc.updated_at,
    
    -- Growth metrics
    CASE 
        WHEN safc.current_arr > 0 AND safc.target_arr > safc.current_arr
        THEN ROUND(((safc.target_arr - safc.current_arr) / safc.current_arr) * 100, 2)
        ELSE NULL
    END AS arr_growth_target_percent,
    
    -- Session performance
    COALESCE(session_stats.total_sessions, 0) AS total_sessions,
    COALESCE(session_stats.active_sessions, 0) AS active_sessions,
    COALESCE(session_stats.avg_session_score, 0) AS avg_session_score,
    
    -- Optimization performance
    COALESCE(optimization_stats.total_optimizations, 0) AS total_optimizations,
    COALESCE(optimization_stats.avg_impact_score, 0) AS avg_impact_score,
    COALESCE(optimization_stats.avg_business_value_score, 0) AS avg_business_value_score,
    
    -- Professional credibility metrics
    CASE 
        WHEN safc.professional_language_score >= 90 THEN 'excellent'
        WHEN safc.professional_language_score >= 75 THEN 'good'
        WHEN safc.professional_language_score >= 60 THEN 'needs_improvement'
        ELSE 'poor'
    END AS professional_credibility_status,
    
    -- Gaming terminology count
    COALESCE(jsonb_array_length(safc.gaming_terminology_detected), 0) AS gaming_terminology_count

FROM series_a_founder_contexts safc

-- Session statistics
LEFT JOIN (
    SELECT 
        user_id,
        COUNT(*) AS total_sessions,
        COUNT(*) FILTER (WHERE status = 'active') AS active_sessions,
        AVG(session_score) AS avg_session_score
    FROM agent_orchestration_sessions
    GROUP BY user_id
) session_stats ON safc.user_id = session_stats.user_id

-- Optimization statistics
LEFT JOIN (
    SELECT 
        user_id,
        COUNT(*) AS total_optimizations,
        AVG(impact_score) AS avg_impact_score,
        AVG(business_value_score) AS avg_business_value_score
    FROM agent_optimization_history
    WHERE implementation_status = 'implemented'
    GROUP BY user_id
) optimization_stats ON safc.user_id = optimization_stats.user_id

ORDER BY safc.updated_at DESC;

-- ===============================================
-- AGENT_REALTIME_MONITORING VIEW
-- ===============================================

CREATE OR REPLACE VIEW agent_realtime_monitoring AS
SELECT 
    aos.id AS session_id,
    aos.user_id,
    aos.session_name,
    aos.session_type,
    aos.status AS session_status,
    aos.started_at,
    
    -- Current execution status
    COALESCE(current_execution.agent_name, 'No active execution') AS current_agent,
    COALESCE(current_execution.status, 'idle') AS current_execution_status,
    COALESCE(current_execution.started_at, NULL) AS current_execution_started_at,
    
    -- Performance metrics (last 5 minutes)
    COALESCE(recent_metrics.avg_execution_time_ms, 0) AS recent_avg_execution_time_ms,
    COALESCE(recent_metrics.avg_optimization_score, 0) AS recent_avg_optimization_score,
    COALESCE(recent_metrics.metric_count, 0) AS recent_metric_count,
    
    -- Friction detection
    COALESCE(friction_detection.friction_count, 0) AS recent_friction_count,
    COALESCE(friction_detection.avg_friction_severity, 0) AS avg_friction_severity,
    
    -- System health
    CASE 
        WHEN current_execution.status = 'failed' THEN 'critical'
        WHEN friction_detection.friction_count > 3 THEN 'warning'
        WHEN recent_metrics.avg_optimization_score < 50 THEN 'warning'
        ELSE 'healthy'
    END AS system_health_status,
    
    -- Last activity
    GREATEST(
        aos.updated_at,
        COALESCE(current_execution.updated_at, '1900-01-01'::timestamptz),
        COALESCE(recent_metrics.last_metric_time, '1900-01-01'::timestamptz)
    ) AS last_activity_at

FROM agent_orchestration_sessions aos

-- Current execution
LEFT JOIN (
    SELECT 
        session_id,
        agent_name,
        status,
        started_at,
        updated_at,
        ROW_NUMBER() OVER (PARTITION BY session_id ORDER BY started_at DESC) as rn
    FROM agent_executions
    WHERE status IN ('running', 'pending')
) current_execution ON aos.id = current_execution.session_id AND current_execution.rn = 1

-- Recent performance metrics (last 5 minutes)
LEFT JOIN (
    SELECT 
        session_id,
        AVG(metric_value) FILTER (WHERE metric_name = 'execution_time_ms') AS avg_execution_time_ms,
        AVG(metric_value) FILTER (WHERE metric_name = 'optimization_score') AS avg_optimization_score,
        COUNT(*) AS metric_count,
        MAX(recorded_at) AS last_metric_time
    FROM agent_performance_metrics
    WHERE recorded_at >= NOW() - INTERVAL '5 minutes'
    GROUP BY session_id
) recent_metrics ON aos.id = recent_metrics.session_id

-- Friction detection (last 5 minutes)
LEFT JOIN (
    SELECT 
        session_id,
        COUNT(*) AS friction_count,
        AVG(metric_value) AS avg_friction_severity
    FROM agent_performance_metrics
    WHERE metric_name = 'friction_severity' 
        AND recorded_at >= NOW() - INTERVAL '5 minutes'
        AND metric_value > 0.3  -- Friction threshold
    GROUP BY session_id
) friction_detection ON aos.id = friction_detection.session_id

WHERE aos.status = 'active'
ORDER BY last_activity_at DESC;

-- ===============================================
-- AGENT_ANALYTICS_SUMMARY VIEW
-- ===============================================

CREATE OR REPLACE VIEW agent_analytics_summary AS
SELECT 
    DATE_TRUNC('day', aos.created_at) AS date,
    aos.session_type,
    COUNT(*) AS total_sessions,
    COUNT(*) FILTER (WHERE aos.status = 'completed') AS completed_sessions,
    COUNT(*) FILTER (WHERE aos.status = 'failed') AS failed_sessions,
    
    -- Performance metrics
    AVG(aos.session_score) AS avg_session_score,
    AVG(aos.total_optimizations) AS avg_optimizations_per_session,
    AVG(aos.successful_optimizations) AS avg_successful_optimizations_per_session,
    
    -- Execution metrics
    AVG(execution_stats.avg_execution_time_ms) AS avg_execution_time_ms,
    AVG(execution_stats.total_executions) AS avg_executions_per_session,
    
    -- Optimization impact
    AVG(optimization_stats.avg_impact_score) AS avg_impact_score,
    AVG(optimization_stats.avg_business_value_score) AS avg_business_value_score,
    AVG(optimization_stats.total_optimizations_applied) AS avg_optimizations_applied_per_session

FROM agent_orchestration_sessions aos

-- Execution statistics
LEFT JOIN (
    SELECT 
        session_id,
        AVG(execution_time_ms) AS avg_execution_time_ms,
        COUNT(*) AS total_executions
    FROM agent_executions
    GROUP BY session_id
) execution_stats ON aos.id = execution_stats.session_id

-- Optimization statistics
LEFT JOIN (
    SELECT 
        session_id,
        AVG(impact_score) AS avg_impact_score,
        AVG(business_value_score) AS avg_business_value_score,
        COUNT(*) AS total_optimizations_applied
    FROM agent_optimization_history
    WHERE implementation_status = 'implemented'
    GROUP BY session_id
) optimization_stats ON aos.id = optimization_stats.session_id

WHERE aos.created_at >= NOW() - INTERVAL '30 days'  -- Last 30 days
GROUP BY DATE_TRUNC('day', aos.created_at), aos.session_type
ORDER BY date DESC, aos.session_type;

-- ===============================================
-- VIEW PERMISSIONS
-- ===============================================

-- Grant permissions to authenticated users for all views
GRANT SELECT ON agent_session_summary TO authenticated;
GRANT SELECT ON agent_performance_dashboard TO authenticated;
GRANT SELECT ON agent_optimization_impact TO authenticated;
GRANT SELECT ON series_a_founder_insights TO authenticated;
GRANT SELECT ON agent_realtime_monitoring TO authenticated;
GRANT SELECT ON agent_analytics_summary TO authenticated;

-- Grant permissions to service role
GRANT SELECT ON agent_session_summary TO service_role;
GRANT SELECT ON agent_performance_dashboard TO service_role;
GRANT SELECT ON agent_optimization_impact TO service_role;
GRANT SELECT ON series_a_founder_insights TO service_role;
GRANT SELECT ON agent_realtime_monitoring TO service_role;
GRANT SELECT ON agent_analytics_summary TO authenticated;

-- ===============================================
-- VIEW COMMENTS
-- ===============================================

COMMENT ON VIEW agent_session_summary IS 'Comprehensive summary of agent orchestration sessions with calculated performance metrics';
COMMENT ON VIEW agent_performance_dashboard IS 'Real-time performance dashboard data for agent system monitoring';
COMMENT ON VIEW agent_optimization_impact IS 'Detailed view of optimization impact and business value metrics';
COMMENT ON VIEW series_a_founder_insights IS 'Insights and analytics for Series A founder optimization performance';
COMMENT ON VIEW agent_realtime_monitoring IS 'Real-time monitoring data for active agent sessions and system health';
COMMENT ON VIEW agent_analytics_summary IS 'Daily analytics summary for agent system performance trends';

-- ===============================================
-- MIGRATION COMPLETE
-- ===============================================

-- Log successful migration
INSERT INTO public.migration_log (migration_name, executed_at, status) 
VALUES ('20250130000001_create_agent_system_complete', NOW(), 'success');
