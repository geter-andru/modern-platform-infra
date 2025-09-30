-- ===============================================
-- ROW LEVEL SECURITY POLICIES
-- H&S Revenue Intelligence Platform
-- Date: September 3, 2025
-- ===============================================

-- Enable RLS on all tables
ALTER TABLE public.ai_resource_generations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.resource_generation_summary ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.generation_error_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customer_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_configurations ENABLE ROW LEVEL SECURITY;

-- ===============================================
-- CUSTOMER_PROFILES POLICIES
-- ===============================================

-- Users can only see their own profile
CREATE POLICY "Users can view own profile" ON public.customer_profiles
    FOR SELECT USING (auth.uid()::text = customer_id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile" ON public.customer_profiles
    FOR UPDATE USING (auth.uid()::text = customer_id);

-- Users can insert their own profile (for first-time setup)
CREATE POLICY "Users can insert own profile" ON public.customer_profiles
    FOR INSERT WITH CHECK (auth.uid()::text = customer_id);

-- ===============================================
-- AI_RESOURCE_GENERATIONS POLICIES
-- ===============================================

-- Users can only see their own AI generations
CREATE POLICY "Users can view own AI generations" ON public.ai_resource_generations
    FOR SELECT USING (auth.uid()::text = customer_id);

-- Users can create AI generations for themselves
CREATE POLICY "Users can create own AI generations" ON public.ai_resource_generations
    FOR INSERT WITH CHECK (auth.uid()::text = customer_id);

-- Users can update their own AI generations
CREATE POLICY "Users can update own AI generations" ON public.ai_resource_generations
    FOR UPDATE USING (auth.uid()::text = customer_id);

-- ===============================================
-- RESOURCE_GENERATION_SUMMARY POLICIES
-- ===============================================

-- Users can only see resource summaries for their own generations
CREATE POLICY "Users can view own resource summaries" ON public.resource_generation_summary
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.ai_resource_generations
            WHERE id = resource_generation_summary.generation_id
            AND customer_id = auth.uid()::text
        )
    );

-- Users can insert resource summaries for their own generations
CREATE POLICY "Users can create own resource summaries" ON public.resource_generation_summary
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.ai_resource_generations
            WHERE id = resource_generation_summary.generation_id
            AND customer_id = auth.uid()::text
        )
    );

-- Users can update resource summaries for their own generations
CREATE POLICY "Users can update own resource summaries" ON public.resource_generation_summary
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.ai_resource_generations
            WHERE id = resource_generation_summary.generation_id
            AND customer_id = auth.uid()::text
        )
    );

-- ===============================================
-- GENERATION_ERROR_LOGS POLICIES
-- ===============================================

-- Users can only see error logs for their own generations
CREATE POLICY "Users can view own error logs" ON public.generation_error_logs
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.ai_resource_generations
            WHERE id = generation_error_logs.generation_id
            AND customer_id = auth.uid()::text
        )
    );

-- System can insert error logs (no user restriction on INSERT)
CREATE POLICY "System can create error logs" ON public.generation_error_logs
    FOR INSERT WITH CHECK (true);

-- ===============================================
-- PRODUCT_CONFIGURATIONS POLICIES
-- ===============================================

-- All authenticated users can read product configurations
CREATE POLICY "Authenticated users can view product configs" ON public.product_configurations
    FOR SELECT USING (auth.role() = 'authenticated');

-- Only service role can modify product configurations
-- (This will be handled by admin functions only)

-- ===============================================
-- ADMIN ACCESS FUNCTIONS
-- ===============================================

-- Function to check if user is admin (based on email domain or specific users)
CREATE OR REPLACE FUNCTION public.is_admin(user_id uuid DEFAULT auth.uid())
RETURNS boolean AS $$
DECLARE
    user_email text;
BEGIN
    -- Get user email from auth.users
    SELECT email INTO user_email
    FROM auth.users
    WHERE id = user_id;
    
    -- Define admin criteria (customize as needed)
    RETURN user_email LIKE '%@andru.ai' OR 
           user_email IN ('admin@example.com', 'support@andru.ai');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Admin policy for all tables - admins can do everything
CREATE POLICY "Admins have full access" ON public.customer_profiles
    FOR ALL USING (public.is_admin());

CREATE POLICY "Admins have full access to generations" ON public.ai_resource_generations
    FOR ALL USING (public.is_admin());

CREATE POLICY "Admins have full access to summaries" ON public.resource_generation_summary
    FOR ALL USING (public.is_admin());

CREATE POLICY "Admins have full access to errors" ON public.generation_error_logs
    FOR ALL USING (public.is_admin());

CREATE POLICY "Admins have full access to configs" ON public.product_configurations
    FOR ALL USING (public.is_admin());

-- ===============================================
-- UTILITY FUNCTIONS
-- ===============================================

-- Function to get current user's profile
CREATE OR REPLACE FUNCTION public.get_current_user_profile()
RETURNS TABLE (
    id uuid,
    customer_id text,
    email text,
    company_name text,
    first_name text,
    last_name text,
    role text
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        cp.id,
        cp.customer_id,
        cp.email,
        cp.company_name,
        cp.first_name,
        cp.last_name,
        cp.role
    FROM public.customer_profiles cp
    WHERE cp.customer_id = auth.uid()::text;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to create user profile on first login
CREATE OR REPLACE FUNCTION public.create_user_profile_on_signup()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.customer_profiles (
        customer_id,
        email,
        first_name,
        last_name,
        created_at,
        updated_at
    ) VALUES (
        NEW.id::text,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'first_name', ''),
        COALESCE(NEW.raw_user_meta_data->>'last_name', ''),
        NOW(),
        NOW()
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to automatically create profile when user signs up
DROP TRIGGER IF EXISTS create_profile_on_signup ON auth.users;
CREATE TRIGGER create_profile_on_signup
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.create_user_profile_on_signup();

-- ===============================================
-- INDEXES FOR PERFORMANCE
-- ===============================================

-- Indexes on frequently queried columns
CREATE INDEX IF NOT EXISTS idx_customer_profiles_customer_id ON public.customer_profiles(customer_id);
CREATE INDEX IF NOT EXISTS idx_customer_profiles_email ON public.customer_profiles(email);
CREATE INDEX IF NOT EXISTS idx_ai_generations_customer_id ON public.ai_resource_generations(customer_id);
CREATE INDEX IF NOT EXISTS idx_ai_generations_status ON public.ai_resource_generations(generation_status);
CREATE INDEX IF NOT EXISTS idx_resource_summary_generation_id ON public.resource_generation_summary(generation_id);
CREATE INDEX IF NOT EXISTS idx_error_logs_generation_id ON public.generation_error_logs(generation_id);