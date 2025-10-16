-- ===========================================
-- ADD UNIQUE CONSTRAINTS FOR IDEMPOTENT SEEDING
-- ===========================================
-- Migration: 20250127000003_add_unique_constraints_for_seeding.sql
-- Description: Adds unique constraints to enable idempotent database seeding
-- Date: October 3, 2025
-- Status: MVP Ready

-- ===========================================
-- MIGRATION LOGGING
-- ===========================================

-- Record start of migration
INSERT INTO public.migration_log (migration_name, executed_at, status, details)
VALUES ('20250127000003_add_unique_constraints_for_seeding', now(), 'started', 'Adding unique constraints for idempotent seeding');

-- ===========================================
-- 1. ADD UNIQUE CONSTRAINT TO RESOURCES TABLE
-- ===========================================
-- Purpose: Enable upsert operations on resources by (customer_id, title)

-- Add unique constraint for resources
ALTER TABLE resources
ADD CONSTRAINT IF NOT EXISTS resources_unique_customer_title UNIQUE (customer_id, title);

-- ===========================================
-- 2. ENSURE UNIQUE CONSTRAINT ON MIGRATION_LOG
-- ===========================================
-- Purpose: Enable idempotent migration logging

-- Add unique constraint for migration_log
ALTER TABLE public.migration_log
ADD CONSTRAINT IF NOT EXISTS migration_log_unique_migration_name UNIQUE (migration_name);

-- ===========================================
-- 3. VERIFY CONSTRAINTS WERE ADDED
-- ===========================================

-- Verify resources constraint
DO $$
DECLARE
  constraint_exists BOOLEAN;
BEGIN
  SELECT EXISTS(
    SELECT 1 FROM information_schema.table_constraints 
    WHERE table_name = 'resources' 
    AND constraint_name = 'resources_unique_customer_title'
    AND constraint_type = 'UNIQUE'
  ) INTO constraint_exists;
  
  IF constraint_exists THEN
    RAISE NOTICE '✅ SUCCESS: Unique constraint added to resources table';
  ELSE
    RAISE EXCEPTION '❌ ERROR: Failed to add unique constraint to resources table';
  END IF;
END $$;

-- Verify migration_log constraint
DO $$
DECLARE
  constraint_exists BOOLEAN;
BEGIN
  SELECT EXISTS(
    SELECT 1 FROM information_schema.table_constraints 
    WHERE table_name = 'migration_log' 
    AND constraint_name = 'migration_log_unique_migration_name'
    AND constraint_type = 'UNIQUE'
  ) INTO constraint_exists;
  
  IF constraint_exists THEN
    RAISE NOTICE '✅ SUCCESS: Unique constraint added to migration_log table';
  ELSE
    RAISE EXCEPTION '❌ ERROR: Failed to add unique constraint to migration_log table';
  END IF;
END $$;

-- ===========================================
-- MIGRATION COMPLETION
-- ===========================================

-- Record successful completion
INSERT INTO public.migration_log (migration_name, executed_at, status, details)
VALUES ('20250127000003_add_unique_constraints_for_seeding', now(), 'success', 'Unique constraints added successfully for idempotent seeding');

-- Final success message
DO $$
BEGIN
  RAISE NOTICE '🎉 UNIQUE CONSTRAINTS MIGRATION COMPLETED SUCCESSFULLY!';
  RAISE NOTICE '📊 Added: resources(customer_id, title) and migration_log(migration_name) unique constraints';
  RAISE NOTICE '🎯 Ready for idempotent database seeding!';
  RAISE NOTICE '✅ All verification checks passed';
END $$;








