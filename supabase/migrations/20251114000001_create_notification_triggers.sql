-- ===============================================
-- NOTIFICATION TRIGGERS FOR ADMIN ALERTS
-- Date: 2025-11-14
-- Purpose: Auto-notify admin via email when new assessments or waitlist signups occur
-- ===============================================

-- CONFIGURATION INSTRUCTIONS:
-- This migration creates database triggers that call webhook endpoints on your backend.
--
-- IMPORTANT: After running this migration, you must configure the Supabase secrets:
--   1. Go to Supabase Dashboard → Project Settings → Edge Functions
--   2. Add these secrets:
--      - WEBHOOK_URL (e.g., 'https://your-backend.onrender.com/api/webhooks')
--      - WEBHOOK_SECRET (must match WEBHOOK_SECRET in backend .env)
--
-- Alternatively, you can use Supabase's Database Webhooks feature in the dashboard:
--   1. Go to Database → Webhooks
--   2. Create webhooks for:
--      - assessment_sessions (INSERT event)
--      - beta_signups (INSERT event)
--   3. Point them to your backend webhook endpoints with Bearer token auth
-- ===============================================

-- Enable the pg_net extension for making async HTTP requests from triggers
-- This extension is available in Supabase (may need to be enabled in dashboard first)
-- Go to: Database → Extensions → Enable "pg_net"
CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;

-- ===============================================
-- PART 1: ASSESSMENT NOTIFICATION TRIGGER
-- ===============================================

-- Function to notify admin when a new assessment is completed
CREATE OR REPLACE FUNCTION notify_new_assessment()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  webhook_url TEXT;
  webhook_secret TEXT;
  response_status INTEGER;
  payload JSONB;
BEGIN
  -- Get configuration from environment (set these in Supabase dashboard)
  -- For now, we'll use placeholder values that need to be updated
  webhook_url := current_setting('app.settings.webhook_url', true);
  webhook_secret := current_setting('app.settings.webhook_secret', true);

  -- If webhook URL is not configured, log warning and exit gracefully
  IF webhook_url IS NULL OR webhook_url = '' THEN
    RAISE WARNING 'Webhook URL not configured. Skipping assessment notification for session %', NEW.id;
    RETURN NEW;
  END IF;

  -- Build the payload to send to webhook
  payload := jsonb_build_object(
    'id', NEW.id,
    'session_id', NEW.session_id,
    'user_email', NEW.user_email,
    'company_name', NEW.company_name,
    'overall_score', NEW.overall_score,
    'buyer_score', NEW.buyer_score,
    'created_at', NEW.created_at
  );

  -- Make async HTTP POST request to webhook endpoint
  -- Using pg_net for non-blocking HTTP requests
  PERFORM
    extensions.net.http_post(
      url := webhook_url || '/notifications/assessment',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || COALESCE(webhook_secret, '')
      ),
      body := payload
    );

  -- Log successful trigger execution
  RAISE LOG 'Assessment notification webhook triggered for session %', NEW.id;

  RETURN NEW;

EXCEPTION
  WHEN OTHERS THEN
    -- Log error but don't fail the INSERT operation
    RAISE WARNING 'Failed to send assessment notification webhook: %', SQLERRM;
    RETURN NEW;
END;
$$;

-- Create trigger on assessment_sessions table
DROP TRIGGER IF EXISTS trigger_notify_new_assessment ON assessment_sessions;
CREATE TRIGGER trigger_notify_new_assessment
  AFTER INSERT ON assessment_sessions
  FOR EACH ROW
  EXECUTE FUNCTION notify_new_assessment();

COMMENT ON FUNCTION notify_new_assessment() IS 'Sends HTTP webhook to backend when new assessment is completed';

-- ===============================================
-- PART 2: WAITLIST SIGNUP NOTIFICATION TRIGGER
-- ===============================================

-- Function to notify admin when a new waitlist signup occurs
CREATE OR REPLACE FUNCTION notify_new_waitlist_signup()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  webhook_url TEXT;
  webhook_secret TEXT;
  response_status INTEGER;
  payload JSONB;
BEGIN
  -- Get configuration from environment
  webhook_url := current_setting('app.settings.webhook_url', true);
  webhook_secret := current_setting('app.settings.webhook_secret', true);

  -- If webhook URL is not configured, log warning and exit gracefully
  IF webhook_url IS NULL OR webhook_url = '' THEN
    RAISE WARNING 'Webhook URL not configured. Skipping waitlist notification for signup %', NEW.id;
    RETURN NEW;
  END IF;

  -- Build the payload to send to webhook
  payload := jsonb_build_object(
    'id', NEW.id,
    'full_name', NEW.full_name,
    'email', NEW.email,
    'company', NEW.company,
    'job_title', NEW.job_title,
    'product_description', NEW.product_description,
    'referral_source', NEW.referral_source,
    'linkedin_profile', NEW.linkedin_profile,
    'created_at', NEW.created_at
  );

  -- Make async HTTP POST request to webhook endpoint
  PERFORM
    extensions.net.http_post(
      url := webhook_url || '/notifications/waitlist',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || COALESCE(webhook_secret, '')
      ),
      body := payload
    );

  -- Log successful trigger execution
  RAISE LOG 'Waitlist notification webhook triggered for signup %', NEW.id;

  RETURN NEW;

