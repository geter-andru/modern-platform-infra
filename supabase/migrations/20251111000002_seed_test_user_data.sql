-- ===============================================
-- SEED TEST USER DATA
-- Date: 2025-11-11
-- Purpose: Populate empty tables with test data for existing users
-- ===============================================

-- ============================================================================
-- 1. SEED USER_ROLES
-- ============================================================================

-- Insert admin role for geter@humusnshore.org
INSERT INTO user_roles (user_id, role_name, granted_by, granted_at, is_active)
VALUES ('85e54a00-d75b-420e-a3bb-ddd750fc548a', 'admin', '85e54a00-d75b-420e-a3bb-ddd750fc548a', NOW(), true)
ON CONFLICT (user_id, role_name, is_active) DO NOTHING;

-- Insert user roles for other users
INSERT INTO user_roles (user_id, role_name, granted_by, granted_at, is_active)
VALUES
  ('882f7ce8-ac8d-4dca-9704-c797e782acd0', 'user', '85e54a00-d75b-420e-a3bb-ddd750fc548a', NOW(), true),
  ('2492642c-8053-4558-8559-85dacd6daa30', 'user', '85e54a00-d75b-420e-a3bb-ddd750fc548a', NOW(), true),
  ('3537b889-3148-4b07-a31b-ebbd1bb150a4', 'user', '85e54a00-d75b-420e-a3bb-ddd750fc548a', NOW(), true)
ON CONFLICT (user_id, role_name, is_active) DO NOTHING;

-- ============================================================================
-- 2. SEED USER_ACTIVITY_LOG
-- ============================================================================

INSERT INTO user_activity_log (user_id, activity_type, details, ip_address)
VALUES
  ('85e54a00-d75b-420e-a3bb-ddd750fc548a', 'login', '{"method": "google_oauth", "timestamp": "2025-11-11T12:00:00Z"}'::jsonb, '192.168.1.1'::inet),
  ('85e54a00-d75b-420e-a3bb-ddd750fc548a', 'profile_update', '{"fields_updated": ["full_name"]}'::jsonb, '192.168.1.1'::inet),
  ('882f7ce8-ac8d-4dca-9704-c797e782acd0', 'login', '{"method": "google_oauth"}'::jsonb, '192.168.1.2'::inet),
  ('2492642c-8053-4558-8559-85dacd6daa30', 'login', '{"method": "google_oauth"}'::jsonb, '192.168.1.3'::inet),
  ('3537b889-3148-4b07-a31b-ebbd1bb150a4', 'login', '{"method": "test_account"}'::jsonb, '127.0.0.1'::inet);

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- Verify the seed worked
DO $$
DECLARE
  v_user_roles_count INTEGER;
  v_activity_log_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_user_roles_count FROM user_roles;
  SELECT COUNT(*) INTO v_activity_log_count FROM user_activity_log;

  RAISE NOTICE '✅ Seed migration complete:';
  RAISE NOTICE '   - user_roles: % rows', v_user_roles_count;
  RAISE NOTICE '   - user_activity_log: % rows', v_activity_log_count;

  IF v_user_roles_count < 4 THEN
    RAISE WARNING 'Expected at least 4 user_roles, found %', v_user_roles_count;
  END IF;

  IF v_activity_log_count < 5 THEN
    RAISE WARNING 'Expected at least 5 activity_log entries, found %', v_activity_log_count;
  END IF;
END $$;
