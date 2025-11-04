-- ===============================================
-- CORRECTED SUPABASE SCHEMA MIGRATION FROM AIRTABLE
-- H&S Revenue Intelligence Platform
-- Date: September 4, 2025
-- ===============================================

-- Enable RLS by default for security
ALTER DEFAULT PRIVILEGES REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT EXECUTE ON FUNCTIONS TO authenticated;

-- ===============================================
-- CORE SYSTEM MANAGEMENT TABLES (9 TABLES)
-- ===============================================

-- 1. AI_Resource_Generations (Primary Hub)
-- Check if table exists before attempting to create it
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'ai_resource_generations') THEN
        CREATE TABLE public.ai_resource_generations (
            id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
            customer_id TEXT NOT NULL,
            generation_job_id TEXT UNIQUE NOT NULL,
            product_name TEXT,
            target_market TEXT,
            product_description TEXT,
            key_features TEXT,
            generation_status TEXT CHECK (generation_status IN ('pending', 'processing', 'completed', 'failed', 'cancelled')),
            quality_score INTEGER CHECK (quality_score >= 0 AND quality_score <= 100),
            total_resources_generated INTEGER DEFAULT 0,
            cost_usd DECIMAL(10,4),
            processing_time_seconds INTEGER,
            webhook_data JSONB,
            error_details TEXT,
            retry_count INTEGER DEFAULT 0,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            completed_at TIMESTAMP WITH TIME ZONE
        );
        
        COMMENT ON TABLE ai_resource_generations IS 'Master tracking for all AI resource generation processes';
    ELSE
        RAISE NOTICE 'Table ai_resource_generations already exists. Skipping creation.';
    END IF;
END
$$ LANGUAGE plpgsql;

-- 2. Resource_Generation_Summary
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'resource_generation_summary') THEN
        CREATE TABLE public.resource_generation_summary (
            id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
            generation_id UUID REFERENCES ai_resource_generations(id) ON DELETE CASCADE,
            resource_type TEXT NOT NULL CHECK (resource_type IN ('icp_analysis', 'buyer_personas', 'empathy_map', 'market_potential', 'value_messaging', 'competitive_analysis')),
            resource_name TEXT NOT NULL,
            content TEXT,
            quality_score INTEGER CHECK (quality_score >= 0 AND quality_score <= 100),
            confidence_level TEXT CHECK (confidence_level IN ('low', 'medium', 'high', 'excellent')),
            word_count INTEGER,
            generation_time_seconds INTEGER,
            status TEXT CHECK (status IN ('pending', 'generated', 'approved', 'rejected')),
            feedback TEXT,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        
        RAISE NOTICE 'Table resource_generation_summary created successfully.';
    ELSE
        RAISE NOTICE 'Table resource_generation_summary already exists. Skipping creation.';
    END IF;
END
$$ LANGUAGE plpgsql;

-- 3. Generation_Error_Logs
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'generation_error_logs') THEN
        CREATE TABLE public.generation_error_logs (
            id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
            generation_id UUID REFERENCES ai_resource_generations(id) ON DELETE CASCADE,
            error_type TEXT CHECK (error_type IN ('api_timeout', 'rate_limit', 'parsing_error', 'system_failure', 'validation_error')),
            error_message TEXT NOT NULL,
            error_details JSONB,
            severity_level TEXT CHECK (severity_level IN ('low', 'medium', 'high', 'critical')),
            resolution_status TEXT CHECK (resolution_status IN ('open', 'investigating', 'resolved', 'escalated')),
            resolution_notes TEXT,
            retry_attempted BOOLEAN DEFAULT FALSE,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            resolved_at TIMESTAMP WITH TIME ZONE
        );
        
        RAISE NOTICE 'Table generation_error_logs created successfully.';
    ELSE
        RAISE NOTICE 'Table generation_error_logs already exists. Skipping creation.';
    END IF;
END
$$ LANGUAGE plpgsql;

-- 4. Customer_Profiles
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'customer_profiles') THEN
CREATE TABLE public.customer_profiles (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    customer_id TEXT UNIQUE NOT NULL,
    email TEXT UNIQUE NOT NULL,
    company_name TEXT,
    first_name TEXT,
    last_name TEXT,
    role TEXT,
    phone TEXT,
    industry TEXT,
    company_size TEXT,
    annual_revenue_range TEXT,
    purchase_history JSONB,
    satisfaction_score INTEGER CHECK (satisfaction_score >= 1 AND satisfaction_score <= 10),
    lifecycle_stage TEXT CHECK (lifecycle_stage IN ('lead', 'trial', 'active', 'churned', 'enterprise')),
    subscription_tier TEXT CHECK (subscription_tier IN ('basic', 'professional', 'enterprise')),
    last_login_at TIMESTAMP WITH TIME ZONE,
    total_sessions INTEGER DEFAULT 0,
    preferred_communication TEXT,
    timezone TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
   RAISE NOTICE 'Table customer_profiles created successfully.';
    ELSE
        RAISE NOTICE 'Table customer_profiles already exists. Skipping creation.';
    END IF;
END 
$$ LANGUAGE plpgsql;

-- 5. Product_Configurations
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'products_configuration') THEN
CREATE TABLE public.products_configuration (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    product_name TEXT NOT NULL,
    product_description TEXT,
    pricing_tier TEXT CHECK (pricing_tier IN ('basic', 'professional', 'enterprise')),
    resource_bundle_definition JSONB,
    included_resource_types TEXT[],
    max_generations_per_month INTEGER,
    usage_tracking JSONB,
    success_rate_threshold DECIMAL(5,4),
    quality_requirements JSONB,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
RAISE NOTICE 'Table products_configuration created successfully.';
    ELSE
        RAISE NOTICE 'Table products_configuration already exists. Skipping creation.';
    END IF;
END 
$$ LANGUAGE plpgsql;

-- 6. Performance_Metrics
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'performance_metrics') THEN
CREATE TABLE public.performance_metrics (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    date DATE NOT NULL,
    total_revenue DECIMAL(12,2),
    new_customers INTEGER DEFAULT 0,
    active_customers INTEGER DEFAULT 0,
    churned_customers INTEGER DEFAULT 0,
    total_generations INTEGER DEFAULT 0,
    successful_generations INTEGER DEFAULT 0,
    completion_rate DECIMAL(5,4),
    average_quality_score DECIMAL(5,2),
    total_api_costs DECIMAL(10,4),
    average_processing_time_seconds INTEGER,
    error_rate DECIMAL(5,4),
    customer_satisfaction_avg DECIMAL(3,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
RAISE NOTICE 'Table performance_metrics created successfully.';
    ELSE
        RAISE NOTICE 'Table performance_metrics already exists. Skipping creation.';
    END IF;
END 
$$ LANGUAGE plpgsql;

-- 7. Support_Tickets
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'support_tickets') THEN
CREATE TABLE public.support_tickets (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    ticket_number TEXT UNIQUE NOT NULL,
    customer_id TEXT,
    subject TEXT NOT NULL,
    description TEXT,
    category TEXT CHECK (category IN ('technical', 'billing', 'feature_request', 'bug_report', 'general')),
    priority_level TEXT CHECK (priority_level IN ('low', 'medium', 'high', 'urgent')),
    status TEXT CHECK (status IN ('open', 'in_progress', 'waiting_customer', 'resolved', 'closed')),
    assigned_to TEXT,
    resolution_details TEXT,
    customer_satisfaction INTEGER CHECK (customer_satisfaction >= 1 AND customer_satisfaction <= 5),
    response_time_hours INTEGER,
    resolution_time_hours INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    resolved_at TIMESTAMP WITH TIME ZONE,
    FOREIGN KEY (customer_id) REFERENCES customer_profiles(customer_id) ON DELETE SET NULL
);
RAISE NOTICE 'Table support_tickets created successfully.';
    ELSE
        RAISE NOTICE 'Table support_tickets already exists. Skipping creation.';
    END IF;
END 
$$ LANGUAGE plpgsql;

-- 8. Admin_Dashboard_Metrics
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'admin_dashboard_metrics') THEN
CREATE TABLE public.admin_dashboard_metrics (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    metric_type TEXT NOT NULL,
    metric_value DECIMAL(15,4),
    metric_unit TEXT,
    dashboard_section TEXT,
    alert_threshold_low DECIMAL(15,4),
    alert_threshold_high DECIMAL(15,4),
    current_status TEXT CHECK (current_status IN ('normal', 'warning', 'critical')),
    last_alert_sent_at TIMESTAMP WITH TIME ZONE,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
RAISE NOTICE 'Table admin_dashboard_metrics created successfully.';
    ELSE
        RAISE NOTICE 'Table admin_dashboard_metrics already exists. Skipping creation.';
    END IF;
END 
$$ LANGUAGE plpgsql;

-- 9. Quality_Benchmarks
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'quality_benchmarks') THEN
CREATE TABLE public.quality_benchmarks (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    resource_type TEXT NOT NULL,
    benchmark_name TEXT NOT NULL,
    minimum_score INTEGER,
    target_score INTEGER,
    excellent_score INTEGER,
    measurement_criteria JSONB,
    improvement_triggers JSONB,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(resource_type, benchmark_name)
);
RAISE NOTICE 'Table quality_benchmarks created successfully.';
    ELSE
        RAISE NOTICE 'Table quality_benchmarks already exists. Skipping creation.';
    END IF;
