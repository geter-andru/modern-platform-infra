-- Create assessment_results table for competency tracking and professional development
-- This table stores all assessment history and competency progression data

CREATE TABLE assessment_results (
  -- Primary Fields
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id TEXT NOT NULL,
  assessment_date TIMESTAMPTZ DEFAULT NOW(),
  
  -- Assessment Scores (0-100 scale)
  customer_analysis_score NUMERIC(5,2), -- e.g., 67.50
  value_communication_score NUMERIC(5,2), -- e.g., 72.25  
  sales_execution_score NUMERIC(5,2), -- e.g., 58.75
  overall_score NUMERIC(5,2), -- Calculated average
  
  -- Professional Development Tracking
  total_progress_points INTEGER DEFAULT 0,
  competency_level TEXT,
  previous_level TEXT,
  
  -- Assessment Metadata
  assessment_type TEXT CHECK (assessment_type IN ('baseline', 'progress', 'retake', 'milestone')) DEFAULT 'progress',
  assessment_version TEXT DEFAULT 'v1.0',
  
  -- Performance Analysis
  improvement_areas JSONB, -- Areas needing development
  strength_areas JSONB, -- Areas of excellence
  recommended_actions JSONB, -- Next steps and recommendations
  
  -- Competency Details
  buyer_understanding_score NUMERIC(5,2),
  tech_to_value_translation_score NUMERIC(5,2),
  stakeholder_communication_score NUMERIC(5,2),
  roi_presentation_score NUMERIC(5,2),
  
  -- Professional Context
  industry_focus TEXT,
  company_stage TEXT, -- 'Pre-Seed', 'Seed', 'Series A', 'Series B+'
  revenue_range TEXT, -- '$0-1M', '$1M-5M', '$5M-10M', '$10M+'
  
  -- Session Data
  assessment_duration INTEGER, -- Minutes spent on assessment
  completion_percentage NUMERIC(5,2), -- Percentage completed if partial
  
  -- Notes and Context
  notes TEXT,
  assessor_notes TEXT, -- For admin/coach notes
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX idx_assessment_results_customer_id ON assessment_results(customer_id);
CREATE INDEX idx_assessment_results_assessment_date ON assessment_results(assessment_date);
CREATE INDEX idx_assessment_results_assessment_type ON assessment_results(assessment_type);
CREATE INDEX idx_assessment_results_competency_level ON assessment_results(competency_level);
CREATE INDEX idx_assessment_results_overall_score ON assessment_results(overall_score);

-- Foreign key constraint to customer_assets
ALTER TABLE assessment_results 
ADD CONSTRAINT fk_assessment_customer 
FOREIGN KEY (customer_id) REFERENCES customer_assets(customer_id) ON DELETE CASCADE;

-- Create trigger to automatically update updated_at timestamp
CREATE TRIGGER update_assessment_results_updated_at 
    BEFORE UPDATE ON assessment_results 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Enable Row Level Security
ALTER TABLE assessment_results ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can only access their own assessment data
CREATE POLICY assessment_results_policy ON assessment_results
    FOR ALL USING (
        customer_id = auth.jwt() ->> 'sub' OR 
        customer_id IN (
            SELECT customer_id FROM customer_assets 
            WHERE access_token = auth.jwt() ->> 'sub'
        )
    );

-- Insert sample assessment data for admin user
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
);