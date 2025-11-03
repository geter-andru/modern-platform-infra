-- ===============================================
-- TEST SUITE FOR BUYER_PERSONAS TABLE
-- Migration: 20251027000001_create_buyer_personas_table.sql
-- Total Tests: 12 (All must pass before proceeding)
-- ===============================================

-- INSTRUCTIONS:
-- 1. Apply main migration first: 20251027000001_create_buyer_personas_table.sql
-- 2. Run each test below in Supabase SQL Editor
-- 3. Verify "Expected" result matches actual result
-- 4. If any test fails, use RCA protocol before proceeding

-- ===============================================
-- TEST 1.1.1: Table exists
-- ===============================================
SELECT
  table_name,
  table_type,
  CASE
    WHEN table_name = 'buyer_personas' AND table_type = 'BASE TABLE'
    THEN '✅ PASS'
    ELSE '❌ FAIL'
  END as test_result
FROM information_schema.tables
WHERE table_name = 'buyer_personas';

-- Expected: 1 row returned
-- table_name = 'buyer_personas'
-- table_type = 'BASE TABLE'
-- test_result = '✅ PASS'


-- ===============================================
-- TEST 1.1.2: All columns exist with correct types
-- ===============================================
SELECT
  column_name,
  data_type,
  is_nullable,
  column_default,
  CASE
    WHEN column_name = 'id' AND data_type = 'uuid' AND is_nullable = 'NO' THEN '✅'
    WHEN column_name = 'user_id' AND data_type = 'uuid' AND is_nullable = 'NO' THEN '✅'
    WHEN column_name = 'personas' AND data_type = 'jsonb' AND is_nullable = 'NO' THEN '✅'
    WHEN column_name = 'company_context' AND data_type = 'text' AND is_nullable = 'YES' THEN '✅'
    WHEN column_name = 'industry' AND data_type = 'text' AND is_nullable = 'YES' THEN '✅'
    WHEN column_name = 'target_market' AND data_type = 'text' AND is_nullable = 'YES' THEN '✅'
    WHEN column_name = 'created_at' AND data_type = 'timestamp with time zone' THEN '✅'
    WHEN column_name = 'updated_at' AND data_type = 'timestamp with time zone' THEN '✅'
    ELSE '❌'
  END as test_result
FROM information_schema.columns
WHERE table_name = 'buyer_personas'
ORDER BY ordinal_position;

-- Expected: 8 rows with all test_result = '✅'
-- Verify: created_at and updated_at are 'timestamp with time zone' (TIMESTAMPTZ)
-- Verify: company_context, industry, target_market are 'text' (not varchar)
-- Verify: personas is 'jsonb' and NOT NULL


-- ===============================================
-- TEST 1.1.3: Constraints exist
-- ===============================================
SELECT
  constraint_name,
  constraint_type,
  CASE
    WHEN constraint_type IN ('PRIMARY KEY', 'FOREIGN KEY', 'CHECK') THEN '✅'
    ELSE '❌'
  END as test_result
FROM information_schema.table_constraints
WHERE table_name = 'buyer_personas'
ORDER BY constraint_type, constraint_name;

-- Expected: At least 4 constraints
-- 1. PRIMARY KEY (buyer_personas_pkey or similar)
-- 2. FOREIGN KEY (buyer_personas_user_id_fkey or similar)
-- 3. CHECK (personas_not_empty)
-- 4. CHECK (valid_industry)


-- ===============================================
-- TEST 1.1.4: Indexes exist
-- ===============================================
SELECT
  indexname,
  CASE
    WHEN indexname LIKE '%pkey' THEN '✅ Primary Key'
    WHEN indexname LIKE '%user_id' THEN '✅ User ID index'
    WHEN indexname LIKE '%industry' THEN '✅ Industry index'
    WHEN indexname LIKE '%created_at' THEN '✅ Created At index'
    WHEN indexname LIKE '%personas_gin' THEN '✅ JSONB GIN index'
    ELSE '⚠️ Unknown index'
  END as index_type
