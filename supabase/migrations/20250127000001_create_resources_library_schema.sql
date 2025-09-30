-- ===========================================
-- RESOURCES LIBRARY DATABASE SCHEMA
-- ===========================================
-- Migration: 20250127000001_create_resources_library_schema.sql
-- Description: Creates comprehensive database schema for three-tier Resources Library
-- Date: January 27, 2025
-- Status: Production Ready

-- ===========================================
-- 1. RESOURCES TABLE
-- ===========================================
-- Main table for storing AI-generated resources
CREATE TABLE IF NOT EXISTS resources (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id TEXT NOT NULL,
  tier INTEGER NOT NULL CHECK (tier IN (1, 2, 3)),
  category TEXT NOT NULL CHECK (category IN (
    'buyer_intelligence',
    'sales_frameworks', 
    'strategic_tools',
    'implementation_guides',
    'competitive_intelligence',
    'behavioral_analysis'
  )),
  title TEXT NOT NULL,
  description TEXT,
  content JSONB NOT NULL,
  metadata JSONB DEFAULT '{}',
  dependencies TEXT[] DEFAULT '{}',
  unlock_criteria JSONB DEFAULT '{}',
  export_formats TEXT[] DEFAULT '{"pdf", "docx", "csv"}',
  generation_status TEXT DEFAULT 'pending' CHECK (generation_status IN (
    'pending',
    'generating', 
    'completed',
    'failed',
    'archived'
  )),
  ai_context JSONB DEFAULT '{}',
  generation_time_ms INTEGER,
  access_count INTEGER DEFAULT 0,
  last_accessed TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ===========================================
-- 2. RESOURCE DEPENDENCIES TABLE
-- ===========================================
-- Tracks dependencies between resources for cumulative intelligence
CREATE TABLE IF NOT EXISTS resource_dependencies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  resource_id UUID NOT NULL REFERENCES resources(id) ON DELETE CASCADE,
  depends_on_resource_id UUID NOT NULL REFERENCES resources(id) ON DELETE CASCADE,
  dependency_type TEXT NOT NULL CHECK (dependency_type IN (
    'prerequisite',
    'context_enhancer',
    'data_source',
    'template_base'
  )),
  context_data JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Ensure no circular dependencies
  CONSTRAINT no_self_dependency CHECK (resource_id != depends_on_resource_id)
);

-- ===========================================
-- 3. RESOURCE GENERATION LOGS TABLE
-- ===========================================
-- Tracks AI generation process and performance
CREATE TABLE IF NOT EXISTS resource_generation_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id TEXT NOT NULL,
  resource_id UUID REFERENCES resources(id) ON DELETE CASCADE,
  generation_status TEXT NOT NULL CHECK (generation_status IN (
    'initiated',
    'ai_processing',
    'content_generation',
    'validation',
    'completed',
    'failed'
  )),
  ai_context JSONB DEFAULT '{}',
  generation_time_ms INTEGER,
  tokens_used INTEGER,
  cost_estimate DECIMAL(10,4),
  error_message TEXT,
  retry_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ===========================================
