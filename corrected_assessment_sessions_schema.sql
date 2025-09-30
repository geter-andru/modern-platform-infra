-- ===============================================
-- CORRECTED ASSESSMENT SESSIONS SCHEMA
-- Cross-app integration for assessment data
-- Date: September 4, 2025
-- ===============================================

-- Create assessment_sessions table for cross-app integration
-- This table stores completed assessments before user signup/signin

CREATE TABLE IF NOT EXISTS assessment_sessions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    session_id TEXT UNIQUE NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    assessment_data JSONB NOT NULL,
    user_email TEXT NOT NULL,
    company_name TEXT,
    overall_score INTEGER CHECK (overall_score >= 0 AND overall_score <= 100),
    buyer_score INTEGER CHECK (buyer_score >= 0 AND buyer_score <= 100),
    status TEXT DEFAULT 'completed_awaiting_signup' CHECK (
        status IN (
            'completed_awaiting_signup', 
            'completed_with_user', 
            'expired',
            'linked'
        )
    ),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_assessment_sessions_session_id 
    ON assessment_sessions(session_id);

CREATE INDEX IF NOT EXISTS idx_assessment_sessions_user_email 
    ON assessment_sessions(user_email);

CREATE INDEX IF NOT EXISTS idx_assessment_sessions_user_id 
    ON assessment_sessions(user_id);

CREATE INDEX IF NOT EXISTS idx_assessment_sessions_status 
    ON assessment_sessions(status);

CREATE INDEX IF NOT EXISTS idx_assessment_sessions_created_at 
    ON assessment_sessions(created_at DESC);

-- Create trigger function for updating timestamps (use IF NOT EXISTS pattern)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$ language 'plpgsql';

-- Drop and recreate trigger to ensure it's current
DROP TRIGGER IF EXISTS update_assessment_sessions_updated_at ON assessment_sessions;
CREATE TRIGGER update_assessment_sessions_updated_at 
    BEFORE UPDATE ON assessment_sessions 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Enable RLS (Row Level Security)
ALTER TABLE assessment_sessions ENABLE ROW LEVEL SECURITY;

-- ===============================================
-- CORRECTED RLS POLICIES - DROP EXISTING FIRST
-- ===============================================

-- Drop all existing policies to avoid conflicts
DROP POLICY IF EXISTS "Users can view their own assessment sessions" ON assessment_sessions;
DROP POLICY IF EXISTS "Service role can manage all assessment sessions" ON assessment_sessions;
DROP POLICY IF EXISTS "Allow anonymous assessment creation" ON assessment_sessions;

-- Policy 1: Users can read their own assessment sessions
CREATE POLICY "users_can_view_own_assessments" ON assessment_sessions 
    FOR SELECT 
    TO authenticated
    USING (
        user_id = auth.uid() OR 
        user_email = (auth.jwt() ->> 'email')
    );

-- Policy 2: Service role can manage all assessment sessions (for cross-app functionality)
CREATE POLICY "service_role_full_access" ON assessment_sessions 
    FOR ALL 
    TO service_role
    USING (true)
    WITH CHECK (true);

-- Policy 3: Allow insert for anonymous users (assessment completion before signup)
CREATE POLICY "anonymous_can_create_assessments" ON assessment_sessions 
    FOR INSERT 
    TO anon
    WITH CHECK (user_id IS NULL);

-- Policy 4: Authenticated users can insert their own assessments
CREATE POLICY "authenticated_can_create_own_assessments" ON assessment_sessions 
    FOR INSERT 
    TO authenticated
    WITH CHECK (
        user_id = auth.uid() OR 
        user_email = (auth.jwt() ->> 'email')
    );

-- Policy 5: Users can update their own assessment sessions
CREATE POLICY "users_can_update_own_assessments" ON assessment_sessions 
    FOR UPDATE 
    TO authenticated
    USING (
        user_id = auth.uid() OR 
        user_email = (auth.jwt() ->> 'email')
    )
    WITH CHECK (
        user_id = auth.uid() OR 
        user_email = (auth.jwt() ->> 'email')
    );

-- ===============================================
-- DOCUMENTATION COMMENTS
-- ===============================================

COMMENT ON TABLE assessment_sessions IS 'Stores completed assessments from the assessment app before user signup/signin in the platform';
COMMENT ON COLUMN assessment_sessions.id IS 'Primary key using UUID';
COMMENT ON COLUMN assessment_sessions.session_id IS 'Unique session identifier from assessment app';
COMMENT ON COLUMN assessment_sessions.user_id IS 'Links to auth.users after signup, NULL before signup';
COMMENT ON COLUMN assessment_sessions.assessment_data IS 'Complete assessment results as JSON';
COMMENT ON COLUMN assessment_sessions.user_email IS 'Email provided during assessment';
COMMENT ON COLUMN assessment_sessions.company_name IS 'Company name from assessment';
COMMENT ON COLUMN assessment_sessions.overall_score IS 'Overall assessment score (0-100)';
COMMENT ON COLUMN assessment_sessions.buyer_score IS 'Buyer understanding score (0-100)';
COMMENT ON COLUMN assessment_sessions.status IS 'Current status of the assessment session';
COMMENT ON COLUMN assessment_sessions.created_at IS 'Timestamp when assessment was created';
COMMENT ON COLUMN assessment_sessions.updated_at IS 'Timestamp when assessment was last updated';

-- ===============================================
-- OPTIONAL: HELPER FUNCTIONS FOR CROSS-APP INTEGRATION
-- ===============================================

-- Function to link assessment session to user after signup
CREATE OR REPLACE FUNCTION link_assessment_to_user(
    p_session_id TEXT,
    p_user_id UUID
) RETURNS BOOLEAN AS $
DECLARE
    rows_updated INTEGER;
BEGIN
    UPDATE assessment_sessions 
    SET 
        user_id = p_user_id,
        status = 'linked',
        updated_at = NOW()
    WHERE 
        session_id = p_session_id 
        AND user_id IS NULL
        AND status = 'completed_awaiting_signup';
    
    GET DIAGNOSTICS rows_updated = ROW_COUNT;
    
    RETURN rows_updated > 0;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get assessment data for a user
CREATE OR REPLACE FUNCTION get_user_assessment_data(p_user_id UUID)
RETURNS TABLE(
    session_id TEXT,
    assessment_data JSONB,
    overall_score INTEGER,
    buyer_score INTEGER,
    created_at TIMESTAMPTZ
) AS $
BEGIN
    RETURN QUERY
    SELECT 
        a.session_id,
        a.assessment_data,
        a.overall_score,
        a.buyer_score,
        a.created_at
    FROM assessment_sessions a
    WHERE a.user_id = p_user_id
    ORDER BY a.created_at DESC;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions on helper functions
GRANT EXECUTE ON FUNCTION link_assessment_to_user(TEXT, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_assessment_data(UUID) TO authenticated;