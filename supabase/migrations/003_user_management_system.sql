-- Migration 003: Enhanced User Management System
-- Phase 3: User Management (Days 5-6)
-- Date: September 3, 2025

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- ENHANCED ROLE SYSTEM
-- =====================================================

-- Create role hierarchy table
CREATE TABLE IF NOT EXISTS user_roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    role_name TEXT NOT NULL CHECK (role_name IN ('super_admin', 'admin', 'manager', 'user', 'guest', 'readonly')),
    granted_by UUID REFERENCES auth.users(id),
    granted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true,
    metadata JSONB DEFAULT '{}',
    
    CONSTRAINT unique_active_user_role UNIQUE (user_id, role_name, is_active),
    CREATED_AT TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UPDATED_AT TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create role permissions mapping
CREATE TABLE IF NOT EXISTS role_permissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    role_name TEXT NOT NULL CHECK (role_name IN ('super_admin', 'admin', 'manager', 'user', 'guest', 'readonly')),
    permission TEXT NOT NULL,
    resource_type TEXT DEFAULT 'general',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT unique_role_permission UNIQUE (role_name, permission, resource_type)
);

-- =====================================================
-- ORGANIZATION & TEAM MANAGEMENT
-- =====================================================

-- Organizations table for multi-tenancy
CREATE TABLE IF NOT EXISTS organizations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    description TEXT,
    owner_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    plan TEXT DEFAULT 'basic' CHECK (plan IN ('basic', 'professional', 'enterprise')),
    settings JSONB DEFAULT '{}',
    max_members INTEGER DEFAULT 5,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User organization memberships
CREATE TABLE IF NOT EXISTS user_organizations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    role TEXT DEFAULT 'member' CHECK (role IN ('owner', 'admin', 'manager', 'member', 'guest')),
    permissions TEXT[] DEFAULT '{}',
    invited_by UUID REFERENCES auth.users(id),
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true,
    
    CONSTRAINT unique_user_org UNIQUE (user_id, organization_id)
);

-- Team invitations table
CREATE TABLE IF NOT EXISTS team_invitations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    role TEXT DEFAULT 'member' CHECK (role IN ('admin', 'manager', 'member', 'guest')),
    permissions TEXT[] DEFAULT '{}',
    invited_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    invitation_token TEXT UNIQUE DEFAULT encode(gen_random_bytes(32), 'base64'),
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '7 days'),
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'expired', 'revoked')),
    accepted_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT unique_pending_invitation UNIQUE (organization_id, email, status) DEFERRABLE INITIALLY DEFERRED
);

-- =====================================================
-- ENHANCED USER PROFILES
-- =====================================================

-- User profiles table (extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT,
    avatar_url TEXT,
    company TEXT,
    job_title TEXT,
    phone TEXT,
    timezone TEXT DEFAULT 'UTC',
    locale TEXT DEFAULT 'en',
    preferences JSONB DEFAULT '{
        "email_notifications": true,
        "marketing_emails": false,
        "theme": "system",
        "language": "en"
    }',
    onboarding_completed BOOLEAN DEFAULT false,
    onboarding_step INTEGER DEFAULT 0,
    last_seen_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- PERMISSION SYSTEM
-- =====================================================

-- Granular permissions table
CREATE TABLE IF NOT EXISTS permissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT UNIQUE NOT NULL,
    description TEXT,
    category TEXT DEFAULT 'general',
    resource_type TEXT DEFAULT 'general',
    is_system_permission BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User permission overrides (individual user permissions)
CREATE TABLE IF NOT EXISTS user_permission_overrides (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    permission_id UUID REFERENCES permissions(id) ON DELETE CASCADE,
    organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    granted BOOLEAN NOT NULL,
    granted_by UUID REFERENCES auth.users(id),
    granted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE,
    reason TEXT,
    
    CONSTRAINT unique_user_permission_override UNIQUE (user_id, permission_id, organization_id)
);

-- =====================================================
-- AUDIT & ACTIVITY TRACKING
-- =====================================================

-- User activity log
CREATE TABLE IF NOT EXISTS user_activity_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    organization_id UUID REFERENCES organizations(id) ON DELETE SET NULL,
    activity_type TEXT NOT NULL,
    resource_type TEXT,
    resource_id TEXT,
    details JSONB DEFAULT '{}',
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Index for efficient querying
    CONSTRAINT valid_activity_type CHECK (activity_type IN (
        'login', 'logout', 'profile_update', 'permission_change', 
        'organization_join', 'organization_leave', 'invitation_sent', 
        'invitation_accepted', 'role_change', 'data_export', 'api_access'
    ))
);

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