FROM pg_indexes
WHERE tablename = 'buyer_personas'
ORDER BY indexname;

-- Expected: 5 indexes
-- 1. buyer_personas_pkey (primary key)
-- 2. idx_buyer_personas_created_at
-- 3. idx_buyer_personas_industry
-- 4. idx_buyer_personas_personas_gin
-- 5. idx_buyer_personas_user_id


-- ===============================================
-- TEST 1.1.5: RLS enabled
-- ===============================================
SELECT
  tablename,
  rowsecurity,
  CASE
    WHEN rowsecurity = true THEN '✅ PASS - RLS enabled'
    ELSE '❌ FAIL - RLS not enabled'
  END as test_result
FROM pg_tables
WHERE tablename = 'buyer_personas';

-- Expected: rowsecurity = true


-- ===============================================
-- TEST 1.1.6: RLS policies exist (4 policies)
-- ===============================================
SELECT
  policyname,
  cmd,
  CASE
    WHEN cmd = 'SELECT' THEN '✅ View policy'
    WHEN cmd = 'INSERT' THEN '✅ Insert policy'
    WHEN cmd = 'UPDATE' THEN '✅ Update policy'
    WHEN cmd = 'DELETE' THEN '✅ Delete policy'
    ELSE '❌ Unknown policy'
  END as test_result
FROM pg_policies
WHERE tablename = 'buyer_personas'
ORDER BY cmd;

-- Expected: 4 rows (DELETE, INSERT, SELECT, UPDATE)
-- "Users can delete their own personas" | DELETE
-- "Users can insert their own personas" | INSERT
-- "Users can view their own personas"   | SELECT
-- "Users can update their own personas" | UPDATE


-- ===============================================
-- TEST 1.1.7: Realtime enabled
-- ===============================================
SELECT
  schemaname,
  tablename,
  CASE
    WHEN tablename = 'buyer_personas' THEN '✅ PASS - Realtime enabled'
    ELSE '❌ FAIL'
  END as test_result
FROM pg_publication_tables
WHERE pubname = 'supabase_realtime'
  AND tablename = 'buyer_personas';

-- Expected: 1 row returned with test_result = '✅ PASS - Realtime enabled'


-- ===============================================
-- TEST 1.1.8: Trigger exists
-- ===============================================
SELECT
  trigger_name,
  event_manipulation,
  event_object_table,
  CASE
    WHEN trigger_name LIKE '%update%'
      AND event_manipulation = 'UPDATE'
      AND event_object_table = 'buyer_personas'
    THEN '✅ PASS - Trigger configured correctly'
    ELSE '❌ FAIL'
  END as test_result
FROM information_schema.triggers
WHERE event_object_table = 'buyer_personas';

-- Expected: 1 row
-- trigger_name = 'update_buyer_personas_updated_at'
-- event_manipulation = 'UPDATE'


-- ===============================================
-- TEST 1.1.9: Manual INSERT test
-- IMPORTANT: Replace <real-user-id> with actual UUID from auth.users
-- ===============================================

-- First, get a real user_id (copy this UUID for next steps)
SELECT id, email FROM auth.users LIMIT 1;

-- Then insert test record (replace <real-user-id> below)
-- INSERT INTO buyer_personas (user_id, personas, company_context, industry)
-- VALUES (
--   '<real-user-id>',
--   '[{"title": "Test Persona", "demographics": {}}]'::jsonb,
--   'Test context for surgical verification',
--   'Technology'
-- )
-- RETURNING
--   id,
--   user_id,
--   personas,
--   created_at,
--   updated_at,
--   created_at = updated_at as timestamps_equal,
--   CASE
--     WHEN created_at = updated_at THEN '✅ PASS - Timestamps equal on insert'
--     ELSE '❌ FAIL - Timestamps should be equal'
--   END as test_result;

