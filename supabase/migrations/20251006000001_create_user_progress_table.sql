-- ===============================================
-- USER_PROGRESS TABLE
-- Date: 2025-10-06
-- Purpose: Track user progress through platform tools and features
-- ===============================================

-- 1. CREATE TABLE
CREATE TABLE IF NOT EXISTS user_progress (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    customer_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    tool_name TEXT NOT NULL CHECK (tool_name IN (
        'icp_analysis',
        'cost_calculator',
        'business_case',
        'resources',
        'competency_assessment',
        'onboarding'
    )),

    -- Progress data stored as JSONB for flexibility
    progress_data JSONB DEFAULT '{}'::jsonb,

    -- Completion tracking
    completion_percentage INTEGER DEFAULT 0 CHECK (completion_percentage >= 0 AND completion_percentage <= 100),
    is_completed BOOLEAN DEFAULT false,
    completed_at TIMESTAMPTZ,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Unique constraint: one progress record per customer per tool
    CONSTRAINT unique_customer_tool UNIQUE (customer_id, tool_name)
);

-- 2. CREATE INDEXES
CREATE INDEX IF NOT EXISTS idx_user_progress_customer_id ON user_progress(customer_id);
CREATE INDEX IF NOT EXISTS idx_user_progress_tool_name ON user_progress(tool_name);
CREATE INDEX IF NOT EXISTS idx_user_progress_created_at ON user_progress(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_progress_updated_at ON user_progress(updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_progress_customer_tool ON user_progress(customer_id, tool_name);
CREATE INDEX IF NOT EXISTS idx_user_progress_is_completed ON user_progress(is_completed);

-- 3. CREATE TRIGGER FOR UPDATED_AT
DROP TRIGGER IF EXISTS update_user_progress_updated_at ON user_progress;
CREATE TRIGGER update_user_progress_updated_at
    BEFORE UPDATE ON user_progress
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 4. ENABLE RLS
ALTER TABLE user_progress ENABLE ROW LEVEL SECURITY;

-- 5. CREATE RLS POLICIES
DROP POLICY IF EXISTS "Users can view their own progress" ON user_progress;
CREATE POLICY "Users can view their own progress" ON user_progress
    FOR SELECT USING (auth.uid() = customer_id);

DROP POLICY IF EXISTS "Users can insert their own progress" ON user_progress;
CREATE POLICY "Users can insert their own progress" ON user_progress
    FOR INSERT WITH CHECK (auth.uid() = customer_id);

DROP POLICY IF EXISTS "Users can update their own progress" ON user_progress;
CREATE POLICY "Users can update their own progress" ON user_progress
    FOR UPDATE USING (auth.uid() = customer_id);

DROP POLICY IF EXISTS "Users can delete their own progress" ON user_progress;
CREATE POLICY "Users can delete their own progress" ON user_progress
    FOR DELETE USING (auth.uid() = customer_id);

DROP POLICY IF EXISTS "Service role full access to user_progress" ON user_progress;
CREATE POLICY "Service role full access to user_progress" ON user_progress
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- 6. ENABLE REALTIME
ALTER PUBLICATION supabase_realtime ADD TABLE user_progress;

-- 7. GRANT PERMISSIONS
GRANT ALL ON user_progress TO authenticated;
GRANT ALL ON user_progress TO service_role;

-- 8. ADD COMMENTS
COMMENT ON TABLE user_progress IS 'Tracks user progress through platform tools and features';
COMMENT ON COLUMN user_progress.customer_id IS 'User who owns this progress record';
COMMENT ON COLUMN user_progress.tool_name IS 'Name of the tool or feature being tracked';
COMMENT ON COLUMN user_progress.progress_data IS 'Flexible JSONB field for tool-specific progress data';
COMMENT ON COLUMN user_progress.completion_percentage IS 'Percentage of completion (0-100)';
COMMENT ON COLUMN user_progress.is_completed IS 'Whether the tool workflow is completed';
COMMENT ON COLUMN user_progress.completed_at IS 'Timestamp when the tool was marked complete';
