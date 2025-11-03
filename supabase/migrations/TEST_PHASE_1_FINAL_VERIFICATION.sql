-- ===============================================
-- PHASE 1 FINAL VERIFICATION TESTS
-- Integration tests across all Phase 1 chunks
-- Total Tests: 3 (All must pass before Phase 2)
-- ===============================================

-- PREREQUISITES:
-- ✅ Chunk 1 complete (buyer_personas table)
-- ✅ Chunk 2 complete (company_ratings table)
-- ✅ Chunk 3 complete (performance indexes)

-- ===============================================
-- TEST 1.F.1: Cross-table foreign key integrity
-- ===============================================

DO $$
DECLARE
  test_user_id UUID;
  test_framework_id UUID;
  test_personas_id UUID;
  test_rating_id UUID;
  framework_id_after_delete UUID;
BEGIN
  -- Get test user
  SELECT id INTO test_user_id FROM auth.users LIMIT 1;

  RAISE NOTICE 'Starting cross-table integrity test...';

  -- Create ICP framework
  INSERT INTO icp_frameworks (user_id, product_name, product_description, framework)
  VALUES (test_user_id, 'Integration Test Product', 'Test Description', '{}'::jsonb)
  RETURNING id INTO test_framework_id;
  RAISE NOTICE '1. Created framework: %', test_framework_id;

  -- Create buyer personas
  INSERT INTO buyer_personas (user_id, personas, company_context, industry)
  VALUES (
    test_user_id,
    '[{"title":"CEO Test"}]'::jsonb,
    'Integration test context',
    'Technology'
  )
  RETURNING id INTO test_personas_id;
  RAISE NOTICE '2. Created personas: %', test_personas_id;

  -- Create company rating linked to framework
  INSERT INTO company_ratings (user_id, icp_framework_id, company_url, rating, reasoning)
  VALUES (
    test_user_id,
    test_framework_id,
    'https://integration-test.com',
    85,
    'Integration test reasoning for cross-table FK'
  )
  RETURNING id INTO test_rating_id;
  RAISE NOTICE '3. Created rating: %', test_rating_id;

  -- Delete framework
  DELETE FROM icp_frameworks WHERE id = test_framework_id;
  RAISE NOTICE '4. Deleted framework';

  -- Check rating still exists with NULL framework (ON DELETE SET NULL)
  SELECT icp_framework_id INTO framework_id_after_delete
  FROM company_ratings WHERE id = test_rating_id;

  IF framework_id_after_delete IS NULL THEN
    RAISE NOTICE '5. ✅ PASS - Rating survived deletion, framework set to NULL';
  ELSE
    RAISE EXCEPTION '❌ FAIL - Framework should be NULL after deletion';
  END IF;

  -- Check personas still exists (independent of framework)
  IF EXISTS (SELECT 1 FROM buyer_personas WHERE id = test_personas_id) THEN
    RAISE NOTICE '6. ✅ PASS - Personas survived (independent table)';
  ELSE
    RAISE EXCEPTION '❌ FAIL - Personas should still exist';
  END IF;

  -- Cleanup
  DELETE FROM company_ratings WHERE id = test_rating_id;
  DELETE FROM buyer_personas WHERE id = test_personas_id;
  RAISE NOTICE '7. Cleanup complete';

  RAISE NOTICE '=== TEST 1.F.1: ✅ PASS ===';
END $$;


-- ===============================================
-- TEST 1.F.2: RLS cross-table verification
-- ===============================================

-- NOTE: This test requires two separate auth contexts
-- Cannot be fully tested in SQL Editor (requires auth tokens)

-- Manual verification steps:
-- 1. User A: Create framework, personas, rating
-- 2. User B: Try to JOIN and access User A's data
-- 3. Expected: User B sees 0 rows (RLS blocks at all tables)

-- Automated partial test (same-user join should work):
DO $$
DECLARE
  test_user_id UUID;
  test_framework_id UUID;
  test_rating_id UUID;
  join_count INTEGER;
