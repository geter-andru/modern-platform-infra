-- ============================================
-- APPLICATION LOGS TABLE
-- Created: 2025-10-16
-- Purpose: Production logging with Supabase persistence
-- ============================================

-- Create logs table
CREATE TABLE IF NOT EXISTS public.application_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  timestamp TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  level TEXT NOT NULL CHECK (level IN ('debug', 'info', 'warn', 'error')),
  message TEXT NOT NULL,
  context JSONB DEFAULT '{}',

  -- User tracking
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  session_id TEXT,

  -- Request context
  url TEXT,
  user_agent TEXT,
  ip_address INET,

  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,

  -- Constraints
  CONSTRAINT valid_log_level CHECK (level IN ('debug', 'info', 'warn', 'error'))
);

-- ============================================
-- INDEXES for fast querying
-- ============================================

-- Primary timestamp index (most common query pattern)
CREATE INDEX IF NOT EXISTS idx_application_logs_timestamp
  ON public.application_logs(timestamp DESC);

-- Level index (filter by severity)
CREATE INDEX IF NOT EXISTS idx_application_logs_level
  ON public.application_logs(level);

-- User tracking indexes
CREATE INDEX IF NOT EXISTS idx_application_logs_user_id
  ON public.application_logs(user_id)
  WHERE user_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_application_logs_session
  ON public.application_logs(session_id)
  WHERE session_id IS NOT NULL;

-- Composite index for common queries
CREATE INDEX IF NOT EXISTS idx_application_logs_level_timestamp
  ON public.application_logs(level, timestamp DESC);

-- JSONB context index for fast context searches
CREATE INDEX IF NOT EXISTS idx_application_logs_context
  ON public.application_logs USING GIN (context);

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================

ALTER TABLE public.application_logs ENABLE ROW LEVEL SECURITY;

-- Policy: Admins can view all logs
CREATE POLICY "Admins can view all logs"
  ON public.application_logs
  FOR SELECT
  USING (
    auth.jwt() ->> 'role' = 'admin'
    OR
    auth.jwt() ->> 'email' IN (
      'your-admin@example.com'
    )
  );

-- Policy: Users can view their own logs
CREATE POLICY "Users can view own logs"
  ON public.application_logs
  FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Service role can insert logs (for backend logging)
CREATE POLICY "Service role can insert logs"
  ON public.application_logs
  FOR INSERT
  WITH CHECK (true);

-- Policy: Authenticated users can insert their own logs
CREATE POLICY "Authenticated users can insert own logs"
  ON public.application_logs
  FOR INSERT
  WITH CHECK (auth.uid() = user_id OR user_id IS NULL);

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Function: Clean up old logs (call via cron or manually)
CREATE OR REPLACE FUNCTION public.cleanup_old_application_logs(
  retention_days INTEGER DEFAULT 90
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  deleted_count INTEGER;
BEGIN
  DELETE FROM public.application_logs
  WHERE timestamp < NOW() - (retention_days || ' days')::INTERVAL;

  GET DIAGNOSTICS deleted_count = ROW_COUNT;

  RETURN deleted_count;
END;
$$;

-- Function: Get error count for last N hours
CREATE OR REPLACE FUNCTION public.get_error_count(
  hours INTEGER DEFAULT 24
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  error_count INTEGER;
BEGIN
  SELECT COUNT(*)
  INTO error_count
  FROM public.application_logs
  WHERE
    level = 'error'
    AND timestamp > NOW() - (hours || ' hours')::INTERVAL;

  RETURN error_count;
END;
$$;

-- Function: Get log statistics
CREATE OR REPLACE FUNCTION public.get_log_statistics(
  hours INTEGER DEFAULT 24
)
RETURNS TABLE (
  level TEXT,
  count BIGINT,
  latest_timestamp TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT
    l.level,
    COUNT(*) as count,
    MAX(l.timestamp) as latest_timestamp
  FROM public.application_logs l
  WHERE l.timestamp > NOW() - (hours || ' hours')::INTERVAL
  GROUP BY l.level
  ORDER BY count DESC;
END;
$$;

-- ============================================
-- COMMENTS for documentation
-- ============================================

COMMENT ON TABLE public.application_logs IS 'Production application logs with structured logging';
COMMENT ON COLUMN public.application_logs.level IS 'Log severity: debug, info, warn, error';
COMMENT ON COLUMN public.application_logs.context IS 'Additional context data as JSONB (flexible structure)';
COMMENT ON COLUMN public.application_logs.session_id IS 'Browser session ID for tracking user sessions';
COMMENT ON FUNCTION public.cleanup_old_application_logs IS 'Delete logs older than specified days (default 90)';
COMMENT ON FUNCTION public.get_error_count IS 'Count errors in the last N hours (default 24)';
COMMENT ON FUNCTION public.get_log_statistics IS 'Get log count by level for last N hours';

-- ============================================
-- GRANT PERMISSIONS
-- ============================================

-- Grant select to authenticated users (filtered by RLS)
GRANT SELECT ON public.application_logs TO authenticated;

-- Grant insert to authenticated users (for client-side logging)
GRANT INSERT ON public.application_logs TO authenticated;

-- Grant all to service role (for backend operations)
GRANT ALL ON public.application_logs TO service_role;

-- ============================================
-- SAMPLE USAGE
-- ============================================

-- Insert a log entry:
-- INSERT INTO public.application_logs (level, message, context, user_id, url)
-- VALUES ('error', 'Failed to load dashboard', '{"error": "NetworkError"}', auth.uid(), '/dashboard');

-- Query recent errors:
-- SELECT * FROM public.application_logs
-- WHERE level = 'error' AND timestamp > NOW() - INTERVAL '1 hour'
-- ORDER BY timestamp DESC;

-- Get statistics:
-- SELECT * FROM public.get_log_statistics(24);

-- Clean up old logs:
-- SELECT public.cleanup_old_application_logs(90);
