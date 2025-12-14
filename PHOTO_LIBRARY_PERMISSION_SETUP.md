# Photo Library Permission Setup

This document explains how to set up photo library access permissions for the profile picture feature.

## Info.plist Configuration

You need to add a permission description to your app's Info.plist file. This description will be shown to users when they're asked for photo library access.

### Steps:

1. **Open your Xcode project**
2. **Select your app target** (Accountability Buddy)
3. **Go to the "Info" tab**
4. **Add a new entry:**
   - Key: `NSPhotoLibraryUsageDescription` (or `Privacy - Photo Library Usage Description`)
   - Type: `String`
   - Value: `"We need access to your photo library to let you select a profile picture."`

   OR for iOS 14+ with write access:
   - Key: `NSPhotoLibraryAddUsageDescription` (or `Privacy - Photo Library Additions Usage Description`)
   - Type: `String`
   - Value: `"We need access to save your profile picture to your photo library."`

### Recommended: Add Both

For best compatibility, add both:
- `NSPhotoLibraryUsageDescription` - For reading photos
- `NSPhotoLibraryAddUsageDescription` - For saving photos (if needed in future)

### Alternative: Edit Info.plist Directly

If you have an Info.plist file, you can add these entries directly:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to your photo library to let you select a profile picture.</string>

<key>NSPhotoLibraryAddUsageDescription</key>
<string>We need access to save your profile picture to your photo library.</string>
```

## How It Works

1. When the user opens the Edit Profile view, the app checks photo library permission status
2. If permission hasn't been requested yet, it will automatically request it when the user taps "Select Photo"
3. If permission is denied, an alert will appear with an option to open Settings
4. The PhotosPicker component handles the actual permission request automatically

## Testing

1. Run the app on a device or simulator
2. Go to Profile → Edit Profile
3. Tap "Select Photo"
4. You should see the system permission dialog (first time only)
5. If you deny permission, you'll see an alert with an option to open Settings

## Notes

- The permission request happens automatically when using PhotosPicker
- Users can change permissions in Settings → Privacy & Security → Photos → Accountability Buddy
- The app will show a helpful message if access is denied

