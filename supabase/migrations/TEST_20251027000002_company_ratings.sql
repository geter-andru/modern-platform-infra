-- ===============================================
-- TEST SUITE FOR COMPANY_RATINGS TABLE
-- Migration: 20251027000002_create_company_ratings_table.sql
-- Total Tests: 12 (All must pass before proceeding)
-- ===============================================

-- ===============================================
-- TEST 1.2.1: Table exists
-- ===============================================
SELECT
  table_name,
  table_type,
  CASE
    WHEN table_name = 'company_ratings' AND table_type = 'BASE TABLE'
    THEN '✅ PASS'
    ELSE '❌ FAIL'
  END as test_result
FROM information_schema.tables
WHERE table_name = 'company_ratings';

-- Expected: 1 row, test_result = '✅ PASS'


-- ===============================================
-- TEST 1.2.2: All columns exist with correct types
-- ===============================================
SELECT
  column_name,
  data_type,
  is_nullable,
  CASE
    WHEN column_name = 'id' AND data_type = 'uuid' THEN '✅'
    WHEN column_name = 'user_id' AND data_type = 'uuid' AND is_nullable = 'NO' THEN '✅'
    WHEN column_name = 'icp_framework_id' AND data_type = 'uuid' AND is_nullable = 'YES' THEN '✅'
    WHEN column_name = 'company_url' AND data_type = 'text' AND is_nullable = 'NO' THEN '✅'
    WHEN column_name = 'company_name' AND data_type = 'text' AND is_nullable = 'YES' THEN '✅'
    WHEN column_name = 'rating' AND data_type = 'integer' AND is_nullable = 'NO' THEN '✅'
    WHEN column_name = 'reasoning' AND data_type = 'text' AND is_nullable = 'NO' THEN '✅'
    WHEN column_name = 'company_data' AND data_type = 'jsonb' THEN '✅'
    WHEN column_name = 'rating_version' AND data_type = 'text' THEN '✅'
    WHEN column_name = 'created_at' AND data_type = 'timestamp with time zone' THEN '✅'
    WHEN column_name = 'updated_at' AND data_type = 'timestamp with time zone' THEN '✅'
    ELSE '❌'
  END as test_result
FROM information_schema.columns
WHERE table_name = 'company_ratings'
ORDER BY ordinal_position;

-- Expected: 11 rows, all with test_result = '✅'
-- Verify: All TEXT (not VARCHAR), all TIMESTAMPTZ


-- ===============================================
-- TEST 1.2.3: CHECK constraint - rating bounds
-- ===============================================

-- Test negative rating (should FAIL)
DO $$
BEGIN
  BEGIN
    INSERT INTO company_ratings (user_id, company_url, rating, reasoning)
    VALUES (
      (SELECT id FROM auth.users LIMIT 1),
      'https://test.com',
      -1,
      'Test reasoning'
    );
    RAISE EXCEPTION '❌ FAIL - Negative rating was allowed';
  EXCEPTION WHEN check_violation THEN
    RAISE NOTICE '✅ PASS - Negative rating rejected';
  END;
END $$;

-- Test rating > 100 (should FAIL)
DO $$
BEGIN
  BEGIN
    INSERT INTO company_ratings (user_id, company_url, rating, reasoning)
    VALUES (
      (SELECT id FROM auth.users LIMIT 1),
      'https://test.com',
      101,
      'Test reasoning'
    );
    RAISE EXCEPTION '❌ FAIL - Rating >100 was allowed';
  EXCEPTION WHEN check_violation THEN
    RAISE NOTICE '✅ PASS - Rating >100 rejected';
  END;
END $$;

-- Test valid rating (should SUCCEED)
DO $$
DECLARE
  test_user_id UUID;
  test_rating_id UUID;
