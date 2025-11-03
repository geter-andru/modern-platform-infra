-- ===============================================
-- BETA_SIGNUPS TABLE
-- Date: 2025-11-01
-- Purpose: Founding member beta signup applications
-- Reference: BETA_SIGNUP_PAGE_REQUIREMENTS.md
-- ===============================================

-- 1. CREATE TABLE
CREATE TABLE IF NOT EXISTS beta_signups (
  -- Primary identification
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,

  -- Application data
  full_name TEXT NOT NULL,
  email TEXT NOT NULL,
  company TEXT NOT NULL,
  job_title TEXT NOT NULL,
  product_description TEXT NOT NULL,
  referral_source TEXT NOT NULL,
  linkedin_profile TEXT,

  -- Application status
  status TEXT DEFAULT 'pending' NOT NULL,

  -- Audit timestamps (CRITICAL: Use TIMESTAMPTZ not TIMESTAMP)
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Constraints
  CONSTRAINT beta_signups_email_unique UNIQUE (email),
  CONSTRAINT beta_signups_valid_email CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
  CONSTRAINT beta_signups_valid_status CHECK (status IN ('pending', 'approved', 'rejected')),
  CONSTRAINT beta_signups_product_desc_length CHECK (char_length(product_description) >= 20 AND char_length(product_description) <= 500),
  CONSTRAINT beta_signups_valid_linkedin CHECK (linkedin_profile IS NULL OR linkedin_profile ~* '^https?://')
);

-- 2. CREATE INDEXES (CRITICAL: Separate CREATE INDEX statements, use IF NOT EXISTS)
CREATE INDEX IF NOT EXISTS idx_beta_signups_email ON beta_signups(email);
CREATE INDEX IF NOT EXISTS idx_beta_signups_status ON beta_signups(status);
CREATE INDEX IF NOT EXISTS idx_beta_signups_created_at ON beta_signups(created_at DESC);

-- 3. CREATE TRIGGER (CRITICAL: DROP first, then CREATE)
DROP TRIGGER IF EXISTS set_timestamp_beta_signups ON beta_signups;
CREATE TRIGGER set_timestamp_beta_signups
    BEFORE UPDATE ON beta_signups
    FOR EACH ROW EXECUTE FUNCTION public.tg_set_timestamp();

-- 4. RLS NOT NEEDED (backend-only access via service role key)
-- Beta signups are managed exclusively through backend API with service role key

-- 5. GRANT PERMISSIONS
GRANT ALL ON beta_signups TO service_role;

-- 6. ADD COMMENTS
COMMENT ON TABLE beta_signups IS 'Founding member beta signup applications for 100-person free beta launch';
COMMENT ON COLUMN beta_signups.email IS 'Unique email address - prevents duplicate signups';
COMMENT ON COLUMN beta_signups.status IS 'Application status: pending (default), approved, or rejected';
COMMENT ON COLUMN beta_signups.product_description IS 'User-provided product description (20-500 characters)';
