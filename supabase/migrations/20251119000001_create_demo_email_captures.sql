-- Migration: Create demo_email_captures table
-- Purpose: Capture email addresses from demo pages for lead generation
-- Created: 2025-11-19
-- Feature: Email Me This Analysis button on /icp/demo-v2 page

-- Create demo_email_captures table
CREATE TABLE IF NOT EXISTS public.demo_email_captures (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL,
  demo_type TEXT NOT NULL DEFAULT 'icp_analysis',
  company_slug TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),

  -- Prevent duplicate emails for same demo type
  CONSTRAINT unique_email_per_demo_type UNIQUE(email, demo_type)
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_demo_email_captures_email
  ON public.demo_email_captures(email);

CREATE INDEX IF NOT EXISTS idx_demo_email_captures_created_at
  ON public.demo_email_captures(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_demo_email_captures_demo_type
  ON public.demo_email_captures(demo_type);

-- Enable Row Level Security
ALTER TABLE public.demo_email_captures ENABLE ROW LEVEL SECURITY;

-- Policy: Allow anonymous users to insert their email (public access)
CREATE POLICY "Allow anonymous email capture"
  ON public.demo_email_captures
  FOR INSERT
  TO anon
  WITH CHECK (true);

-- Policy: Allow authenticated users to read their own emails
CREATE POLICY "Users can read own emails"
  ON public.demo_email_captures
  FOR SELECT
  TO authenticated
  USING (email = (SELECT email FROM auth.users WHERE id = auth.uid()));

-- Policy: Service role has full access (for admin operations)
CREATE POLICY "Service role has full access"
  ON public.demo_email_captures
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- Add table comment
COMMENT ON TABLE public.demo_email_captures IS
  'Captures email addresses from demo pages (e.g., ICP analysis demo) for lead generation and follow-up nurture campaigns. Designed for anonymous users who want to receive analysis results via email.';

-- Add column comments
COMMENT ON COLUMN public.demo_email_captures.email IS
  'Email address provided by demo user';

COMMENT ON COLUMN public.demo_email_captures.demo_type IS
  'Type of demo that captured the email (e.g., icp_analysis, roi_calculator)';

COMMENT ON COLUMN public.demo_email_captures.company_slug IS
  'Optional: Company slug if demo was run for a specific company';

COMMENT ON COLUMN public.demo_email_captures.created_at IS
  'Timestamp when email was captured';
