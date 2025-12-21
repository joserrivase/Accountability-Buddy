-- =====================================================
-- Add description column to goals table
-- =====================================================
-- This script adds an optional description field to the goals table
-- to allow users to provide additional context about their goals.
--
-- Run this script in your Supabase SQL Editor
-- =====================================================

-- Add the description column (nullable text field)
ALTER TABLE goals
ADD COLUMN IF NOT EXISTS description TEXT;

-- Add a comment to document the column
COMMENT ON COLUMN goals.description IS 'Optional description providing additional context about the goal';

-- =====================================================
-- Verification Queries
-- =====================================================
-- Run these queries to verify the column was added correctly:

-- 1. Check if the column exists
-- SELECT column_name, data_type, is_nullable
-- FROM information_schema.columns
-- WHERE table_name = 'goals' AND column_name = 'description';

-- 2. Check the structure of the goals table
-- SELECT column_name, data_type, is_nullable
-- FROM information_schema.columns
-- WHERE table_name = 'goals'
-- ORDER BY ordinal_position;

-- =====================================================
-- Notes:
-- =====================================================
-- - The column is nullable, so existing goals will have NULL descriptions
-- - New goals can optionally include a description
-- - The column uses TEXT type to allow for longer descriptions
-- =====================================================