BEGIN
  SELECT id INTO test_user_id FROM auth.users LIMIT 1;

  -- Create test data
  INSERT INTO icp_frameworks (user_id, product_name, product_description, framework)
  VALUES (test_user_id, 'RLS Test Product', 'RLS Test', '{}'::jsonb)
  RETURNING id INTO test_framework_id;

  INSERT INTO company_ratings (user_id, icp_framework_id, company_url, rating, reasoning)
  VALUES (test_user_id, test_framework_id, 'https://rls-test.com', 75, 'RLS test reasoning')
  RETURNING id INTO test_rating_id;

  -- Test JOIN within same user (should work)
  SELECT count(*) INTO join_count
  FROM company_ratings r
  LEFT JOIN icp_frameworks f ON r.icp_framework_id = f.id
  WHERE r.user_id = test_user_id AND f.user_id = test_user_id;

  IF join_count > 0 THEN
    RAISE NOTICE '✅ PASS - Same-user JOIN works (found % rows)', join_count;
  ELSE
    RAISE EXCEPTION '❌ FAIL - Same-user JOIN should return data';
  END IF;

  -- Cleanup
  DELETE FROM company_ratings WHERE id = test_rating_id;
  DELETE FROM icp_frameworks WHERE id = test_framework_id;

  RAISE NOTICE '=== TEST 1.F.2: ⚠️ PARTIAL PASS (full test requires multi-user auth) ===';
END $$;


-- ===============================================
-- TEST 1.F.3: Performance test (bulk data)
-- ===============================================

DO $$
DECLARE
  test_user_id UUID;
  framework_id UUID;
  start_time TIMESTAMP;
  end_time TIMESTAMP;
  duration_ms INTEGER;
BEGIN
  SELECT id INTO test_user_id FROM auth.users LIMIT 1;

  RAISE NOTICE 'Starting performance test...';

  -- Ensure we have enough data (at least 10 frameworks)
  FOR i IN 1..10 LOOP
    INSERT INTO icp_frameworks (user_id, product_name, product_description, framework)
    VALUES (
      test_user_id,
      'Performance Test Product ' || i,
      'Test product for performance benchmarking',
      jsonb_build_object(
        'buyerPersonas', jsonb_build_array(
          jsonb_build_object('title', 'CEO', 'level', 'C-Suite')
        )
      )
    );
  END LOOP;

  RAISE NOTICE 'Created 10 test frameworks';

  -- Run ANALYZE to update statistics
  ANALYZE icp_frameworks;

  -- Performance test: Query with JSONB filter
  start_time := clock_timestamp();

  SELECT id INTO framework_id
  FROM icp_frameworks
  WHERE user_id = test_user_id
    AND framework @> '{"buyerPersonas": [{"title": "CEO"}]}'::jsonb
  LIMIT 1;

  end_time := clock_timestamp();
  duration_ms := EXTRACT(MILLISECONDS FROM (end_time - start_time))::INTEGER;

  RAISE NOTICE 'Query completed in % ms', duration_ms;

  IF duration_ms < 100 THEN
    RAISE NOTICE '✅ PASS - Query performance excellent (< 100ms)';
  ELSIF duration_ms < 500 THEN
    RAISE NOTICE '⚠️ WARNING - Query performance acceptable but slow (100-500ms)';
  ELSE
    RAISE NOTICE '❌ FAIL - Query performance poor (> 500ms) - check indexes';
  END IF;

  -- Cleanup
  DELETE FROM icp_frameworks
  WHERE user_id = test_user_id
    AND product_name LIKE 'Performance Test Product%';

  RAISE NOTICE '=== TEST 1.F.3: Performance benchmark complete ===';
END $$;


-- ===============================================
-- COMPREHENSIVE SCHEMA VALIDATION
-- ===============================================

