-- =====================================================
-- DIAGNOSTIC SCRIPT FOR FEEDBACK TABLE
-- Run this in Supabase SQL Editor and share the output
-- =====================================================

-- 1. Check if feedback table exists and show its structure
SELECT '=== TABLE STRUCTURE ===' as info;
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'feedback'
ORDER BY ordinal_position;

-- 2. Show ALL policies on feedback table
SELECT '=== ALL POLICIES ===' as info;
SELECT 
    policyname,
    permissive,
    roles,
    cmd,
    qual::text as using_expression,
    with_check::text as with_check_expression
FROM pg_policies 
WHERE tablename = 'feedback';

-- 3. Check if RLS is enabled
SELECT '=== RLS STATUS ===' as info;
SELECT 
    relname as table_name,
    relrowsecurity as rls_enabled,
    relforcerowsecurity as rls_forced
FROM pg_class
WHERE relname = 'feedback';

-- 4. Check for any triggers on the table
SELECT '=== TRIGGERS ===' as info;
SELECT 
    trigger_name,
    event_manipulation,
    action_statement
FROM information_schema.triggers
WHERE event_object_table = 'feedback';

-- 5. Check foreign key constraints
SELECT '=== FOREIGN KEYS ===' as info;
SELECT
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.table_name = 'feedback' AND tc.constraint_type = 'FOREIGN KEY';

-- =====================================================
-- NUCLEAR FIX: COMPLETELY DISABLE RLS FOR TESTING
-- =====================================================
-- Run this section to completely disable RLS and test if the insert works

-- First, drop ALL policies
DROP POLICY IF EXISTS "Allow public feedback submission" ON feedback;
DROP POLICY IF EXISTS "Allow authenticated feedback submission" ON feedback;
DROP POLICY IF EXISTS "Allow all users to submit feedback" ON feedback;
DROP POLICY IF EXISTS "Users can insert their own feedback" ON feedback;
DROP POLICY IF EXISTS "Authenticated users can insert feedback" ON feedback;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON feedback;
DROP POLICY IF EXISTS "Enable insert for users based on user_id" ON feedback;

-- Now DISABLE RLS completely
ALTER TABLE feedback DISABLE ROW LEVEL SECURITY;

-- Verify RLS is disabled
SELECT '=== RLS STATUS AFTER DISABLE ===' as info;
SELECT 
    relname as table_name,
    relrowsecurity as rls_enabled
FROM pg_class
WHERE relname = 'feedback';

-- =====================================================
-- TEST: Try a manual insert to verify the table works
-- Replace 'YOUR-USER-ID-HERE' with an actual user ID from your auth.users table
-- =====================================================
-- First, get a user ID:
SELECT '=== SAMPLE USER IDS ===' as info;
SELECT id FROM auth.users LIMIT 3;

-- Then try inserting (uncomment and replace the UUID):
-- INSERT INTO feedback (user_id, name, email, message) 
-- VALUES ('PUT-A-REAL-USER-ID-HERE', 'Test', 'test@test.com', 'Test message');