END 
$$ LANGUAGE plpgsql;

-- ===============================================
-- CUSTOMER PSYCHOLOGY & INSIGHTS TABLES (2 TABLES)
-- ===============================================

-- 10. Moment_in_Life_Descriptions
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'moment_in_life_descriptions') THEN
CREATE TABLE public.moment_in_life_descriptions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    customer_id TEXT,
    trigger_event TEXT NOT NULL,
    emotional_state TEXT,
    decision_context TEXT,
    urgency_level TEXT CHECK (urgency_level IN ('low', 'medium', 'high', 'critical')),
    success_definition TEXT,
    failure_definition TEXT,
    time_pressure TEXT,
    stakeholders_involved TEXT[],
    budget_constraints TEXT,
    decision_timeline TEXT,
    competing_priorities TEXT,
    moment_description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    FOREIGN KEY (customer_id) REFERENCES customer_profiles(customer_id) ON DELETE SET NULL
);
RAISE NOTICE 'Table moment_in_life_descriptions created successfully.';
    ELSE
        RAISE NOTICE 'Table moment_in_life_descriptions already exists. Skipping creation.';
    END IF;
END 
$$ LANGUAGE plpgsql;

-- 11. Empathy_Maps
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'empathy_maps') THEN
CREATE TABLE public.empathy_maps (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    customer_id TEXT,
    persona_name TEXT NOT NULL,
    what_they_think TEXT,
    what_they_feel TEXT,
    what_they_see TEXT,
    what_they_say TEXT,
    what_they_do TEXT,
    what_they_hear TEXT,
    pains JSONB,
    gains JSONB,
    motivations TEXT[],
    goals TEXT[],
    fears TEXT[],
    aspirations TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    FOREIGN KEY (customer_id) REFERENCES customer_profiles(customer_id) ON DELETE SET NULL
);
RAISE NOTICE 'Table empathy_maps created successfully.';
    ELSE
        RAISE NOTICE 'Table empathy_maps already exists. Skipping creation.';
    END IF;
END 
$$ LANGUAGE plpgsql;

-- ===============================================
-- ADVANCED SALES RESOURCES TABLES (10 TABLES)
-- ===============================================

-- 12. Advanced_Sales_Tasks
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'advanced_sales_tasks') THEN
CREATE TABLE public.advanced_sales_tasks (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    customer_id TEXT,
    task_name TEXT NOT NULL,
    task_description TEXT,
    sales_methodology TEXT,
    task_category TEXT CHECK (task_category IN ('prospecting', 'discovery', 'demo', 'proposal', 'negotiation', 'closing')),
    difficulty_level TEXT CHECK (difficulty_level IN ('beginner', 'intermediate', 'advanced', 'expert')),
    estimated_time_hours INTEGER,
    success_criteria TEXT,
    required_tools TEXT[],
    deliverables TEXT[],
    optimization_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    FOREIGN KEY (customer_id) REFERENCES customer_profiles(customer_id) ON DELETE SET NULL
);
RAISE NOTICE 'Table advanced_sales_tasks created successfully.';
    ELSE
        RAISE NOTICE 'Table advanced_sales_tasks already exists. Skipping creation.';
    END IF;
END 
$$ LANGUAGE plpgsql;

-- 13. Buyer_UX_Considerations
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'buyer_ux_considerations') THEN
CREATE TABLE public.buyer_ux_considerations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    customer_id TEXT,
    consideration_name TEXT NOT NULL,
    ux_element TEXT,
    buyer_impact TEXT,
    friction_points TEXT[],
    optimization_suggestions TEXT[],
    priority_level TEXT CHECK (priority_level IN ('low', 'medium', 'high', 'critical')),
    implementation_effort TEXT CHECK (implementation_effort IN ('low', 'medium', 'high')),
    expected_impact TEXT CHECK (expected_impact IN ('low', 'medium', 'high')),
    test_criteria TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    FOREIGN KEY (customer_id) REFERENCES customer_profiles(customer_id) ON DELETE SET NULL
);
RAISE NOTICE 'Table buyer_ux_considerations created successfully.';
    ELSE
        RAISE NOTICE 'Table buyer_ux_considerations already exists. Skipping creation.';
    END IF;
END 
$$ LANGUAGE plpgsql;

-- 14. Product_Usage_Assessments
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'product_usage_assessments') THEN
CREATE TABLE public.product_usage_assessments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    customer_id TEXT,
    product_feature TEXT NOT NULL,
    usage_frequency TEXT CHECK (usage_frequency IN ('daily', 'weekly', 'monthly', 'rarely', 'never')),
    user_satisfaction INTEGER CHECK (user_satisfaction >= 1 AND user_satisfaction <= 10),
    adoption_barriers TEXT[],
    usage_patterns JSONB,
    feature_requests TEXT[],
    competitive_alternatives TEXT[],
    retention_risk TEXT CHECK (retention_risk IN ('low', 'medium', 'high')),
    expansion_opportunities TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    FOREIGN KEY (customer_id) REFERENCES customer_profiles(customer_id) ON DELETE SET NULL
);
RAISE NOTICE 'Table product_usage_assessments created successfully.';
    ELSE
        RAISE NOTICE 'Table product_usage_assessments already exists. Skipping creation.';
    END IF;
END 
$$ LANGUAGE plpgsql;

-- 15. Day_in_Life_Descriptions
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'day_in_life_descriptions') THEN
CREATE TABLE public.day_in_life_descriptions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    customer_id TEXT,
    persona_name TEXT NOT NULL,
    time_slot TIME,
    activity_description TEXT,
    tools_used TEXT[],
    pain_points TEXT[],
    product_interaction TEXT,
    context_details TEXT,
    frequency TEXT CHECK (frequency IN ('daily', 'weekly', 'monthly', 'occasionally')),
    importance_level TEXT CHECK (importance_level IN ('low', 'medium', 'high', 'critical')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    FOREIGN KEY (customer_id) REFERENCES customer_profiles(customer_id) ON DELETE SET NULL
);
RAISE NOTICE 'Table day_in_life_descriptions created successfully.';
    ELSE
        RAISE NOTICE 'Table day_in_life_descriptions already exists. Skipping creation.';
    END IF;
END 
$$ LANGUAGE plpgsql;

-- 16. Month_in_Life_Descriptions
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'month_in_life_descriptions') THEN
CREATE TABLE public.month_in_life_descriptions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    customer_id TEXT,
    month_phase TEXT NOT NULL,
    key_objectives TEXT[],
    seasonal_patterns TEXT,
    budget_cycles TEXT,
    team_changes TEXT,
    product_usage_evolution TEXT,
    success_metrics TEXT[],
    challenges TEXT[],
    strategic_priorities TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    FOREIGN KEY (customer_id) REFERENCES customer_profiles(customer_id) ON DELETE SET NULL
);
RAISE NOTICE 'Table month_in_life_descriptions created successfully.';
    ELSE
        RAISE NOTICE 'Table month_in_life_descriptions already exists. Skipping creation.';
    END IF;
END 
$$ LANGUAGE plpgsql;

-- 17. User_Journey_Maps
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'user_journey_maps') THEN
CREATE TABLE public.user_journey_maps (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    customer_id TEXT,
    journey_name TEXT NOT NULL,
    stage_name TEXT NOT NULL,
    stage_order INTEGER,
    touchpoints TEXT[],
    customer_actions TEXT[],
    emotions TEXT[],
    pain_points TEXT[],
    opportunities TEXT[],
    channels TEXT[],
    metrics TEXT[],
    duration_estimate TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    FOREIGN KEY (customer_id) REFERENCES customer_profiles(customer_id) ON DELETE SET NULL
);
RAISE NOTICE 'Table user_journey_maps created successfully.';
    ELSE
        RAISE NOTICE 'Table user_journey_maps already exists. Skipping creation.';
    END IF;
END 
$$ LANGUAGE plpgsql;

-- 18. Service_Blueprints
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'service_blueprints') THEN
CREATE TABLE public.service_blueprints (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    customer_id TEXT,
    service_name TEXT NOT NULL,
    customer_actions TEXT[],
    frontstage_actions TEXT[],
    backstage_actions TEXT[],
    support_processes TEXT[],
    physical_evidence TEXT[],
    pain_points TEXT[],
    fail_points TEXT[],
    wait_times TEXT[],
    improvement_opportunities TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    FOREIGN KEY (customer_id) REFERENCES customer_profiles(customer_id) ON DELETE SET NULL
);
RAISE NOTICE 'Table service_blueprints created successfully.';
    ELSE
        RAISE NOTICE 'Table service_blueprints already exists. Skipping creation.';
    END IF;
END 
$$ LANGUAGE plpgsql;

-- 19. Jobs_to_be_Done
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'jobs_to_be_done') THEN
CREATE TABLE public.jobs_to_be_done (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    customer_id TEXT,
    job_statement TEXT NOT NULL,
    job_category TEXT CHECK (job_category IN ('functional', 'emotional', 'social')),
    job_importance INTEGER CHECK (job_importance >= 1 AND job_importance <= 10),
    current_satisfaction INTEGER CHECK (current_satisfaction >= 1 AND current_satisfaction <= 10),
    opportunity_score INTEGER GENERATED ALWAYS AS (job_importance + (10 - current_satisfaction)) STORED,
    context_description TEXT,
    desired_outcomes TEXT[],
    success_criteria TEXT[],
    current_solutions TEXT[],
    solution_gaps TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    FOREIGN KEY (customer_id) REFERENCES customer_profiles(customer_id) ON DELETE SET NULL
);
RAISE NOTICE 'Table jobs_to_be_done created successfully.';
    ELSE
        RAISE NOTICE 'Table jobs_to_be_done already exists. Skipping creation.';
    END IF;
