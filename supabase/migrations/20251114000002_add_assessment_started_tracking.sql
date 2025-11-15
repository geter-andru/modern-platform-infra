-- ===============================================
-- ASSESSMENT STARTED TRACKING & NOTIFICATIONS
-- Date: 2025-11-14
-- Purpose: Track when assessments start (not just complete) and notify admin
-- ===============================================

-- PART 1: ADD NEW COLUMNS
-- ===============================================

-- Add started_at timestamp to track when assessment begins
ALTER TABLE assessment_sessions
ADD COLUMN IF NOT EXISTS started_at TIMESTAMPTZ;

-- Add completed_at to distinguish start vs completion time
ALTER TABLE assessment_sessions
ADD COLUMN IF NOT EXISTS completed_at TIMESTAMPTZ;

-- Add progress tracking fields
ALTER TABLE assessment_sessions
ADD COLUMN IF NOT EXISTS current_step TEXT;

ALTER TABLE assessment_sessions
ADD COLUMN IF NOT EXISTS total_steps INTEGER;

ALTER TABLE assessment_sessions
ADD COLUMN IF NOT EXISTS completion_percentage INTEGER CHECK (completion_percentage >= 0 AND completion_percentage <= 100);

-- Backfill existing rows: set started_at = created_at for historical data
UPDATE assessment_sessions
SET started_at = created_at
WHERE started_at IS NULL;

-- Backfill completed_at for existing completed assessments
UPDATE assessment_sessions
SET completed_at = created_at
WHERE status IN ('completed_awaiting_signup', 'completed_with_user', 'linked', 'expired')
  AND completed_at IS NULL;

-- Make started_at NOT NULL after backfill
ALTER TABLE assessment_sessions
ALTER COLUMN started_at SET NOT NULL;

-- Set default for new rows
ALTER TABLE assessment_sessions
ALTER COLUMN started_at SET DEFAULT NOW();

-- Add comments
COMMENT ON COLUMN assessment_sessions.started_at IS 'When the user first opened the assessment (not when they completed it)';
COMMENT ON COLUMN assessment_sessions.completed_at IS 'When the user finished the assessment and submitted scores';
COMMENT ON COLUMN assessment_sessions.current_step IS 'Current step identifier (e.g., "intro", "market", "product")';
COMMENT ON COLUMN assessment_sessions.total_steps IS 'Total number of steps in the assessment';
COMMENT ON COLUMN assessment_sessions.completion_percentage IS 'Progress through assessment (0-100)';

-- ===============================================
-- PART 2: UPDATE STATUS FIELD TO INCLUDE 'STARTED'
-- ===============================================

-- Drop existing constraint
ALTER TABLE assessment_sessions
DROP CONSTRAINT IF EXISTS assessment_sessions_status_check;

-- Add new constraint with 'started' status
ALTER TABLE assessment_sessions
ADD CONSTRAINT assessment_sessions_status_check
CHECK (status IN (
  'started',                      -- NEW: User opened assessment but hasn't finished
  'completed_awaiting_signup',    -- Existing: Completed, waiting for signup
  'completed_with_user',          -- Existing: Completed by authenticated user
  'expired',                      -- Existing: Session expired
  'linked'                        -- Existing: Linked to user account
));

-- Update default status for new assessments
ALTER TABLE assessment_sessions
ALTER COLUMN status SET DEFAULT 'started';

COMMENT ON COLUMN assessment_sessions.status IS 'Assessment lifecycle: started → completed_awaiting_signup → linked';

-- ===============================================
-- PART 3: CREATE FUNCTION TO NOTIFY ON ASSESSMENT START
-- ===============================================

CREATE OR REPLACE FUNCTION notify_assessment_started()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  webhook_url TEXT;
  webhook_secret TEXT;
  payload JSONB;
  completed_steps_array TEXT[];
