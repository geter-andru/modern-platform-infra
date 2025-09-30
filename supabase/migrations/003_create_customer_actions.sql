-- Create customer_actions table for gamification and professional activity tracking
-- This table stores real-world business activities with point tracking system

CREATE TABLE customer_actions (
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
  base_points INTEGER, -- Points before multipliers
  impact_multiplier NUMERIC(3,2) DEFAULT 1.0, -- 1.0x to 3.0x multiplier
  
  -- Categorization
  category TEXT CHECK (category IN ('customerAnalysis', 'valueCommunication', 'salesExecution')) NOT NULL,
  subcategory TEXT, -- More specific classification
  
  -- Professional Context
  deal_size_range TEXT, -- 'Under $10K', '$10K-50K', '$50K-250K', '$250K+'
  stakeholder_level TEXT, -- 'Individual Contributor', 'Manager', 'Director', 'Executive'
  industry_context TEXT,
  
  -- Evidence & Verification
  evidence_link TEXT, -- URL or file reference
  evidence_type TEXT, -- 'meeting_notes', 'email', 'proposal', 'recording', 'document'
  verified BOOLEAN DEFAULT FALSE,
  verified_by TEXT, -- Who verified the action
  verified_at TIMESTAMPTZ,
  
  -- Timing
  action_date TIMESTAMPTZ NOT NULL,
  duration_minutes INTEGER, -- How long the action took
  
  -- Outcome Tracking
  outcome_achieved BOOLEAN,
  outcome_description TEXT,
  follow_up_required BOOLEAN DEFAULT FALSE,
  follow_up_date TIMESTAMPTZ,
  
  -- Learning & Development
  skills_demonstrated JSONB, -- Which competencies this action developed
  lessons_learned TEXT,
  improvement_notes TEXT,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX idx_customer_actions_customer_id ON customer_actions(customer_id);
CREATE INDEX idx_customer_actions_action_type ON customer_actions(action_type);
CREATE INDEX idx_customer_actions_action_date ON customer_actions(action_date);
CREATE INDEX idx_customer_actions_category ON customer_actions(category);
CREATE INDEX idx_customer_actions_impact_level ON customer_actions(impact_level);
CREATE INDEX idx_customer_actions_points_awarded ON customer_actions(points_awarded);
CREATE INDEX idx_customer_actions_verified ON customer_actions(verified);

-- Foreign key constraint to customer_assets
ALTER TABLE customer_actions 
ADD CONSTRAINT fk_actions_customer 
FOREIGN KEY (customer_id) REFERENCES customer_assets(customer_id) ON DELETE CASCADE;

-- Create trigger to automatically update updated_at timestamp
CREATE TRIGGER update_customer_actions_updated_at 
    BEFORE UPDATE ON customer_actions 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Enable Row Level Security
ALTER TABLE customer_actions ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can only access their own action data
CREATE POLICY customer_actions_policy ON customer_actions
    FOR ALL USING (
        customer_id = auth.jwt() ->> 'sub' OR 
        customer_id IN (
            SELECT customer_id FROM customer_assets 
            WHERE access_token = auth.jwt() ->> 'sub'
        )
    );

-- Insert sample action data for admin user
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
  outcome_achieved,
  outcome_description,
  verified,
  skills_demonstrated
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
  true,
  'Identified 3 key technical integration requirements and budget authority',
  true,
  '["buyer_research", "technical_translation", "stakeholder_mapping"]'
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
  true,
  'CFO approved budget allocation for pilot program',
  true,
  '["value_quantification", "financial_modeling", "executive_communication"]'
);