END 
$$ LANGUAGE plpgsql;

-- 20. Compelling_Events
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'compelling_events') THEN
CREATE TABLE public.compelling_events (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    customer_id TEXT,
    event_name TEXT NOT NULL,
    event_description TEXT,
    trigger_type TEXT CHECK (trigger_type IN ('external', 'internal', 'competitive', 'regulatory', 'financial')),
    urgency_factor INTEGER CHECK (urgency_factor >= 1 AND urgency_factor <= 10),
    impact_assessment TEXT,
    decision_timeline TEXT,
    key_stakeholders TEXT[],
    budget_impact TEXT,
    risk_factors TEXT[],
    sales_acceleration_potential TEXT CHECK (sales_acceleration_potential IN ('low', 'medium', 'high', 'critical')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    FOREIGN KEY (customer_id) REFERENCES customer_profiles(customer_id) ON DELETE SET NULL
);
RAISE NOTICE 'Table compelling_events created successfully.';
    ELSE
        RAISE NOTICE 'Table compelling_events already exists. Skipping creation.';
    END IF;
END 
$$ LANGUAGE plpgsql;

-- 21. Scenario_Planning
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'scenario_planning') THEN
CREATE TABLE public.scenario_planning (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    customer_id TEXT,
    scenario_name TEXT NOT NULL,
    scenario_type TEXT CHECK (scenario_type IN ('best_case', 'worst_case', 'most_likely', 'contingency')),
    probability_percentage INTEGER CHECK (probability_percentage >= 0 AND probability_percentage <= 100),
    scenario_description TEXT,
    key_assumptions TEXT[],
    potential_outcomes TEXT[],
    required_actions TEXT[],
    success_metrics TEXT[],
    risk_factors TEXT[],
    mitigation_strategies TEXT[],
    resource_requirements TEXT,
    timeline_estimate TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    FOREIGN KEY (customer_id) REFERENCES customer_profiles(customer_id) ON DELETE SET NULL
);
RAISE NOTICE 'Table scenario_planning created successfully.';
    ELSE
        RAISE NOTICE 'Table scenario_planning already exists. Skipping creation.';
    END IF;
END 
$$ LANGUAGE plpgsql;

-- ===============================================
-- INDEXES FOR PERFORMANCE OPTIMIZATION
-- ===============================================

-- Check and create indexes for frequently queried fields
DO $$
BEGIN
    -- Check and create index for ai_resource_generations(customer_id)
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE indexname = 'idx_ai_resource_generations_customer_id'
    ) THEN
        CREATE INDEX idx_ai_resource_generations_customer_id ON ai_resource_generations(customer_id);
        RAISE NOTICE 'Index idx_ai_resource_generations_customer_id created.';
    ELSE
        RAISE NOTICE 'Index idx_ai_resource_generations_customer_id already exists. Skipping creation.';
    END IF;
    
    -- Check and create index for ai_resource_generations(generation_status)
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE indexname = 'idx_ai_resource_generations_status'
    ) THEN
        CREATE INDEX idx_ai_resource_generations_status ON ai_resource_generations(generation_status);
        RAISE NOTICE 'Index idx_ai_resource_generations_status created.';
    ELSE
        RAISE NOTICE 'Index idx_ai_resource_generations_status already exists. Skipping creation.';
    END IF;
    
    -- Check and create index for ai_resource_generations(created_at DESC)
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE indexname = 'idx_ai_resource_generations_created_at'
    ) THEN
        CREATE INDEX idx_ai_resource_generations_created_at ON ai_resource_generations(created_at DESC);
        RAISE NOTICE 'Index idx_ai_resource_generations_created_at created.';
    ELSE
        RAISE NOTICE 'Index idx_ai_resource_generations_created_at already exists. Skipping creation.';
    END IF;

    -- Check and create index for resource_generation_summary(generation_id)
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE indexname = 'idx_resource_generation_summary_generation_id'
    ) THEN
        CREATE INDEX idx_resource_generation_summary_generation_id ON resource_generation_summary(generation_id);
        RAISE NOTICE 'Index idx_resource_generation_summary_generation_id created.';
    ELSE
        RAISE NOTICE 'Index idx_resource_generation_summary_generation_id already exists. Skipping creation.';
    END IF;
    
    -- Check and create index for resource_generation_summary(resource_type)
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE indexname = 'idx_resource_generation_summary_type'
    ) THEN
        CREATE INDEX idx_resource_generation_summary_type ON resource_generation_summary(resource_type);
        RAISE NOTICE 'Index idx_resource_generation_summary_type created.';
    ELSE
        RAISE NOTICE 'Index idx_resource_generation_summary_type already exists. Skipping creation.';
    END IF;
    
    -- Check and create index for resource_generation_summary(status)
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE indexname = 'idx_resource_generation_summary_status'
    ) THEN
        CREATE INDEX idx_resource_generation_summary_status ON resource_generation_summary(status);
        RAISE NOTICE 'Index idx_resource_generation_summary_status created.';
    ELSE
        RAISE NOTICE 'Index idx_resource_generation_summary_status already exists. Skipping creation.';
    END IF;

    -- Check and create index for generation_error_logs(generation_id)
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE indexname = 'idx_generation_error_logs_generation_id'
    ) THEN
        CREATE INDEX idx_generation_error_logs_generation_id ON generation_error_logs(generation_id);
        RAISE NOTICE 'Index idx_generation_error_logs_generation_id created.';
    ELSE
        RAISE NOTICE 'Index idx_generation_error_logs_generation_id already exists. Skipping creation.';
    END IF;
    
    -- Check and create index for generation_error_logs(severity_level)
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE indexname = 'idx_generation_error_logs_severity'
    ) THEN
        CREATE INDEX idx_generation_error_logs_severity ON generation_error_logs(severity_level);
        RAISE NOTICE 'Index idx_generation_error_logs_severity created.';
    ELSE
        RAISE NOTICE 'Index idx_generation_error_logs_severity already exists. Skipping creation.';
    END IF;
    
    -- Check and create index for generation_error_logs(created_at DESC)
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE indexname = 'idx_generation_error_logs_created_at'
    ) THEN
        CREATE INDEX idx_generation_error_logs_created_at ON generation_error_logs(created_at DESC);
        RAISE NOTICE 'Index idx_generation_error_logs_created_at created.';
    ELSE
        RAISE NOTICE 'Index idx_generation_error_logs_created_at already exists. Skipping creation.';
    END IF;

    -- Check and create index for customer_profiles(customer_id)
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE indexname = 'idx_customer_profiles_customer_id'
    ) THEN
        CREATE INDEX idx_customer_profiles_customer_id ON customer_profiles(customer_id);
        RAISE NOTICE 'Index idx_customer_profiles_customer_id created.';
    ELSE
        RAISE NOTICE 'Index idx_customer_profiles_customer_id already exists. Skipping creation.';
    END IF;
    
    -- Check and create index for customer_profiles(email)
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE indexname = 'idx_customer_profiles_email'
    ) THEN
        CREATE INDEX idx_customer_profiles_email ON customer_profiles(email);
        RAISE NOTICE 'Index idx_customer_profiles_email created.';
    ELSE
        RAISE NOTICE 'Index idx_customer_profiles_email already exists. Skipping creation.';
    END IF;
    
    -- Check and create index for customer_profiles(lifecycle_stage)
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE indexname = 'idx_customer_profiles_lifecycle_stage'
    ) THEN
        CREATE INDEX idx_customer_profiles_lifecycle_stage ON customer_profiles(lifecycle_stage);
        RAISE NOTICE 'Index idx_customer_profiles_lifecycle_stage created.';
    ELSE
        RAISE NOTICE 'Index idx_customer_profiles_lifecycle_stage already exists. Skipping creation.';
    END IF;

    -- Check and create index for support_tickets(customer_id)
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE indexname = 'idx_support_tickets_customer_id'
    ) THEN
        CREATE INDEX idx_support_tickets_customer_id ON support_tickets(customer_id);
        RAISE NOTICE 'Index idx_support_tickets_customer_id created.';
    ELSE
        RAISE NOTICE 'Index idx_support_tickets_customer_id already exists. Skipping creation.';
    END IF;
    
    -- Check and create index for support_tickets(status)
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE indexname = 'idx_support_tickets_status'
    ) THEN
        CREATE INDEX idx_support_tickets_status ON support_tickets(status);
        RAISE NOTICE 'Index idx_support_tickets_status created.';
    ELSE
        RAISE NOTICE 'Index idx_support_tickets_status already exists. Skipping creation.';
    END IF;
    
    -- Check and create index for support_tickets(priority_level)
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE indexname = 'idx_support_tickets_priority'
    ) THEN
        CREATE INDEX idx_support_tickets_priority ON support_tickets(priority_level);
        RAISE NOTICE 'Index idx_support_tickets_priority created.';
    ELSE
        RAISE NOTICE 'Index idx_support_tickets_priority already exists. Skipping creation.';
    END IF;
