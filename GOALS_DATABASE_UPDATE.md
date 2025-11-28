# Goals Database Update - Questionnaire Answers

This document provides SQL commands to update the `goals` table to store all questionnaire answers.

## Update Goals Table Schema

Run this SQL in your Supabase SQL Editor to add the new columns:

```sql
-- Add questionnaire answer columns to goals table
ALTER TABLE goals
ADD COLUMN IF NOT EXISTS goal_type TEXT,
ADD COLUMN IF NOT EXISTS task_being_tracked TEXT,
ADD COLUMN IF NOT EXISTS list_items TEXT[],
ADD COLUMN IF NOT EXISTS keep_streak BOOLEAN,
ADD COLUMN IF NOT EXISTS track_daily_quantity BOOLEAN,
ADD COLUMN IF NOT EXISTS unit_tracked TEXT,
ADD COLUMN IF NOT EXISTS challenge_or_friendly TEXT,
ADD COLUMN IF NOT EXISTS winning_condition TEXT,
ADD COLUMN IF NOT EXISTS winning_number INTEGER,
ADD COLUMN IF NOT EXISTS end_date TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS winners_prize TEXT;

-- Add comments to document the columns
COMMENT ON COLUMN goals.goal_type IS 'Type of goal: list_tracker, daily_tracker, or list_created_by_user';
COMMENT ON COLUMN goals.task_being_tracked IS 'Task description for list_tracker goals (e.g., "Books Read")';
COMMENT ON COLUMN goals.list_items IS 'Array of items for list_created_by_user goals';
COMMENT ON COLUMN goals.keep_streak IS 'Whether to track daily streak for daily_tracker goals';
COMMENT ON COLUMN goals.track_daily_quantity IS 'Whether to track daily quantity for daily_tracker goals';
COMMENT ON COLUMN goals.unit_tracked IS 'Unit for daily quantity tracking (e.g., "Mi", "Km", "Pages")';
COMMENT ON COLUMN goals.challenge_or_friendly IS 'Mode: "challenge" or "friendly"';
COMMENT ON COLUMN goals.winning_condition IS 'Winning condition description for challenge mode';
COMMENT ON COLUMN goals.winning_number IS 'Target number for winning condition';
COMMENT ON COLUMN goals.end_date IS 'End date for challenge mode';
COMMENT ON COLUMN goals.winners_prize IS 'Prize description for challenge mode';
```

## Column Descriptions

### goal_type
- **Type:** TEXT
- **Values:** `"list_tracker"`, `"daily_tracker"`, `"list_created_by_user"`
- **Description:** The type of goal selected in the questionnaire

### task_being_tracked
- **Type:** TEXT
- **Description:** For `list_tracker` goals, this is the task description (e.g., "Books Read", "Projects Completed")

### list_items
- **Type:** TEXT[]
- **Description:** For `list_created_by_user` goals, this is an array of items the user wants to complete

### keep_streak
- **Type:** BOOLEAN
- **Description:** For `daily_tracker` goals, whether the user wants to track a daily streak

### track_daily_quantity
- **Type:** BOOLEAN
- **Description:** For `daily_tracker` goals, whether the user wants to track a daily quantity

### unit_tracked
- **Type:** TEXT
- **Description:** For `daily_tracker` goals with quantity tracking, the unit (e.g., "Mi", "Km", "Pages", "Min", "Hr", or custom)

### challenge_or_friendly
- **Type:** TEXT
- **Values:** `"challenge"` or `"friendly"`
- **Description:** Whether the goal is in challenge mode or friendly mode

### winning_condition
- **Type:** TEXT
- **Description:** For challenge mode, the description of the winning condition

### winning_number
- **Type:** INTEGER
- **Description:** For challenge mode, the target number to reach (if applicable)

### end_date
- **Type:** TIMESTAMP WITH TIME ZONE
- **Description:** For challenge mode, the end date of the challenge (if applicable)

### winners_prize
- **Type:** TEXT
- **Description:** For challenge mode, the prize description

## Notes

- All new columns are nullable (optional) to support existing goals and different goal types
- The columns will only be populated based on the goal type and mode selected
- For example:
  - `list_tracker` goals will have `task_being_tracked` populated
  - `list_created_by_user` goals will have `list_items` populated
  - `daily_tracker` goals will have `keep_streak`, `track_daily_quantity`, and optionally `unit_tracked` populated
  - Challenge mode goals will have `challenge_or_friendly`, `winning_condition`, and optionally `winning_number`, `end_date`, and `winners_prize` populated

## Verification

After running the SQL, verify the columns were added:

```sql
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'goals'
ORDER BY ordinal_position;
```

You should see all the new columns listed.

## Note on Tracking Method

The `tracking_method` column is still used for backward compatibility and progress tracking logic. You can keep it as-is. The new `goal_type` field provides more detailed information about the goal type, while `tracking_method` determines which progress fields are used.

## No Changes Needed to goal_progress Table

The existing `goal_progress` table structure supports all tracking scenarios:
- `numeric_value` - for totals and daily quantity totals
- `completed_days` - for day tracking
- `list_items` (JSONB) - for list items and daily quantity entries

No schema changes are required for the `goal_progress` table.

