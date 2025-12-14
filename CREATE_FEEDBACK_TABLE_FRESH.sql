-- Create Feedback Table from Scratch with User ID
-- Run this SQL in your Supabase SQL Editor

-- Step 1: Drop existing feedback table and all its policies (if they exist)
DROP TABLE IF EXISTS feedback CASCADE;

-- Step 2: Create the feedback table with user_id referencing auth.users
CREATE TABLE feedback (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    message TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Step 3: Enable Row Level Security
ALTER TABLE feedback ENABLE ROW LEVEL SECURITY;

-- Step 4: Create a policy that allows authenticated users to insert feedback with their own user_id
CREATE POLICY "Allow authenticated users to submit feedback"
    ON feedback
    FOR INSERT
    TO authenticated
    WITH CHECK (
        -- Users can only insert feedback with their own user_id
        user_id = auth.uid()
    );

-- Step 5: Create indexes for better query performance
CREATE INDEX idx_feedback_created_at ON feedback(created_at DESC);
CREATE INDEX idx_feedback_user_id ON feedback(user_id);

-- Verify the table and policy were created
SELECT * FROM pg_policies WHERE tablename = 'feedback';