END
$$ LANGUAGE plpgsql;

-- ===============================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ===============================================

-- Enable RLS on all tables
ALTER TABLE ai_resource_generations ENABLE ROW LEVEL SECURITY;
ALTER TABLE resource_generation_summary ENABLE ROW LEVEL SECURITY;
ALTER TABLE generation_error_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE customer_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_configurations ENABLE ROW LEVEL SECURITY;
ALTER TABLE performance_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE support_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_dashboard_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE quality_benchmarks ENABLE ROW LEVEL SECURITY;
ALTER TABLE moment_in_life_descriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE empathy_maps ENABLE ROW LEVEL SECURITY;
ALTER TABLE advanced_sales_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE buyer_ux_considerations ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_usage_assessments ENABLE ROW LEVEL SECURITY;
ALTER TABLE day_in_life_descriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE month_in_life_descriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_journey_maps ENABLE ROW LEVEL SECURITY;
ALTER TABLE service_blueprints ENABLE ROW LEVEL SECURITY;
ALTER TABLE jobs_to_be_done ENABLE ROW LEVEL SECURITY;
ALTER TABLE compelling_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE scenario_planning ENABLE ROW LEVEL SECURITY;

-- ===============================================
-- CORRECTED RLS POLICIES WITH PROPER SYNTAX
-- ===============================================

-- Customer-specific data access policies
CREATE POLICY "customer_profiles_access" ON customer_profiles
    FOR ALL 
    TO authenticated
    USING ((auth.jwt() ->> 'user_id') = customer_id::text OR (auth.jwt() ->> 'role') = 'admin');

CREATE POLICY "ai_resource_generations_access" ON ai_resource_generations
    FOR ALL 
    TO authenticated
    USING (customer_id = (auth.jwt() ->> 'user_id') OR (auth.jwt() ->> 'role') = 'admin');

CREATE POLICY "resource_generation_summary_access" ON resource_generation_summary
    FOR ALL 
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM ai_resource_generations 
            WHERE id = generation_id 
            AND (customer_id = (auth.jwt() ->> 'user_id') OR (auth.jwt() ->> 'role') = 'admin')
        )
    );

CREATE POLICY "generation_error_logs_access" ON generation_error_logs
    FOR ALL 
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM ai_resource_generations 
            WHERE id = generation_id 
            AND (customer_id = (auth.jwt() ->> 'user_id') OR (auth.jwt() ->> 'role') = 'admin')
        )
    );

-- Admin-only access policies
CREATE POLICY "performance_metrics_admin_access" ON performance_metrics
    FOR ALL 
    TO authenticated
    USING ((auth.jwt() ->> 'role') = 'admin');

CREATE POLICY "admin_dashboard_metrics_access" ON admin_dashboard_metrics
    FOR ALL 
    TO authenticated
    USING ((auth.jwt() ->> 'role') = 'admin');

CREATE POLICY "quality_benchmarks_admin_access" ON quality_benchmarks
    FOR ALL 
    TO authenticated
    USING ((auth.jwt() ->> 'role') = 'admin');

CREATE POLICY "product_configurations_admin_access" ON product_configurations
    FOR ALL 
    TO authenticated
    USING ((auth.jwt() ->> 'role') = 'admin');

-- Support tickets - users can see their own, admins can see all
CREATE POLICY "support_tickets_access" ON support_tickets
    FOR ALL 
    TO authenticated
    USING (customer_id = (auth.jwt() ->> 'user_id') OR (auth.jwt() ->> 'role') = 'admin');

-- Psychology and sales tables - customer-specific access
CREATE POLICY "moment_in_life_descriptions_access" ON moment_in_life_descriptions
    FOR ALL 
    TO authenticated
    USING (customer_id = (auth.jwt() ->> 'user_id') OR (auth.jwt() ->> 'role') = 'admin');

CREATE POLICY "empathy_maps_access" ON empathy_maps
    FOR ALL 
    TO authenticated
    USING (customer_id = (auth.jwt() ->> 'user_id') OR (auth.jwt() ->> 'role') = 'admin');

CREATE POLICY "advanced_sales_tasks_access" ON advanced_sales_tasks
    FOR ALL 
    TO authenticated
    USING (customer_id = (auth.jwt() ->> 'user_id') OR (auth.jwt() ->> 'role') = 'admin');

CREATE POLICY "buyer_ux_considerations_access" ON buyer_ux_considerations
    FOR ALL 
    TO authenticated
    USING (customer_id = (auth.jwt() ->> 'user_id') OR (auth.jwt() ->> 'role') = 'admin');

CREATE POLICY "product_usage_assessments_access" ON product_usage_assessments
    FOR ALL 
    TO authenticated
    USING (customer_id = (auth.jwt() ->> 'user_id') OR (auth.jwt() ->> 'role') = 'admin');

CREATE POLICY "day_in_life_descriptions_access" ON day_in_life_descriptions
    FOR ALL 
    TO authenticated
    USING (customer_id = (auth.jwt() ->> 'user_id') OR (auth.jwt() ->> 'role') = 'admin');

CREATE POLICY "month_in_life_descriptions_access" ON month_in_life_descriptions
    FOR ALL 
    TO authenticated
    USING (customer_id = (auth.jwt() ->> 'user_id') OR (auth.jwt() ->> 'role') = 'admin');

CREATE POLICY "user_journey_maps_access" ON user_journey_maps
    FOR ALL 
    TO authenticated
    USING (customer_id = (auth.jwt() ->> 'user_id') OR (auth.jwt() ->> 'role') = 'admin');

CREATE POLICY "service_blueprints_access" ON service_blueprints
    FOR ALL 
    TO authenticated
    USING (customer_id = (auth.jwt() ->> 'user_id') OR (auth.jwt() ->> 'role') = 'admin');

CREATE POLICY "jobs_to_be_done_access" ON jobs_to_be_done
    FOR ALL 
    TO authenticated
    USING (customer_id = (auth.jwt() ->> 'user_id') OR (auth.jwt() ->> 'role') = 'admin');

CREATE POLICY "compelling_events_access" ON compelling_events
    FOR ALL 
    TO authenticated
    USING (customer_id = (auth.jwt() ->> 'user_id') OR (auth.jwt() ->> 'role') = 'admin');

CREATE POLICY "scenario_planning_access" ON scenario_planning
    FOR ALL 
    TO authenticated
    USING (customer_id = (auth.jwt() ->> 'user_id') OR (auth.jwt() ->> 'role') = 'admin');

-- ===============================================
-- TRIGGERS FOR AUTOMATIC TIMESTAMP UPDATES - IMPROVED APPROACH
-- ===============================================

-- Create or replace the timestamp update function (always succeeds)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply triggers to all tables with updated_at, checking for existence first
DO $$
DECLARE
    trigger_exists BOOLEAN;
