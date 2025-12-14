-- =====================================================
-- FIX FEEDBACK TABLE - COMPLETE SOLUTION
-- Run this ENTIRE script in your Supabase SQL Editor
-- =====================================================

-- STEP 1: Check if the feedback table exists and its structure
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'feedback'
ORDER BY ordinal_position;

-- STEP 2: Drop ALL existing policies on feedback table
DROP POLICY IF EXISTS "Allow public feedback submission" ON feedback;
DROP POLICY IF EXISTS "Allow authenticated feedback submission" ON feedback;
DROP POLICY IF EXISTS "Allow all users to submit feedback" ON feedback;
DROP POLICY IF EXISTS "Users can insert their own feedback" ON feedback;
DROP POLICY IF EXISTS "Authenticated users can insert feedback" ON feedback;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON feedback;
DROP POLICY IF EXISTS "Enable insert for users based on user_id" ON feedback;

-- STEP 3: Ensure RLS is enabled
ALTER TABLE feedback ENABLE ROW LEVEL SECURITY;

-- STEP 4: Create the correct policy
-- This policy allows authenticated users to insert feedback
-- where the user_id matches their auth.uid()
CREATE POLICY "Authenticated users can insert feedback"
    ON feedback
    FOR INSERT
    TO authenticated
    WITH CHECK (user_id = auth.uid());

-- STEP 5: Verify the policy was created
SELECT 
    policyname,
    permissive,
    roles,
    cmd,
    with_check
FROM pg_policies 
WHERE tablename = 'feedback';

-- =====================================================
-- IF THE ABOVE DOESN'T WORK, TRY THIS SIMPLER APPROACH
-- =====================================================
-- Uncomment and run these lines instead:

DROP POLICY IF EXISTS "Authenticated users can insert feedback" ON feedback;

CREATE POLICY "Authenticated users can insert feedback"
    ON feedback
    FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- =====================================================
-- NUCLEAR OPTION: RECREATE THE TABLE FROM SCRATCH
-- Only use this if nothing else works!
-- =====================================================
-- WARNING: This will DELETE all existing feedback data!

DROP TABLE IF EXISTS feedback CASCADE;

CREATE TABLE feedback (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    message TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE feedback ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can insert feedback"
    ON feedback
    FOR INSERT
    TO authenticated
    WITH CHECK (user_id = auth.uid());
