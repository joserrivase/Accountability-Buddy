//
//  NOTIFICATIONS_SETUP.md
//  Accountability Buddy
//
//  Created by Jose Rivas on 11/9/25.
//

# Notifications Feature Setup Instructions

## 1. Create Notifications Table in Supabase

1. Go to your Supabase dashboard
2. Navigate to **SQL Editor**
3. Click **"New query"**
4. Paste and run this SQL:

```sql
-- Create notifications table
CREATE TABLE IF NOT EXISTS notifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('friend_request', 'goal_update')),
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    related_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    related_goal_id UUID REFERENCES goals(id) ON DELETE SET NULL,
    is_read BOOLEAN DEFAULT FALSE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()) NOT NULL
);

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(user_id, is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);

-- Enable Row Level Security
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Create policy to allow users to read their own notifications
CREATE POLICY "Users can read their own notifications"
    ON notifications FOR SELECT
    USING (auth.uid() = user_id);

-- Create policy to allow users to insert notifications for themselves
-- (This is primarily for system-generated notifications, but users could create their own)
CREATE POLICY "Users can insert their own notifications"
    ON notifications FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Create policy to allow users to update their own notifications
CREATE POLICY "Users can update their own notifications"
    ON notifications FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Create policy to allow users to delete their own notifications
CREATE POLICY "Users can delete their own notifications"
    ON notifications FOR DELETE
    USING (auth.uid() = user_id);
```

5. Click **"Run"** to execute the query

## 2. Create Function to Auto-Create Friend Request Notifications

1. In the same SQL Editor, create a new query
2. Paste and run this SQL to create a function that automatically creates notifications when friend requests are sent:

```sql
-- Create function to notify user when they receive a friend request
CREATE OR REPLACE FUNCTION notify_friend_request()
RETURNS TRIGGER AS $$
DECLARE
    from_user_name TEXT;
    from_user_username TEXT;
BEGIN
    -- Get the sender's profile info
    SELECT name, username INTO from_user_name, from_user_username
    FROM profiles
    WHERE user_id = NEW.user_id;
    
    -- Create notification for the recipient
    INSERT INTO notifications (user_id, type, title, message, related_user_id, is_read)
    VALUES (
        NEW.friend_id,
        'friend_request',
        'New Friend Request',
        COALESCE(from_user_name, from_user_username, 'Someone') || ' wants to be your friend',
        NEW.user_id,
        FALSE
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to automatically create notification on friend request
CREATE TRIGGER on_friend_request
    AFTER INSERT ON friendships
    FOR EACH ROW
    WHEN (NEW.status = 'pending')
    EXECUTE FUNCTION notify_friend_request();
```

3. Click **"Run"** to execute the query

## 3. Create Function to Auto-Create Goal Update Notifications

1. In the same SQL Editor, create a new query
2. Paste and run this SQL to create a function that automatically creates notifications when goal progress is updated:

```sql
-- Create function to notify goal buddies when progress is updated
CREATE OR REPLACE FUNCTION notify_goal_update()
RETURNS TRIGGER AS $$
DECLARE
    goal_record RECORD;
    user_name TEXT;
    user_username TEXT;
    buddy_id_to_notify UUID;
BEGIN
    -- Get the goal details
    SELECT * INTO goal_record
    FROM goals
    WHERE id = NEW.goal_id;
    
    -- Get the user's profile info
    SELECT name, username INTO user_name, user_username
    FROM profiles
    WHERE user_id = NEW.user_id;
    
    -- Notify the buddy if the user is the creator
    IF goal_record.creator_id = NEW.user_id AND goal_record.buddy_id IS NOT NULL THEN
        buddy_id_to_notify := goal_record.buddy_id;
    -- Notify the creator if the user is the buddy
    ELSIF goal_record.buddy_id = NEW.user_id THEN
        buddy_id_to_notify := goal_record.creator_id;
    END IF;
    
    -- Create notification if there's someone to notify
    IF buddy_id_to_notify IS NOT NULL THEN
        INSERT INTO notifications (user_id, type, title, message, related_user_id, related_goal_id, is_read)
        VALUES (
            buddy_id_to_notify,
            'goal_update',
            'Goal Update',
            COALESCE(user_name, user_username, 'Your buddy') || ' updated progress on "' || goal_record.name || '"',
            NEW.user_id,
            NEW.goal_id,
            FALSE
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to automatically create notification on goal progress update
CREATE TRIGGER on_goal_progress_update
    AFTER INSERT OR UPDATE ON goal_progress
    FOR EACH ROW
    EXECUTE FUNCTION notify_goal_update();
```

3. Click **"Run"** to execute the query

## 4. Verify Tables and Functions Created

After running the SQL, verify that:
- The `notifications` table was created
- Row Level Security is enabled on the notifications table
- All policies were created successfully
- Indexes were created
- The triggers and functions were created successfully

## Notes

- Notifications are automatically created when:
  - Someone sends you a friend request
  - Your accountability buddy updates progress on a shared goal
- Notifications are marked as read when the user taps on them
- Users can mark all notifications as read at once
- Notifications are automatically deleted when a user is deleted (CASCADE)
- Goal-related notifications are automatically deleted when a goal is deleted (CASCADE)

## Testing

To test the notifications feature:

1. Have one user send a friend request to another
   - The recipient should receive a notification
2. Have one user update progress on a shared goal
   - Their buddy should receive a notification
3. Mark notifications as read and verify they update
4. Delete notifications and verify they are removed

## Troubleshooting

### "Permission denied" errors
- Make sure Row Level Security policies are set up correctly
- Verify that the user is authenticated
- Check that the policies allow the operation you're trying to perform

### Notifications not being created
- Check that the triggers were created successfully
- Verify that the functions have SECURITY DEFINER (required to insert notifications for other users)
- Check the Supabase logs for any errors in the trigger functions

### Notifications not showing
- Verify that notifications were created in the database
- Check that the user_id matches the authenticated user
- Ensure the app is fetching notifications correctly

