//
//  README.md
//  Accountability Buddy
//
//  Created by Jose Rivas on 11/9/25.
//

# Accountability Buddy iOS App

A SwiftUI app for tracking reading challenges between users using Supabase.

## Setup Instructions

### 1. Install Dependencies

Add the Supabase Swift client to your Xcode project:

1. In Xcode, go to **File → Add Package Dependencies...**
2. Enter the following URL:
   ```
   https://github.com/supabase/supabase-swift
   ```
3. Select the latest version and click **Add Package**
4. When prompted, add the `Supabase` library to your target

### 2. Configure Supabase Credentials

1. Open `Services/SupabaseService.swift` in Xcode
2. Find these two lines (around lines 10-13):
   ```swift
   private let supabaseURL = "YOUR_SUPABASE_URL"
   private let supabaseKey = "YOUR_SUPABASE_ANON_KEY"
   ```
3. Replace `YOUR_SUPABASE_URL` with your Supabase project URL
   - You can find this in your Supabase dashboard under **Settings → API**
   - It should look like: `https://xxxxxxxxxxxxx.supabase.co`
4. Replace `YOUR_SUPABASE_ANON_KEY` with your Supabase anon/public key
   - Also found in **Settings → API** in your Supabase dashboard
   - It's the `anon` `public` key (not the `service_role` key)

### 3. Set Up Supabase Database

#### Create the `books` table:

1. Go to your Supabase dashboard
2. Navigate to **SQL Editor**
3. Run the following SQL to create the `books` table:

```sql
-- Create books table
CREATE TABLE books (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title TEXT NOT NULL,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()) NOT NULL
);

-- Enable Row Level Security
ALTER TABLE books ENABLE ROW LEVEL SECURITY;

-- Create policy to allow users to read their own books
CREATE POLICY "Users can read their own books"
    ON books FOR SELECT
    USING (auth.uid() = user_id);

-- Create policy to allow users to insert their own books
CREATE POLICY "Users can insert their own books"
    ON books FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Create policy to allow users to delete their own books
CREATE POLICY "Users can delete their own books"
    ON books FOR DELETE
    USING (auth.uid() = user_id);
```

### 4. Enable Email Auth in Supabase

1. Go to **Authentication → Providers** in your Supabase dashboard
2. Ensure **Email** provider is enabled
3. Configure email settings as needed (you can use Supabase's built-in email service for development)

## Project Structure

```
AccountabilityBuddy/
├── AccountabilityBuddyApp.swift    # App entry point
├── ContentView.swift               # Main content view with auth routing
├── Models/
│   └── Book.swift                  # Book data model
├── Services/
│   └── SupabaseService.swift       # Supabase client and API calls
├── ViewModels/
│   ├── AuthViewModel.swift         # Authentication view model
│   └── BooksViewModel.swift        # Books list view model
└── Views/
    ├── AuthView.swift              # Login/Sign up view
    ├── BooksView.swift             # Main books list view
    └── AddBookView.swift           # Add new book view
```

## Features

- ✅ User authentication (sign up, sign in, sign out)
- ✅ View list of finished books
- ✅ Display total count of books finished
- ✅ Add new finished books
- ✅ Delete books (swipe to delete)
- ✅ MVVM architecture
- ✅ Row Level Security for data protection

## Next Steps

To extend this app for a reading challenge between two users, you would need to:

1. Create a `challenges` table to track challenge relationships
2. Add friend/user connections
3. Display both users' book counts in the challenge view
4. Add notifications when a user completes a book
5. Add challenge completion tracking and winner determination
