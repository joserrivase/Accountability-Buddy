-- SIMPLEST FIX: Just disable RLS completely
-- Copy and paste this ENTIRE block into Supabase SQL Editor and click "Run"

ALTER TABLE feedback DISABLE ROW LEVEL SECURITY;

-- Verify it's disabled (should show rls_enabled = false)
SELECT relname, relrowsecurity as rls_enabled FROM pg_class WHERE relname = 'feedback';

