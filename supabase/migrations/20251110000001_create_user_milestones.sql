-- ===============================================
-- USER MILESTONES MIGRATION
-- Date: 2025-11-10
-- Purpose: Track user journey milestones for founding member onboarding
-- Reference: FOUNDING_MEMBER_PRICING_STRATEGY.md
-- ===============================================

-- ============================================================================
-- 1. CREATE TABLE
-- ============================================================================

-- Table: user_milestones
-- Purpose: Track user journey from assessment through waitlist to platform access
CREATE TABLE IF NOT EXISTS public.user_milestones (
  -- Primary identification
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,

  -- Foreign key to auth.users (user who achieved milestone)
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Milestone type
  milestone_type TEXT NOT NULL CHECK (milestone_type IN (
    'account_created',
    'assessment_started',
    'assessment_completed',
    'demo_viewed',
    'waitlist_joined',
    'waitlist_paid',           -- Payment successful via Stripe
    'urgent_assistance_booked',
    'early_access_granted',     -- Dec 1st platform access unlock
    'first_icp_generated',
    'slack_community_joined',
    'founding_member_onboarded',
    'upgraded_to_full_platform' -- Transition from $497 to $750
  )),

  -- Status tracking
  status TEXT CHECK (status IN ('pending', 'completed', 'expired')),

  -- Timestamps (CRITICAL: Use TIMESTAMPTZ not TIMESTAMP)
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Metadata for flexible data storage
  metadata JSONB DEFAULT '{}'::jsonb,

  -- Founding member specific fields
  is_founding_member BOOLEAN DEFAULT FALSE,
  has_early_access BOOLEAN DEFAULT FALSE,
  access_granted_date TIMESTAMPTZ,  -- December 1, 2025 for waitlist members
  forever_lock_price DECIMAL(10,2), -- $750 for founding members

  -- Stripe integration
  stripe_customer_id TEXT,
  stripe_subscription_id TEXT,

  -- Ensure one milestone of each type per user
  CONSTRAINT unique_user_milestone UNIQUE(user_id, milestone_type)
);

-- ============================================================================
-- 2. CREATE INDEXES
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_user_milestones_user_id ON public.user_milestones(user_id);
CREATE INDEX IF NOT EXISTS idx_user_milestones_milestone_type ON public.user_milestones(milestone_type);
CREATE INDEX IF NOT EXISTS idx_user_milestones_status ON public.user_milestones(status);
CREATE INDEX IF NOT EXISTS idx_user_milestones_is_founding_member ON public.user_milestones(is_founding_member);
CREATE INDEX IF NOT EXISTS idx_user_milestones_access_granted_date ON public.user_milestones(access_granted_date);
CREATE INDEX IF NOT EXISTS idx_user_milestones_completed_at ON public.user_milestones(completed_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_milestones_created_at ON public.user_milestones(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_milestones_stripe_customer_id ON public.user_milestones(stripe_customer_id);

-- ============================================================================
-- 3. CREATE TRIGGERS
-- ============================================================================

-- Trigger for user_milestones updated_at
DROP TRIGGER IF EXISTS update_user_milestones_updated_at ON public.user_milestones;
CREATE TRIGGER update_user_milestones_updated_at
  BEFORE UPDATE ON public.user_milestones
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================================
-- 4. ENABLE RLS
-- ============================================================================

ALTER TABLE public.user_milestones ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 5. CREATE RLS POLICIES
-- ============================================================================

-- Users can read their own milestones
DROP POLICY IF EXISTS "Users can read their own milestones" ON public.user_milestones;
CREATE POLICY "Users can read their own milestones"
  ON public.user_milestones
  FOR SELECT
  USING (auth.uid() = user_id);

-- Service role can insert milestones (webhook creates milestones)
DROP POLICY IF EXISTS "Service role can insert milestones" ON public.user_milestones;
CREATE POLICY "Service role can insert milestones"
  ON public.user_milestones
  FOR INSERT
  TO service_role
  WITH CHECK (true);

-- Service role can update milestones
DROP POLICY IF EXISTS "Service role can update milestones" ON public.user_milestones;
CREATE POLICY "Service role can update milestones"
  ON public.user_milestones
  FOR UPDATE
  TO service_role
  USING (true);

-- Users can update their own milestones (for client-side status updates)
DROP POLICY IF EXISTS "Users can update their own milestones" ON public.user_milestones;
CREATE POLICY "Users can update their own milestones"
  ON public.user_milestones
  FOR UPDATE
  USING (auth.uid() = user_id);

-- ============================================================================
-- 6. GRANT PERMISSIONS
-- ============================================================================

-- Grant service_role full access
GRANT ALL ON public.user_milestones TO service_role;

-- Grant authenticated users read access to their own data
GRANT SELECT ON public.user_milestones TO authenticated;

-- ============================================================================
-- 7. COMMENTS (Documentation)
-- ============================================================================

COMMENT ON TABLE public.user_milestones IS 'Tracks user journey milestones for founding member onboarding and platform access control';
COMMENT ON COLUMN public.user_milestones.milestone_type IS 'Type of milestone achieved (waitlist_paid, early_access_granted, etc.)';
COMMENT ON COLUMN public.user_milestones.access_granted_date IS 'Date when platform access is granted (Dec 1, 2025 for waitlist members)';
COMMENT ON COLUMN public.user_milestones.forever_lock_price IS 'Locked monthly price for founding members ($750)';
COMMENT ON COLUMN public.user_milestones.is_founding_member IS 'Whether user is a founding member (100 spots, locked pricing)';
