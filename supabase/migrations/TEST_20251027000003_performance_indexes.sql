-- ===============================================
-- TEST SUITE FOR PERFORMANCE INDEXES
-- Migration: 20251027000003_add_performance_indexes.sql
-- Total Tests: 8 (All must pass before proceeding)
-- ===============================================

-- ===============================================
-- TEST 1.3.1: Count indexes on icp_frameworks
-- ===============================================
SELECT
  count(*) as total_indexes,
  CASE
    WHEN count(*) >= 6 THEN '✅ PASS - At least 6 indexes'
    ELSE '❌ FAIL - Missing indexes'
  END as test_result
FROM pg_indexes
WHERE tablename = 'icp_frameworks';

-- Expected: total_indexes >= 6 (PK + 5 new indexes)


-- ===============================================
-- TEST 1.3.2: Verify GIN indexes on icp_frameworks
-- ===============================================
SELECT
  indexname,
  CASE
    WHEN indexname LIKE '%framework_gin%' THEN '✅ Framework JSONB GIN index'
    WHEN indexname LIKE '%description_fts%' THEN '✅ Description full-text index'
    ELSE '⚠️ Other index'
  END as index_type
FROM pg_indexes
WHERE tablename = 'icp_frameworks'
  AND indexdef LIKE '%GIN%'
ORDER BY indexname;

-- Expected: 2 rows
-- idx_icp_frameworks_framework_gin
-- idx_icp_frameworks_description_fts


-- ===============================================
-- TEST 1.3.3: Test JSONB query uses index
-- ===============================================
EXPLAIN (FORMAT TEXT)
SELECT * FROM icp_frameworks
WHERE framework @> '{"buyerPersonas": [{"title": "VP of Sales"}]}'::jsonb;

-- Expected output should contain:
-- "Bitmap Index Scan using idx_icp_frameworks_framework_gin"
-- or "Index Scan using idx_icp_frameworks_framework_gin"

-- Manual verification: Check the EXPLAIN output
-- ✅ PASS if query plan shows index usage
-- ❌ FAIL if query plan shows "Seq Scan"


-- ===============================================
-- TEST 1.3.4: Test user_id query uses index
-- ===============================================
EXPLAIN (FORMAT TEXT)
SELECT * FROM icp_frameworks
WHERE user_id = (SELECT id FROM auth.users LIMIT 1);

-- Expected output should contain:
-- "Index Scan using idx_icp_frameworks_user_id"

-- Manual verification: Check the EXPLAIN output
-- ✅ PASS if shows index usage
-- ❌ FAIL if shows "Seq Scan"


-- ===============================================
-- TEST 1.3.5: Test full-text search uses index
-- ===============================================
EXPLAIN (FORMAT TEXT)
SELECT * FROM icp_frameworks
WHERE to_tsvector('english', product_description) @@ to_tsquery('english', 'sales & automation');

-- Expected output should contain:
-- "Bitmap Index Scan using idx_icp_frameworks_description_fts"

-- Manual verification: Check the EXPLAIN output
-- ✅ PASS if shows index usage
-- ⚠️ OK if shows Seq Scan (table might be too small for planner to prefer index)


-- ===============================================
-- TEST 1.3.6: Performance benchmark (user lookup)
-- ===============================================

-- First, ensure there's at least some data
SELECT
  count(*) as framework_count,
  CASE
    WHEN count(*) > 0 THEN 'Ready for benchmark'
    ELSE 'No data - create test frameworks first'
  END as status
FROM icp_frameworks;

-- Run timed query (note the execution time)
\timing on
SELECT * FROM icp_frameworks
WHERE user_id = (SELECT id FROM auth.users LIMIT 1)
LIMIT 10;
\timing off

-- Expected: Execution time < 100ms
-- With index: typically < 10ms
-- Without index: typically > 100ms

-- Manual verification:
-- ✅ PASS if execution time < 100ms
-- ⚠️ WARNING if 100-500ms
-- ❌ FAIL if > 500ms


-- ===============================================
-- TEST 1.3.7: Verify company_research indexes
-- ===============================================
SELECT
  count(*) as total_indexes,
  CASE
    WHEN count(*) >= 5 THEN '✅ PASS - At least 5 indexes'
    ELSE '❌ FAIL - Missing indexes'
  END as test_result