BEGIN
    -- ai_resource_generations trigger
    SELECT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'update_ai_resource_generations_updated_at'
        AND tgrelid = 'public.ai_resource_generations'::regclass
    ) INTO trigger_exists;
    
    IF NOT trigger_exists THEN
        CREATE TRIGGER update_ai_resource_generations_updated_at
            BEFORE UPDATE ON ai_resource_generations
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
        RAISE NOTICE 'Created trigger update_ai_resource_generations_updated_at';
    ELSE
        RAISE NOTICE 'Trigger update_ai_resource_generations_updated_at already exists. Skipping.';
    END IF;

    -- resource_generation_summary trigger
    SELECT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'update_resource_generation_summary_updated_at'
        AND tgrelid = 'public.resource_generation_summary'::regclass
    ) INTO trigger_exists;
    
    IF NOT trigger_exists THEN
        CREATE TRIGGER update_resource_generation_summary_updated_at
            BEFORE UPDATE ON resource_generation_summary
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
        RAISE NOTICE 'Created trigger update_resource_generation_summary_updated_at';
    ELSE
        RAISE NOTICE 'Trigger update_resource_generation_summary_updated_at already exists. Skipping.';
    END IF;

    -- customer_profiles trigger
    SELECT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'update_customer_profiles_updated_at'
        AND tgrelid = 'public.customer_profiles'::regclass
    ) INTO trigger_exists;
    
    IF NOT trigger_exists THEN
        CREATE TRIGGER update_customer_profiles_updated_at
            BEFORE UPDATE ON customer_profiles
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
        RAISE NOTICE 'Created trigger update_customer_profiles_updated_at';
    ELSE
        RAISE NOTICE 'Trigger update_customer_profiles_updated_at already exists. Skipping.';
    END IF;

    -- product_configurations trigger
    SELECT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'update_product_configurations_updated_at'
        AND tgrelid = 'public.product_configurations'::regclass
    ) INTO trigger_exists;
    
    IF NOT trigger_exists THEN
        CREATE TRIGGER update_product_configurations_updated_at
            BEFORE UPDATE ON product_configurations
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
        RAISE NOTICE 'Created trigger update_product_configurations_updated_at';
    ELSE
        RAISE NOTICE 'Trigger update_product_configurations_updated_at already exists. Skipping.';
    END IF;

    -- support_tickets trigger
    SELECT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'update_support_tickets_updated_at'
        AND tgrelid = 'public.support_tickets'::regclass
    ) INTO trigger_exists;
    
    IF NOT trigger_exists THEN
        CREATE TRIGGER update_support_tickets_updated_at
            BEFORE UPDATE ON support_tickets
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
        RAISE NOTICE 'Created trigger update_support_tickets_updated_at';
    ELSE
        RAISE NOTICE 'Trigger update_support_tickets_updated_at already exists. Skipping.';
    END IF;

    -- admin_dashboard_metrics trigger
    SELECT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'update_admin_dashboard_metrics_updated_at'
        AND tgrelid = 'public.admin_dashboard_metrics'::regclass
    ) INTO trigger_exists;
    
    IF NOT trigger_exists THEN
        CREATE TRIGGER update_admin_dashboard_metrics_updated_at
            BEFORE UPDATE ON admin_dashboard_metrics
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
        RAISE NOTICE 'Created trigger update_admin_dashboard_metrics_updated_at';
    ELSE
        RAISE NOTICE 'Trigger update_admin_dashboard_metrics_updated_at already exists. Skipping.';
    END IF;

    -- quality_benchmarks trigger
    SELECT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'update_quality_benchmarks_updated_at'
        AND tgrelid = 'public.quality_benchmarks'::regclass
    ) INTO trigger_exists;
    
    IF NOT trigger_exists THEN
        CREATE TRIGGER update_quality_benchmarks_updated_at
            BEFORE UPDATE ON quality_benchmarks
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
        RAISE NOTICE 'Created trigger update_quality_benchmarks_updated_at';
    ELSE
        RAISE NOTICE 'Trigger update_quality_benchmarks_updated_at already exists. Skipping.';
    END IF;

    -- moment_in_life_descriptions trigger
    SELECT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'update_moment_in_life_descriptions_updated_at'
        AND tgrelid = 'public.moment_in_life_descriptions'::regclass
    ) INTO trigger_exists;
    
    IF NOT trigger_exists THEN
        CREATE TRIGGER update_moment_in_life_descriptions_updated_at
            BEFORE UPDATE ON moment_in_life_descriptions
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
        RAISE NOTICE 'Created trigger update_moment_in_life_descriptions_updated_at';
    ELSE
        RAISE NOTICE 'Trigger update_moment_in_life_descriptions_updated_at already exists. Skipping.';
    END IF;

    -- empathy_maps trigger
    SELECT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'update_empathy_maps_updated_at'
        AND tgrelid = 'public.empathy_maps'::regclass
    ) INTO trigger_exists;
    
    IF NOT trigger_exists THEN
        CREATE TRIGGER update_empathy_maps_updated_at
            BEFORE UPDATE ON empathy_maps
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
        RAISE NOTICE 'Created trigger update_empathy_maps_updated_at';
    ELSE
        RAISE NOTICE 'Trigger update_empathy_maps_updated_at already exists. Skipping.';
    END IF;

    -- advanced_sales_tasks trigger
    SELECT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'update_advanced_sales_tasks_updated_at'
        AND tgrelid = 'public.advanced_sales_tasks'::regclass
    ) INTO trigger_exists;
    
    IF NOT trigger_exists THEN
        CREATE TRIGGER update_advanced_sales_tasks_updated_at
            BEFORE UPDATE ON advanced_sales_tasks
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
        RAISE NOTICE 'Created trigger update_advanced_sales_tasks_updated_at';
    ELSE
        RAISE NOTICE 'Trigger update_advanced_sales_tasks_updated_at already exists. Skipping.';
    END IF;

    -- buyer_ux_considerations trigger
    SELECT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'update_buyer_ux_considerations_updated_at'
        AND tgrelid = 'public.buyer_ux_considerations'::regclass
    ) INTO trigger_exists;
    
    IF NOT trigger_exists THEN
        CREATE TRIGGER update_buyer_ux_considerations_updated_at
            BEFORE UPDATE ON buyer_ux_considerations
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
        RAISE NOTICE 'Created trigger update_buyer_ux_considerations_updated_at';
    ELSE
        RAISE NOTICE 'Trigger update_buyer_ux_considerations_updated_at already exists. Skipping.';
    END IF;

    -- product_usage_assessments trigger
    SELECT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'update_product_usage_assessments_updated_at'
        AND tgrelid = 'public.product_usage_assessments'::regclass
    ) INTO trigger_exists;
    
    IF NOT trigger_exists THEN
        CREATE TRIGGER update_product_usage_assessments_updated_at
            BEFORE UPDATE ON product_usage_assessments
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
        RAISE NOTICE 'Created trigger update_product_usage_assessments_updated_at';
    ELSE
        RAISE NOTICE 'Trigger update_product_usage_assessments_updated_at already exists. Skipping.';
    END IF;

    -- day_in_life_descriptions trigger
    SELECT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'update_day_in_life_descriptions_updated_at'
        AND tgrelid = 'public.day_in_life_descriptions'::regclass
    ) INTO trigger_exists;
    
    IF NOT trigger_exists THEN
        CREATE TRIGGER update_day_in_life_descriptions_updated_at
            BEFORE UPDATE ON day_in_life_descriptions
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
        RAISE NOTICE 'Created trigger update_day_in_life_descriptions_updated_at';
    ELSE
        RAISE NOTICE 'Trigger update_day_in_life_descriptions_updated_at already exists. Skipping.';
    END IF;

    -- month_in_life_descriptions trigger
    SELECT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'update_month_in_life_descriptions_updated_at'
        AND tgrelid = 'public.month_in_life_descriptions'::regclass
    ) INTO trigger_exists;
    
    IF NOT trigger_exists THEN
        CREATE TRIGGER update_month_in_life_descriptions_updated_at
            BEFORE UPDATE ON month_in_life_descriptions
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
        RAISE NOTICE 'Created trigger update_month_in_life_descriptions_updated_at';
    ELSE
        RAISE NOTICE 'Trigger update_month_in_life_descriptions_updated_at already exists. Skipping.';
    END IF;

    -- user_journey_maps trigger
    SELECT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'update_user_journey_maps_updated_at'
        AND tgrelid = 'public.user_journey_maps'::regclass
    ) INTO trigger_exists;
    
    IF NOT trigger_exists THEN
        CREATE TRIGGER update_user_journey_maps_updated_at
            BEFORE UPDATE ON user_journey_maps
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
        RAISE NOTICE 'Created trigger update_user_journey_maps_updated_at';
    ELSE
        RAISE NOTICE 'Trigger update_user_journey_maps_updated_at already exists. Skipping.';
    END IF;

    -- service_blueprints trigger
    SELECT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'update_service_blueprints_updated_at'
        AND tgrelid = 'public.service_blueprints'::regclass
    ) INTO trigger_exists;
    
    IF NOT trigger_exists THEN
        CREATE TRIGGER update_service_blueprints_updated_at
            BEFORE UPDATE ON service_blueprints
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
        RAISE NOTICE 'Created trigger update_service_blueprints_updated_at';
    ELSE
        RAISE NOTICE 'Trigger update_service_blueprints_updated_at already exists. Skipping.';
    END IF;

    -- jobs_to_be_done trigger
    SELECT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'update_jobs_to_be_done_updated_at'
        AND tgrelid = 'public.jobs_to_be_done'::regclass
    ) INTO trigger_exists;
    
    IF NOT trigger_exists THEN
        CREATE TRIGGER update_jobs_to_be_done_updated_at
            BEFORE UPDATE ON jobs_to_be_done
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
        RAISE NOTICE 'Created trigger update_jobs_to_be_done_updated_at';
    ELSE
        RAISE NOTICE 'Trigger update_jobs_to_be_done_updated_at already exists. Skipping.';
    END IF;

    -- compelling_events trigger
    SELECT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'update_compelling_events_updated_at'
        AND tgrelid = 'public.compelling_events'::regclass
    ) INTO trigger_exists;
    
    IF NOT trigger_exists THEN
        CREATE TRIGGER update_compelling_events_updated_at
            BEFORE UPDATE ON compelling_events
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
        RAISE NOTICE 'Created trigger update_compelling_events_updated_at';
    ELSE
        RAISE NOTICE 'Trigger update_compelling_events_updated_at already exists. Skipping.';
    END IF;

    -- scenario_planning trigger
    SELECT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'update_scenario_planning_updated_at'
        AND tgrelid = 'public.scenario_planning'::regclass
    ) INTO trigger_exists;
    
    IF NOT trigger_exists THEN
        CREATE TRIGGER update_scenario_planning_updated_at
            BEFORE UPDATE ON scenario_planning
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
        RAISE NOTICE 'Created trigger update_scenario_planning_updated_at';
    ELSE
        RAISE NOTICE 'Trigger update_scenario_planning_updated_at already exists. Skipping.';
    END IF;

END 
$$ LANGUAGE plpgsql;

-- ===============================================
-- COMMENTS FOR DOCUMENTATION
-- ===============================================

