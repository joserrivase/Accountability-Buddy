-- Fix Feedback RLS Policy
-- Run this SQL in your Supabase SQL Editor to fix the feedback submission issue

-- First, drop any existing policies
DROP POLICY IF EXISTS "Allow public feedback submission" ON feedback;
DROP POLICY IF EXISTS "Allow authenticated feedback submission" ON feedback;

-- Create a policy that allows BOTH authenticated and anonymous users to insert feedback
-- This ensures feedback works whether the user is logged in or not
CREATE POLICY "Allow all users to submit feedback"
    ON feedback
    FOR INSERT
    TO PUBLIC
    WITH CHECK (true);

-- Optional: If you want to track which user submitted feedback (if logged in),
-- you can add a user_id column and update the policy:
-- ALTER TABLE feedback ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id);
-- 
-- Then update the policy to:
-- CREATE POLICY "Allow all users to submit feedback"
--     ON feedback
--     FOR INSERT
--     TO PUBLIC
--     WITH CHECK (true);

-- Verify the policy was created
SELECT * FROM pg_policies WHERE tablename = 'feedback';