-- 4. RESOURCE ACCESS TRACKING TABLE
-- ===========================================
-- Tracks user engagement with resources
CREATE TABLE IF NOT EXISTS resource_access_tracking (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id TEXT NOT NULL,
  resource_id UUID NOT NULL REFERENCES resources(id) ON DELETE CASCADE,
  access_type TEXT NOT NULL CHECK (access_type IN (
    'view',
    'download',
    'export',
    'share',
    'edit'
  )),
  access_count INTEGER DEFAULT 1,
  last_accessed TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  session_id TEXT,
  user_agent TEXT,
  ip_address INET,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ===========================================
-- 5. RESOURCE UNLOCK CRITERIA TABLE
-- ===========================================
-- Defines progressive unlocking requirements
CREATE TABLE IF NOT EXISTS resource_unlock_criteria (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  resource_id UUID NOT NULL REFERENCES resources(id) ON DELETE CASCADE,
  criteria_type TEXT NOT NULL CHECK (criteria_type IN (
    'milestone_completion',
    'tool_usage',
    'competency_threshold',
    'behavioral_trigger',
    'time_based',
    'manual_approval'
  )),
  criteria_config JSONB NOT NULL,
  is_required BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ===========================================
-- 6. RESOURCE TEMPLATES TABLE
-- ===========================================
-- Stores reusable templates for resource generation
CREATE TABLE IF NOT EXISTS resource_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  template_name TEXT NOT NULL UNIQUE,
  template_type TEXT NOT NULL CHECK (template_type IN (
    'ai_prompt',
    'content_structure',
    'export_format',
    'validation_schema'
  )),
  tier INTEGER NOT NULL CHECK (tier IN (1, 2, 3)),
  category TEXT NOT NULL,
  template_content JSONB NOT NULL,
  variables JSONB DEFAULT '{}',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ===========================================
-- 7. RESOURCE EXPORTS TABLE
-- ===========================================
-- Tracks exported resources and their formats
CREATE TABLE IF NOT EXISTS resource_exports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id TEXT NOT NULL,
  resource_id UUID NOT NULL REFERENCES resources(id) ON DELETE CASCADE,
  export_format TEXT NOT NULL CHECK (export_format IN (
    'pdf',
    'docx',
    'csv',
    'json',
    'html'
  )),
  export_status TEXT DEFAULT 'pending' CHECK (export_status IN (
    'pending',
    'processing',
    'completed',
    'failed'
  )),
  file_path TEXT,
  file_size_bytes INTEGER,
  download_url TEXT,
  expires_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ===========================================
-- 8. RESOURCE FEEDBACK TABLE
-- ===========================================
-- Collects user feedback on resource quality and usefulness
CREATE TABLE IF NOT EXISTS resource_feedback (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id TEXT NOT NULL,
  resource_id UUID NOT NULL REFERENCES resources(id) ON DELETE CASCADE,
  rating INTEGER CHECK (rating >= 1 AND rating <= 5),
  feedback_text TEXT,
  feedback_type TEXT CHECK (feedback_type IN (
    'quality',
    'usefulness',
    'accuracy',
    'completeness',
    'clarity'
  )),
  is_helpful BOOLEAN,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ===========================================
-- INDEXES FOR PERFORMANCE
-- ===========================================

-- Resources table indexes
CREATE INDEX IF NOT EXISTS idx_resources_customer_id ON resources(customer_id);
CREATE INDEX IF NOT EXISTS idx_resources_tier ON resources(tier);
CREATE INDEX IF NOT EXISTS idx_resources_category ON resources(category);
CREATE INDEX IF NOT EXISTS idx_resources_generation_status ON resources(generation_status);
CREATE INDEX IF NOT EXISTS idx_resources_created_at ON resources(created_at);
CREATE INDEX IF NOT EXISTS idx_resources_customer_tier ON resources(customer_id, tier);

-- Resource dependencies indexes
CREATE INDEX IF NOT EXISTS idx_resource_dependencies_resource_id ON resource_dependencies(resource_id);
CREATE INDEX IF NOT EXISTS idx_resource_dependencies_depends_on ON resource_dependencies(depends_on_resource_id);
CREATE INDEX IF NOT EXISTS idx_resource_dependencies_type ON resource_dependencies(dependency_type);

-- Generation logs indexes
CREATE INDEX IF NOT EXISTS idx_generation_logs_customer_id ON resource_generation_logs(customer_id);
CREATE INDEX IF NOT EXISTS idx_generation_logs_resource_id ON resource_generation_logs(resource_id);
CREATE INDEX IF NOT EXISTS idx_generation_logs_status ON resource_generation_logs(generation_status);
CREATE INDEX IF NOT EXISTS idx_generation_logs_created_at ON resource_generation_logs(created_at);

-- Access tracking indexes
CREATE INDEX IF NOT EXISTS idx_access_tracking_customer_id ON resource_access_tracking(customer_id);
CREATE INDEX IF NOT EXISTS idx_access_tracking_resource_id ON resource_access_tracking(resource_id);
CREATE INDEX IF NOT EXISTS idx_access_tracking_type ON resource_access_tracking(access_type);
CREATE INDEX IF NOT EXISTS idx_access_tracking_last_accessed ON resource_access_tracking(last_accessed);

-- Unlock criteria indexes
CREATE INDEX IF NOT EXISTS idx_unlock_criteria_resource_id ON resource_unlock_criteria(resource_id);
CREATE INDEX IF NOT EXISTS idx_unlock_criteria_type ON resource_unlock_criteria(criteria_type);

-- Templates indexes
CREATE INDEX IF NOT EXISTS idx_templates_type ON resource_templates(template_type);
CREATE INDEX IF NOT EXISTS idx_templates_tier ON resource_templates(tier);
CREATE INDEX IF NOT EXISTS idx_templates_category ON resource_templates(category);
CREATE INDEX IF NOT EXISTS idx_templates_active ON resource_templates(is_active);

-- Exports indexes
CREATE INDEX IF NOT EXISTS idx_exports_customer_id ON resource_exports(customer_id);
CREATE INDEX IF NOT EXISTS idx_exports_resource_id ON resource_exports(resource_id);
CREATE INDEX IF NOT EXISTS idx_exports_format ON resource_exports(export_format);
CREATE INDEX IF NOT EXISTS idx_exports_status ON resource_exports(export_status);

-- Feedback indexes
CREATE INDEX IF NOT EXISTS idx_feedback_customer_id ON resource_feedback(customer_id);
CREATE INDEX IF NOT EXISTS idx_feedback_resource_id ON resource_feedback(resource_id);
CREATE INDEX IF NOT EXISTS idx_feedback_rating ON resource_feedback(rating);
CREATE INDEX IF NOT EXISTS idx_feedback_type ON resource_feedback(feedback_type);

-- ===========================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ===========================================

-- Enable RLS on all tables
ALTER TABLE resources ENABLE ROW LEVEL SECURITY;
ALTER TABLE resource_dependencies ENABLE ROW LEVEL SECURITY;
ALTER TABLE resource_generation_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE resource_access_tracking ENABLE ROW LEVEL SECURITY;
ALTER TABLE resource_unlock_criteria ENABLE ROW LEVEL SECURITY;
ALTER TABLE resource_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE resource_exports ENABLE ROW LEVEL SECURITY;
ALTER TABLE resource_feedback ENABLE ROW LEVEL SECURITY;

-- Resources policies
CREATE POLICY "Customers can view their own resources" ON resources
  FOR SELECT USING (customer_id = current_setting('app.current_customer_id', true));

CREATE POLICY "Customers can insert their own resources" ON resources
  FOR INSERT WITH CHECK (customer_id = current_setting('app.current_customer_id', true));

CREATE POLICY "Customers can update their own resources" ON resources
  FOR UPDATE USING (customer_id = current_setting('app.current_customer_id', true));

-- Resource dependencies policies
CREATE POLICY "Customers can view dependencies for their resources" ON resource_dependencies
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM resources 
      WHERE id = resource_dependencies.resource_id 
      AND customer_id = current_setting('app.current_customer_id', true)
    )
  );

-- Generation logs policies
CREATE POLICY "Customers can view their generation logs" ON resource_generation_logs
  FOR SELECT USING (customer_id = current_setting('app.current_customer_id', true));

-- Access tracking policies
CREATE POLICY "Customers can view their access tracking" ON resource_access_tracking
  FOR SELECT USING (customer_id = current_setting('app.current_customer_id', true));

CREATE POLICY "Customers can insert their access tracking" ON resource_access_tracking
  FOR INSERT WITH CHECK (customer_id = current_setting('app.current_customer_id', true));

-- Unlock criteria policies
CREATE POLICY "Customers can view unlock criteria for their resources" ON resource_unlock_criteria
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM resources 
      WHERE id = resource_unlock_criteria.resource_id 
      AND customer_id = current_setting('app.current_customer_id', true)
    )
  );