FROM pg_indexes
WHERE tablename = 'company_research';

-- Expected: total_indexes >= 5
-- List of indexes:
-- company_research_pkey
-- idx_company_research_cached_at
-- idx_company_research_data_gin
-- idx_company_research_name_fts
-- idx_company_research_url
-- idx_company_research_user_id


-- ===============================================
-- TEST 1.3.8: Test company URL lookup performance
-- ===============================================

-- Check index usage
EXPLAIN (FORMAT TEXT)
SELECT * FROM company_research
WHERE company_url = 'https://example.com';

-- Expected output should contain:
-- "Index Scan using idx_company_research_url"

-- Performance test (if data exists)
\timing on
SELECT * FROM company_research
WHERE company_url = (SELECT company_url FROM company_research LIMIT 1)
LIMIT 1;
\timing off

-- Expected: Execution time < 10ms with index

-- Manual verification:
-- ✅ PASS if EXPLAIN shows index usage AND execution time < 10ms
-- ⚠️ OK if Seq Scan (small table, planner optimizing)
-- ❌ FAIL if Seq Scan on large table (> 1000 rows)


-- ===============================================
-- ADDITIONAL VERIFICATION: Index Comments
-- ===============================================
SELECT
  schemaname,
  tablename,
  indexname,
  obj_description(indexrelid, 'pg_class') as index_comment
FROM pg_indexes
JOIN pg_class ON pg_class.relname = indexname
WHERE tablename IN ('icp_frameworks', 'company_research')
  AND obj_description(indexrelid, 'pg_class') IS NOT NULL
ORDER BY tablename, indexname;

-- Expected: Comments on key indexes
-- idx_icp_frameworks_user_id: 'Fast customer framework lookups'
-- idx_icp_frameworks_framework_gin: 'Enable JSONB array/object searches within framework'
-- idx_company_research_url: 'Fast URL-based cache lookups'
-- idx_company_research_data_gin: 'Enable JSONB searches on research_data'


-- ===============================================
-- TEST SUMMARY CHECKLIST
-- ===============================================

-- [ ] Test 1.3.1: icp_frameworks has >= 6 indexes
-- [ ] Test 1.3.2: GIN indexes exist (2 on icp_frameworks)
-- [ ] Test 1.3.3: JSONB query uses index (EXPLAIN)
-- [ ] Test 1.3.4: user_id query uses index (EXPLAIN)
-- [ ] Test 1.3.5: Full-text search uses index (EXPLAIN)
-- [ ] Test 1.3.6: Performance < 100ms for user lookups
-- [ ] Test 1.3.7: company_research has >= 5 indexes
-- [ ] Test 1.3.8: URL lookup uses index (EXPLAIN)

-- ===============================================
-- RCA PROTOCOL NOTES
-- ===============================================

-- If EXPLAIN shows "Seq Scan" instead of "Index Scan":
--
-- Layer 1 Analysis: Index exists but not being used
--
-- Layer 2 Root Causes:
-- 1. Table has < 100 rows (planner prefers Seq Scan for small tables - this is OK)
-- 2. Statistics out of date (run ANALYZE)
-- 3. Query pattern doesn't match index exactly
-- 4. Data type mismatch
--
-- Fixes:
-- - Run: ANALYZE icp_frameworks;
-- - Run: ANALYZE company_research;
-- - If table has < 100 rows, Seq Scan is actually faster (PASS the test)
-- - Verify query matches index column exactly
--
-- Re-test with EXPLAIN ANALYZE after fixes


-- ===============================================
-- ACCEPTANCE CRITERIA
-- ===============================================
-- ✅ All indexes created with IF NOT EXISTS
-- ✅ EXPLAIN ANALYZE shows index usage (or justifiable Seq Scan)
-- ✅ Query performance < 100ms for indexed lookups
-- ✅ GIN indexes work for JSONB and full-text searches
-- ✅ Index comments exist for key indexes
-- ✅ Follows SUPABASE_SCHEMA_SYNTAX_REFERENCE.md
-- ✅ No errors in Supabase logs

-- Only proceed to Phase 1 Final Verification when ALL tests pass ✅
