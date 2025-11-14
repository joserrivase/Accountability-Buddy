
# Setup Guide for Accountability Buddy iOS App

## Step-by-Step Setup Instructions

### 1. Create Xcode Project

1. Open Xcode
2. Create a new project:
   - Choose **iOS → App**
   - Product Name: `AccountabilityBuddy`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Save the project

### 2. Add Files to Xcode Project

Add all the generated files to your Xcode project:

1. **Drag and drop** the following folders/files into your Xcode project:
   - `Models/Book.swift`
   - `Services/SupabaseService.swift`
   - `ViewModels/AuthViewModel.swift`
   - `ViewModels/BooksViewModel.swift`
   - `Views/AuthView.swift`
   - `Views/BooksView.swift`
   - `Views/AddBookView.swift`
   - `AccountabilityBuddyApp.swift`
   - `ContentView.swift`

2. When dragging, make sure to:
   - Check "Copy items if needed"
   - Select your app target
   - Choose "Create groups" (not folder references)

### 3. Install Supabase Swift Package

1. In Xcode, select your project in the navigator
2. Go to your app target
3. Click on **"Package Dependencies"** tab
4. Click the **"+"** button
5. Enter this URL:
   ```
   https://github.com/supabase/supabase-swift
   ```
6. Click **"Add Package"**
7. Select the latest version
8. When prompted, add the **Supabase** library to your target
9. Click **"Add Package"**

### 4. Configure Supabase Credentials

**IMPORTANT**: You need to replace the placeholder values in `SupabaseService.swift`

1. Open `Services/SupabaseService.swift` in Xcode
2. Find these lines (around lines 9-11):
   ```swift
   private let supabaseURL = "YOUR_SUPABASE_URL"
   private let supabaseKey = "YOUR_SUPABASE_ANON_KEY"
   ```

3. **Get your Supabase credentials:**
   - Go to [Supabase Dashboard](https://app.supabase.com)
   - Select your project (or create a new one)
   - Go to **Settings → API**
   - Copy the **Project URL** (looks like: `https://xxxxxxxxxxxxx.supabase.co`)
   - Copy the **anon public** key (under "Project API keys")

4. **Paste the credentials:**
   - Replace `YOUR_SUPABASE_URL` with your Project URL
   - Replace `YOUR_SUPABASE_ANON_KEY` with your anon public key

   Example:
   ```swift
   private let supabaseURL = "https://abcdefghijklmnop.supabase.co"
   private let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
   ```

### 5. Set Up Supabase Database

1. In your Supabase dashboard, go to **SQL Editor**
2. Click **"New query"**
3. Paste and run this SQL:

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

4. Click **"Run"** to execute the query

### 6. Enable Email Authentication

1. In Supabase dashboard, go to **Authentication → Providers**
2. Make sure **Email** is enabled
3. For development, you can use Supabase's built-in email service
4. Optionally configure email templates in **Authentication → Email Templates**

### 7. Build and Run

1. In Xcode, select your target device or simulator
2. Press **⌘ + R** to build and run
3. The app should launch and show the authentication screen

## Troubleshooting

### "Supabase client not initialized" error
- Check that you've replaced `YOUR_SUPABASE_URL` and `YOUR_SUPABASE_ANON_KEY` in `SupabaseService.swift`
- Make sure there are no extra spaces or quotes around the values
- Verify your Supabase project is active

### Authentication not working
- Verify Email provider is enabled in Supabase dashboard
- Check that RLS policies are set up correctly
- Check Xcode console for error messages

### Books not loading
- Verify the `books` table was created successfully
- Check that RLS policies allow SELECT for the current user
- Verify the user_id matches between auth.users and books table

### Build errors
- Make sure Supabase package is added to your target
- Clean build folder: **Product → Clean Build Folder** (⇧⌘K)
- Restart Xcode if needed

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

## Next Steps

After the basic app is working, you can extend it to support:
- Reading challenges between two users
- Friend connections
- Real-time updates when a friend adds a book
- Challenge completion tracking
- Push notifications