SELECT
  table_name,
  (SELECT count(*) FROM pg_indexes WHERE tablename = table_name) as index_count,
  (SELECT count(*) FROM pg_policies WHERE tablename = table_name) as policy_count,
  (SELECT rowsecurity FROM pg_tables WHERE tablename = table_name) as rls_enabled,
  CASE
    WHEN table_name = 'buyer_personas' AND
         (SELECT count(*) FROM pg_indexes WHERE tablename = table_name) >= 5 AND
         (SELECT count(*) FROM pg_policies WHERE tablename = table_name) = 4 AND
         (SELECT rowsecurity FROM pg_tables WHERE tablename = table_name) = true
    THEN '✅ VALID'
    WHEN table_name = 'company_ratings' AND
         (SELECT count(*) FROM pg_indexes WHERE tablename = table_name) >= 8 AND
         (SELECT count(*) FROM pg_policies WHERE tablename = table_name) = 4 AND
         (SELECT rowsecurity FROM pg_tables WHERE tablename = table_name) = true
    THEN '✅ VALID'
    WHEN table_name = 'icp_frameworks' AND
         (SELECT count(*) FROM pg_indexes WHERE tablename = table_name) >= 6 AND
         (SELECT rowsecurity FROM pg_tables WHERE tablename = table_name) = true
    THEN '✅ VALID'
    WHEN table_name = 'company_research' AND
         (SELECT count(*) FROM pg_indexes WHERE tablename = table_name) >= 5 AND
         (SELECT rowsecurity FROM pg_tables WHERE tablename = table_name) = true
    THEN '✅ VALID'
    ELSE '❌ INVALID'
  END as validation_status
FROM information_schema.tables
WHERE table_name IN ('buyer_personas', 'company_ratings', 'icp_frameworks', 'company_research')
  AND table_schema = 'public'
ORDER BY table_name;

-- Expected: All tables show '✅ VALID'


-- ===============================================
-- REALTIME VERIFICATION
-- ===============================================

SELECT
  tablename,
  CASE
    WHEN tablename IN ('buyer_personas', 'company_ratings') THEN '✅ Should be enabled'
    ELSE '⚠️ Optional'
  END as realtime_required,
  CASE
    WHEN EXISTS (
      SELECT 1 FROM pg_publication_tables
      WHERE pubname = 'supabase_realtime'
        AND tablename = t.tablename
    ) THEN '✅ Enabled'
    ELSE '❌ Not enabled'
  END as realtime_status
FROM (
  SELECT 'buyer_personas' as tablename
  UNION ALL SELECT 'company_ratings'
  UNION ALL SELECT 'icp_frameworks'
  UNION ALL SELECT 'company_research'
) t
ORDER BY tablename;

-- Expected: buyer_personas and company_ratings both show '✅ Enabled'


-- ===============================================
-- PHASE 1 ACCEPTANCE CRITERIA
-- ===============================================

/*
ALL must pass before proceeding to Phase 2:

✅ buyer_personas table fully functional
✅ company_ratings table fully functional
✅ All indexes created with IF NOT EXISTS
✅ All indexes used by query planner (or justified Seq Scan)
✅ RLS policies isolate user data perfectly
✅ Foreign keys enforce referential integrity with correct ON DELETE
✅ CHECK constraints prevent invalid data
✅ Triggers update timestamps correctly
✅ Realtime enabled for both new tables
✅ Permissions granted to authenticated role
✅ Performance benchmarks met (< 100ms indexed queries)
✅ Integration tests pass
✅ Zero errors in Supabase logs
✅ 100% compliance with SUPABASE_SCHEMA_SYNTAX_REFERENCE.md
*/


-- ===============================================
-- FINAL CHECKLIST
-- ===============================================

/*
[ ] TEST 1.F.1: Cross-table foreign key integrity ✅
[ ] TEST 1.F.2: RLS cross-table verification (partial ⚠️, full test manual)
[ ] TEST 1.F.3: Performance test (< 100ms) ✅
[ ] Comprehensive schema validation (all tables ✅ VALID)
[ ] Realtime verification (buyer_personas & company_ratings enabled)

If ALL tests pass: ✅ PHASE 1 COMPLETE - Ready for Phase 2
*/