BEGIN
  -- Only trigger on INSERT (new assessment starting)
  IF TG_OP != 'INSERT' THEN
    RETURN NEW;
  END IF;

  -- Get webhook configuration
  webhook_url := current_setting('app.settings.webhook_url', true);
  webhook_secret := current_setting('app.settings.webhook_secret', true);

  -- Skip if webhook not configured
  IF webhook_url IS NULL OR webhook_url = '' THEN
    RAISE WARNING 'Webhook URL not configured. Skipping assessment started notification for session %', NEW.id;
    RETURN NEW;
  END IF;

  -- Extract completed_steps from assessment_data JSONB if it exists
  IF NEW.assessment_data ? 'completed_steps' THEN
    SELECT ARRAY(SELECT jsonb_array_elements_text(NEW.assessment_data->'completed_steps'))
    INTO completed_steps_array;
  END IF;

  -- Build payload with progress tracking
  payload := jsonb_build_object(
    'id', NEW.id,
    'session_id', NEW.session_id,
    'user_email', NEW.user_email,
    'company_name', NEW.company_name,
    'started_at', NEW.started_at,
    'status', NEW.status,
    'current_step', NEW.current_step,
    'total_steps', NEW.total_steps,
    'completion_percentage', NEW.completion_percentage,
    'completed_steps', COALESCE(completed_steps_array, ARRAY[]::TEXT[])
  );

  -- Send async HTTP POST
  PERFORM
    extensions.net.http_post(
      url := webhook_url || '/notifications/assessment-started',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || COALESCE(webhook_secret, '')
      ),
      body := payload
    );

  RAISE LOG 'Assessment started notification webhook triggered for session %', NEW.id;

  RETURN NEW;

EXCEPTION
  WHEN OTHERS THEN
    RAISE WARNING 'Failed to send assessment started notification: %', SQLERRM;
    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION notify_assessment_started() IS 'Sends webhook when new assessment is started';

-- ===============================================
-- PART 4: UPDATE COMPLETION NOTIFICATION FUNCTION
-- ===============================================

CREATE OR REPLACE FUNCTION notify_assessment_completed()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  webhook_url TEXT;
  webhook_secret TEXT;
  payload JSONB;
BEGIN
  -- Only trigger when status changes to a completed state
  IF TG_OP = 'UPDATE' THEN
    -- Check if status changed to completed
    IF NEW.status NOT IN ('completed_awaiting_signup', 'completed_with_user', 'linked') THEN
      RETURN NEW;
    END IF;

    -- Check if this is actually a status change (not just updating other fields)
    IF OLD.status = NEW.status THEN
      RETURN NEW;
    END IF;
  END IF;

  -- Get webhook configuration
  webhook_url := current_setting('app.settings.webhook_url', true);
  webhook_secret := current_setting('app.settings.webhook_secret', true);

  -- Skip if webhook not configured
  IF webhook_url IS NULL OR webhook_url = '' THEN
    RAISE WARNING 'Webhook URL not configured. Skipping assessment completion notification for session %', NEW.id;
    RETURN NEW;
  END IF;

  -- Build payload
  payload := jsonb_build_object(
    'id', NEW.id,
    'session_id', NEW.session_id,
    'user_email', NEW.user_email,
    'company_name', NEW.company_name,
    'overall_score', NEW.overall_score,
    'buyer_score', NEW.buyer_score,
    'started_at', NEW.started_at,
    'completed_at', NEW.completed_at,
    'created_at', NEW.created_at
  );

  -- Send async HTTP POST
  PERFORM
    extensions.net.http_post(
      url := webhook_url || '/notifications/assessment-completed',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || COALESCE(webhook_secret, '')
      ),
      body := payload
    );

  RAISE LOG 'Assessment completed notification webhook triggered for session %', NEW.id;

  RETURN NEW;

EXCEPTION
  WHEN OTHERS THEN
    RAISE WARNING 'Failed to send assessment completed notification: %', SQLERRM;
    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION notify_assessment_completed() IS 'Sends webhook when assessment is completed with scores';

-- ===============================================
-- PART 5: CREATE TRIGGERS
-- ===============================================

-- Drop existing triggers first (per syntax reference)
DROP TRIGGER IF EXISTS trigger_notify_new_assessment ON assessment_sessions;
DROP TRIGGER IF EXISTS trigger_notify_assessment_started ON assessment_sessions;
DROP TRIGGER IF EXISTS trigger_notify_assessment_completed ON assessment_sessions;

-- Create trigger for assessment started (on INSERT)
CREATE TRIGGER trigger_notify_assessment_started
  AFTER INSERT ON assessment_sessions
  FOR EACH ROW
  EXECUTE FUNCTION notify_assessment_started();

-- Create trigger for assessment completed (on UPDATE to completed status)
CREATE TRIGGER trigger_notify_assessment_completed
  AFTER UPDATE ON assessment_sessions
  FOR EACH ROW
  WHEN (NEW.status IN ('completed_awaiting_signup', 'completed_with_user', 'linked'))
  EXECUTE FUNCTION notify_assessment_completed();

-- ===============================================
-- PART 6: CREATE INDEXES FOR PERFORMANCE
-- ===============================================

-- Index on started_at for analytics queries
CREATE INDEX IF NOT EXISTS idx_assessment_sessions_started_at
  ON assessment_sessions(started_at DESC);

