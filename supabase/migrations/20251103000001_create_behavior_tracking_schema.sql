-- ==============================================
-- PHASE 3.1: Comprehensive Behavior Tracking System
-- ==============================================
-- Digital platform interaction tracking for systematic scaling intelligence
-- Complements customer_actions (offline) with digital behavior analytics

-- ----------------------------------------------
-- 1. Behavior Events Table
-- ----------------------------------------------
CREATE TABLE IF NOT EXISTS behavior_events (
  -- Primary Fields
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id TEXT NOT NULL,
  session_id TEXT NOT NULL,

  -- Event Classification
  event_type TEXT NOT NULL CHECK (event_type IN (
    'tool_usage',              -- ICP, Cost Calculator, Business Case usage
    'export_action',           -- PDF, CSV, email export actions
    'competency_milestone',    -- Leveling up, achievements
    'scaling_metric',          -- ARR updates, growth metrics
    'professional_action',     -- High-value systematic actions
    'navigation',              -- Page/tool navigation
    'content_interaction',     -- Reading, expanding sections
    'resource_generation',     -- AI content generation
    'resource_share',          -- Sharing outputs with stakeholders
    'systematic_progression'   -- Systematic scaling advancement
  )),

  -- Tool-Specific Context
  tool_id TEXT,  -- 'icp-analysis', 'cost-calculator', 'business-case', 'resources'
  tool_section TEXT,  -- Which part of the tool was used

  -- Scaling Context (mirrors BehavioralEvent interface)
  current_arr TEXT,  -- e.g. "$2.5M"
  target_arr TEXT,   -- e.g. "$10M"
  growth_stage TEXT CHECK (growth_stage IN ('early_scaling', 'rapid_scaling', 'mature_scaling')),
  systematic_approach BOOLEAN DEFAULT TRUE,

  -- Business Impact Assessment
  business_impact TEXT CHECK (business_impact IN ('low', 'medium', 'high')) NOT NULL,
  professional_credibility INTEGER CHECK (professional_credibility BETWEEN 0 AND 100),
  competency_area TEXT CHECK (competency_area IN (
    'customer_intelligence',
    'value_communication',
    'sales_execution',
    'systematic_optimization'
  )),

  -- Event Metadata
  event_metadata JSONB,  -- Flexible JSON for tool-specific data
  user_agent TEXT,
  ip_address INET,

  -- Timing & Duration
  event_timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  session_duration INTEGER,  -- Milliseconds in current session
  time_on_page INTEGER,      -- Milliseconds on current page

  -- Outcome Tracking
  action_completed BOOLEAN DEFAULT FALSE,
  action_outcome TEXT,  -- What was the result
  follow_up_scheduled BOOLEAN DEFAULT FALSE,

  -- Privacy Controls
  anonymized BOOLEAN DEFAULT FALSE,
  retention_days INTEGER DEFAULT 365,  -- Data retention period
  deleted_at TIMESTAMPTZ,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for Performance
CREATE INDEX idx_behavior_events_customer_id ON behavior_events(customer_id);
CREATE INDEX idx_behavior_events_session_id ON behavior_events(session_id);
CREATE INDEX idx_behavior_events_event_type ON behavior_events(event_type);
CREATE INDEX idx_behavior_events_tool_id ON behavior_events(tool_id);
CREATE INDEX idx_behavior_events_business_impact ON behavior_events(business_impact);
CREATE INDEX idx_behavior_events_competency_area ON behavior_events(competency_area);
CREATE INDEX idx_behavior_events_timestamp ON behavior_events(event_timestamp DESC);
CREATE INDEX idx_behavior_events_growth_stage ON behavior_events(growth_stage);
CREATE INDEX idx_behavior_events_customer_timestamp ON behavior_events(customer_id, event_timestamp DESC);

-- ----------------------------------------------
-- 2. Behavior Insights Table (Aggregated Analytics)
-- ----------------------------------------------
CREATE TABLE IF NOT EXISTS behavior_insights (
  -- Primary Fields
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id TEXT NOT NULL UNIQUE,

  -- Overall Scaling Metrics
  current_scaling_score INTEGER DEFAULT 75 CHECK (current_scaling_score BETWEEN 0 AND 100),
  systematic_progression_rate NUMERIC(3,2) DEFAULT 1.0,
  professional_credibility_trend TEXT CHECK (professional_credibility_trend IN ('improving', 'stable', 'declining')) DEFAULT 'improving',

  -- Competency Milestones (matches BehavioralIntelligence interface)
  customer_intelligence_score INTEGER DEFAULT 60,
  value_communication_score INTEGER DEFAULT 55,
  sales_execution_score INTEGER DEFAULT 45,
  systematic_optimization_score INTEGER DEFAULT 40,

  -- Scaling Velocity Metrics
  weekly_progress_points INTEGER DEFAULT 8,
  monthly_milestones_completed INTEGER DEFAULT 3,
  quarterly_targets_achieved INTEGER DEFAULT 2,

  -- Risk Factors
  inconsistent_system_usage BOOLEAN DEFAULT FALSE,
  low_business_impact_actions BOOLEAN DEFAULT FALSE,
  professional_credibility_drift BOOLEAN DEFAULT FALSE,

  -- Tool Usage Statistics
  total_tool_sessions INTEGER DEFAULT 0,
  total_exports_generated INTEGER DEFAULT 0,
  total_resources_created INTEGER DEFAULT 0,
  total_time_spent_minutes INTEGER DEFAULT 0,

  -- Last Activity
  last_session_timestamp TIMESTAMPTZ,
  last_tool_used TEXT,
  days_since_last_activity INTEGER,

  -- Recommendations (JSONB array)
  next_systematic_actions JSONB DEFAULT '[]'::jsonb,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Foreign Key
  CONSTRAINT fk_insights_customer FOREIGN KEY (customer_id)
    REFERENCES customer_assets(customer_id) ON DELETE CASCADE
);

-- Indexes
CREATE INDEX idx_behavior_insights_customer_id ON behavior_insights(customer_id);
CREATE INDEX idx_behavior_insights_scaling_score ON behavior_insights(current_scaling_score DESC);
CREATE INDEX idx_behavior_insights_last_activity ON behavior_insights(last_session_timestamp DESC);

-- ----------------------------------------------
-- 3. Session Summary Table
-- ----------------------------------------------
CREATE TABLE IF NOT EXISTS behavior_sessions (
  -- Primary Fields
  session_id TEXT PRIMARY KEY,
  customer_id TEXT NOT NULL,

  -- Session Metadata
  started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ended_at TIMESTAMPTZ,
  duration_seconds INTEGER,

  -- Tools Used in Session
  tools_accessed TEXT[],  -- Array of tool IDs
  primary_tool TEXT,      -- Main tool used

  -- Session Metrics
  events_count INTEGER DEFAULT 0,
  exports_generated INTEGER DEFAULT 0,
  competency_points_earned INTEGER DEFAULT 0,
  business_impact_level TEXT CHECK (business_impact_level IN ('low', 'medium', 'high')),

  -- Device & Context
  device_type TEXT,  -- 'desktop', 'tablet', 'mobile'
  browser TEXT,
  referrer_source TEXT,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Foreign Key
  CONSTRAINT fk_sessions_customer FOREIGN KEY (customer_id)
    REFERENCES customer_assets(customer_id) ON DELETE CASCADE
);

-- Indexes
CREATE INDEX idx_behavior_sessions_customer_id ON behavior_sessions(customer_id);
CREATE INDEX idx_behavior_sessions_started_at ON behavior_sessions(started_at DESC);
CREATE INDEX idx_behavior_sessions_primary_tool ON behavior_sessions(primary_tool);

-- ----------------------------------------------
-- 4. Update Triggers
-- ----------------------------------------------

-- Auto-update updated_at timestamps
CREATE TRIGGER update_behavior_events_updated_at
  BEFORE UPDATE ON behavior_events
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_behavior_insights_updated_at
  BEFORE UPDATE ON behavior_insights
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_behavior_sessions_updated_at
  BEFORE UPDATE ON behavior_sessions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ----------------------------------------------
-- 5. Row Level Security (RLS)
-- ----------------------------------------------

-- Enable RLS on all tables
ALTER TABLE behavior_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE behavior_insights ENABLE ROW LEVEL SECURITY;
ALTER TABLE behavior_sessions ENABLE ROW LEVEL SECURITY;

-- RLS Policies: Users can only access their own data
CREATE POLICY behavior_events_policy ON behavior_events
  FOR ALL USING (
    customer_id = auth.jwt() ->> 'sub' OR
    customer_id IN (
      SELECT customer_id FROM customer_assets
      WHERE access_token = auth.jwt() ->> 'sub'
    )
  );

CREATE POLICY behavior_insights_policy ON behavior_insights
  FOR ALL USING (
    customer_id = auth.jwt() ->> 'sub' OR
    customer_id IN (
      SELECT customer_id FROM customer_assets
      WHERE access_token = auth.jwt() ->> 'sub'
    )
  );

CREATE POLICY behavior_sessions_policy ON behavior_sessions
  FOR ALL USING (
    customer_id = auth.jwt() ->> 'sub' OR
    customer_id IN (
      SELECT customer_id FROM customer_assets
      WHERE access_token = auth.jwt() ->> 'sub'
    )
  );

-- ----------------------------------------------
-- 6. Data Retention Function
-- ----------------------------------------------

-- Function to automatically delete old behavior events based on retention_days
CREATE OR REPLACE FUNCTION cleanup_expired_behavior_events()
RETURNS void AS $$
BEGIN
  DELETE FROM behavior_events
  WHERE
    deleted_at IS NULL AND
    event_timestamp < NOW() - (retention_days || ' days')::INTERVAL;
END;
$$ LANGUAGE plpgsql;

-- Create a scheduled job (requires pg_cron extension)
-- This would be set up separately in Supabase dashboard
-- SELECT cron.schedule('cleanup-behavior-events', '0 2 * * *', 'SELECT cleanup_expired_behavior_events()');

-- ----------------------------------------------
-- 7. Helper Functions for Analytics
-- ----------------------------------------------

-- Function to update behavior insights when new event is tracked
CREATE OR REPLACE FUNCTION update_behavior_insights_on_event()
RETURNS TRIGGER AS $$
BEGIN
  -- Insert or update insights record
  INSERT INTO behavior_insights (
    customer_id,
    last_session_timestamp,
    last_tool_used,
    total_tool_sessions
  ) VALUES (
    NEW.customer_id,
    NEW.event_timestamp,
    NEW.tool_id,
    1
  )
  ON CONFLICT (customer_id) DO UPDATE SET
    last_session_timestamp = NEW.event_timestamp,
    last_tool_used = NEW.tool_id,
    total_tool_sessions = behavior_insights.total_tool_sessions + CASE WHEN NEW.event_type = 'tool_usage' THEN 1 ELSE 0 END,
    total_exports_generated = behavior_insights.total_exports_generated + CASE WHEN NEW.event_type = 'export_action' THEN 1 ELSE 0 END,
    total_resources_created = behavior_insights.total_resources_created + CASE WHEN NEW.event_type = 'resource_generation' THEN 1 ELSE 0 END,
    days_since_last_activity = 0,
    updated_at = NOW();

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-update insights
CREATE TRIGGER trigger_update_insights_on_event
  AFTER INSERT ON behavior_events
  FOR EACH ROW EXECUTE FUNCTION update_behavior_insights_on_event();

-- ----------------------------------------------
-- 8. Sample Data for Testing
-- ----------------------------------------------

-- Initialize insights for admin user
INSERT INTO behavior_insights (
  customer_id,
  current_scaling_score,
  systematic_progression_rate,
  professional_credibility_trend,
  customer_intelligence_score,
  value_communication_score,
  sales_execution_score,
  systematic_optimization_score,
  weekly_progress_points,
  monthly_milestones_completed,
  next_systematic_actions
) VALUES (
  'dru78DR9789SDF862',
  82,
  1.5,
  'improving',
  75,
  68,
  62,
  58,
  15,
  5,
  '[
    "Complete comprehensive ICP analysis session",
    "Export first professional stakeholder asset",
    "Track real-world scaling application metrics",
    "Advance to Level 3 in Customer Intelligence",
    "Generate systematic business case for executive review"
  ]'::jsonb
) ON CONFLICT (customer_id) DO NOTHING;

COMMENT ON TABLE behavior_events IS 'Tracks all digital platform interactions for systematic scaling intelligence';
COMMENT ON TABLE behavior_insights IS 'Aggregated analytics and insights derived from behavior events';
COMMENT ON TABLE behavior_sessions IS 'Session-level analytics for usage patterns and tool engagement';