COMMENT ON TABLE ai_resource_generations IS 'Master tracking for all AI resource generation processes';
COMMENT ON TABLE resource_generation_summary IS 'Individual resource tracking within generation jobs';
COMMENT ON TABLE generation_error_logs IS 'Comprehensive error tracking and resolution management';
COMMENT ON TABLE customer_profiles IS 'Enhanced customer relationship management and lifecycle tracking';
COMMENT ON TABLE product_configurations IS 'Product catalog and pricing management';
COMMENT ON TABLE performance_metrics IS 'Daily system performance and analytics tracking';
COMMENT ON TABLE support_tickets IS 'Customer support ticket management and resolution';
COMMENT ON TABLE admin_dashboard_metrics IS 'Real-time system health and operational monitoring';
COMMENT ON TABLE quality_benchmarks IS 'Quality standards and thresholds for resource generation';
COMMENT ON TABLE moment_in_life_descriptions IS 'Detailed trigger event and emotional state analysis';
COMMENT ON TABLE empathy_maps IS 'Comprehensive customer psychology mapping';
COMMENT ON TABLE advanced_sales_tasks IS 'Comprehensive sales methodology optimization';
COMMENT ON TABLE buyer_ux_considerations IS 'Buyer-centric user experience design';
COMMENT ON TABLE product_usage_assessments IS 'Product adoption and usage patterns';
COMMENT ON TABLE day_in_life_descriptions IS 'Daily workflow and product interaction scenarios';
COMMENT ON TABLE month_in_life_descriptions IS 'Long-term patterns and evolutionary tracking';
COMMENT ON TABLE user_journey_maps IS 'Stage-based customer journey analysis';
COMMENT ON TABLE service_blueprints IS 'Service delivery process mapping';
COMMENT ON TABLE jobs_to_be_done IS 'JTBD framework analysis';
COMMENT ON TABLE compelling_events IS 'Sales acceleration trigger identification';
COMMENT ON TABLE scenario_planning IS 'Strategic scenario analysis and contingency planning';



-- ADDITIONAL SUPABASE SCHEMA FOR ANDRU REVENUE INTELLIGENCE PLATFORM USER TABLES
-- Run this single file in Supabase SQL Editor to create all tables and data

-- PART 1: CREATE CUSTOMER_ASSETS TABLE (32+ FIELDS)
-- 