-- Expected: 1 row inserted
-- timestamps_equal = true (created_at = updated_at on first insert)
-- test_result = '✅ PASS - Timestamps equal on insert'

-- IMPORTANT: Save the returned 'id' for Test 1.1.11


-- ===============================================
-- TEST 1.1.10: RLS policy test (isolation)
-- REQUIRES: Two different user accounts
-- ===============================================

-- This test must be run from Supabase client with different auth tokens
-- Cannot be tested via SQL Editor alone (requires auth context)

-- Manual verification steps:
-- 1. As User A: Create persona record (done in Test 1.1.9)
-- 2. As User B (different auth token): Try to query User A's persona
--    Expected: 0 rows returned (RLS blocks cross-user access)

-- SQL to run as User B (via authenticated Supabase client):
-- SELECT * FROM buyer_personas WHERE user_id = '<User A ID>';
-- Expected: 0 rows (RLS policy blocks)

-- Mark as: ⚠️ MANUAL TEST REQUIRED (cannot verify in SQL Editor)


-- ===============================================
-- TEST 1.1.11: Trigger test (updated_at)
-- IMPORTANT: Replace <test-id> with ID from Test 1.1.9
-- ===============================================

-- Wait 2 seconds then update
-- SELECT pg_sleep(2);

-- UPDATE buyer_personas
-- SET company_context = 'Updated context after 2 seconds'
-- WHERE id = '<test-id>'
-- RETURNING
--   created_at,
--   updated_at,
--   created_at < updated_at as trigger_worked,
--   CASE
--     WHEN created_at < updated_at THEN '✅ PASS - Trigger updated timestamp'
--     ELSE '❌ FAIL - Trigger did not fire'
--   END as test_result;

-- Expected: trigger_worked = true
-- Expected: updated_at > created_at
-- Expected: test_result = '✅ PASS - Trigger updated timestamp'


-- ===============================================
-- TEST 1.1.12: Check constraint test (personas_not_empty)
-- ===============================================

-- This should FAIL (empty array violates constraint)
-- INSERT INTO buyer_personas (user_id, personas, industry)
-- VALUES ('<user-id>', '[]'::jsonb, 'Tech');

-- Expected: ERROR - new row for relation "buyer_personas" violates check constraint "personas_not_empty"

-- If you see this error, test PASSES ✅
-- If insert succeeds, test FAILS ❌


-- ===============================================
-- CLEANUP (Optional - run after all tests pass)
-- ===============================================

-- Delete test data
-- DELETE FROM buyer_personas WHERE company_context LIKE 'Test context%';
-- DELETE FROM buyer_personas WHERE company_context LIKE 'Updated context%';


-- ===============================================
-- TEST SUMMARY CHECKLIST
-- ===============================================

-- [ ] Test 1.1.1:  Table exists
-- [ ] Test 1.1.2:  All columns with correct types
-- [ ] Test 1.1.3:  Constraints exist
-- [ ] Test 1.1.4:  Indexes exist (5 total)
-- [ ] Test 1.1.5:  RLS enabled
-- [ ] Test 1.1.6:  RLS policies exist (4 total)
-- [ ] Test 1.1.7:  Realtime enabled
-- [ ] Test 1.1.8:  Trigger exists
-- [ ] Test 1.1.9:  Manual INSERT succeeds
-- [ ] Test 1.1.10: RLS isolation (manual test)
-- [ ] Test 1.1.11: Trigger updates timestamp
-- [ ] Test 1.1.12: Empty personas array rejected

-- ===============================================
-- ACCEPTANCE CRITERIA
-- ===============================================
-- ✅ All 12 tests must pass (11 in SQL Editor + 1 manual)
-- ✅ Zero errors in Supabase logs
-- ✅ Test data can be inserted, updated, deleted
-- ✅ RLS blocks unauthorized access
-- ✅ Realtime enabled
-- ✅ Trigger auto-updates updated_at
-- ✅ Constraints prevent invalid data

-- Only proceed to Chunk 2 when ALL tests pass ✅
