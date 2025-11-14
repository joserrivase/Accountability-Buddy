//
//  PROFILE_SETUP.md
//  Accountability Buddy
//
//  Created by Jose Rivas on 11/9/25.
//

# Profile Setup Instructions

## 1. Create Profiles Table in Supabase

1. Go to your Supabase dashboard
2. Navigate to **SQL Editor**
3. Click **"New query"**
4. Paste and run this SQL:

```sql
-- Create profiles table
CREATE TABLE IF NOT EXISTS profiles (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
    username TEXT,
    name TEXT,
    profile_image_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()) NOT NULL
);

-- Enable Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Create policy to allow users to read their own profile
CREATE POLICY "Users can read their own profile"
    ON profiles FOR SELECT
    USING (auth.uid() = user_id);

-- Create policy to allow users to insert their own profile
CREATE POLICY "Users can insert their own profile"
    ON profiles FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Create policy to allow users to update their own profile
CREATE POLICY "Users can update their own profile"
    ON profiles FOR UPDATE
    USING (auth.uid() = user_id);

-- Create policy to allow users to delete their own profile
CREATE POLICY "Users can delete their own profile"
    ON profiles FOR DELETE
    USING (auth.uid() = user_id);

-- Create function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = TIMEZONE('utc', NOW());
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to automatically update updated_at
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

5. Click **"Run"** to execute the query

## 2. Create Storage Bucket for Profile Images

1. In Supabase dashboard, go to **Storage**
2. Click **"New bucket"**
3. Name it: `profile-images`
4. Make it **Public** (uncheck "Private bucket")
5. Click **"Create bucket"**

## 3. Set Up Storage Policies

1. After creating the bucket, click on it
2. Go to **"Policies"** tab
3. Click **"New policy"**
4. Create the following policies:

### Policy 1: Allow users to upload their own images
- Policy name: `Users can upload their own profile images`
- Allowed operation: `INSERT`
- Policy definition:
```sql
(user_id = (storage.foldername(name))[1]::uuid)
```

### Policy 2: Allow users to update their own images
- Policy name: `Users can update their own profile images`
- Allowed operation: `UPDATE`
- Policy definition:
```sql
(user_id = (storage.foldername(name))[1]::uuid)
```

### Policy 3: Allow users to delete their own images
- Policy name: `Users can delete their own profile images`
- Allowed operation: `DELETE`
- Policy definition:
```sql
(user_id = (storage.foldername(name))[1]::uuid)
```

### Policy 4: Allow public read access
- Policy name: `Public can read profile images`
- Allowed operation: `SELECT`
- Policy definition:
```sql
true
```

## 4. Update Storage Policy for User-Specific Access

If you want to restrict access so users can only access their own images, use this policy instead:

1. Go to Storage → `profile-images` → Policies
2. For the SELECT policy, use:
```sql
bucket_id = 'profile-images' AND (storage.foldername(name))[1]::uuid = auth.uid()
```

## Notes

- The profile image storage uses the pattern: `{userId}/{imageId}.jpg`
- Images are stored as JPEG format with compression
- The `updated_at` field is automatically updated when a profile is modified
- Each user can have only one profile (enforced by UNIQUE constraint on user_id)

