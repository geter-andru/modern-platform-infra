-- ===============================================
-- SEED ASSESSMENT SESSIONS
-- Date: 2025-11-11
-- Purpose: Populate assessment_sessions with test data
-- ===============================================

-- ============================================================================
-- SEED ASSESSMENT_SESSIONS
-- ============================================================================

INSERT INTO assessment_sessions (
  session_id,
  user_id,
  user_email,
  company_name,
  assessment_data,
  overall_score,
  buyer_score,
  status,
  created_at,
  updated_at
)
VALUES
  (
    'sess_geter_' || encode(gen_random_bytes(8), 'hex'),
    '85e54a00-d75b-420e-a3bb-ddd750fc548a',
    'geter@humusnshore.org',
    'Humus & Shore',
    '{
      "product_type": "B2B SaaS",
      "target_market": "Enterprise",
      "stage": "Growth",
      "completed_steps": ["intro", "market", "product", "revenue"],
      "completion_date": "2025-11-06T12:00:00Z"
    }'::jsonb,
    85,
    90,
    'completed_with_user',
    NOW() - INTERVAL '5 days',
    NOW()
  ),
  (
    'sess_brandon_' || encode(gen_random_bytes(8), 'hex'),
    '882f7ce8-ac8d-4dca-9704-c797e782acd0',
    'brandon.geter01@gmail.com',
    'Humus & Shore',
    '{
      "product_type": "B2B SaaS",
      "target_market": "SMB",
      "stage": "Seed",
      "completed_steps": ["intro", "market"],
      "completion_date": "2025-11-07T14:30:00Z"
    }'::jsonb,
    75,
    80,
    'completed_with_user',
    NOW() - INTERVAL '4 days',
    NOW()
  ),
  (
    'sess_dotun_' || encode(gen_random_bytes(8), 'hex'),
    '2492642c-8053-4558-8559-85dacd6daa30',
    'dotun@adesolarenergy.com',
    'Adesol Energy',
    '{
      "product_type": "Clean Energy",
      "target_market": "Commercial",
      "stage": "Series A",
      "completed_steps": ["intro", "market", "product"],
      "completion_date": "2025-11-08T10:15:00Z"
    }'::jsonb,
    92,
    88,
    'completed_with_user',
    NOW() - INTERVAL '3 days',
    NOW()
  ),
  (
    'sess_test_' || encode(gen_random_bytes(8), 'hex'),
    '3537b889-3148-4b07-a31b-ebbd1bb150a4',
    'test-migration@humusnshore.org',
    'Test Lab',
    '{
      "product_type": "Testing Tool",
      "target_market": "Developers",
      "stage": "MVP",
      "completed_steps": ["intro"],
      "completion_date": "2025-11-09T16:00:00Z"
    }'::jsonb,
    60,
    65,
    'completed_with_user',
    NOW() - INTERVAL '2 days',
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
  SELECT COUNT(*) INTO v_count FROM assessment_sessions;

  RAISE NOTICE '✅ Assessment sessions seeded: % rows', v_count;

  IF v_count < 4 THEN
    RAISE WARNING 'Expected 4 assessment_sessions, found %', v_count;
  END IF;
END $$;