-- User roles indexes
CREATE INDEX IF NOT EXISTS idx_user_roles_user_id ON user_roles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_active ON user_roles(user_id, is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_user_roles_expires ON user_roles(expires_at) WHERE expires_at IS NOT NULL;

-- Organizations indexes
CREATE INDEX IF NOT EXISTS idx_organizations_owner ON organizations(owner_id);
CREATE INDEX IF NOT EXISTS idx_organizations_active ON organizations(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_organizations_slug ON organizations(slug);

-- User organizations indexes
CREATE INDEX IF NOT EXISTS idx_user_organizations_user ON user_organizations(user_id);
CREATE INDEX IF NOT EXISTS idx_user_organizations_org ON user_organizations(organization_id);
CREATE INDEX IF NOT EXISTS idx_user_organizations_active ON user_organizations(user_id, organization_id, is_active) WHERE is_active = true;

-- Team invitations indexes
CREATE INDEX IF NOT EXISTS idx_team_invitations_org ON team_invitations(organization_id);
CREATE INDEX IF NOT EXISTS idx_team_invitations_email ON team_invitations(email);
CREATE INDEX IF NOT EXISTS idx_team_invitations_status ON team_invitations(status);
CREATE INDEX IF NOT EXISTS idx_team_invitations_expires ON team_invitations(expires_at) WHERE expires_at > NOW();

-- User profiles indexes
CREATE INDEX IF NOT EXISTS idx_user_profiles_email ON user_profiles(email);
CREATE INDEX IF NOT EXISTS idx_user_profiles_company ON user_profiles(company);
CREATE INDEX IF NOT EXISTS idx_user_profiles_active ON user_profiles(is_active) WHERE is_active = true;

-- Activity log indexes
CREATE INDEX IF NOT EXISTS idx_user_activity_log_user ON user_activity_log(user_id);
CREATE INDEX IF NOT EXISTS idx_user_activity_log_org ON user_activity_log(organization_id);
CREATE INDEX IF NOT EXISTS idx_user_activity_log_created ON user_activity_log(created_at);
CREATE INDEX IF NOT EXISTS idx_user_activity_log_type ON user_activity_log(activity_type);

-- =====================================================
-- FUNCTIONS AND TRIGGERS
-- =====================================================

-- Function to automatically create user profile on auth.users insert
CREATE OR REPLACE FUNCTION create_user_profile()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO user_profiles (id, email, full_name)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name')
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create profile on user signup
DROP TRIGGER IF EXISTS create_user_profile_trigger ON auth.users;
CREATE TRIGGER create_user_profile_trigger
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION create_user_profile();

-- Function to update updated_at timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at triggers
DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON user_profiles;
CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_organizations_updated_at ON organizations;
CREATE TRIGGER update_organizations_updated_at
    BEFORE UPDATE ON organizations
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Function to check if user is super admin
CREATE OR REPLACE FUNCTION is_super_admin(user_email TEXT DEFAULT NULL)
RETURNS BOOLEAN AS $$
BEGIN
    -- Check by email parameter or current user
    IF user_email IS NULL THEN
        user_email := auth.email();
    END IF;
    
    -- Super admin check: @andru.ai domain or explicit super_admin role
    RETURN (
        user_email LIKE '%@andru.ai' OR
        EXISTS (
            SELECT 1 FROM user_roles ur 
            JOIN auth.users u ON ur.user_id = u.id 
            WHERE u.email = user_email 
            AND ur.role_name = 'super_admin' 
            AND ur.is_active = true
            AND (ur.expires_at IS NULL OR ur.expires_at > NOW())
        )
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check organization membership and role
CREATE OR REPLACE FUNCTION user_has_org_role(user_uuid UUID, org_uuid UUID, required_role TEXT DEFAULT 'member')
RETURNS BOOLEAN AS $$
DECLARE
    user_role TEXT;
    role_hierarchy TEXT[] := ARRAY['guest', 'member', 'manager', 'admin', 'owner'];
    required_level INTEGER;
    user_level INTEGER;
BEGIN
    -- Get user's role in organization
    SELECT role INTO user_role
    FROM user_organizations
    WHERE user_id = user_uuid 
    AND organization_id = org_uuid 
    AND is_active = true;
    
    IF user_role IS NULL THEN
        RETURN false;
    END IF;
    
    -- Get hierarchy levels
    SELECT array_position(role_hierarchy, required_role) INTO required_level;
    SELECT array_position(role_hierarchy, user_role) INTO user_level;
    
    -- User has required role or higher
    RETURN user_level >= required_level;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- DEFAULT PERMISSIONS DATA
-- =====================================================

-- Insert default permissions
INSERT INTO permissions (name, description, category, resource_type) VALUES
-- General permissions
('read', 'View content and data', 'general', 'general'),
('write', 'Create and edit content', 'general', 'general'),
('delete', 'Delete content and data', 'general', 'general'),
('export', 'Export data', 'general', 'general'),

-- User management
('user.invite', 'Invite new users', 'user_management', 'users'),
('user.manage', 'Manage user accounts', 'user_management', 'users'),
('user.roles', 'Manage user roles', 'user_management', 'users'),

-- Organization management
('org.manage', 'Manage organization settings', 'organization', 'organizations'),
('org.billing', 'Manage billing and subscriptions', 'organization', 'organizations'),
('org.delete', 'Delete organization', 'organization', 'organizations'),

-- Analytics and reporting
('analytics.view', 'View analytics dashboards', 'analytics', 'analytics'),
('analytics.export', 'Export analytics data', 'analytics', 'analytics'),
('reports.generate', 'Generate custom reports', 'analytics', 'reports'),

-- Admin functions
('admin.system', 'System administration', 'admin', 'system'),
('admin.users', 'Global user administration', 'admin', 'users'),
('admin.audit', 'View audit logs', 'admin', 'audit')

ON CONFLICT (name) DO NOTHING;

-- Insert default role permissions
INSERT INTO role_permissions (role_name, permission, resource_type) VALUES
-- Guest role
('guest', 'read', 'general'),

-- User role (basic user)
('user', 'read', 'general'),
('user', 'write', 'general'),
('user', 'export', 'general'),
('user', 'analytics.view', 'analytics'),

-- Manager role
('manager', 'read', 'general'),
('manager', 'write', 'general'),
('manager', 'delete', 'general'),
('manager', 'export', 'general'),
('manager', 'user.invite', 'users'),
('manager', 'analytics.view', 'analytics'),
('manager', 'analytics.export', 'analytics'),
('manager', 'reports.generate', 'reports'),

-- Admin role
('admin', 'read', 'general'),
('admin', 'write', 'general'),
('admin', 'delete', 'general'),
('admin', 'export', 'general'),
('admin', 'user.invite', 'users'),
('admin', 'user.manage', 'users'),
('admin', 'user.roles', 'users'),
('admin', 'org.manage', 'organizations'),
('admin', 'org.billing', 'organizations'),
('admin', 'analytics.view', 'analytics'),
('admin', 'analytics.export', 'analytics'),
('admin', 'reports.generate', 'reports'),

-- Super Admin role (all permissions)
('super_admin', 'read', 'general'),
('super_admin', 'write', 'general'),
('super_admin', 'delete', 'general'),
('super_admin', 'export', 'general'),
('super_admin', 'user.invite', 'users'),
('super_admin', 'user.manage', 'users'),
('super_admin', 'user.roles', 'users'),
('super_admin', 'org.manage', 'organizations'),
('super_admin', 'org.billing', 'organizations'),
('super_admin', 'org.delete', 'organizations'),
('super_admin', 'analytics.view', 'analytics'),
('super_admin', 'analytics.export', 'analytics'),
('super_admin', 'reports.generate', 'reports'),
('super_admin', 'admin.system', 'system'),
('super_admin', 'admin.users', 'users'),
('super_admin', 'admin.audit', 'audit')

ON CONFLICT (role_name, permission, resource_type) DO NOTHING;

-- =====================================================
-- ROW LEVEL SECURITY POLICIES
-- =====================================================

-- Enable RLS on all new tables
ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE role_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_permission_overrides ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_activity_log ENABLE ROW LEVEL SECURITY;

-- User Roles Policies
CREATE POLICY "Users can view their own roles" ON user_roles
    FOR SELECT USING (auth.uid() = user_id OR is_super_admin());

CREATE POLICY "Super admins can manage all user roles" ON user_roles
    FOR ALL USING (is_super_admin());

CREATE POLICY "Organization admins can manage roles in their org" ON user_roles
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM user_organizations uo
            WHERE uo.user_id = auth.uid()
            AND uo.role IN ('admin', 'owner')
            AND uo.is_active = true
        )
    );

-- Organizations Policies
CREATE POLICY "Users can view organizations they belong to" ON organizations
    FOR SELECT USING (
        id IN (
            SELECT organization_id FROM user_organizations 
            WHERE user_id = auth.uid() AND is_active = true
        ) OR is_super_admin()
    );

CREATE POLICY "Organization owners can manage their organization" ON organizations
    FOR ALL USING (
        owner_id = auth.uid() OR is_super_admin()
    );

-- User Organizations Policies
CREATE POLICY "Users can view their organization memberships" ON user_organizations
    FOR SELECT USING (
        user_id = auth.uid() OR 
        is_super_admin() OR
        organization_id IN (
            SELECT organization_id FROM user_organizations 
            WHERE user_id = auth.uid() AND role IN ('admin', 'owner') AND is_active = true
        )
    );

CREATE POLICY "Organization admins can manage memberships" ON user_organizations
    FOR ALL USING (
        is_super_admin() OR
        organization_id IN (
            SELECT organization_id FROM user_organizations 
            WHERE user_id = auth.uid() AND role IN ('admin', 'owner') AND is_active = true
        )
    );

-- Team Invitations Policies
CREATE POLICY "Organization members can view invitations" ON team_invitations
    FOR SELECT USING (
        is_super_admin() OR
        organization_id IN (
            SELECT organization_id FROM user_organizations 
            WHERE user_id = auth.uid() AND is_active = true
        )
    );

CREATE POLICY "Organization admins can manage invitations" ON team_invitations
    FOR ALL USING (
        is_super_admin() OR
        organization_id IN (
            SELECT organization_id FROM user_organizations 
            WHERE user_id = auth.uid() AND role IN ('admin', 'manager', 'owner') AND is_active = true
        )
    );

-- User Profiles Policies
CREATE POLICY "Users can view and update their own profile" ON user_profiles
    FOR ALL USING (auth.uid() = id);

CREATE POLICY "Organization members can view profiles of other members" ON user_profiles
    FOR SELECT USING (
        is_super_admin() OR
        id IN (
            SELECT DISTINCT uo1.user_id FROM user_organizations uo1
            JOIN user_organizations uo2 ON uo1.organization_id = uo2.organization_id
            WHERE uo2.user_id = auth.uid() AND uo1.is_active = true AND uo2.is_active = true
        )
    );

CREATE POLICY "Super admins can manage all profiles" ON user_profiles
    FOR ALL USING (is_super_admin());

-- Permissions Policies (read-only for non-super-admins)
CREATE POLICY "All authenticated users can view permissions" ON permissions
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Only super admins can manage permissions" ON permissions
    FOR ALL USING (is_super_admin());

-- User Permission Overrides Policies
CREATE POLICY "Users can view their permission overrides" ON user_permission_overrides
    FOR SELECT USING (user_id = auth.uid() OR is_super_admin());

CREATE POLICY "Only super admins can manage permission overrides" ON user_permission_overrides
    FOR ALL USING (is_super_admin());

-- Activity Log Policies
CREATE POLICY "Users can view their own activity" ON user_activity_log
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Organization admins can view org activity" ON user_activity_log
    FOR SELECT USING (
        is_super_admin() OR
        organization_id IN (
            SELECT organization_id FROM user_organizations 
            WHERE user_id = auth.uid() AND role IN ('admin', 'owner') AND is_active = true
        )
    );

CREATE POLICY "System can insert activity logs" ON user_activity_log
    FOR INSERT WITH CHECK (true);

-- Role Permissions Policies (read-only)
CREATE POLICY "All authenticated users can view role permissions" ON role_permissions
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Only super admins can manage role permissions" ON role_permissions
    FOR ALL USING (is_super_admin());

COMMENT ON TABLE user_roles IS 'Enhanced role system with hierarchical permissions and expiration';
COMMENT ON TABLE organizations IS 'Multi-tenant organization management';
COMMENT ON TABLE user_profiles IS 'Extended user profiles with preferences and onboarding';
COMMENT ON TABLE team_invitations IS 'Team member invitation workflow';
COMMENT ON TABLE user_activity_log IS 'Comprehensive user activity tracking for audit and compliance';