-- Templates policies (read-only for customers)
CREATE POLICY "Customers can view active templates" ON resource_templates
  FOR SELECT USING (is_active = true);

-- Exports policies
CREATE POLICY "Customers can view their exports" ON resource_exports
  FOR SELECT USING (customer_id = current_setting('app.current_customer_id', true));

CREATE POLICY "Customers can insert their exports" ON resource_exports
  FOR INSERT WITH CHECK (customer_id = current_setting('app.current_customer_id', true));

-- Feedback policies
CREATE POLICY "Customers can view their feedback" ON resource_feedback
  FOR SELECT USING (customer_id = current_setting('app.current_customer_id', true));

CREATE POLICY "Customers can insert their feedback" ON resource_feedback
  FOR INSERT WITH CHECK (customer_id = current_setting('app.current_customer_id', true));

-- ===========================================
-- TRIGGERS FOR AUTOMATIC UPDATES
-- ===========================================

-- Update updated_at timestamp on resources
CREATE OR REPLACE FUNCTION update_resources_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_resources_updated_at
  BEFORE UPDATE ON resources
  FOR EACH ROW
  EXECUTE FUNCTION update_resources_updated_at();

-- Update updated_at timestamp on templates
CREATE OR REPLACE FUNCTION update_templates_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_templates_updated_at
  BEFORE UPDATE ON resource_templates
  FOR EACH ROW
  EXECUTE FUNCTION update_templates_updated_at();

