# Feedback Table Setup

This document contains the SQL commands to create the `feedback` table in Supabase.

## Table Schema

```sql
-- Create feedback table
CREATE TABLE IF NOT EXISTS feedback (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    message TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE feedback ENABLE ROW LEVEL SECURITY;

-- Drop existing policy if it exists (in case you need to recreate it)
DROP POLICY IF EXISTS "Allow public feedback submission" ON feedback;

-- Create policy to allow anyone to insert feedback (for public feedback submission)
-- This allows both anonymous and authenticated users to submit feedback
-- Using PUBLIC role makes it accessible to all users
CREATE POLICY "Allow public feedback submission"
    ON feedback
    FOR INSERT
    TO PUBLIC
    WITH CHECK (true);

-- Create policy to allow only authenticated users to read feedback (optional - for admin access)
-- Uncomment if you want to restrict reading feedback to authenticated users only
-- CREATE POLICY "Allow authenticated users to read feedback"
--     ON feedback
--     FOR SELECT
--     TO authenticated
--     USING (true);

-- Create index on created_at for better query performance
CREATE INDEX IF NOT EXISTS idx_feedback_created_at ON feedback(created_at DESC);
```

## Notes

- The table allows public insertion (anyone can submit feedback)
- Reading feedback is currently unrestricted, but you can add a policy to restrict it to authenticated users if needed
- The `created_at` field is automatically set to the current timestamp
- An index is created on `created_at` for better query performance when sorting by date

## Usage

1. Go to your Supabase dashboard
2. Navigate to SQL Editor
3. Paste the SQL commands above
4. Run the query to create the table and policies