CREATE TABLE IF NOT EXISTS customer_assets (
  -- Core Identity Fields
  customer_id TEXT PRIMARY KEY,
  customer_name TEXT,
  email TEXT UNIQUE,
  company TEXT,
  access_token TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  last_accessed TIMESTAMPTZ,
  
  -- Payment & Status Fields  
  payment_status TEXT CHECK (payment_status IN ('Pending', 'Completed', 'Failed', 'Refunded')) DEFAULT 'Pending',
  content_status TEXT CHECK (content_status IN ('Pending', 'Generating', 'Ready', 'Error', 'Expired')) DEFAULT 'Pending',
  usage_count INTEGER DEFAULT 0,
  
  -- Content Storage (JSON fields for complex data)
  icp_content JSONB,
  cost_calculator_content JSONB,
  business_case_content JSONB,
  
  -- Professional Development Fields
  competency_progress JSONB,
  tool_access_status JSONB,
  professional_milestones JSONB,
  daily_objectives JSONB,
  user_preferences JSONB,
  detailed_icp_analysis JSONB,
  target_buyer_personas JSONB,
  
  -- Development Planning
  development_plan_active BOOLEAN DEFAULT FALSE,
  competency_level TEXT,
  achievement_ids TEXT,
  last_assessment_date TIMESTAMPTZ,
  development_focus TEXT CHECK (development_focus IN ('balanced', 'strength_based', 'gap_focused', 'career_accelerated')),
  learning_velocity NUMERIC(5,1),
  last_action_date TIMESTAMPTZ,
  
  -- Workflow & Analytics
  workflow_progress JSONB,
  usage_analytics JSONB,
  
  -- Enhanced fields for revolutionary platform
  technical_translation_data JSONB,
  stakeholder_arsenal_data JSONB,
  resources_library_data JSONB,
  gamification_state JSONB,
  
  -- Timestamps
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_customer_assets_email ON customer_assets(email);
CREATE INDEX IF NOT EXISTS idx_customer_assets_access_token ON customer_assets(access_token);
CREATE INDEX IF NOT EXISTS idx_customer_assets_payment_status ON customer_assets(payment_status);
CREATE INDEX IF NOT EXISTS idx_customer_assets_last_accessed ON customer_assets(last_accessed);

-- Create trigger to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_customer_assets_updated_at ON customer_assets;
CREATE TRIGGER update_customer_assets_updated_at 
    BEFORE UPDATE ON customer_assets 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- PART 2: CREATE ASSESSMENT_RESULTS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS assessment_results (
  -- Primary Fields
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id TEXT NOT NULL,
  assessment_date TIMESTAMPTZ DEFAULT NOW(),
  
  -- Assessment Scores (0-100 scale)
  customer_analysis_score NUMERIC(5,2),
  value_communication_score NUMERIC(5,2),
  sales_execution_score NUMERIC(5,2),
  overall_score NUMERIC(5,2),
  
  -- Professional Development Tracking
  total_progress_points INTEGER DEFAULT 0,
  competency_level TEXT,
  previous_level TEXT,
  
  -- Assessment Metadata
  assessment_type TEXT CHECK (assessment_type IN ('baseline', 'progress', 'retake', 'milestone')) DEFAULT 'progress',
  assessment_version TEXT DEFAULT 'v1.0',
  
  -- Performance Analysis
  improvement_areas JSONB,
  strength_areas JSONB,
  recommended_actions JSONB,
  
  -- Competency Details
  buyer_understanding_score NUMERIC(5,2),
  tech_to_value_translation_score NUMERIC(5,2),
  stakeholder_communication_score NUMERIC(5,2),
  roi_presentation_score NUMERIC(5,2),
  
  -- Professional Context
  industry_focus TEXT,
  company_stage TEXT,
  revenue_range TEXT,
  
  -- Session Data
  assessment_duration INTEGER,
  completion_percentage NUMERIC(5,2),
  
  -- Notes and Context
  notes TEXT,
  assessor_notes TEXT,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_assessment_results_customer_id ON assessment_results(customer_id);
CREATE INDEX IF NOT EXISTS idx_assessment_results_assessment_date ON assessment_results(assessment_date);
CREATE INDEX IF NOT EXISTS idx_assessment_results_assessment_type ON assessment_results(assessment_type);
CREATE INDEX IF NOT EXISTS idx_assessment_results_competency_level ON assessment_results(competency_level);
CREATE INDEX IF NOT EXISTS idx_assessment_results_overall_score ON assessment_results(overall_score);

-- Foreign key constraint to customer_assets
ALTER TABLE assessment_results 
DROP CONSTRAINT IF EXISTS fk_assessment_customer;
ALTER TABLE assessment_results 
ADD CONSTRAINT fk_assessment_customer 
FOREIGN KEY (customer_id) REFERENCES customer_assets(customer_id) ON DELETE CASCADE;

-- Create trigger to automatically update updated_at timestamp
DROP TRIGGER IF EXISTS update_assessment_results_updated_at ON assessment_results;
CREATE TRIGGER update_assessment_results_updated_at 
    BEFORE UPDATE ON assessment_results 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- PART 3: CREATE CUSTOMER_ACTIONS TABLE (GAMIFICATION)
-- ============================================================================

CREATE TABLE IF NOT EXISTS customer_actions (
  -- Primary Fields
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id TEXT NOT NULL,
  
  -- Action Details
  action_type TEXT NOT NULL CHECK (action_type IN (
    'customer_meeting',
    'prospect_qualification', 
    'value_proposition_delivery',
    'roi_presentation',
    'proposal_creation',
    'deal_closure',
    'referral_generation',
    'case_study_development'
  )),
  action_description TEXT NOT NULL,
  
  -- Impact & Scoring
  impact_level TEXT CHECK (impact_level IN ('low', 'medium', 'high', 'critical')) DEFAULT 'medium',
  points_awarded INTEGER NOT NULL,
  base_points INTEGER,
  impact_multiplier NUMERIC(3,2) DEFAULT 1.0,
  
  -- Categorization
  category TEXT CHECK (category IN ('customerAnalysis', 'valueCommunication', 'salesExecution')) NOT NULL,
  subcategory TEXT,
  
  -- Professional Context
  deal_size_range TEXT,
  stakeholder_level TEXT,
  industry_context TEXT,
  
  -- Evidence & Verification
  evidence_link TEXT,
  evidence_type TEXT,
  verified BOOLEAN DEFAULT FALSE,
  verified_by TEXT,
  verified_at TIMESTAMPTZ,
  
  -- Timing
  action_date TIMESTAMPTZ NOT NULL,
  duration_minutes INTEGER,
  
  -- Outcome Tracking
  outcome_achieved BOOLEAN,
  outcome_description TEXT,
  follow_up_required BOOLEAN DEFAULT FALSE,
  follow_up_date TIMESTAMPTZ,
  
  -- Learning & Development
  skills_demonstrated JSONB,
  lessons_learned TEXT,
  improvement_notes TEXT,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_customer_actions_customer_id ON customer_actions(customer_id);
CREATE INDEX IF NOT EXISTS idx_customer_actions_action_type ON customer_actions(action_type);
CREATE INDEX IF NOT EXISTS idx_customer_actions_action_date ON customer_actions(action_date);
CREATE INDEX IF NOT EXISTS idx_customer_actions_category ON customer_actions(category);
CREATE INDEX IF NOT EXISTS idx_customer_actions_impact_level ON customer_actions(impact_level);
CREATE INDEX IF NOT EXISTS idx_customer_actions_points_awarded ON customer_actions(points_awarded);
CREATE INDEX IF NOT EXISTS idx_customer_actions_verified ON customer_actions(verified);

-- Foreign key constraint to customer_assets
ALTER TABLE customer_actions 
DROP CONSTRAINT IF EXISTS fk_actions_customer;
ALTER TABLE customer_actions 
ADD CONSTRAINT fk_actions_customer 
FOREIGN KEY (customer_id) REFERENCES customer_assets(customer_id) ON DELETE CASCADE;

-- Create trigger to automatically update updated_at timestamp
DROP TRIGGER IF EXISTS update_customer_actions_updated_at ON customer_actions;
CREATE TRIGGER update_customer_actions_updated_at 
    BEFORE UPDATE ON customer_actions 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 
-- ============================================================================
-- PART 4: ROW LEVEL SECURITY (RLS) POLICIES - FIXED
-- ============================================================================

-- Enable Row Level Security on all tables
ALTER TABLE customer_assets ENABLE ROW LEVEL SECURITY;
ALTER TABLE assessment_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE customer_actions ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS customer_assets_select_policy ON customer_assets;
DROP POLICY IF EXISTS customer_assets_insert_policy ON customer_assets;
DROP POLICY IF EXISTS customer_assets_update_policy ON customer_assets;
DROP POLICY IF EXISTS customer_assets_delete_policy ON customer_assets;
DROP POLICY IF EXISTS assessment_results_select_policy ON assessment_results;
DROP POLICY IF EXISTS assessment_results_insert_policy ON assessment_results;
DROP POLICY IF EXISTS assessment_results_update_policy ON assessment_results;
DROP POLICY IF EXISTS customer_actions_select_policy ON customer_actions;
DROP POLICY IF EXISTS customer_actions_insert_policy ON customer_actions;
DROP POLICY IF EXISTS customer_actions_update_policy ON customer_actions;

-- Customer Assets Policies - FIXED
CREATE POLICY "customer_assets_select_policy" ON customer_assets
    FOR SELECT 
    TO authenticated
    USING (
        customer_id = (auth.jwt() ->> 'sub') OR 
        access_token = (auth.jwt() ->> 'sub') OR
        customer_id = 'dru78DR9789SDF862'
    );

CREATE POLICY "customer_assets_insert_policy" ON customer_assets
    FOR INSERT 
    TO authenticated
    WITH CHECK (
        customer_id = (auth.jwt() ->> 'sub') OR
        access_token = (auth.jwt() ->> 'sub')
    );

CREATE POLICY "customer_assets_update_policy" ON customer_assets
    FOR UPDATE 
    TO authenticated
    USING (
        customer_id = (auth.jwt() ->> 'sub') OR 
        access_token = (auth.jwt() ->> 'sub') OR
        customer_id = 'dru78DR9789SDF862'
    )
    WITH CHECK (
        customer_id = (auth.jwt() ->> 'sub') OR 
        access_token = (auth.jwt() ->> 'sub') OR
        customer_id = 'dru78DR9789SDF862'
    );

CREATE POLICY "customer_assets_delete_policy" ON customer_assets
    FOR DELETE 
    TO authenticated
    USING (
        customer_id = (auth.jwt() ->> 'sub') OR
        customer_id = 'dru78DR9789SDF862'
    );

-- Assessment Results Policies - FIXED
CREATE POLICY "assessment_results_select_policy" ON assessment_results
    FOR SELECT 
    TO authenticated
    USING (
        customer_id = (auth.jwt() ->> 'sub') OR 
        customer_id IN (
            SELECT customer_id FROM customer_assets 
            WHERE access_token = (auth.jwt() ->> 'sub')
        ) OR
        customer_id = 'dru78DR9789SDF862'
    );

CREATE POLICY "assessment_results_insert_policy" ON assessment_results
    FOR INSERT 
    TO authenticated
    WITH CHECK (
        customer_id = (auth.jwt() ->> 'sub') OR
        customer_id IN (
            SELECT customer_id FROM customer_assets 
            WHERE access_token = (auth.jwt() ->> 'sub')
        )
    );

CREATE POLICY "assessment_results_update_policy" ON assessment_results
    FOR UPDATE 
    TO authenticated
    USING (
        customer_id = (auth.jwt() ->> 'sub') OR 
        customer_id IN (
            SELECT customer_id FROM customer_assets 
            WHERE access_token = (auth.jwt() ->> 'sub')
        ) OR
        customer_id = 'dru78DR9789SDF862'
    )
    WITH CHECK (
        customer_id = (auth.jwt() ->> 'sub') OR 
        customer_id IN (
            SELECT customer_id FROM customer_assets 
            WHERE access_token = (auth.jwt() ->> 'sub')
        ) OR
        customer_id = 'dru78DR9789SDF862'
    );

-- Customer Actions Policies - FIXED
CREATE POLICY "customer_actions_select_policy" ON customer_actions
    FOR SELECT 
    TO authenticated
    USING (
        customer_id = (auth.jwt() ->> 'sub') OR 
        customer_id IN (
            SELECT customer_id FROM customer_assets 
            WHERE access_token = (auth.jwt() ->> 'sub')
        ) OR
        customer_id = 'dru78DR9789SDF862'
    );

CREATE POLICY "customer_actions_insert_policy" ON customer_actions
    FOR INSERT 
    TO authenticated
    WITH CHECK (
        customer_id = (auth.jwt() ->> 'sub') OR
        customer_id IN (
            SELECT customer_id FROM customer_assets 
            WHERE access_token = (auth.jwt() ->> 'sub')
        )
    );

CREATE POLICY "customer_actions_update_policy" ON customer_actions
    FOR UPDATE 
    TO authenticated
    USING (
        customer_id = (auth.jwt() ->> 'sub') OR 
        customer_id IN (
            SELECT customer_id FROM customer_assets 
            WHERE access_token = (auth.jwt() ->> 'sub')
        ) OR
        customer_id = 'dru78DR9789SDF862'
    )
    WITH CHECK (
        customer_id = (auth.jwt() ->> 'sub') OR 
        customer_id IN (
            SELECT customer_id FROM customer_assets 
            WHERE access_token = (auth.jwt() ->> 'sub')
        ) OR
        customer_id = 'dru78DR9789SDF862'
    );

-- ============================================================================
-- PART 5: UTILITY FUNCTIONS AND VIEWS
-- ============================================================================

-- Create function to calculate competency level based on points
CREATE OR REPLACE FUNCTION calculate_competency_level(total_points INTEGER)
RETURNS TEXT AS $$
BEGIN
  CASE 
    WHEN total_points < 1000 THEN RETURN 'Customer Intelligence Foundation';
    WHEN total_points < 2500 THEN RETURN 'Systematic Buyer Understanding';  
    WHEN total_points < 5000 THEN RETURN 'Value Communication Proficiency';
    WHEN total_points < 10000 THEN RETURN 'Advanced Sales Execution';
    WHEN total_points < 25000 THEN RETURN 'Revenue Intelligence Expert';
    ELSE RETURN 'Revenue Intelligence Master';
  END CASE;
END;
$$ LANGUAGE plpgsql;

-- Create view for customer competency summary
DROP VIEW IF EXISTS customer_competency_summary;
CREATE VIEW customer_competency_summary AS
SELECT 
  ca.customer_id,
  ca.customer_name,
  ca.email,
  ca.competency_level,
  COALESCE(
    (SELECT SUM(points_awarded) FROM customer_actions WHERE customer_id = ca.customer_id),
    0
  ) as total_progress_points,
  ar.overall_score as latest_assessment_score,
  ar.assessment_date as latest_assessment_date,
  COUNT(act.id) as total_actions,
  SUM(act.points_awarded) as total_action_points
FROM customer_assets ca
LEFT JOIN LATERAL (
  SELECT * FROM assessment_results 
  WHERE customer_id = ca.customer_id 
  ORDER BY assessment_date DESC 
  LIMIT 1
) ar ON true
LEFT JOIN customer_actions act ON act.customer_id = ca.customer_id
GROUP BY ca.customer_id, ca.customer_name, ca.email, ca.competency_level, 
         ar.overall_score, ar.assessment_date;

-- ============================================================================
-- PART 6: INSERT SAMPLE DATA
-- ============================================================================

-- Insert admin user (dru78DR9789SDF862)
INSERT INTO customer_assets (
  customer_id,
  customer_name, 
  email,
  company,
  access_token,
  payment_status,
  content_status,
  competency_level,
  development_plan_active,
  icp_content,
  cost_calculator_content,
  business_case_content
) VALUES (
  'dru78DR9789SDF862',
  'Admin Demo User',
  'admin@h-and-s.ai',
  'H&S Platform',
  'admin-demo-token-2025',
  'Completed',
  'Ready',
  'Revenue Intelligence Expert',
  true,
  '{"framework": "enterprise", "segments": ["Enterprise SaaS", "Mid-Market Tech"], "confidence": 95}',
  '{"scenarios": ["conservative", "realistic", "aggressive"], "calculations": {"roi": 325, "payback": 8}}',
  '{"templates": ["pilot", "full_implementation"], "value": 250000, "timeline": "6-18 months"}'
) ON CONFLICT (customer_id) DO NOTHING;

-- Insert test user dru78DR9789SDF862
INSERT INTO customer_assets (
  customer_id,
  customer_name,
  email,
  company,
  access_token,
  payment_status,
  content_status,
  usage_count,
  competency_level,
  development_plan_active,
  icp_content,
  cost_calculator_content,
  business_case_content,
  competency_progress,
  tool_access_status,
  professional_milestones,
  daily_objectives,
  user_preferences,
  workflow_progress,
  usage_analytics,
  technical_translation_data,
  stakeholder_arsenal_data,
  resources_library_data,
  gamification_state
) VALUES (
  'dru78DR9789SDF862',
  'Test User Sarah',
  'sarah.test@example.com',
  'Test Company Inc',
  'test-token-123456',
  'Completed',
  'Ready',
  15,
  'Systematic Buyer Understanding',
  true,
  '{"framework": "comprehensive", "segments": [{"name": "Enterprise SaaS", "score": 85}, {"name": "Mid-Market Tech", "score": 72}], "confidence": 78}',
  '{"scenarios": ["conservative", "realistic", "aggressive"], "calculations": {"roi": 245, "payback": 12, "totalCost": 125000, "savings": 180000}}',
  '{"templates": ["pilot_program"], "value": 180000, "timeline": "6-12 months", "stakeholders": ["CTO", "CFO", "Head of Operations"]}',
  '{"current_level": "Systematic Buyer Understanding", "points_earned": 1850, "areas_of_focus": ["Value Communication", "ROI Analysis"], "last_updated": "2024-08-27"}',
  '{"icp_analysis": true, "cost_calculator": true, "business_case_builder": true, "advanced_features": false}',
  '{"achievements": [{"title": "First ICP Analysis", "description": "Completed comprehensive ICP framework", "date": "2024-08-20", "impact": "Improved prospect qualification"}], "current_goals": ["Master ROI presentations", "Develop stakeholder communication"], "next_milestone": {"target": "Q4 2024", "goal": "Advanced Sales Execution level"}}',
  '{"today": [{"priority": "high", "task": "Review enterprise prospects", "timeBlock": "9:00-10:30", "outcome": "Qualify 2 opportunities"}], "thisWeek": ["Complete cost calculator training", "Practice stakeholder presentations"], "metrics": {"completionRate": 75, "focusTime": "4.2 hours", "keyResults": 2}}',
  '{"interface_theme": "dark", "notification_settings": {"email": true, "milestone_alerts": true}, "workflow_preferences": {"auto_save": true, "detailed_analysis": true}}',
  '{"tools_completed": ["icp_analysis", "cost_calculator"], "current_step": "business_case_builder", "completion_percentage": 67}',
  '{"session_count": 18, "total_time_spent": 320, "feature_usage": {"icp": 8, "calculator": 6, "business_case": 4}}',
  '{"templates": [{"stakeholder": "CTO", "focus": "architecture", "templates": ["scalability_framework", "security_compliance"]}, {"stakeholder": "CFO", "focus": "financial", "templates": ["roi_calculator", "cost_benefit_analysis"]}], "translation_history": [{"from": "technical_spec", "to": "business_value", "date": "2024-08-25", "success": true}]}',
  '{"stakeholder_profiles": [{"role": "CTO", "priorities": ["scalability", "security", "integration"], "communication_style": "technical_depth"}, {"role": "CFO", "priorities": ["cost_reduction", "roi", "risk_mitigation"], "communication_style": "metrics_focused"}], "communication_templates": ["executive_summary", "technical_deep_dive", "financial_analysis"]}',
  '{"generated_resources": [{"type": "competitive_analysis", "date": "2024-08-26", "quality_score": 88}, {"type": "market_sizing", "date": "2024-08-25", "quality_score": 92}], "custom_templates": ["enterprise_pilot_framework", "technical_evaluation_criteria"]}',
  '{"current_level": "Systematic Buyer Understanding", "points_balance": 1850, "achievements_unlocked": ["first_icp", "cost_analysis_expert", "systematic_approach"], "milestone_progress": {"current_milestone": "Advanced Sales Execution", "progress_percentage": 62, "points_needed": 1150}}'
) ON CONFLICT (customer_id) DO NOTHING;

-- Insert assessment results for admin user
INSERT INTO assessment_results (
  customer_id,
  customer_analysis_score,
  value_communication_score, 
  sales_execution_score,
  overall_score,
  total_progress_points,
  competency_level,
  assessment_type,
  buyer_understanding_score,
  tech_to_value_translation_score,
  stakeholder_communication_score,
  roi_presentation_score,
  industry_focus,
  company_stage,
  revenue_range,
  improvement_areas,
  strength_areas,
  recommended_actions
) VALUES (
  'dru78DR9789SDF862',
  72.5,
  68.0,
  75.2,
  71.9,
  1250,
  'Revenue Intelligence Expert',
  'baseline',
  74.0,
  67.5,
  71.0,
  73.5,
  'Enterprise AI/SaaS',
  'Series A',
  '$5M-10M',
  '["Value quantification", "Stakeholder alignment", "ROI presentation"]',
  '["Technical architecture", "Product vision", "Market analysis"]',
  '["Develop systematic ROI frameworks", "Practice stakeholder presentations", "Build value calculation templates"]'
) ON CONFLICT ON CONSTRAINT assessment_results_pkey DO NOTHING;

-- Insert assessment history for dru78DR9789SDF862
INSERT INTO assessment_results (
  customer_id,
  assessment_date,
  customer_analysis_score,
  value_communication_score,
  sales_execution_score,
  overall_score,
  total_progress_points,
  competency_level,
  assessment_type,
  buyer_understanding_score,
  tech_to_value_translation_score,
  stakeholder_communication_score,
  roi_presentation_score,
  industry_focus,
  company_stage,
  revenue_range,
  improvement_areas,
  strength_areas,
  recommended_actions
) VALUES 
(
  'dru78DR9789SDF862',
  '2024-08-20 10:00:00+00',
  65.5,
  58.2,
  52.8,
  58.8,
  800,
  'Customer Intelligence Foundation',
  'baseline',
  62.0,
  55.5,
  61.0,
  48.5,
  'Enterprise SaaS',
  'Series A',
  '$1M-5M',
  '["ROI quantification", "Executive communication", "Value proposition clarity"]',
  '["Technical understanding", "Market analysis", "Product positioning"]',
  '["Practice stakeholder presentations", "Develop ROI frameworks", "Study buyer psychology"]'
),
(
  'dru78DR9789SDF862',
  '2024-08-25 14:30:00+00',
  72.0,
  65.8,
  58.5,
  65.4,
  1850,
  'Systematic Buyer Understanding',
  'progress',
  74.5,
  63.2,
  68.0,
  58.0,
  'Enterprise SaaS',
  'Series A', 
  '$1M-5M',
  '["Advanced ROI modeling", "C-suite communication", "Deal closure techniques"]',
  '["Systematic analysis", "Technical translation", "Buyer research"]',
  '["Master financial modeling", "Practice executive presentations", "Develop proposal templates"]'
) ON CONFLICT ON CONSTRAINT assessment_results_pkey DO NOTHING;

-- Insert sample customer actions
INSERT INTO customer_actions (
  customer_id,
  action_type,
  action_description,
  impact_level,
  points_awarded,
  base_points,
  impact_multiplier,
  category,
  stakeholder_level,
  action_date,
  duration_minutes,
  outcome_achieved,
  outcome_description,
  verified,
  skills_demonstrated,
  deal_size_range
) VALUES 
(
  'dru78DR9789SDF862',
  'customer_meeting',
  'Discovery call with Enterprise AI prospect - 45min technical architecture discussion',
  'high',
  200,
  100,
  2.0,
  'customerAnalysis',
  'Executive', 
  '2024-08-27 14:30:00+00',
  45,
  true,
  'Identified 3 key technical integration requirements and budget authority',
  true,
  '["buyer_research", "technical_translation", "stakeholder_mapping"]',
  '$250K+'
),
(
  'dru78DR9789SDF862', 
  'roi_presentation',
  'ROI analysis presentation to CFO - demonstrated 35% cost reduction potential',
  'critical',
  600,
  200,
  3.0,
  'valueCommunication',
  'Executive',
  '2024-08-26 16:00:00+00',
  60,
  true,
  'CFO approved budget allocation for pilot program',
  true,
  '["value_quantification", "financial_modeling", "executive_communication"]',
  '$250K+'
),
(
  'dru78DR9789SDF862',
  'customer_meeting',
  'Discovery call with TechCorp - identified 3 key pain points and budget authority',
  'medium',
  150,
  100,
  1.5,
  'customerAnalysis',
  'Manager',
  '2024-08-22 15:00:00+00',
  45,
  true,
  'Qualified as high-potential prospect with $50K budget',
  true,
  '["buyer_research", "pain_point_identification", "budget_qualification"]',
  '$50K-250K'
),
(
  'dru78DR9789SDF862',
  'value_proposition_delivery',
  'Technical demo with focus on business value - 30min presentation to CTO and COO',
  'high',
  300,
  150,
  2.0,
  'valueCommunication',
  'Executive',
  '2024-08-24 11:00:00+00',
  30,
  true,
  'Secured agreement for pilot program discussion',
  true,
  '["technical_translation", "stakeholder_alignment", "value_communication"]',
  '$50K-250K'
) ON CONFLICT ON CONSTRAINT customer_actions_pkey DO NOTHING;
;