-- ===============================================
-- CREATE PLATFORM_ACTIONS TABLE
-- Date: October 9, 2025
-- ===============================================

-- This migration creates a new platform_actions table for tracking user interactions
-- with the platform (page views, form completions, exports, etc.) separate from
-- professional development actions tracked in customer_actions table.

-- ============================================================================
-- CREATE PLATFORM_ACTIONS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS platform_actions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Action details (no CHECK constraint - fully flexible for platform events)
    action_type TEXT NOT NULL,
    action_description TEXT,
    
    -- Context information
    page_context TEXT,
    tool_context TEXT,
    session_id TEXT,
    
    -- Flexible metadata storage
    action_metadata JSONB DEFAULT '{}'::jsonb,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT valid_action_type CHECK (action_type IS NOT NULL AND action_type != '')
);

-- ============================================================================
-- CREATE PERFORMANCE INDEXES
-- ============================================================================

-- User-based queries (most common)
CREATE INDEX IF NOT EXISTS idx_platform_actions_user_id ON platform_actions(user_id);

-- Time-based queries (for analytics and cleanup)
CREATE INDEX IF NOT EXISTS idx_platform_actions_created_at ON platform_actions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_platform_actions_updated_at ON platform_actions(updated_at DESC);

-- Action type queries (for filtering and analytics)
CREATE INDEX IF NOT EXISTS idx_platform_actions_action_type ON platform_actions(action_type);

-- Context queries (for page/tool analytics)
CREATE INDEX IF NOT EXISTS idx_platform_actions_page_context ON platform_actions(page_context);
CREATE INDEX IF NOT EXISTS idx_platform_actions_tool_context ON platform_actions(tool_context);

-- Session-based queries (for user journey tracking)
CREATE INDEX IF NOT EXISTS idx_platform_actions_session_id ON platform_actions(session_id);

-- Composite indexes for common query patterns
CREATE INDEX IF NOT EXISTS idx_platform_actions_user_created ON platform_actions(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_platform_actions_user_action ON platform_actions(user_id, action_type);

-- JSONB metadata queries (GIN index for flexible JSON queries)
CREATE INDEX IF NOT EXISTS idx_platform_actions_metadata ON platform_actions USING GIN (action_metadata);

-- ============================================================================
-- CREATE UPDATED_AT TRIGGER
-- ============================================================================

-- Ensure update_updated_at_column function exists
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for auto-updating updated_at
DROP TRIGGER IF EXISTS update_platform_actions_updated_at ON platform_actions;
CREATE TRIGGER update_platform_actions_updated_at 
    BEFORE UPDATE ON platform_actions 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- ENABLE ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE platform_actions ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- CREATE RLS POLICIES
-- ============================================================================

-- Users can view their own platform actions
DROP POLICY IF EXISTS "Users can view their own platform actions" ON platform_actions;
CREATE POLICY "Users can view their own platform actions" ON platform_actions
    FOR SELECT USING (auth.uid() = user_id);

-- Users can insert their own platform actions
DROP POLICY IF EXISTS "Users can insert their own platform actions" ON platform_actions;
CREATE POLICY "Users can insert their own platform actions" ON platform_actions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own platform actions
DROP POLICY IF EXISTS "Users can update their own platform actions" ON platform_actions;
CREATE POLICY "Users can update their own platform actions" ON platform_actions
    FOR UPDATE USING (auth.uid() = user_id);

-- Users can delete their own platform actions
DROP POLICY IF EXISTS "Users can delete their own platform actions" ON platform_actions;
CREATE POLICY "Users can delete their own platform actions" ON platform_actions
    FOR DELETE USING (auth.uid() = user_id);

-- Service role has full access (for backend operations)
DROP POLICY IF EXISTS "Service role full access to platform actions" ON platform_actions;
CREATE POLICY "Service role full access to platform actions" ON platform_actions
    FOR ALL 
    TO service_role
    USING (true)
    WITH CHECK (true);

-- ============================================================================
-- ENABLE REALTIME
-- ============================================================================

-- Enable realtime for live updates (useful for analytics dashboards)
ALTER PUBLICATION supabase_realtime ADD TABLE platform_actions;

-- ============================================================================
-- GRANT PERMISSIONS
-- ============================================================================

-- Grant permissions to authenticated users
GRANT ALL ON platform_actions TO authenticated;

-- ============================================================================
-- ADD DOCUMENTATION
-- ============================================================================

COMMENT ON TABLE platform_actions IS 'Tracks user interactions with the platform (page views, form completions, exports, etc.)';
COMMENT ON COLUMN platform_actions.user_id IS 'User who performed this action (required for RLS)';
COMMENT ON COLUMN platform_actions.action_type IS 'Type of platform action (page_view, form_completion, export, etc.)';
COMMENT ON COLUMN platform_actions.action_description IS 'Human-readable description of the action';
COMMENT ON COLUMN platform_actions.page_context IS 'Page or route where action occurred';
COMMENT ON COLUMN platform_actions.tool_context IS 'Tool or feature being used';
COMMENT ON COLUMN platform_actions.session_id IS 'Session identifier for grouping related actions';
COMMENT ON COLUMN platform_actions.action_metadata IS 'Additional metadata about the action (JSON format)';

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================

-- Log successful migration
DO $$
BEGIN
    RAISE NOTICE '✅ Created platform_actions table successfully';
    RAISE NOTICE '📊 Table includes: action_type, page_context, tool_context, session_id, action_metadata';
    RAISE NOTICE '⚡ Created performance indexes for user_id, created_at, action_type, and metadata';
    RAISE NOTICE '🔒 Enabled RLS with user-based access policies';
    RAISE NOTICE '🔄 Enabled realtime for live updates';
    RAISE NOTICE '📝 Added comprehensive documentation';
END $$;
