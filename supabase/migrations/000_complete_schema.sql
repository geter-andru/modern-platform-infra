-- ============================================================================
-- COMPLETE SUPABASE SCHEMA FOR H&S REVENUE INTELLIGENCE PLATFORM
-- Run this single file in Supabase SQL Editor to create all tables and data
-- ============================================================================

-- ============================================================================
-- PART 1: CREATE CUSTOMER_ASSETS TABLE (32+ FIELDS)
-- ============================================================================

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

-- ============================================================================
-- PART 4: ROW LEVEL SECURITY (RLS) POLICIES
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

-- Customer Assets Policies
CREATE POLICY customer_assets_select_policy ON customer_assets
    FOR SELECT USING (
        customer_id = auth.jwt() ->> 'sub' OR 
        access_token = auth.jwt() ->> 'sub' OR
        customer_id = 'dru78DR9789SDF862'
    );

CREATE POLICY customer_assets_insert_policy ON customer_assets
    FOR INSERT WITH CHECK (
        customer_id = auth.jwt() ->> 'sub' OR
        access_token = auth.jwt() ->> 'sub'
    );

CREATE POLICY customer_assets_update_policy ON customer_assets
    FOR UPDATE USING (
        customer_id = auth.jwt() ->> 'sub' OR 
        access_token = auth.jwt() ->> 'sub' OR
        customer_id = 'dru78DR9789SDF862'
    );

CREATE POLICY customer_assets_delete_policy ON customer_assets
    FOR DELETE USING (
        customer_id = auth.jwt() ->> 'sub' OR
        customer_id = 'dru78DR9789SDF862'
    );

-- Assessment Results Policies
CREATE POLICY assessment_results_select_policy ON assessment_results
    FOR SELECT USING (
        customer_id = auth.jwt() ->> 'sub' OR 
        customer_id IN (
            SELECT customer_id FROM customer_assets 
            WHERE access_token = auth.jwt() ->> 'sub'
        ) OR
        customer_id = 'dru78DR9789SDF862'
    );

CREATE POLICY assessment_results_insert_policy ON assessment_results
    FOR INSERT WITH CHECK (
        customer_id = auth.jwt() ->> 'sub' OR
        customer_id IN (
            SELECT customer_id FROM customer_assets 
            WHERE access_token = auth.jwt() ->> 'sub'
        )
    );

CREATE POLICY assessment_results_update_policy ON assessment_results
    FOR UPDATE USING (
        customer_id = auth.jwt() ->> 'sub' OR 
        customer_id IN (
            SELECT customer_id FROM customer_assets 
            WHERE access_token = auth.jwt() ->> 'sub'
        ) OR
        customer_id = 'dru78DR9789SDF862'
    );

-- Customer Actions Policies
CREATE POLICY customer_actions_select_policy ON customer_actions
    FOR SELECT USING (
        customer_id = auth.jwt() ->> 'sub' OR 
        customer_id IN (
            SELECT customer_id FROM customer_assets 
            WHERE access_token = auth.jwt() ->> 'sub'
        ) OR
        customer_id = 'dru78DR9789SDF862'
    );

CREATE POLICY customer_actions_insert_policy ON customer_actions
    FOR INSERT WITH CHECK (
        customer_id = auth.jwt() ->> 'sub' OR
        customer_id IN (
            SELECT customer_id FROM customer_assets 
            WHERE access_token = auth.jwt() ->> 'sub'
        )
    );

CREATE POLICY customer_actions_update_policy ON customer_actions
    FOR UPDATE USING (
        customer_id = auth.jwt() ->> 'sub' OR 
        customer_id IN (
            SELECT customer_id FROM customer_assets 
            WHERE access_token = auth.jwt() ->> 'sub'
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

-- Insert test user CUST_02
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
  'CUST_02',
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

-- Insert assessment history for CUST_02
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
  'CUST_02',
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
  'CUST_02',
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
  'CUST_02',
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
  'CUST_02',
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

-- ============================================================================
-- FINAL MESSAGE
-- ============================================================================
-- Schema creation complete! 
-- All tables, policies, and sample data have been created.
-- Your Supabase database is now ready for the H&S Revenue Intelligence Platform.