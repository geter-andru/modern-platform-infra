-- ===============================================
-- SEED CUSTOMER PROFILES
-- Date: 2025-11-11
-- Purpose: Populate customer_profiles with test data
-- ===============================================

-- ============================================================================
-- SEED CUSTOMER_PROFILES
-- ============================================================================

INSERT INTO customer_profiles (
  customer_id,
  email,
  company_name,
  first_name,
  last_name,
  role,
  industry,
  company_size,
  annual_revenue_range,
  lifecycle_stage,
  subscription_tier,
  total_sessions,
  preferred_communication,
  timezone,
  created_at,
  updated_at
)
VALUES
  (
    '85e54a00-d75b-420e-a3bb-ddd750fc548a',
    'geter@humusnshore.org',
    'Humus & Shore',
    'Geter',
    NULL,
    'Founder',
    'Technology',
    '1-10',
    '$0-$100K',
    'active',
    'enterprise',
    5,
    'email',
    'America/New_York',
    NOW(),
    NOW()
  ),
  (
    '882f7ce8-ac8d-4dca-9704-c797e782acd0',
    'brandon.geter01@gmail.com',
    'Humus & Shore',
    'Brandon',
    'Geter',
    'Co-Founder',
    'Technology',
    '1-10',
    '$0-$100K',
    'trial',
    'professional',
    3,
    'email',
    'America/New_York',
    NOW(),
    NOW()
  ),
  (
    '2492642c-8053-4558-8559-85dacd6daa30',
    'dotun@adesolarenergy.com',
    'Adesol Energy',
    'Dotun',
    'Odewale',
    'Founder',
    'Renewable Energy',
    '11-50',
    '$500K-$1M',
    'active',
    'professional',
    2,
    'email',
    'America/Los_Angeles',
    NOW(),
    NOW()
  ),
  (
    '3537b889-3148-4b07-a31b-ebbd1bb150a4',
    'test-migration@humusnshore.org',
    'Test Lab',
    'Test',
    'User',
    'Tester',
    'Testing',
    '1-10',
    '$0-$100K',
    'trial',
    'basic',
    1,
    'email',
    'America/New_York',
    NOW(),
    NOW()
  )
ON CONFLICT (customer_id) DO NOTHING;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
DECLARE
  v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count FROM customer_profiles;

  RAISE NOTICE '✅ Customer profiles seeded: % rows', v_count;

  IF v_count < 4 THEN
    RAISE WARNING 'Expected 4 customer_profiles, found %', v_count;
  END IF;
END $$;
