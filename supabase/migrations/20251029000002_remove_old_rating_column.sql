-- ===============================================
-- REMOVE OLD RATING COLUMN FROM COMPANY_RATINGS
-- Date: 2025-10-29
-- Purpose: Remove deprecated 'rating' column (replaced by 'rating_score')
-- Reference: SUPABASE_SCHEMA_SYNTAX_REFERENCE.md
-- ===============================================

-- Drop the old rating column if it exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_name='company_ratings' AND column_name='rating') THEN
        ALTER TABLE company_ratings DROP COLUMN rating;
        RAISE NOTICE 'Old rating column dropped successfully';
    ELSE
        RAISE NOTICE 'Old rating column does not exist, skipping';
    END IF;
END $$;
