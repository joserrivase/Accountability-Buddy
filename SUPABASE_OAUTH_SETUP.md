# Supabase OAuth Setup Instructions

This guide will help you configure Apple Sign In and Google Sign In in your Supabase project.

## Prerequisites

- A Supabase project (already set up)
- Apple Developer account (for Apple Sign In)
- Google Cloud Console account (for Google Sign In)

---

## 1. Configure URL Scheme in Xcode

1. Open your Xcode project
2. Select your app target
3. Go to the **Info** tab
4. Expand **URL Types**
5. Click the **+** button to add a new URL Type
6. Set the following:
   - **Identifier**: `com.joserivas.accountabilitybuddy.oauth`
   - **URL Schemes**: `com.joserivas.accountabilitybuddy`
   - **Role**: Editor

This allows your app to receive OAuth callbacks.

---

## 2. Apple Sign In Setup

### Step 1: Enable Sign in with Apple in Xcode

1. In Xcode, select your app target
2. Go to the **Signing & Capabilities** tab
3. Click **+ Capability**
4. Add **Sign in with Apple**

### Step 2: Configure Apple Sign In in Supabase

1. Go to your Supabase Dashboard: https://supabase.com/dashboard
2. Navigate to **Authentication** → **Providers**
3. Find **Apple** in the list and click to configure
4. Enable the Apple provider
5. You'll need to provide:
   - **Services ID**: Create one in Apple Developer Portal (see below)
   - **Secret Key**: Generate in Apple Developer Portal (see below)
   - **Redirect URL**: `https://pttbhlhkbbturoqjxzma.supabase.co/auth/v1/callback`

### Step 3: Create Apple Services ID

1. Go to https://developer.apple.com/account/resources/identifiers/list/serviceId
2. Click the **+** button to create a new Services ID
3. Fill in:
   - **Description**: BuddyUp App
   - **Identifier**: `com.joserivas.accountabilitybuddy.apple` (or your preferred identifier)
