-- ===============================================
-- SETUP TRIGGER FUNCTION (Run FIRST before any migrations)
-- Date: 2025-10-27
-- Purpose: Create standard Supabase trigger function for updated_at
-- ===============================================

-- This function automatically updates the updated_at column
-- whenever a row is modified (but not if only updated_at changed)

CREATE OR REPLACE FUNCTION public.tg_set_timestamp()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  -- If nothing but updated_at changed, do nothing
  IF ROW(NEW.*) IS NOT DISTINCT FROM ROW(OLD.*) THEN
    RETURN NEW;
  END IF;

  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.tg_set_timestamp() IS 'Automatically updates updated_at column when row is modified';