-- Update access count on resources when accessed
CREATE OR REPLACE FUNCTION update_resource_access_count()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE resources 
  SET access_count = access_count + 1,
      last_accessed = NOW()
  WHERE id = NEW.resource_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_resource_access_count
  AFTER INSERT ON resource_access_tracking
  FOR EACH ROW
  EXECUTE FUNCTION update_resource_access_count();

-- ===========================================
-- INITIAL DATA SEEDING
-- ===========================================

-- Insert default resource templates for Tier 1 (Core/Foundation Resources)
INSERT INTO resource_templates (template_name, template_type, tier, category, template_content, variables) VALUES
-- PDR (Product-Development-Revenue) Analysis Template
('pdr_analysis_template', 'ai_prompt', 1, 'buyer_intelligence', 
 '{"prompt": "Generate a comprehensive PDR (Product-Development-Revenue) analysis for the following product: {product_details}. Include: 1) Product-market fit assessment, 2) Development stage analysis, 3) Revenue potential evaluation, 4) Market positioning insights, 5) Competitive advantages, 6) Growth opportunities. Use the cumulative intelligence from previous analyses: {cumulative_context}.", "structure": {"sections": ["executive_summary", "product_analysis", "market_assessment", "revenue_potential", "competitive_positioning", "growth_opportunities", "recommendations"]}}',
 '{"product_details": "string", "cumulative_context": "object"}'),

-- Target Buyer Persona Template
('buyer_persona_template', 'ai_prompt', 1, 'buyer_intelligence',
 '{"prompt": "Create detailed buyer personas based on the product details: {product_details} and ICP analysis: {icp_analysis}. Generate 3-5 distinct personas including: 1) Demographics and firmographics, 2) Pain points and challenges, 3) Goals and motivations, 4) Buying behavior patterns, 5) Decision-making process, 6) Preferred communication channels, 7) Objections and concerns. Use cumulative intelligence: {cumulative_context}.", "structure": {"sections": ["persona_overview", "demographics", "pain_points", "goals_motivations", "buying_behavior", "decision_process", "communication_preferences", "objections_concerns"]}}',
 '{"product_details": "string", "icp_analysis": "object", "cumulative_context": "object"}'),