4. Enable **Sign in with Apple**
5. Click **Configure** next to "Sign in with Apple"
6. Add your **Primary App ID** (your app's bundle ID)
7. Add **Website URLs**:
   - **Domains**: `pttbhlhkbbturoqjxzma.supabase.co`
   - **Return URLs**: `https://pttbhlhkbbturoqjxzma.supabase.co/auth/v1/callback`
8. Save and continue

### Step 4: Create Apple Secret Key

1. Go to https://developer.apple.com/account/resources/authkeys/list
2. Click the **+** button
3. Enter a **Key Name**: "BuddyUp Supabase Key"
4. Enable **Sign in with Apple**
5. Click **Configure** and select your **Primary App ID**
6. Click **Save**
7. **Download the key file** (`.p8` file) - you can only download it once!
8. Note the **Key ID** shown

### Step 5: Generate Client Secret

You need to generate a JWT token as the client secret. Use this online tool or a script:

**Option A: Use online tool**
- Go to https://appleid.apple.com/signinwithapple/jwt
- Or use: https://developer.apple.com/documentation/sign_in_with_apple/generate_and_validate_tokens

**Option B: Use this Node.js script** (save as `generate-apple-secret.js`):

```javascript
const jwt = require('jsonwebtoken');
const fs = require('fs');

const teamId = 'YOUR_TEAM_ID'; // Find in Apple Developer Portal
const clientId = 'com.joserivas.accountabilitybuddy.apple'; // Your Services ID
const keyId = 'YOUR_KEY_ID'; // From step 4
const privateKey = fs.readFileSync('path/to/your/AuthKey_KEYID.p8');

const token = jwt.sign(
  {
    iss: teamId,
    iat: Math.floor(Date.now() / 1000),
    exp: Math.floor(Date.now() / 1000) + 86400 * 180, // 6 months
    aud: 'https://appleid.apple.com',
    sub: clientId,
  },
  privateKey,
  {
    algorithm: 'ES256',
    keyid: keyId,
  }
);

console.log(token);
```

Run: `node generate-apple-secret.js`

### Step 6: Enter Credentials in Supabase

1. Go back to Supabase Dashboard → Authentication → Providers → Apple
2. Enter:
   - **Services ID**: `com.joserivas.accountabilitybuddy.apple` (or your Services ID)
   - **Secret Key**: The JWT token generated in Step 5
3. Click **Save**

---

## 3. Google Sign In Setup

### Step 1: Create Google OAuth Credentials

1. Go to https://console.cloud.google.com/
2. Select your project (or create a new one)
3. Navigate to **APIs & Services** → **Credentials**
4. Click **+ CREATE CREDENTIALS** → **OAuth client ID**
5. If prompted, configure the OAuth consent screen first:
   - **User Type**: External (unless you have a Google Workspace)
   - **App name**: BuddyUp
   - **User support email**: Your email
   - **Developer contact**: Your email
   - Click **Save and Continue**
   - Add scopes: `email`, `profile`, `openid`
   - Add test users if needed
   - Click **Save and Continue**
6. Back to creating OAuth client:
   - **Application type**: iOS
   - **Name**: BuddyUp iOS
   - **Bundle ID**: `com.joserivas.accountabilitybuddy`
   - Click **Create**
   - **Note the Client ID** (you'll need this)

### Step 2: Create Web Application Credentials (for Supabase)

1. Still in Google Cloud Console → Credentials
2. Click **+ CREATE CREDENTIALS** → **OAuth client ID**
3. Select **Web application**
4. **Name**: BuddyUp Web (for Supabase)
5. **Authorized redirect URIs**: 
   - `https://pttbhlhkbbturoqjxzma.supabase.co/auth/v1/callback`
6. Click **Create**
7. **Note both the Client ID and Client Secret**

### Step 3: Configure Google in Supabase

1. Go to Supabase Dashboard → **Authentication** → **Providers**
2. Find **Google** and click to configure
3. Enable the Google provider
4. Enter:
   - **Client ID (for OAuth)**: The **Web application** Client ID from Step 2
   - **Client Secret (for OAuth)**: The **Web application** Client Secret from Step 2
5. Click **Save**

---

## 4. Configure Account Linking (Important!)

To prevent duplicate accounts when users sign in with different methods using the same email:

### Option A: Enable Account Linking in Supabase (Recommended)

1. Go to Supabase Dashboard → **Authentication** → **Settings**
2. Under **Account Linking**, enable:
   - **Enable account linking**: ON
   - **Link accounts with same email**: ON
3. This will automatically link accounts with the same email address

### Option B: Manual Account Linking (if Option A doesn't work)

If automatic linking doesn't work, you may need to handle it in your code. The current implementation checks if a profile exists and uses the existing account.

---

## 5. Test the Implementation

1. **Test Apple Sign In**:
   - Run your app
   - Tap "Continue with Apple"
   - Complete the Apple Sign In flow
   - Verify you're signed in and profile is created

2. **Test Google Sign In**:
   - Run your app
   - Tap "Continue with Google"
   - Complete the Google Sign In flow in the browser
   - Verify you're signed in and profile is created

3. **Test Account Linking**:
   - Sign up with email/password
   - Sign out
   - Sign in with Apple/Google using the same email
   - Verify you're signed into the same account (not a new one)

---

## 6. Troubleshooting

### Apple Sign In Issues

- **"Invalid client"**: Check that your Services ID matches in both Apple Developer Portal and Supabase
- **"Invalid redirect URI"**: Ensure the redirect URL in Apple Developer Portal matches: `https://pttbhlhkbbturoqjxzma.supabase.co/auth/v1/callback`
- **Secret key expired**: Regenerate the JWT token (it expires after 6 months)

### Google Sign In Issues

- **"Redirect URI mismatch"**: Ensure the redirect URI in Google Cloud Console exactly matches: `https://pttbhlhkbbturoqjxzma.supabase.co/auth/v1/callback`
- **"Invalid client"**: Make sure you're using the **Web application** Client ID/Secret, not the iOS one
- **OAuth consent screen**: Make sure it's configured and published if needed

### General Issues

- **URL scheme not working**: Verify the URL scheme is configured in Xcode Info tab
- **Session not established**: Check that the callback URL is being handled correctly in the app
- **Profile not created**: Check Supabase logs for errors in profile creation

---

## 7. Security Notes

- Keep your Apple Secret Key (`.p8` file) secure
- Keep your Google Client Secret secure
- Never commit these credentials to version control
- Regenerate secrets if they're ever exposed
- The JWT token for Apple expires after 6 months - set a reminder to regenerate

---

## 8. Additional Resources

- Supabase Auth Documentation: https://supabase.com/docs/guides/auth
- Apple Sign In Documentation: https://developer.apple.com/sign-in-with-apple/
- Google OAuth Documentation: https://developers.google.com/identity/protocols/oauth2

---

## Quick Checklist

- [ ] URL scheme configured in Xcode
- [ ] Sign in with Apple capability added
- [ ] Apple Services ID created
- [ ] Apple Secret Key generated
- [ ] Apple credentials entered in Supabase
- [ ] Google OAuth credentials created (iOS and Web)
- [ ] Google credentials entered in Supabase
- [ ] Account linking enabled in Supabase
- [ ] Tested Apple Sign In
- [ ] Tested Google Sign In
- [ ] Tested account linking

