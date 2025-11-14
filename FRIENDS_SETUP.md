//
//  FRIENDS_SETUP.md
//  Accountability Buddy
//
//  Created by Jose Rivas on 11/9/25.
//

# Friends Feature Setup Instructions

## 1. Create Friendships Table in Supabase

1. Go to your Supabase dashboard
2. Navigate to **SQL Editor**
3. Click **"New query"**
4. Paste and run this SQL:

```sql
-- Create friendships table
CREATE TABLE IF NOT EXISTS friendships (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    friend_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'blocked')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()) NOT NULL,
    UNIQUE(user_id, friend_id),
    CHECK (user_id != friend_id)
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_friendships_user_id ON friendships(user_id);
CREATE INDEX IF NOT EXISTS idx_friendships_friend_id ON friendships(friend_id);
CREATE INDEX IF NOT EXISTS idx_friendships_status ON friendships(status);

-- Enable Row Level Security
ALTER TABLE friendships ENABLE ROW LEVEL SECURITY;

-- Create policy to allow users to read their own friendships
CREATE POLICY "Users can read their own friendships"
    ON friendships FOR SELECT
    USING (auth.uid() = user_id OR auth.uid() = friend_id);

-- Create policy to allow users to insert their own friend requests
CREATE POLICY "Users can insert their own friend requests"
    ON friendships FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Create policy to allow users to update friendships they're involved in
CREATE POLICY "Users can update their own friendships"
    ON friendships FOR UPDATE
    USING (auth.uid() = user_id OR auth.uid() = friend_id)
    WITH CHECK (auth.uid() = user_id OR auth.uid() = friend_id);

-- Create policy to allow users to delete their own friendships
CREATE POLICY "Users can delete their own friendships"
    ON friendships FOR DELETE
    USING (auth.uid() = user_id OR auth.uid() = friend_id);

-- Create function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_friendships_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = TIMEZONE('utc', NOW());
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to automatically update updated_at
CREATE TRIGGER update_friendships_updated_at BEFORE UPDATE ON friendships
    FOR EACH ROW EXECUTE FUNCTION update_friendships_updated_at_column();
```

5. Click **"Run"** to execute the query

## 2. Verify Table Creation

After running the SQL, verify that:
- The `friendships` table was created
- Row Level Security is enabled
- All policies were created successfully
- Indexes were created

## Notes

- The friendships table uses a bidirectional relationship (user_id and friend_id)
- Status can be: `pending`, `accepted`, or `blocked`
- The UNIQUE constraint prevents duplicate friendships
- The CHECK constraint prevents users from adding themselves as friends
- Friendships are automatically deleted when a user is deleted (CASCADE)
- The `updated_at` field is automatically updated when a friendship is modified

## Testing

To test the friends feature:

1. Create two user accounts
2. Search for a user by username or name
3. Send a friend request
4. Accept the friend request from the other account
5. Verify the friendship appears in the friends list

## Troubleshooting

### "Permission denied" errors
- Make sure Row Level Security policies are set up correctly
- Verify that the user is authenticated
- Check that the policies allow the operation you're trying to perform

### Search not working
- Make sure users have set their username or name in their profile
- Verify that the profiles table has data
- Check that the search query is not empty

### Friend requests not showing
- Verify that the friend request was created with status 'pending'
- Check that you're viewing the requests from the correct user account
- Ensure the friend_id matches the receiving user's ID

