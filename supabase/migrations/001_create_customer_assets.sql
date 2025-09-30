-- Create customer_assets table with full Airtable parity (32+ fields)
-- This table stores all customer data, content, and professional development tracking

CREATE TABLE customer_assets (
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
CREATE INDEX idx_customer_assets_email ON customer_assets(email);
CREATE INDEX idx_customer_assets_access_token ON customer_assets(access_token);
CREATE INDEX idx_customer_assets_payment_status ON customer_assets(payment_status);
CREATE INDEX idx_customer_assets_last_accessed ON customer_assets(last_accessed);

-- Create trigger to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_customer_assets_updated_at 
    BEFORE UPDATE ON customer_assets 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Enable Row Level Security
ALTER TABLE customer_assets ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can only access their own data
CREATE POLICY customer_assets_policy ON customer_assets
    FOR ALL USING (auth.jwt() ->> 'sub' = customer_id OR auth.jwt() ->> 'sub' = access_token);

-- Insert sample admin user (dru78DR9789SDF862)
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
);