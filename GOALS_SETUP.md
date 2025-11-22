//
//  GOALS_SETUP.md
//  Accountability Buddy
//
//  Created by Jose Rivas on 11/9/25.
//

# Goals Feature Setup Instructions

## 1. Create Goals Table in Supabase

1. Go to your Supabase dashboard
2. Navigate to **SQL Editor**
3. Click **"New query"**
4. Paste and run this SQL:

```sql
-- Create goals table
CREATE TABLE IF NOT EXISTS goals (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    tracking_method TEXT NOT NULL CHECK (tracking_method IN ('input_numbers', 'track_days_completed', 'input_list')),
    creator_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    buddy_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()) NOT NULL
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_goals_creator_id ON goals(creator_id);
CREATE INDEX IF NOT EXISTS idx_goals_buddy_id ON goals(buddy_id);

-- Enable Row Level Security
ALTER TABLE goals ENABLE ROW LEVEL SECURITY;

-- Create policy to allow users to read goals they're involved in
CREATE POLICY "Users can read their own goals"
    ON goals FOR SELECT
    USING (auth.uid() = creator_id OR auth.uid() = buddy_id);

-- Create policy to allow users to insert their own goals
CREATE POLICY "Users can insert their own goals"
    ON goals FOR INSERT
    WITH CHECK (auth.uid() = creator_id);

-- Create policy to allow users to update goals they created
CREATE POLICY "Users can update goals they created"
    ON goals FOR UPDATE
    USING (auth.uid() = creator_id)
    WITH CHECK (auth.uid() = creator_id);

-- Create policy to allow users to delete goals they created
CREATE POLICY "Users can delete goals they created"
    ON goals FOR DELETE
    USING (auth.uid() = creator_id);

-- Create function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_goals_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = TIMEZONE('utc', NOW());
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to automatically update updated_at
CREATE TRIGGER update_goals_updated_at BEFORE UPDATE ON goals
    FOR EACH ROW EXECUTE FUNCTION update_goals_updated_at_column();
```

5. Click **"Run"** to execute the query

> **Note:** If you created the `goal_progress` table before this update and the `list_items` column is still of type `TEXT[]`, run the following command to convert it to `JSONB` so we can store structured list entries with timestamps:
>
> ```sql
> ALTER TABLE goal_progress
> ALTER COLUMN list_items TYPE JSONB USING list_items::jsonb;
> ```
>
> (Run this only once to migrate existing setups.)

## 2. Create Goal Progress Table

1. In the same SQL Editor, create a new query
2. Paste and run this SQL:

```sql
-- Create goal_progress table
CREATE TABLE IF NOT EXISTS goal_progress (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    goal_id UUID NOT NULL REFERENCES goals(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    numeric_value DOUBLE PRECISION,
    completed_days TEXT[], -- Array of date strings (YYYY-MM-DD)
    list_items JSONB, -- Array of completed items (stored as JSON objects with id/title/date)
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()) NOT NULL,
    UNIQUE(goal_id, user_id)
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_goal_progress_goal_id ON goal_progress(goal_id);
CREATE INDEX IF NOT EXISTS idx_goal_progress_user_id ON goal_progress(user_id);

-- Enable Row Level Security
ALTER TABLE goal_progress ENABLE ROW LEVEL SECURITY;

-- Create policy to allow users to read progress for goals they're involved in
CREATE POLICY "Users can read progress for their goals"
    ON goal_progress FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM goals 
            WHERE goals.id = goal_progress.goal_id 
            AND (goals.creator_id = auth.uid() OR goals.buddy_id = auth.uid())
        )
    );

-- Create policy to allow users to insert their own progress
CREATE POLICY "Users can insert their own progress"
    ON goal_progress FOR INSERT
    WITH CHECK (
        auth.uid() = user_id AND
        EXISTS (
            SELECT 1 FROM goals 
            WHERE goals.id = goal_progress.goal_id 
            AND (goals.creator_id = auth.uid() OR goals.buddy_id = auth.uid())
        )
    );

-- Create policy to allow users to update their own progress
CREATE POLICY "Users can update their own progress"
    ON goal_progress FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Create policy to allow users to delete their own progress
CREATE POLICY "Users can delete their own progress"
    ON goal_progress FOR DELETE
    USING (auth.uid() = user_id);

-- Create function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_goal_progress_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = TIMEZONE('utc', NOW());
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to automatically update updated_at
CREATE TRIGGER update_goal_progress_updated_at BEFORE UPDATE ON goal_progress
    FOR EACH ROW EXECUTE FUNCTION update_goal_progress_updated_at_column();
```

3. Click **"Run"** to execute the query

## 3. Verify Tables Created

After running the SQL, verify that:
- The `goals` table was created
- The `goal_progress` table was created
- Row Level Security is enabled on both tables
- All policies were created successfully
- Indexes were created

## Notes

- Goals can be created with or without a buddy (buddy_id can be NULL)
- Each user can only have one progress entry per goal (enforced by UNIQUE constraint)
- Progress tracking varies by method:
  - `input_numbers`: Stores numeric value in `numeric_value`
  - `track_days_completed`: Stores array of date strings in `completed_days`
  - `input_list`: Stores array of items in `list_items`
- The `updated_at` field is automatically updated when a goal or progress is modified
- Goals are automatically deleted when the creator is deleted (CASCADE)
- Progress is automatically deleted when a goal or user is deleted (CASCADE)

## Testing

To test the goals feature:

1. Create a goal with a tracking method
2. Optionally add an accountability buddy
3. Update your progress based on the tracking method
4. Verify your buddy can see your progress (if buddy was added)
5. Verify you can see your buddy's progress

## Troubleshooting

### "Permission denied" errors
- Make sure Row Level Security policies are set up correctly
- Verify that the user is authenticated
- Check that the policies allow the operation you're trying to perform

### Goals not showing
- Verify that goals were created with the correct creator_id
- Check that you're viewing goals where you're either creator or buddy
- Ensure RLS policies allow SELECT for goals you're involved in

### Progress not updating
- Verify that the goal_id and user_id match
- Check that you're updating your own progress (user_id must match auth.uid())
- Ensure the tracking method matches the data you're trying to update

