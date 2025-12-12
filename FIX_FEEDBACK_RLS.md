# Fix Feedback RLS Policy

If you're getting a "new row violates row-level security policy" error when submitting feedback, run this SQL in your Supabase SQL Editor to fix it:

```sql
-- First, drop the existing policy if it exists
DROP POLICY IF EXISTS "Allow public feedback submission" ON feedback;

-- Recreate the policy with explicit PUBLIC role access
CREATE POLICY "Allow public feedback submission"
    ON feedback
    FOR INSERT
    TO PUBLIC
    WITH CHECK (true);

-- If the above doesn't work, try this alternative approach:
-- Allow authenticated users to insert (since the app uses authentication)
DROP POLICY IF EXISTS "Allow authenticated feedback submission" ON feedback;

CREATE POLICY "Allow authenticated feedback submission"
    ON feedback
    FOR INSERT
    TO authenticated
    WITH CHECK (true);
```

## Alternative: Disable RLS (Not Recommended for Production)

If you want to allow all inserts without any restrictions (for testing only):

```sql
-- DISABLE Row Level Security (not recommended for production)
ALTER TABLE feedback DISABLE ROW LEVEL SECURITY;
```

**Note:** Disabling RLS removes all security restrictions. Only do this for testing.

## Recommended Solution

The best approach is to ensure authenticated users can insert feedback. Run the "Allow authenticated feedback submission" policy from above, as your app uses Supabase authentication.

