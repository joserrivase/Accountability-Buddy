-- =====================================================
-- ADD FIRST_NAME AND LAST_NAME COLUMNS TO PROFILES TABLE
-- Run this in your Supabase SQL Editor
-- =====================================================
-- This migration safely adds first_name and last_name columns
-- and migrates existing name data without breaking anything.

-- Step 1: Add the new columns (nullable initially)
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS first_name TEXT,
ADD COLUMN IF NOT EXISTS last_name TEXT;

-- Step 2: Migrate existing name data to first_name and last_name
-- This splits the existing name field into first and last name
-- Using a simpler approach with regexp_split_to_array
UPDATE profiles
SET 
    first_name = CASE 
        WHEN name IS NOT NULL AND TRIM(name) != '' THEN
            -- Get first word as first name
            (regexp_split_to_array(TRIM(name), '\s+'))[1]
        ELSE NULL
    END,
    last_name = CASE 
        WHEN name IS NOT NULL AND TRIM(name) != '' THEN
            -- Get everything after first word as last name
            CASE 
                WHEN array_length(regexp_split_to_array(TRIM(name), '\s+'), 1) > 1 THEN
                    -- Join all words after the first one
                    array_to_string(
                        (regexp_split_to_array(TRIM(name), '\s+'))[2:],
                        ' '
                    )
                ELSE NULL
            END
        ELSE NULL
    END
WHERE (first_name IS NULL OR last_name IS NULL) 
  AND name IS NOT NULL 
  AND TRIM(name) != '';

-- Step 3: Verify the migration
-- Check how many profiles were updated
SELECT 
    COUNT(*) as total_profiles,
    COUNT(name) as profiles_with_name,
    COUNT(first_name) as profiles_with_first_name,
    COUNT(last_name) as profiles_with_last_name
FROM profiles;

-- Step 4: Show sample of migrated data
SELECT 
    id,
    name as old_name,
    first_name,
    last_name,
    username
FROM profiles
LIMIT 10;

-- =====================================================
-- OPTIONAL: After verifying the migration works correctly,
-- you can keep the name column for backward compatibility
-- or remove it later with:
-- =====================================================
-- ALTER TABLE profiles DROP COLUMN name;
-- 
-- However, I recommend keeping it for now in case you need
-- to reference it or roll back. You can remove it later
-- once you're confident everything works.

