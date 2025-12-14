-- Fix Feedback Table to Support User ID and RLS
-- Run this SQL in your Supabase SQL Editor

-- Step 1: Add user_id column to feedback table (nullable for anonymous users)
-- If the column already exists with ON DELETE SET NULL, we'll update it to CASCADE

-- First, drop any existing foreign key constraint on user_id
DO $$ 
DECLARE
    constraint_name_var TEXT;
BEGIN
    -- Find the constraint name for user_id foreign key
    SELECT tc.constraint_name INTO constraint_name_var
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu 
        ON tc.constraint_name = kcu.constraint_name
    WHERE tc.table_name = 'feedback' 
    AND kcu.column_name = 'user_id'
    AND tc.constraint_type = 'FOREIGN KEY'
    LIMIT 1;
    
    -- Drop the constraint if it exists
    IF constraint_name_var IS NOT NULL THEN
        EXECUTE 'ALTER TABLE feedback DROP CONSTRAINT ' || constraint_name_var;
    END IF;
END $$;

-- Add the column if it doesn't exist
ALTER TABLE feedback 
ADD COLUMN IF NOT EXISTS user_id UUID;

-- Add the foreign key constraint with CASCADE
-- This will recreate the constraint with ON DELETE CASCADE
ALTER TABLE feedback
DROP CONSTRAINT IF EXISTS feedback_user_id_fkey;

ALTER TABLE feedback
ADD CONSTRAINT feedback_user_id_fkey 
FOREIGN KEY (user_id) 
REFERENCES auth.users(id) 
ON DELETE CASCADE;

-- Step 2: Create an index on user_id for better query performance
CREATE INDEX IF NOT EXISTS idx_feedback_user_id ON feedback(user_id);

-- Step 3: Drop any existing policies
DROP POLICY IF EXISTS "Allow public feedback submission" ON feedback;
DROP POLICY IF EXISTS "Allow authenticated feedback submission" ON feedback;
DROP POLICY IF EXISTS "Allow all users to submit feedback" ON feedback;

-- Step 4: Create RLS policy that allows:
--   - Authenticated users to insert feedback with their own user_id
--   - Anonymous users to insert feedback without user_id (null)
CREATE POLICY "Allow authenticated users to submit feedback"
    ON feedback
    FOR INSERT
    TO authenticated
    WITH CHECK (
        -- Authenticated users can only insert with their own user_id or null
        (user_id IS NULL OR user_id = auth.uid())
    );

-- Step 5: Also allow anonymous users (unauthenticated) to submit feedback
-- This allows feedback from users who aren't logged in
CREATE POLICY "Allow anonymous feedback submission"
    ON feedback
    FOR INSERT
    TO anon
    WITH CHECK (user_id IS NULL);

-- Step 6: Optional - Allow users to read their own feedback (if you want to show feedback history)
-- Uncomment if you want users to be able to see their own feedback
-- CREATE POLICY "Users can read their own feedback"
--     ON feedback
--     FOR SELECT
--     TO authenticated
--     USING (user_id = auth.uid());

-- Verify the policies were created
SELECT * FROM pg_policies WHERE tablename = 'feedback';

