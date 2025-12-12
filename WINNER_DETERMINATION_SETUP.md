# Winner Determination Feature - Database Setup

This document provides SQL commands to set up the database schema for the winner determination feature.

## 1. Add New Columns to `goals` Table

```sql
-- Add winner_user_id column
ALTER TABLE goals
ADD COLUMN IF NOT EXISTS winner_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- Add loser_user_id column
ALTER TABLE goals
ADD COLUMN IF NOT EXISTS loser_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- Create goal_status enum type
DO $$ BEGIN
    CREATE TYPE goal_status AS ENUM ('active', 'pending_finish', 'finished');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Add goal_status column with default value 'active'
ALTER TABLE goals
ADD COLUMN IF NOT EXISTS goal_status goal_status DEFAULT 'active'::goal_status;

-- Update existing goals to have 'active' status if NULL
UPDATE goals
SET goal_status = 'active'::goal_status
WHERE goal_status IS NULL;
```

## 2. Add New Column to `goal_progress` Table

```sql
-- Add has_seen_winner_message column
ALTER TABLE goal_progress
ADD COLUMN IF NOT EXISTS has_seen_winner_message BOOLEAN DEFAULT FALSE;
```

## 3. Update Row Level Security (RLS) Policies

The existing RLS policies should already allow users to read and update their own goals and progress. The new columns don't require additional policies, but ensure these exist:

**Note:** PostgreSQL doesn't support `IF NOT EXISTS` for `CREATE POLICY` statements. The approach below uses `DROP POLICY IF EXISTS` which will safely drop policies if they exist, then creates them. This section is optional - you can skip it if your existing policies already work correctly.

```sql
-- Drop policies if they exist (ignore errors if they don't)
DROP POLICY IF EXISTS "Users can read their own goals" ON goals;
DROP POLICY IF EXISTS "Users can update their own goals" ON goals;
DROP POLICY IF EXISTS "Users can read progress for their goals" ON goal_progress;
DROP POLICY IF EXISTS "Users can update their own progress" ON goal_progress;

-- Create goals policies
CREATE POLICY "Users can read their own goals"
    ON goals FOR SELECT
    TO authenticated
    USING (
        creator_id = auth.uid() OR
        buddy_id = auth.uid()
    );

CREATE POLICY "Users can update their own goals"
    ON goals FOR UPDATE
    TO authenticated
    USING (creator_id = auth.uid());

-- Create goal_progress policies
CREATE POLICY "Users can read progress for their goals"
    ON goal_progress FOR SELECT
    TO authenticated
    USING (
        user_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM goals
            WHERE goals.id = goal_progress.goal_id
            AND (goals.creator_id = auth.uid() OR goals.buddy_id = auth.uid())
        )
    );

CREATE POLICY "Users can update their own progress"
    ON goal_progress FOR UPDATE
    TO authenticated
    USING (user_id = auth.uid());
```

## 4. Create Indexes (Optional but Recommended)

```sql
-- Index for faster queries on goal_status
CREATE INDEX IF NOT EXISTS idx_goals_status ON goals(goal_status);

-- Index for faster queries on winner_user_id
CREATE INDEX IF NOT EXISTS idx_goals_winner_user_id ON goals(winner_user_id);

-- Index for faster queries on has_seen_winner_message
CREATE INDEX IF NOT EXISTS idx_goal_progress_has_seen_winner_message 
    ON goal_progress(has_seen_winner_message);
```

## 5. Create Supabase Function for End Date Checking (Optional)

If you want to automatically check end dates, you can create a Supabase Edge Function or use a cron job. Here's an example SQL function that can be called periodically:

```sql
-- Function to check end dates and determine winners
CREATE OR REPLACE FUNCTION check_goal_end_dates()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    goal_record RECORD;
BEGIN
    -- Find all active challenge goals with end dates that have passed
    FOR goal_record IN
        SELECT id, creator_id, buddy_id, end_date, winning_condition
        FROM goals
        WHERE challenge_or_friendly = 'challenge'
          AND goal_status = 'active'
          AND end_date IS NOT NULL
          AND end_date <= NOW()
    LOOP
        -- This would trigger the winner determination logic
        -- In practice, you'd call your application's checkAndDetermineWinner function
        -- For now, this is a placeholder
        RAISE NOTICE 'Goal % has reached its end date', goal_record.id;
    END LOOP;
END;
$$;
```

## 6. Notes

- The `goal_status` enum has three values:
  - `active`: Goal is still in progress
  - `pending_finish`: Winner has been determined, waiting for users to see the message
  - `finished`: Both users have seen the message, goal is complete

- The `has_seen_winner_message` field tracks whether each user has seen the winner/loser message. Once both users have seen it, the goal status is updated to `finished`.

- Winner determination happens automatically when progress is updated (for "first to reach" conditions) or when the end date passes (for "most by end date" conditions).

- For end date checking, you may want to set up a cron job or Supabase Edge Function that calls `checkEndDatesAndDetermineWinners()` periodically (e.g., daily at midnight).

## 7. Testing

After running these SQL commands, test the feature by:

1. Creating a challenge goal with a buddy
2. Updating progress until a winner condition is met
3. Verifying that the goal_status changes to 'pending_finish'
4. Verifying that winner_user_id and loser_user_id are set
5. Opening the goal and verifying the winner modal appears
6. Closing the modal and verifying has_seen_winner_message is set to true
7. Verifying that when both users have seen the message, goal_status changes to 'finished'
8. Verifying that finished goals appear in the "Finished" tab

