-- ===============================================
-- UPDATE COMPANY_RATINGS TABLE FOR PHASE 3
-- Date: 2025-10-29
-- Purpose: Add fields required by aiRatingController
-- Reference: SUPABASE_SCHEMA_SYNTAX_REFERENCE.md
-- ===============================================

-- Add new columns if they don't exist
DO $$
BEGIN
    -- Add rating_score (rename from rating for consistency)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name='company_ratings' AND column_name='rating_score') THEN
        ALTER TABLE company_ratings ADD COLUMN rating_score INTEGER;
        -- Copy data from old rating column if it exists
        IF EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name='company_ratings' AND column_name='rating') THEN
            UPDATE company_ratings SET rating_score = rating;
        END IF;
    END IF;

    -- Add fit_level
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name='company_ratings' AND column_name='fit_level') THEN
        ALTER TABLE company_ratings ADD COLUMN fit_level TEXT;
    END IF;

    -- Add breakdown (detailed scoring)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name='company_ratings' AND column_name='breakdown') THEN
        ALTER TABLE company_ratings ADD COLUMN breakdown JSONB DEFAULT '{}'::jsonb;
    END IF;

    -- Add strengths array
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name='company_ratings' AND column_name='strengths') THEN
        ALTER TABLE company_ratings ADD COLUMN strengths TEXT[] DEFAULT ARRAY[]::TEXT[];
    END IF;

    -- Add concerns array
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name='company_ratings' AND column_name='concerns') THEN
        ALTER TABLE company_ratings ADD COLUMN concerns TEXT[] DEFAULT ARRAY[]::TEXT[];
    END IF;

    -- Add recommendation
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name='company_ratings' AND column_name='recommendation') THEN
        ALTER TABLE company_ratings ADD COLUMN recommendation TEXT;
    END IF;

    RAISE NOTICE 'Columns added successfully';
END $$;

-- Update constraints to use rating_score
ALTER TABLE company_ratings DROP CONSTRAINT IF EXISTS company_ratings_rating_check;
ALTER TABLE company_ratings ADD CONSTRAINT company_ratings_rating_score_check
    CHECK (rating_score >= 0 AND rating_score <= 100);

-- Update fit_level constraint
ALTER TABLE company_ratings DROP CONSTRAINT IF EXISTS company_ratings_fit_level_check;
ALTER TABLE company_ratings ADD CONSTRAINT company_ratings_fit_level_check
    CHECK (fit_level IN ('Excellent', 'Good', 'Fair', 'Poor'));

-- Add index on rating_score (follows SUPABASE_SCHEMA_SYNTAX_REFERENCE.md)
CREATE INDEX IF NOT EXISTS idx_company_ratings_score ON company_ratings(rating_score DESC);

-- Add GIN index for breakdown JSONB (follows SUPABASE_SCHEMA_SYNTAX_REFERENCE.md)
CREATE INDEX IF NOT EXISTS idx_company_ratings_breakdown_gin ON company_ratings USING GIN (breakdown);

-- Add comments for new columns
COMMENT ON COLUMN company_ratings.rating_score IS 'Integer 0-100 representing ICP fit score';
COMMENT ON COLUMN company_ratings.fit_level IS 'Qualitative fit level: Excellent (80-100), Good (60-79), Fair (40-59), Poor (0-39)';
COMMENT ON COLUMN company_ratings.breakdown IS 'Detailed scoring breakdown by category (industryFit, companySizeFit, etc.)';
COMMENT ON COLUMN company_ratings.strengths IS 'Array of company strengths relative to ICP';
COMMENT ON COLUMN company_ratings.concerns IS 'Array of concerns or gaps in ICP fit';
COMMENT ON COLUMN company_ratings.recommendation IS 'AI recommendation on whether to pursue this company';