BEGIN
  SELECT id INTO test_user_id FROM auth.users LIMIT 1;

  INSERT INTO company_ratings (user_id, company_url, rating, reasoning)
  VALUES (test_user_id, 'https://test-valid.com', 75, 'Valid test reasoning')
  RETURNING id INTO test_rating_id;

  RAISE NOTICE '✅ PASS - Valid rating accepted, ID: %', test_rating_id;

  -- Cleanup
  DELETE FROM company_ratings WHERE id = test_rating_id;
END $$;


-- ===============================================
-- TEST 1.2.4: CHECK constraint - valid URL
-- ===============================================

-- Test invalid URL (should FAIL)
DO $$
BEGIN
  BEGIN
    INSERT INTO company_ratings (user_id, company_url, rating, reasoning)
    VALUES (
      (SELECT id FROM auth.users LIMIT 1),
      'not-a-url',
      50,
      'Test reasoning'
    );
    RAISE EXCEPTION '❌ FAIL - Invalid URL was allowed';
  EXCEPTION WHEN check_violation THEN
    RAISE NOTICE '✅ PASS - Invalid URL rejected';
  END;
END $$;

-- Test valid http URL (should SUCCEED)
DO $$
DECLARE
  test_id UUID;
BEGIN
  INSERT INTO company_ratings (user_id, company_url, rating, reasoning)
  VALUES (
    (SELECT id FROM auth.users LIMIT 1),
    'http://test.com',
    50,
    'Test reasoning'
  )
  RETURNING id INTO test_id;

  RAISE NOTICE '✅ PASS - HTTP URL accepted';
  DELETE FROM company_ratings WHERE id = test_id;
END $$;

-- Test valid https URL (should SUCCEED)
DO $$
DECLARE
  test_id UUID;
BEGIN
  INSERT INTO company_ratings (user_id, company_url, rating, reasoning)
  VALUES (
    (SELECT id FROM auth.users LIMIT 1),
    'https://test.com',
    50,
    'Test reasoning'
  )
  RETURNING id INTO test_id;

  RAISE NOTICE '✅ PASS - HTTPS URL accepted';
  DELETE FROM company_ratings WHERE id = test_id;
END $$;


-- ===============================================
-- TEST 1.2.5: Foreign key to icp_frameworks
-- ===============================================

-- Test NULL framework (should SUCCEED)
DO $$
DECLARE
  test_id UUID;
BEGIN
  INSERT INTO company_ratings (user_id, icp_framework_id, company_url, rating, reasoning)
  VALUES (
    (SELECT id FROM auth.users LIMIT 1),
    NULL,
    'https://test-null-fk.com',
    80,
    'Test reasoning'
  )
  RETURNING id INTO test_id;

  RAISE NOTICE '✅ PASS - NULL framework accepted';
  DELETE FROM company_ratings WHERE id = test_id;
END $$;

-- Test invalid framework ID (should FAIL)
DO $$
BEGIN
  BEGIN
    INSERT INTO company_ratings (user_id, icp_framework_id, company_url, rating, reasoning)
    VALUES (
      (SELECT id FROM auth.users LIMIT 1),
      '00000000-0000-0000-0000-000000000000',
      'https://test.com',
      80,
      'Test reasoning'
    );
    RAISE EXCEPTION '❌ FAIL - Invalid framework ID was allowed';
  EXCEPTION WHEN foreign_key_violation THEN
    RAISE NOTICE '✅ PASS - Invalid framework ID rejected';
  END;
END $$;


-- ===============================================
-- TEST 1.2.6: Indexes exist (8 indexes)
-- ===============================================
SELECT
  indexname,
  CASE
    WHEN indexname LIKE '%pkey' THEN '✅ Primary Key'
    WHEN indexname LIKE '%user_id' THEN '✅ User ID index'
    WHEN indexname LIKE '%framework' THEN '✅ Framework index'
    WHEN indexname LIKE '%url' THEN '✅ URL index'
    WHEN indexname LIKE '%rating' THEN '✅ Rating index'
    WHEN indexname LIKE '%created_at' THEN '✅ Created At index'
    WHEN indexname LIKE '%data_gin' THEN '✅ JSONB GIN index'
    WHEN indexname LIKE '%name_fts' THEN '✅ Full-text search index'
    ELSE '⚠️ Unknown index'
  END as index_type
