-- ===============================================
-- ADD STRIPE SUBSCRIPTION FIELDS
-- Date: 2025-10-21
-- Purpose: Support $99/month subscription with 3-day trial
-- ===============================================

-- Add subscription tracking columns to customer_assets
ALTER TABLE customer_assets
ADD COLUMN IF NOT EXISTS stripe_subscription_id TEXT,
ADD COLUMN IF NOT EXISTS stripe_customer_id TEXT,
ADD COLUMN IF NOT EXISTS subscription_status TEXT DEFAULT 'none' CHECK (subscription_status IN ('none', 'trial', 'active', 'cancelled', 'past_due')),
ADD COLUMN IF NOT EXISTS trial_end_date TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS subscription_start_date TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS subscription_cancel_date TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS subscription_current_period_end TIMESTAMPTZ;

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_customer_assets_stripe_subscription_id ON customer_assets(stripe_subscription_id);
CREATE INDEX IF NOT EXISTS idx_customer_assets_stripe_customer_id ON customer_assets(stripe_customer_id);
CREATE INDEX IF NOT EXISTS idx_customer_assets_subscription_status ON customer_assets(subscription_status);
CREATE INDEX IF NOT EXISTS idx_customer_assets_trial_end_date ON customer_assets(trial_end_date);

-- Add comments for documentation
COMMENT ON COLUMN customer_assets.stripe_subscription_id IS 'Stripe subscription ID (sub_xxx)';
COMMENT ON COLUMN customer_assets.stripe_customer_id IS 'Stripe customer ID (cus_xxx)';
COMMENT ON COLUMN customer_assets.subscription_status IS 'Subscription status: none (no subscription), trial (3-day trial), active (paying), cancelled (churned), past_due (payment failed)';
COMMENT ON COLUMN customer_assets.trial_end_date IS 'Date when trial ends and auto-charge occurs ($99/month)';
COMMENT ON COLUMN customer_assets.subscription_start_date IS 'Date when subscription was created';
COMMENT ON COLUMN customer_assets.subscription_cancel_date IS 'Date when subscription was cancelled';
COMMENT ON COLUMN customer_assets.subscription_current_period_end IS 'Current billing period end date';
