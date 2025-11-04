-- Update RLS policies to recognize @humusnshore.org as super admin domain
-- First, let's handle the User Roles policies
DROP POLICY IF EXISTS "Super admins can manage all user roles" ON user_roles;
CREATE POLICY "Super admins can manage all user roles" ON user_roles
    FOR ALL TO authenticated
    USING (
        (auth.jwt() ->> 'email') LIKE '%@andru.ai' OR
        (auth.jwt() ->> 'email') LIKE '%@humusnshore.org'
    );

-- Organizations Policies  
DROP POLICY IF EXISTS "Organization owners can manage their organization" ON organizations;
CREATE POLICY "Organization owners can manage their organization" ON organizations
    FOR ALL TO authenticated
    USING (
        owner_id = auth.uid() OR 
        (auth.jwt() ->> 'email') LIKE '%@andru.ai' OR
        (auth.jwt() ->> 'email') LIKE '%@humusnshore.org'
    );

DROP POLICY IF EXISTS "Users can view organizations they belong to" ON organizations;
CREATE POLICY "Users can view organizations they belong to" ON organizations
    FOR SELECT TO authenticated
    USING (
        id IN (
            SELECT organization_id FROM user_organizations 
            WHERE user_id = auth.uid() AND is_active = true
        ) OR 
        (auth.jwt() ->> 'email') LIKE '%@andru.ai' OR
        (auth.jwt() ->> 'email') LIKE '%@humusnshore.org'
    );

-- User Organizations Policies
DROP POLICY IF EXISTS "Users can view their organization memberships" ON user_organizations;
CREATE POLICY "Users can view their organization memberships" ON user_organizations
    FOR SELECT TO authenticated
    USING (
        user_id = auth.uid() OR 
        (auth.jwt() ->> 'email') LIKE '%@andru.ai' OR
        (auth.jwt() ->> 'email') LIKE '%@humusnshore.org'
    );

DROP POLICY IF EXISTS "Super admins can manage all memberships" ON user_organizations;
CREATE POLICY "Super admins can manage all memberships" ON user_organizations
    FOR ALL TO authenticated
    USING (
        (auth.jwt() ->> 'email') LIKE '%@andru.ai' OR
        (auth.jwt() ->> 'email') LIKE '%@humusnshore.org'
    );

-- Team Invitations Policies
DROP POLICY IF EXISTS "Super admins can view all invitations" ON team_invitations;
CREATE POLICY "Super admins can view all invitations" ON team_invitations
    FOR SELECT TO authenticated
    USING (
        (auth.jwt() ->> 'email') LIKE '%@andru.ai' OR
        (auth.jwt() ->> 'email') LIKE '%@humusnshore.org'
    );

DROP POLICY IF EXISTS "Super admins can manage all invitations" ON team_invitations;
CREATE POLICY "Super admins can manage all invitations" ON team_invitations
    FOR ALL TO authenticated
    USING (
        (auth.jwt() ->> 'email') LIKE '%@andru.ai' OR
        (auth.jwt() ->> 'email') LIKE '%@humusnshore.org'
    );

-- User Profiles Policies
DROP POLICY IF EXISTS "Super admins can manage all profiles" ON user_profiles;
CREATE POLICY "Super admins can manage all profiles" ON user_profiles
    FOR ALL TO authenticated
    USING (
        (auth.jwt() ->> 'email') LIKE '%@andru.ai' OR
        (auth.jwt() ->> 'email') LIKE '%@humusnshore.org'
    );

-- Permissions Policies
DROP POLICY IF EXISTS "Only super admins can manage permissions" ON permissions;
CREATE POLICY "Only super admins can manage permissions" ON permissions
    FOR ALL TO authenticated
    USING (
        (auth.jwt() ->> 'email') LIKE '%@andru.ai' OR
        (auth.jwt() ->> 'email') LIKE '%@humusnshore.org'
    );

-- User Permission Overrides Policies
DROP POLICY IF EXISTS "Users can view their permission overrides" ON user_permission_overrides;
CREATE POLICY "Users can view their permission overrides" ON user_permission_overrides
    FOR SELECT TO authenticated
    USING (
        user_id = auth.uid() OR 
        (auth.jwt() ->> 'email') LIKE '%@andru.ai' OR
        (auth.jwt() ->> 'email') LIKE '%@humusnshore.org'
    );

DROP POLICY IF EXISTS "Only super admins can manage permission overrides" ON user_permission_overrides;
CREATE POLICY "Only super admins can manage permission overrides" ON user_permission_overrides
    FOR ALL TO authenticated
    USING (
        (auth.jwt() ->> 'email') LIKE '%@andru.ai' OR
        (auth.jwt() ->> 'email') LIKE '%@humusnshore.org'
    );

-- Role Permissions Policies
DROP POLICY IF EXISTS "Only super admins can manage role permissions" ON role_permissions;
CREATE POLICY "Only super admins can manage role permissions" ON role_permissions
    FOR ALL TO authenticated
    USING (
        (auth.jwt() ->> 'email') LIKE '%@andru.ai' OR
        (auth.jwt() ->> 'email') LIKE '%@humusnshore.org'
    );

-- Verify the policies are updated
SELECT schemaname, tablename, policyname, cmd, qual 
FROM pg_policies 
WHERE tablename IN ('user_roles', 'organizations', 'user_organizations', 'team_invitations', 
                   'user_profiles', 'permissions', 'user_permission_overrides', 'role_permissions')
AND qual LIKE '%humusnshore%';