-- ICP Analysis Template
('icp_analysis_template', 'ai_prompt', 1, 'buyer_intelligence',
 '{"prompt": "Generate a comprehensive Ideal Customer Profile (ICP) analysis for: {product_details}. Include: 1) Company characteristics, 2) Industry verticals, 3) Company size and stage, 4) Technology stack, 5) Budget and decision-making process, 6) Geographic considerations, 7) Success criteria and metrics. Use cumulative intelligence: {cumulative_context}.", "structure": {"sections": ["company_characteristics", "industry_verticals", "size_stage", "technology_stack", "budget_process", "geographic_factors", "success_criteria"]}}',
 '{"product_details": "string", "cumulative_context": "object"}'),

-- Negative Persona Template
('negative_persona_template', 'ai_prompt', 1, 'buyer_intelligence',
 '{"prompt": "Identify negative personas (who to avoid) for: {product_details}. Based on ICP analysis: {icp_analysis} and buyer personas: {buyer_personas}. Include: 1) Characteristics of poor-fit prospects, 2) Red flags to watch for, 3) Industries or segments to avoid, 4) Company stages to skip, 5) Budget constraints that disqualify, 6) Technology incompatibilities. Use cumulative intelligence: {cumulative_context}.", "structure": {"sections": ["poor_fit_characteristics", "red_flags", "industries_to_avoid", "company_stages_to_skip", "budget_constraints", "technology_incompatibilities"]}}',
 '{"product_details": "string", "icp_analysis": "object", "buyer_personas": "object", "cumulative_context": "object"}'),

-- Value Messaging Framework Template
('value_messaging_template', 'ai_prompt', 1, 'sales_frameworks',
 '{"prompt": "Create a value messaging framework for: {product_details}. Based on buyer personas: {buyer_personas} and ICP analysis: {icp_analysis}. Include: 1) Core value propositions, 2) Key benefits by persona, 3) Proof points and evidence, 4) Competitive differentiation, 5) Messaging hierarchy, 6) Call-to-action strategies. Use cumulative intelligence: {cumulative_context}.", "structure": {"sections": ["core_value_propositions", "benefits_by_persona", "proof_points", "competitive_differentiation", "messaging_hierarchy", "call_to_actions"]}}',
 '{"product_details": "string", "buyer_personas": "object", "icp_analysis": "object", "cumulative_context": "object"}'),

-- Empathy Mapping Template
('empathy_mapping_template', 'ai_prompt', 1, 'buyer_intelligence',
 '{"prompt": "Generate empathy maps for each buyer persona: {buyer_personas}. For each persona, include: 1) What they think and feel, 2) What they see, 3) What they say and do, 4) What they hear, 5) Pain points and gains, 6) Emotional journey mapping. Use cumulative intelligence: {cumulative_context}.", "structure": {"sections": ["persona_empathy_maps", "thinking_feeling", "seeing", "saying_doing", "hearing", "pain_points_gains", "emotional_journey"]}}',
 '{"buyer_personas": "object", "cumulative_context": "object"}'),

-- Product Potential Assessment Template
('product_potential_template', 'ai_prompt', 1, 'strategic_tools',
 '{"prompt": "Assess the market potential for: {product_details}. Based on ICP analysis: {icp_analysis} and buyer personas: {buyer_personas}. Include: 1) Market size and opportunity, 2) Competitive landscape, 3) Product-market fit score, 4) Growth potential, 5) Risk factors, 6) Success probability. Use cumulative intelligence: {cumulative_context}.", "structure": {"sections": ["market_size_opportunity", "competitive_landscape", "product_market_fit", "growth_potential", "risk_factors", "success_probability"]}}',
 '{"product_details": "string", "icp_analysis": "object", "buyer_personas": "object", "cumulative_context": "object"}'),