EXCEPTION
  WHEN OTHERS THEN
    -- Log error but don't fail the INSERT operation
    RAISE WARNING 'Failed to send waitlist notification webhook: %', SQLERRM;
    RETURN NEW;
END;
$$;

-- Create trigger on beta_signups table
DROP TRIGGER IF EXISTS trigger_notify_new_waitlist_signup ON beta_signups;
CREATE TRIGGER trigger_notify_new_waitlist_signup
  AFTER INSERT ON beta_signups
  FOR EACH ROW
  EXECUTE FUNCTION notify_new_waitlist_signup();

COMMENT ON FUNCTION notify_new_waitlist_signup() IS 'Sends HTTP webhook to backend when new beta waitlist signup occurs';

-- ===============================================
-- PART 3: CONFIGURATION HELPERS
-- ===============================================

-- Function to set webhook configuration (run this after migration)
-- Example usage:
--   SELECT set_webhook_config('https://your-backend.onrender.com/api/webhooks', 'your-secret-key');
CREATE OR REPLACE FUNCTION set_webhook_config(
  url TEXT,
  secret TEXT
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Set configuration at database level
  EXECUTE format('ALTER DATABASE %I SET app.settings.webhook_url = %L', current_database(), url);
  EXECUTE format('ALTER DATABASE %I SET app.settings.webhook_secret = %L', current_database(), secret);

  -- Reload configuration
  PERFORM pg_reload_conf();

  RETURN 'Webhook configuration updated successfully. URL: ' || url;
END;
$$;

COMMENT ON FUNCTION set_webhook_config(TEXT, TEXT) IS 'Helper to configure webhook URL and secret for notification triggers';

-- ===============================================
-- PART 4: TESTING & VERIFICATION
-- ===============================================

-- Function to manually test assessment notification webhook
-- Usage: SELECT test_assessment_notification('test@example.com', 'Test Company');
CREATE OR REPLACE FUNCTION test_assessment_notification(
  test_email TEXT DEFAULT 'test@example.com',
  test_company TEXT DEFAULT 'Test Company'
)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
  test_session_id TEXT;
  test_id UUID;
BEGIN
  -- Generate test data
  test_session_id := 'TEST_' || gen_random_uuid()::TEXT;
  test_id := gen_random_uuid();

  -- Insert test record (will trigger the notification)
  INSERT INTO assessment_sessions (
    id,
    session_id,
    user_email,
    company_name,
    overall_score,
    buyer_score,
    assessment_data,
    status
  ) VALUES (
    test_id,
    test_session_id,
    test_email,
    test_company,
    85,
    78,
    '{"test": true}'::jsonb,
    'completed_awaiting_signup'
  );

  RETURN 'Test assessment notification triggered. Check your email and logs. Test ID: ' || test_id::TEXT;
END;
$$;

-- Function to manually test waitlist notification webhook
-- Usage: SELECT test_waitlist_notification('Test User', 'test@example.com');
CREATE OR REPLACE FUNCTION test_waitlist_notification(
  test_name TEXT DEFAULT 'Test User',
  test_email TEXT DEFAULT 'test@example.com'
)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
  test_id UUID;
BEGIN
  -- Generate test ID
  test_id := gen_random_uuid();

  -- Insert test record (will trigger the notification)
  INSERT INTO beta_signups (
    id,
    full_name,
    email,
    company,
    job_title,
    product_description,
    referral_source,
    status
  ) VALUES (
    test_id,
    test_name,
    'test_' || gen_random_uuid()::TEXT || '@example.com', -- Unique email
    'Test Company',
    'Test Role',
    'This is a test product description for notification testing purposes.',
    'Manual test',
    'pending'
  );

  RETURN 'Test waitlist notification triggered. Check your email and logs. Test ID: ' || test_id::TEXT;
END;
$$;

COMMENT ON FUNCTION test_assessment_notification(TEXT, TEXT) IS 'Test function to verify assessment notification webhooks are working';
COMMENT ON FUNCTION test_waitlist_notification(TEXT, TEXT) IS 'Test function to verify waitlist notification webhooks are working';

-- ===============================================
-- POST-MIGRATION SETUP INSTRUCTIONS
-- ===============================================

-- After running this migration, complete these steps:
--
-- 1. Configure webhook settings (run from SQL editor in Supabase):
/*
SELECT set_webhook_config(
  'https://your-backend-url.onrender.com/api/webhooks',
  'your-webhook-secret-from-env'
);
*/
--
-- 2. Test the notifications:
/*
SELECT test_assessment_notification('geter@humusnshore.org', 'Test Company');
SELECT test_waitlist_notification('Test User', 'geter@humusnshore.org');
*/
--
-- 3. Check backend logs to verify webhooks are being received
--
-- 4. Verify emails are being sent to geter@humusnshore.org
--
-- ===============================================
