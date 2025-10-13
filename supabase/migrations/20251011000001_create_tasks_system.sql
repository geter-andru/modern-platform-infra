-- Migration: Create Tasks System
-- Created: 2025-10-11
-- Purpose: Task library and completion tracking for Dashboard v2
-- Status: Recreated from live Supabase schema on 2025-10-13

-- ============================================================================
-- TABLE: tasks_library
-- ============================================================================
-- Master catalog of all available tasks for users
-- Tasks are mapped to competency areas and platform tools

CREATE TABLE IF NOT EXISTS tasks_library (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_code VARCHAR(100) UNIQUE NOT NULL,  -- Unique identifier (e.g., "define-icp")
    name VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(100),  -- Customer Discovery, ICP Development, etc.
    stage_milestone VARCHAR(50),  -- foundation-seed, growth-series-a, expansion-series-a
    priority VARCHAR(20) CHECK (priority IN ('critical', 'high', 'medium', 'low')),
    competency_area VARCHAR(50) CHECK (competency_area IN ('customerAnalysis', 'valueCommunication', 'executiveReadiness')),
    estimated_time VARCHAR(50),  -- "2-4 hours", "30 min", etc.
    business_impact TEXT,
    prerequisites TEXT,
    platform_connection JSONB,  -- {tool: 'icp', feature: 'icp-builder', description: '...'}
    resources JSONB DEFAULT '[]'::jsonb,  -- Array of related resource IDs
    source_table VARCHAR(20),  -- 'seed' or 'series-a'
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for common queries
CREATE INDEX IF NOT EXISTS idx_tasks_library_stage_milestone ON tasks_library(stage_milestone);
CREATE INDEX IF NOT EXISTS idx_tasks_library_competency_area ON tasks_library(competency_area);
CREATE INDEX IF NOT EXISTS idx_tasks_library_priority ON tasks_library(priority);
CREATE INDEX IF NOT EXISTS idx_tasks_library_is_active ON tasks_library(is_active);
CREATE INDEX IF NOT EXISTS idx_tasks_library_task_code ON tasks_library(task_code);

-- ============================================================================
-- TABLE: task_completions
-- ============================================================================
-- Tracks user task completions and competency gains

CREATE TABLE IF NOT EXISTS task_completions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    task_id UUID REFERENCES tasks_library(id) ON DELETE CASCADE,
    completed_at TIMESTAMPTZ DEFAULT NOW(),
    competency_gains JSONB DEFAULT '{}'::jsonb,  -- {customerAnalysis: 5, valueCommunication: 3}
    completion_data JSONB DEFAULT '{}'::jsonb,  -- {toolUsed: 'icp', notes: '...'}
    notes TEXT,

    -- Prevent duplicate completions
    UNIQUE(user_id, task_id)
);

-- Create indexes for user queries
CREATE INDEX IF NOT EXISTS idx_task_completions_user_id ON task_completions(user_id);
CREATE INDEX IF NOT EXISTS idx_task_completions_task_id ON task_completions(task_id);
CREATE INDEX IF NOT EXISTS idx_task_completions_completed_at ON task_completions(completed_at);

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Get all completed tasks for a user
CREATE OR REPLACE FUNCTION get_user_completed_tasks(p_user_id UUID)
RETURNS TABLE(
    task_code VARCHAR,
    task_name VARCHAR,
    completed_at TIMESTAMPTZ,
    competency_gains JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        tl.task_code,
        tl.name AS task_name,
        tc.completed_at,
        tc.competency_gains
    FROM task_completions tc
    JOIN tasks_library tl ON tc.task_id = tl.id
    WHERE tc.user_id = p_user_id
    ORDER BY tc.completed_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Get recommended tasks for a user based on competency gaps
CREATE OR REPLACE FUNCTION get_recommended_tasks(
    p_user_id UUID,
    p_stage_milestone VARCHAR DEFAULT 'foundation-seed',
    p_limit INTEGER DEFAULT 10
)
RETURNS TABLE(
    id UUID,
    task_code VARCHAR,
    name VARCHAR,
    description TEXT,
    category VARCHAR,
    priority VARCHAR,
    competency_area VARCHAR,
    platform_connection JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        tl.id,
        tl.task_code,
        tl.name,
        tl.description,
        tl.category,
        tl.priority,
        tl.competency_area,
        tl.platform_connection
    FROM tasks_library tl
    WHERE tl.is_active = TRUE
      AND tl.stage_milestone = p_stage_milestone
      AND tl.id NOT IN (
          SELECT task_id
          FROM task_completions
          WHERE user_id = p_user_id
      )
    ORDER BY
        CASE tl.priority
            WHEN 'critical' THEN 4
            WHEN 'high' THEN 3
            WHEN 'medium' THEN 2
            WHEN 'low' THEN 1
        END DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- Complete a task and update competency scores
CREATE OR REPLACE FUNCTION complete_task(
    p_user_id UUID,
    p_task_id UUID,
    p_competency_gains JSONB DEFAULT '{}'::jsonb,
    p_notes TEXT DEFAULT NULL
)
RETURNS task_completions AS $$
DECLARE
    completion task_completions;
BEGIN
    -- Insert task completion
    INSERT INTO task_completions (user_id, task_id, competency_gains, notes)
    VALUES (p_user_id, p_task_id, p_competency_gains, p_notes)
    ON CONFLICT (user_id, task_id) DO UPDATE
    SET
        completed_at = NOW(),
        competency_gains = EXCLUDED.competency_gains,
        notes = EXCLUDED.notes
    RETURNING * INTO completion;

    -- Update competency_data table if it exists
    -- (This will be handled by application layer)

    RETURN completion;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================

-- Enable RLS on both tables
ALTER TABLE tasks_library ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_completions ENABLE ROW LEVEL SECURITY;

-- tasks_library policies: Everyone can read tasks
CREATE POLICY "Anyone can read tasks"
    ON tasks_library FOR SELECT
    USING (true);

-- task_completions policies: Users can only see their own completions
CREATE POLICY "Users can read own completions"
    ON task_completions FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own completions"
    ON task_completions FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own completions"
    ON task_completions FOR UPDATE
    USING (auth.uid() = user_id);

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Update updated_at timestamp on tasks_library
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_tasks_library_updated_at
    BEFORE UPDATE ON tasks_library
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- REAL-TIME SUBSCRIPTIONS
-- ============================================================================

-- Enable realtime for task completions (for live dashboard updates)
ALTER PUBLICATION supabase_realtime ADD TABLE task_completions;

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE tasks_library IS 'Master catalog of all tasks users can complete to improve competency';
COMMENT ON TABLE task_completions IS 'Tracks which tasks users have completed and their competency gains';
COMMENT ON FUNCTION get_user_completed_tasks IS 'Returns all completed tasks for a user';
COMMENT ON FUNCTION get_recommended_tasks IS 'Returns recommended tasks based on user progress and competency gaps';
COMMENT ON FUNCTION complete_task IS 'Marks a task as complete and updates competency scores';
