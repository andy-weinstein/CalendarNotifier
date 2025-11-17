# Calendar Notifier App

An iOS app that syncs with Google Calendar and sends two notifications for each event:
- 1 hour before (with custom tone 1)
- 15 minutes before (with custom tone 2)

## Features

- Syncs with your primary Google Calendar
- Dual notifications with different tones
- Background syncing to keep notifications up to date
- Simple authentication flow

## Setup Instructions

### 1. Google Cloud Console Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the **Google Calendar API**:
   - Navigate to "APIs & Services" > "Library"
   - Search for "Google Calendar API"
   - Click "Enable"

4. Create OAuth 2.0 credentials:
   - Go to "APIs & Services" > "Credentials"
   - Click "Create Credentials" > "OAuth client ID"
   - Choose "iOS" as the application type
   - Enter your app's Bundle ID (e.g., `com.yourname.CalendarNotifier`)
   - Download the configuration file
   - Note down your Client ID

5. Configure OAuth consent screen:
   - Go to "OAuth consent screen"
   - Add the required information
   - Add `https://www.googleapis.com/auth/calendar.readonly` to scopes

### 2. Xcode Project Setup

1. Create a new iOS App project in Xcode
2. Set your Bundle Identifier to match the one you used in Google Cloud Console
3. Copy all the Swift files from this package into your project:
   - CalendarNotifierApp.swift
   - ContentView.swift
   - GoogleCalendarManager.swift
   - NotificationManager.swift
   - CalendarSyncManager.swift
   - GoogleAuthView.swift

4. Add the Info.plist file to your project and update:
   - Replace `YOUR_CLIENT_ID` with your actual Google Client ID
   - Replace `YOUR_REVERSED_CLIENT_ID` with your reversed client ID
     (e.g., if your client ID is `123-abc.apps.googleusercontent.com`, 
     the reversed ID is `com.googleusercontent.apps.123-abc`)

### 3. Install Dependencies

Add the following packages to your project via Swift Package Manager:
- File > Add Package Dependencies

Add these URLs:
1. **Google Sign-In**: 
   `https://github.com/google/GoogleSignIn-iOS`
   Version: 7.0.0 or later

2. **Google API Client**: 
   `https://github.com/google/google-api-objectivec-client-for-rest`
   Version: 3.0.0 or later
   Make sure to add the "GoogleAPIClientForREST" product

### 4. Configure Notification Sounds

You need to add custom sound files for the two different notification tones:

1. Create two `.caf` audio files:
   - `notification_1hour.caf` (for 1-hour notification)
   - `notification_15min.caf` (for 15-minute notification)

2. Convert your audio files to CAF format:
   ```bash
   # Using afconvert (built into macOS)
   afconvert -f caff -d LEI16 your_sound_1.wav notification_1hour.caf
   afconvert -f caff -d LEI16 your_sound_2.wav notification_15min.caf
   ```

3. Add these files to your Xcode project:
   - Drag them into your project navigator
   - Make sure "Copy items if needed" is checked
   - Make sure your app target is selected

**Note**: iOS requires notification sounds to be:
- In CAF, WAV, or AIFF format
- 30 seconds or less in duration
- Located in the app bundle's main directory

### 5. Update Configuration

In `GoogleCalendarManager.swift`, replace:
```swift
private let clientID = "YOUR_CLIENT_ID.apps.googleusercontent.com"
```
With your actual client ID from Google Cloud Console.

### 6. Capabilities

Enable the following capabilities in your Xcode project:
1. Select your project in the navigator
2. Select your target
3. Go to "Signing & Capabilities"
4. Add "Background Modes" capability
5. Check:
   - Background fetch
   - Remote notifications

### 7. Testing

1. Build and run the app on a real device (notifications don't work reliably in simulator)
2. Sign in with your Google account
3. Grant calendar permissions
4. The app will sync events and schedule notifications
5. You can trigger an immediate sync using the "Sync Now" button

## Usage

1. Launch the app
2. Tap "Connect Google Calendar"
3. Sign in with your Google account
4. Grant calendar access permissions
5. The app will automatically sync and schedule notifications
6. Keep the app installed - it will sync in the background

## Troubleshooting

### Notifications not appearing
- Make sure you've granted notification permissions
- Check that notification sounds are properly added to the bundle
- Verify the events are more than 15 minutes in the future

### Authentication fails
- Verify your Client ID is correct in both the code and Info.plist
- Check that the Calendar API is enabled in Google Cloud Console
- Make sure your Bundle ID matches the one in Google Cloud Console

### Background sync not working
- iOS may limit background fetch based on usage patterns
- The app must be used regularly for iOS to prioritize background updates
- You can manually sync anytime by opening the app

## Customization

To change notification timing, modify the values in `NotificationManager.swift`:
```swift
scheduleNotification(for: event, minutesBefore: 60, ...) // Change 60 to desired minutes
scheduleNotification(for: event, minutesBefore: 15, ...) // Change 15 to desired minutes
```

## Privacy

- This app only requests read-only access to your calendar
- Event data is stored locally only for notification scheduling
- No data is sent to any third-party servers (only Google Calendar API)

## Requirements

- iOS 16.0 or later
- Xcode 15.0 or later
- Google account with Calendar access
- Real iOS device for testing (notifications don't work fully in simulator)
