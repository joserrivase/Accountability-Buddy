# Fix Feedback RLS Policy

If you're getting a "new row violates row-level security policy" error when submitting feedback, run this SQL in your Supabase SQL Editor to fix it:

## Recommended Solution: Add User ID Column (Best for Authenticated Users)

This approach adds a `user_id` column to track which user submitted feedback, and creates proper RLS policies that work with authenticated users.

**See `FIX_FEEDBACK_WITH_USER_ID.sql` for the complete solution.**

This solution:
- Adds a `user_id` column (nullable for anonymous users)
- Allows authenticated users to insert feedback with their own `user_id`
- Allows anonymous users to insert feedback without `user_id`
- Provides better tracking and security

## Alternative Solution (Allows Both Authenticated and Anonymous Users Without User ID)

```sql
-- First, drop any existing policies
DROP POLICY IF EXISTS "Allow public feedback submission" ON feedback;
DROP POLICY IF EXISTS "Allow authenticated feedback submission" ON feedback;
DROP POLICY IF EXISTS "Allow all users to submit feedback" ON feedback;

-- Create a policy that allows BOTH authenticated and anonymous users to insert feedback
-- This ensures feedback works whether the user is logged in or not
CREATE POLICY "Allow all users to submit feedback"
    ON feedback
    FOR INSERT
    TO PUBLIC
    WITH CHECK (true);
```

This policy uses `TO PUBLIC` which allows both authenticated and anonymous users to submit feedback, which is what you want for a feedback form.

## Verify the Policy

After running the SQL above, verify the policy was created:

```sql
SELECT * FROM pg_policies WHERE tablename = 'feedback';
```

You should see a policy named "Allow all users to submit feedback" with `cmd` = 'INSERT' and `roles` = '{public}'.

## Alternative: Disable RLS (Not Recommended for Production)

If you want to allow all inserts without any restrictions (for testing only):

```sql
-- DISABLE Row Level Security (not recommended for production)
ALTER TABLE feedback DISABLE ROW LEVEL SECURITY;
```

**Note:** Disabling RLS removes all security restrictions. Only do this for testing.