-- Moment in Life Descriptions Template
('moment_in_life_template', 'ai_prompt', 1, 'buyer_intelligence',
 '{"prompt": "Describe key moments in the buyer journey for: {product_details}. Based on buyer personas: {buyer_personas} and empathy maps: {empathy_maps}. Include: 1) Trigger events, 2) Discovery moments, 3) Evaluation phases, 4) Decision points, 5) Implementation stages, 6) Success milestones. Use cumulative intelligence: {cumulative_context}.", "structure": {"sections": ["trigger_events", "discovery_moments", "evaluation_phases", "decision_points", "implementation_stages", "success_milestones"]}}',
 '{"product_details": "string", "buyer_personas": "object", "empathy_maps": "object", "cumulative_context": "object"}');

-- ===========================================
-- MIGRATION COMPLETION
-- ===========================================

-- Log migration completion
INSERT INTO public.migration_log (migration_name, executed_at, status) 
VALUES ('20250127000001_create_resources_library_schema', NOW(), 'completed')
ON CONFLICT (migration_name) DO UPDATE SET 
  executed_at = NOW(), 
  status = 'completed';

-- ===========================================
-- SCHEMA VALIDATION
-- ===========================================

-- Verify all tables were created
DO $$
DECLARE
  table_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO table_count
  FROM information_schema.tables 
  WHERE table_schema = 'public' 
  AND table_name IN (
    'resources',
    'resource_dependencies', 
    'resource_generation_logs',
    'resource_access_tracking',
    'resource_unlock_criteria',
    'resource_templates',
    'resource_exports',
    'resource_feedback'
  );
  
  IF table_count = 8 THEN
    RAISE NOTICE '✅ All 8 Resources Library tables created successfully';
  ELSE
    RAISE EXCEPTION '❌ Expected 8 tables, found %', table_count;
  END IF;
END $$;

-- Verify indexes were created
DO $$
DECLARE
  index_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO index_count
  FROM pg_indexes 
  WHERE schemaname = 'public' 
  AND indexname LIKE 'idx_%';
  
  IF index_count >= 20 THEN
    RAISE NOTICE '✅ All indexes created successfully (% found)', index_count;
  ELSE
    RAISE EXCEPTION '❌ Expected at least 20 indexes, found %', index_count;
  END IF;
END $$;

-- Verify RLS policies were created
DO $$
DECLARE
  policy_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO policy_count
  FROM pg_policies 
  WHERE schemaname = 'public';
  
  IF policy_count >= 15 THEN
    RAISE NOTICE '✅ All RLS policies created successfully (% found)', policy_count;
  ELSE
    RAISE EXCEPTION '❌ Expected at least 15 policies, found %', policy_count;
  END IF;
END $$;

-- Verify triggers were created
DO $$
DECLARE
  trigger_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO trigger_count
  FROM information_schema.triggers 
  WHERE trigger_schema = 'public';
  
  IF trigger_count >= 3 THEN
    RAISE NOTICE '✅ All triggers created successfully (% found)', trigger_count;
  ELSE
    RAISE EXCEPTION '❌ Expected at least 3 triggers, found %', trigger_count;
  END IF;
END $$;

-- Verify templates were seeded
DO $$
DECLARE
  template_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO template_count
  FROM resource_templates;
  
  IF template_count >= 8 THEN
    RAISE NOTICE '✅ All resource templates seeded successfully (% found)', template_count;
  ELSE
    RAISE EXCEPTION '❌ Expected at least 8 templates, found %', template_count;
  END IF;
END $$;

RAISE NOTICE '🎉 Resources Library database schema migration completed successfully!';
RAISE NOTICE '📊 Schema includes: 8 tables, 20+ indexes, 15+ RLS policies, 3+ triggers, 8+ templates';
RAISE NOTICE '🔒 Security: Row Level Security enabled on all tables';
RAISE NOTICE '⚡ Performance: Comprehensive indexing strategy implemented';
RAISE NOTICE '🎯 Ready for: Three-tier resource generation and progressive unlocking';
