-- Create resource_shares table for sharing functionality
CREATE TABLE IF NOT EXISTS public.resource_shares (
  id bigserial PRIMARY KEY,
  resource_id uuid NOT NULL REFERENCES public.resources(id) ON DELETE CASCADE,
  customer_id text NOT NULL,
  share_token text NOT NULL UNIQUE,
  share_type text NOT NULL DEFAULT 'view',
  expires_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS resource_shares_resource_id_idx ON public.resource_shares (resource_id);
CREATE INDEX IF NOT EXISTS resource_shares_customer_id_idx ON public.resource_shares (customer_id);
CREATE INDEX IF NOT EXISTS resource_shares_share_token_idx ON public.resource_shares (share_token);
CREATE INDEX IF NOT EXISTS resource_shares_expires_at_idx ON public.resource_shares (expires_at);

-- Enable RLS
ALTER TABLE public.resource_shares ENABLE ROW LEVEL SECURITY;

-- Create RLS policies (removed IF NOT EXISTS as it's not supported)
CREATE POLICY resource_shares_select_policy ON public.resource_shares
  FOR SELECT USING (true);

CREATE POLICY resource_shares_insert_policy ON public.resource_shares
  FOR INSERT WITH CHECK (true);

CREATE POLICY resource_shares_update_policy ON public.resource_shares
  FOR UPDATE USING (true);

CREATE POLICY resource_shares_delete_policy ON public.resource_shares
  FOR DELETE USING (true);

-- Add comment
COMMENT ON TABLE public.resource_shares IS 'Stores shareable links for resources with expiration and access control';
