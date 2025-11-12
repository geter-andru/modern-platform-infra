-- ===============================================
-- SEED CUSTOMER SESSIONS
-- Date: 2025-11-11
-- Purpose: Populate customer_sessions with test data
-- ===============================================

-- ============================================================================
-- SEED CUSTOMER_SESSIONS
-- ============================================================================

INSERT INTO customer_sessions (
  customer_id,
  session_id,
  pipeline_status,
  current_step,
  progress_data,
  error_count,
  last_error,
  expires_at,
  created_at,
  updated_at
)
VALUES
  (
    '85e54a00-d75b-420e-a3bb-ddd750fc548a',
    'cs_' || encode(gen_random_bytes(16), 'hex'),
    'complete',
    'dashboard',
    '{
      "steps_completed": ["onboarding", "assessment", "payment"],
      "current_page": "/dashboard",
      "last_activity": "2025-11-11T12:00:00Z",
      "session_duration_minutes": 45
    }'::jsonb,
    0,
    NULL,
    NOW() + INTERVAL '7 days',
    NOW() - INTERVAL '1 hour',
    NOW()
  ),
  (
    '882f7ce8-ac8d-4dca-9704-c797e782acd0',
    'cs_' || encode(gen_random_bytes(16), 'hex'),
    'generating_calculator',
    'assessment',
    '{
      "steps_completed": ["onboarding"],
      "current_page": "/assessment",
      "last_activity": "2025-11-11T11:00:00Z",
      "session_duration_minutes": 20
    }'::jsonb,
    0,
    NULL,
    NOW() + INTERVAL '7 days',
    NOW() - INTERVAL '2 hours',
    NOW()
  ),
  (
    '2492642c-8053-4558-8559-85dacd6daa30',
    'cs_' || encode(gen_random_bytes(16), 'hex'),
    'generating_icp',
    'icp_builder',
    '{
      "steps_completed": ["onboarding", "assessment"],
      "current_page": "/icp-builder",
      "last_activity": "2025-11-11T10:00:00Z",
      "session_duration_minutes": 30
    }'::jsonb,
    0,
    NULL,
    NOW() + INTERVAL '7 days',
    NOW() - INTERVAL '3 hours',
    NOW()
  ),
  (
    '3537b889-3148-4b07-a31b-ebbd1bb150a4',
    'cs_' || encode(gen_random_bytes(16), 'hex'),
    'pending',
    'onboarding',
    '{
      "steps_completed": [],
      "current_page": "/welcome",
      "last_activity": "2025-11-11T09:00:00Z",
      "session_duration_minutes": 5
    }'::jsonb,
    0,
    NULL,
    NOW() + INTERVAL '1 day',
    NOW() - INTERVAL '4 hours',
    NOW()
  )
ON CONFLICT (session_id) DO NOTHING;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
DECLARE
  v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count FROM customer_sessions;

  RAISE NOTICE '✅ Customer sessions seeded: % rows', v_count;

  IF v_count < 4 THEN
    RAISE WARNING 'Expected 4 customer_sessions, found %', v_count;
  END IF;
END $$;