FROM pg_indexes
WHERE tablename = 'company_ratings'
ORDER BY indexname;

-- Expected: 8 indexes
-- company_ratings_pkey
-- idx_company_ratings_created_at
-- idx_company_ratings_data_gin
-- idx_company_ratings_framework
-- idx_company_ratings_name_fts
-- idx_company_ratings_rating
-- idx_company_ratings_url
-- idx_company_ratings_user_id


-- ===============================================
-- TEST 1.2.7: Full-text search works
-- ===============================================

-- Insert test data
DO $$
DECLARE
  test_user_id UUID;
  test_id_1 UUID;
  test_id_2 UUID;
BEGIN
  SELECT id INTO test_user_id FROM auth.users LIMIT 1;

  INSERT INTO company_ratings (user_id, company_url, company_name, rating, reasoning)
  VALUES (test_user_id, 'https://acme.com', 'Acme Corporation', 85, 'Good fit test')
  RETURNING id INTO test_id_1;

  INSERT INTO company_ratings (user_id, company_url, company_name, rating, reasoning)
  VALUES (test_user_id, 'https://techco.com', 'TechCo Innovations', 70, 'Moderate fit test')
  RETURNING id INTO test_id_2;

  -- Test full-text search
  IF EXISTS (
    SELECT 1 FROM company_ratings
    WHERE to_tsvector('english', company_name) @@ to_tsquery('english', 'Acme')
      AND id = test_id_1
  ) THEN
    RAISE NOTICE '✅ PASS - Full-text search works';
  ELSE
    RAISE EXCEPTION '❌ FAIL - Full-text search failed';
  END IF;

  -- Cleanup
  DELETE FROM company_ratings WHERE id IN (test_id_1, test_id_2);
END $$;


-- ===============================================
-- TEST 1.2.8: RLS policies exist (4 policies)
-- ===============================================
SELECT
  policyname,
  cmd,
  CASE
    WHEN cmd = 'SELECT' THEN '✅ View policy'
    WHEN cmd = 'INSERT' THEN '✅ Insert policy'
    WHEN cmd = 'UPDATE' THEN '✅ Update policy'
    WHEN cmd = 'DELETE' THEN '✅ Delete policy'
    ELSE '❌ Unknown'
  END as test_result
FROM pg_policies
WHERE tablename = 'company_ratings'
ORDER BY cmd;

-- Expected: 4 rows (DELETE, INSERT, SELECT, UPDATE)


-- ===============================================
-- TEST 1.2.9: RLS enabled
-- ===============================================
SELECT
  tablename,
  rowsecurity,
  CASE
    WHEN rowsecurity = true THEN '✅ PASS - RLS enabled'
    ELSE '❌ FAIL - RLS not enabled'
  END as test_result
FROM pg_tables
WHERE tablename = 'company_ratings';

-- Expected: rowsecurity = true


-- ===============================================
-- TEST 1.2.10: Trigger works (updated_at)
-- ===============================================
DO $$
DECLARE
  test_id UUID;
  created_time TIMESTAMPTZ;
  updated_time TIMESTAMPTZ;
