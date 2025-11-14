//
//  SUUPABASE_CREDENTIALS.md
//  Accountability Buddy
//
//  Created by Jose Rivas on 11/9/25.
//

# Where to Paste Supabase Credentials

## Exact Location in Xcode

1. **Open Xcode** and navigate to your project
2. **Open the file**: `Services/SupabaseService.swift`
3. **Find lines 9-11** (you'll see these exact lines):

```swift
// TODO: Replace these with your Supabase credentials
// Paste your Supabase URL here
private let supabaseURL = "YOUR_SUPABASE_URL"
// Paste your Supabase anon key here
private let supabaseKey = "YOUR_SUPABASE_ANON_KEY"
```

## How to Get Your Credentials

### Step 1: Get Your Supabase URL

1. Go to [https://app.supabase.com](https://app.supabase.com)
2. Sign in and select your project (or create a new one)
3. Click on **Settings** (gear icon in the left sidebar)
4. Click on **API** in the settings menu
5. Under **Project URL**, you'll see something like:
   ```
   https://abcdefghijklmnop.supabase.co
   ```
6. **Copy this entire URL** (including `https://`)

### Step 2: Get Your Anon Key

1. Still in **Settings → API**
2. Under **Project API keys**, find the **`anon` `public`** key
3. It will look like:
   ```
   eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFiY2RlZmdoaWprbG1ub3AiLCJyb2xlIjoiYW5vbiIsImlhdCI6MTYzODk2NzI5MCwiZXhwIjoxOTU0NTQzMjkwfQ.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   ```
4. **Copy this entire key** (it's a very long string)

### Step 3: Paste in Xcode

1. In `SupabaseService.swift`, replace `"YOUR_SUPABASE_URL"` with your URL:
   ```swift
   private let supabaseURL = "https://abcdefghijklmnop.supabase.co"
   ```

2. Replace `"YOUR_SUPABASE_ANON_KEY"` with your anon key:
   ```swift
   private let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
   ```

## Important Notes

- ⚠️ **Never commit these credentials to public repositories**
- ✅ Use the **anon/public key**, NOT the `service_role` key
- ✅ Make sure there are **no extra spaces** inside the quotes
- ✅ The URL should start with `https://` and end with `.supabase.co`
- ✅ The key should be a very long string starting with `eyJ`

## Example of Correct Configuration

```swift
private let supabaseURL = "https://abcdefghijklmnop.supabase.co"
private let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFiY2RlZmdoaWprbG1ub3AiLCJyb2xlIjoiYW5vbiIsImlhdCI6MTYzODk2NzI5MCwiZXhwIjoxOTU0NTQzMjkwfQ.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

## Verifying It Works

After pasting your credentials:

1. **Build the project** (⌘ + B)
2. **Run the app** (⌘ + R)
3. Check the Xcode console - you should see:
   ```
   ✅ Supabase client initialized successfully
   ```

If you see:
```
⚠️ Supabase credentials not configured. Please set your URL and anon key in SupabaseService.swift
```

Then check that:
- Both values are replaced (not still `YOUR_SUPABASE_URL` or `YOUR_SUPABASE_ANON_KEY`)
- There are no typos in the URL or key
- The quotes are properly closed
