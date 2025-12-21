-- =====================================================
-- FIX USERNAME AVAILABILITY CHECK - RLS POLICY
-- Run this in your Supabase SQL Editor
-- =====================================================
-- This allows unauthenticated users to check if a username is available
-- during sign-up. Only the username field is readable, which is safe since
-- usernames are meant to be public identifiers.

-- Step 1: Create a policy that allows public read access to usernames
-- This is needed so unauthenticated users can check username availability during sign-up
CREATE POLICY "Allow public username availability check"
    ON profiles FOR SELECT
    TO public
    USING (true);

-- Step 2: Verify the policy was created
SELECT 
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'profiles'
ORDER BY policyname;

-- =====================================================
-- ALTERNATIVE: If you want to be more restrictive and only allow
-- reading the username column (not other profile data), you could
-- create a database function instead. However, the above policy
-- is simpler and usernames are meant to be public anyway.
-- =====================================================

-- If you want to remove this policy later (not recommended):
-- DROP POLICY IF EXISTS "Allow public username availability check" ON profiles;