BEGIN
  -- Insert test record
  INSERT INTO company_ratings (user_id, company_url, rating, reasoning)
  VALUES (
    (SELECT id FROM auth.users LIMIT 1),
    'https://trigger-test.com',
    75,
    'Trigger test reasoning'
  )
  RETURNING id, created_at INTO test_id, created_time;

  -- Wait 2 seconds
  PERFORM pg_sleep(2);

  -- Update record
  UPDATE company_ratings
  SET rating = 90
  WHERE id = test_id
  RETURNING updated_at INTO updated_time;

  -- Check trigger worked
  IF updated_time > created_time THEN
    RAISE NOTICE '✅ PASS - Trigger updated timestamp (created: %, updated: %)', created_time, updated_time;
  ELSE
    RAISE EXCEPTION '❌ FAIL - Trigger did not update timestamp';
  END IF;

  -- Cleanup
  DELETE FROM company_ratings WHERE id = test_id;
END $$;


-- ===============================================
-- TEST 1.2.11: Realtime enabled
-- ===============================================
SELECT
  tablename,
  CASE
    WHEN tablename = 'company_ratings' THEN '✅ PASS - Realtime enabled'
    ELSE '❌ FAIL'
  END as test_result
FROM pg_publication_tables
WHERE pubname = 'supabase_realtime'
  AND tablename = 'company_ratings';

-- Expected: 1 row with test_result = '✅ PASS'


-- ===============================================
-- TEST 1.2.12: ON DELETE SET NULL works
-- ===============================================
DO $$
DECLARE
  test_user_id UUID;
  test_framework_id UUID;
  test_rating_id UUID;
  framework_id_after_delete UUID;
BEGIN
  SELECT id INTO test_user_id FROM auth.users LIMIT 1;

  -- Create test framework
  INSERT INTO icp_frameworks (user_id, product_name, product_description, framework)
  VALUES (test_user_id, 'Test Product FK', 'Test Description', '{}'::jsonb)
  RETURNING id INTO test_framework_id;

  -- Create rating linked to framework
  INSERT INTO company_ratings (user_id, icp_framework_id, company_url, rating, reasoning)
  VALUES (test_user_id, test_framework_id, 'https://fk-test.com', 75, 'FK test reasoning')
  RETURNING id INTO test_rating_id;

  -- Delete framework
  DELETE FROM icp_frameworks WHERE id = test_framework_id;

  -- Check rating still exists with NULL framework
  SELECT icp_framework_id INTO framework_id_after_delete
  FROM company_ratings WHERE id = test_rating_id;

  IF framework_id_after_delete IS NULL THEN
    RAISE NOTICE '✅ PASS - ON DELETE SET NULL worked (rating preserved, framework NULL)';
  ELSE
    RAISE EXCEPTION '❌ FAIL - Framework should be NULL after deletion';
  END IF;

  -- Cleanup
  DELETE FROM company_ratings WHERE id = test_rating_id;
END $$;


-- ===============================================
-- TEST SUMMARY CHECKLIST
-- ===============================================

-- [ ] Test 1.2.1:  Table exists
-- [ ] Test 1.2.2:  All columns with correct types
-- [ ] Test 1.2.3:  Rating bounds constraint
-- [ ] Test 1.2.4:  URL validation constraint
-- [ ] Test 1.2.5:  Foreign key behavior
-- [ ] Test 1.2.6:  Indexes exist (8 total)
-- [ ] Test 1.2.7:  Full-text search works
-- [ ] Test 1.2.8:  RLS policies exist (4 total)
-- [ ] Test 1.2.9:  RLS enabled
-- [ ] Test 1.2.10: Trigger updates timestamp
-- [ ] Test 1.2.11: Realtime enabled
-- [ ] Test 1.2.12: ON DELETE SET NULL works

-- ===============================================
-- ACCEPTANCE CRITERIA
-- ===============================================
-- ✅ All 12 tests pass
-- ✅ Constraints prevent invalid data
-- ✅ Foreign keys enforce referential integrity
-- ✅ Full-text search works
-- ✅ RLS isolates user data
-- ✅ Realtime enabled
-- ✅ Trigger auto-updates timestamps
-- ✅ Follows SUPABASE_SCHEMA_SYNTAX_REFERENCE.md

-- Only proceed to Chunk 3 when ALL tests pass ✅