-- Index on completed_at for completion tracking
CREATE INDEX IF NOT EXISTS idx_assessment_sessions_completed_at
  ON assessment_sessions(completed_at DESC)
  WHERE completed_at IS NOT NULL;

-- Composite index for drop-off analysis
CREATE INDEX IF NOT EXISTS idx_assessment_sessions_status_started
  ON assessment_sessions(status, started_at DESC);

-- Index on completion percentage for progress analytics
CREATE INDEX IF NOT EXISTS idx_assessment_sessions_completion_pct
  ON assessment_sessions(completion_percentage)
  WHERE completion_percentage IS NOT NULL;

-- ===============================================
-- PART 7: HELPER FUNCTIONS FOR TESTING
-- ===============================================

-- Function to test "assessment started" notification
CREATE OR REPLACE FUNCTION test_assessment_started_notification(
  test_email TEXT DEFAULT 'test@example.com',
  test_company TEXT DEFAULT 'Test Company'
)
RETURNS TEXT
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  test_session_id TEXT;
  test_id UUID;
BEGIN
  test_session_id := 'TEST_START_' || gen_random_uuid()::TEXT;
  test_id := gen_random_uuid();

  -- Insert test record with 'started' status and progress tracking
  INSERT INTO assessment_sessions (
    id,
    session_id,
    user_email,
    company_name,
    status,
    assessment_data,
    started_at,
    current_step,
    total_steps,
    completion_percentage
  ) VALUES (
    test_id,
    test_session_id,
    test_email,
    test_company,
    'started',
    '{"completed_steps": []}'::jsonb,
    NOW(),
    'intro',
    5,
    0
  );

  RETURN 'Test "assessment started" notification triggered. Check your email. Test ID: ' || test_id::TEXT;
END;
$$;

-- Function to simulate completing a started assessment
CREATE OR REPLACE FUNCTION test_assessment_completion_flow(
  test_email TEXT DEFAULT 'test@example.com',
  test_company TEXT DEFAULT 'Test Company'
)
RETURNS TEXT
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  test_session_id TEXT;
  test_id UUID;
BEGIN
  test_session_id := 'TEST_FLOW_' || gen_random_uuid()::TEXT;
  test_id := gen_random_uuid();

  -- Step 1: Insert with 'started' status
  INSERT INTO assessment_sessions (
    id,
    session_id,
    user_email,
    company_name,
    status,
    assessment_data,
    started_at,
    current_step,
    total_steps,
    completion_percentage
  ) VALUES (
    test_id,
    test_session_id,
    test_email,
    test_company,
    'started',
    '{"completed_steps": []}'::jsonb,
    NOW(),
    'intro',
    5,
    0
  );

  RAISE NOTICE 'Step 1: Created started assessment (ID: %)', test_id;

  -- Wait a moment to simulate user taking assessment
  PERFORM pg_sleep(2);

  -- Step 2: Update to completed with scores and progress
  UPDATE assessment_sessions
  SET
    status = 'completed_awaiting_signup',
    overall_score = 85,
    buyer_score = 78,
    completed_at = NOW(),
    current_step = 'finished',
    completion_percentage = 100,
    assessment_data = '{"completed_steps": ["intro", "market", "product", "revenue", "summary"], "test": true}'::jsonb
  WHERE id = test_id;

  RAISE NOTICE 'Step 2: Updated to completed with scores';

  RETURN 'Test flow completed. You should have received 2 emails: started + completed. Test ID: ' || test_id::TEXT;
END;
$$;

COMMENT ON FUNCTION test_assessment_started_notification(TEXT, TEXT) IS 'Test function for assessment started webhook';
COMMENT ON FUNCTION test_assessment_completion_flow(TEXT, TEXT) IS 'Test complete flow: started → completed (2 emails)';

-- ===============================================
-- POST-MIGRATION NOTES
-- ===============================================

-- After running this migration:
--
-- 1. Configure webhook URL and secret:
/*
SELECT set_webhook_config(
  'https://your-backend.onrender.com/api/webhooks',
  'your-webhook-secret'
);
*/
--
-- 2. Test the started notification:
/*
SELECT test_assessment_started_notification('geter@humusnshore.org', 'Test Company');
*/
--
-- 3. Test the complete flow (started → completed):
/*
SELECT test_assessment_completion_flow('geter@humusnshore.org', 'Test Company');
*/
--
-- 4. Update frontend to create rows with status='started' when user opens assessment
--    and populate: current_step, total_steps, completion_percentage
--
-- 5. Update frontend to change status to 'completed_awaiting_signup' when finished
--
-- ===============================================
