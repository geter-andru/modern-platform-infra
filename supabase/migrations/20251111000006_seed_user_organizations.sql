-- ===============================================
-- SEED USER ORGANIZATIONS
-- Date: 2025-11-11
-- Purpose: Create organizations and link users to them
-- Note: This assumes an 'organizations' table exists
-- ===============================================

-- ============================================================================
-- 1. CREATE TEST ORGANIZATIONS (if organizations table exists)
-- ============================================================================

-- Check if organizations table exists and create test orgs
DO $$
DECLARE
  v_table_exists BOOLEAN;
  v_org_hs_id UUID;
  v_org_adesol_id UUID;
  v_org_test_id UUID;
BEGIN
  -- Check if organizations table exists
  SELECT EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'public'
    AND table_name = 'organizations'
  ) INTO v_table_exists;

  IF v_table_exists THEN
    RAISE NOTICE 'Organizations table exists, creating test organizations...';

    -- Create or get Humus & Shore organization
    INSERT INTO organizations (id, name, slug, created_at, updated_at)
    VALUES (gen_random_uuid(), 'Humus & Shore', 'humus-shore', NOW(), NOW())
    ON CONFLICT (slug) DO UPDATE SET updated_at = NOW()
    RETURNING id INTO v_org_hs_id;

    -- Create or get Adesol Energy organization
    INSERT INTO organizations (id, name, slug, created_at, updated_at)
    VALUES (gen_random_uuid(), 'Adesol Energy', 'adesol-energy', NOW(), NOW())
    ON CONFLICT (slug) DO UPDATE SET updated_at = NOW()
    RETURNING id INTO v_org_adesol_id;

    -- Create or get Test Lab organization
    INSERT INTO organizations (id, name, slug, created_at, updated_at)
    VALUES (gen_random_uuid(), 'Test Lab', 'test-lab', NOW(), NOW())
    ON CONFLICT (slug) DO UPDATE SET updated_at = NOW()
    RETURNING id INTO v_org_test_id;

    -- Link users to organizations (with conflict handling)
    INSERT INTO user_organizations (user_id, organization_id, role, joined_at, is_active)
    VALUES
      ('85e54a00-d75b-420e-a3bb-ddd750fc548a', v_org_hs_id, 'owner', NOW(), true),
      ('882f7ce8-ac8d-4dca-9704-c797e782acd0', v_org_hs_id, 'admin', NOW(), true),
      ('2492642c-8053-4558-8559-85dacd6daa30', v_org_adesol_id, 'owner', NOW(), true),
      ('3537b889-3148-4b07-a31b-ebbd1bb150a4', v_org_test_id, 'admin', NOW(), true)
    ON CONFLICT (user_id, organization_id) DO NOTHING;

    RAISE NOTICE '✅ Organizations and user_organizations seeded successfully';
  ELSE
    RAISE NOTICE '⚠️  Organizations table does not exist, skipping organization seeding';
    RAISE NOTICE '   user_organizations table requires organization_id UUIDs';
    RAISE NOTICE '   Create organizations through application logic instead';
  END IF;
END $$;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
DECLARE
  v_orgs_count INTEGER;
  v_user_orgs_count INTEGER;
  v_table_exists BOOLEAN;
BEGIN
  -- Check if organizations table exists
  SELECT EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'public'
    AND table_name = 'organizations'
  ) INTO v_table_exists;

  IF v_table_exists THEN
    SELECT COUNT(*) INTO v_orgs_count FROM organizations;
    SELECT COUNT(*) INTO v_user_orgs_count FROM user_organizations;

    RAISE NOTICE '✅ Verification complete:';
    RAISE NOTICE '   - organizations: % rows', v_orgs_count;
    RAISE NOTICE '   - user_organizations: % rows', v_user_orgs_count;
  ELSE
    RAISE NOTICE '⚠️  Skipping verification - organizations table does not exist';
  END IF;
END $$;
