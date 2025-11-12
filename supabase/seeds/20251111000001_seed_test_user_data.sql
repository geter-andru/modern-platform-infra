-- ===============================================
-- SEED TEST USER DATA
-- Date: 2025-11-11
-- Purpose: Populate empty tables with test data for existing users
-- Reference: Actual database schemas from information_schema
-- ===============================================

-- ============================================================================
-- 1. SEED USER_ROLES
-- ============================================================================

INSERT INTO user_roles (user_id, role_name, granted_by, granted_at, is_active)
VALUES
  ('85e54a00-d75b-420e-a3bb-ddd750fc548a', 'admin', '85e54a00-d75b-420e-a3bb-ddd750fc548a', NOW(), true),
  ('882f7ce8-ac8d-4dca-9704-c797e782acd0', 'user', '85e54a00-d75b-420e-a3bb-ddd750fc548a', NOW(), true),
  ('2492642c-8053-4558-8559-85dacd6daa30', 'user', '85e54a00-d75b-420e-a3bb-ddd750fc548a', NOW(), true),
  ('3537b889-3148-4b07-a31b-ebbd1bb150a4', 'user', '85e54a00-d75b-420e-a3bb-ddd750fc548a', NOW(), true)
ON CONFLICT (user_id, role_name) DO NOTHING;

-- ============================================================================
-- 2. SEED USER_ACTIVITY_LOG (Simple activity logs)
-- ============================================================================

INSERT INTO user_activity_log (user_id, activity_type, details, ip_address)
VALUES
  ('85e54a00-d75b-420e-a3bb-ddd750fc548a', 'login', '{"method": "google_oauth", "timestamp": "2025-11-11T12:00:00Z"}'::jsonb, '192.168.1.1'::inet),
  ('85e54a00-d75b-420e-a3bb-ddd750fc548a', 'profile_update', '{"fields_updated": ["full_name"]}'::jsonb, '192.168.1.1'::inet),
  ('882f7ce8-ac8d-4dca-9704-c797e782acd0', 'login', '{"method": "google_oauth"}'::jsonb, '192.168.1.2'::inet),
  ('2492642c-8053-4558-8559-85dacd6daa30', 'login', '{"method": "google_oauth"}'::jsonb, '192.168.1.3'::inet),
  ('3537b889-3148-4b07-a31b-ebbd1bb150a4', 'login', '{"method": "test_account"}'::jsonb, '127.0.0.1'::inet)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 3. SEED COMPLETE - SIMPLIFIED VERSION
-- ============================================================================
-- Note: Only seeding user_roles and user_activity_log
-- Other tables have complex schemas requiring organization_ids, session_ids, etc.
-- that should be populated through application logic rather than direct SQL inserts

-- Verify seed data
DO $$
DECLARE
  v_user_roles_count INTEGER;
  v_activity_log_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_user_roles_count FROM user_roles;
  SELECT COUNT(*) INTO v_activity_log_count FROM user_activity_log;

  RAISE NOTICE '✅ Seed complete:';
  RAISE NOTICE '  - user_roles: % rows', v_user_roles_count;
  RAISE NOTICE '  - user_activity_log: % rows', v_activity_log_count;
END $$;
