# Quick Start Checklist

Follow this checklist to get your Calendar Notifier app up and running:

## ☐ Google Cloud Console
- [ ] Create/select a project at console.cloud.google.com
- [ ] Enable Google Calendar API
- [ ] Create iOS OAuth 2.0 client
- [ ] Note down your Client ID (looks like: XXXXX.apps.googleusercontent.com)
- [ ] Add calendar.readonly scope to OAuth consent screen

## ☐ Xcode Setup
- [ ] Create new iOS App project
- [ ] Set Bundle Identifier (e.g., com.yourname.CalendarNotifier)
- [ ] Add all Swift files to project:
  - CalendarNotifierApp.swift
  - ContentView.swift
  - GoogleCalendarManager.swift
  - NotificationManager.swift
  - CalendarSyncManager.swift
  - GoogleAuthView.swift
- [ ] Add Info.plist to project
- [ ] Update Info.plist with your Client ID (in 2 places)

## ☐ Dependencies
- [ ] Add GoogleSignIn-iOS package (7.0.0+)
  - URL: https://github.com/google/GoogleSignIn-iOS
- [ ] Add google-api-objectivec-client-for-rest package (3.0.0+)
  - URL: https://github.com/google/google-api-objectivec-client-for-rest
  - Product: GoogleAPIClientForREST

## ☐ Code Configuration
- [ ] Update clientID in GoogleCalendarManager.swift with your Client ID

## ☐ Notification Sounds
Choose ONE option:

### Option A: Custom Sounds (Recommended)
- [ ] Create/find two audio files
- [ ] Convert to CAF format using afconvert
- [ ] Name them: notification_1hour.caf and notification_15min.caf
- [ ] Add both files to Xcode project (copy to bundle)

### Option B: Use iOS System Sounds
- [ ] Modify NotificationManager.swift to use system sounds
- [ ] See SOUND_GUIDE.md for code examples

## ☐ Capabilities
- [ ] Go to Signing & Capabilities in Xcode
- [ ] Add "Background Modes" capability
- [ ] Enable "Background fetch"
- [ ] Enable "Remote notifications"

## ☐ Testing
- [ ] Build app on a REAL iOS device (not simulator)
- [ ] Grant notification permissions when prompted
- [ ] Sign in with Google account
- [ ] Grant calendar access
- [ ] Check that events sync (tap "Sync Now")
- [ ] Verify notifications are scheduled

## ☐ Verification
- [ ] Create a test calendar event 2 hours from now
- [ ] Wait for notifications at 1 hour and 15 minutes before
- [ ] Verify different tones play for each notification

## Common Issues

**"Sign in failed"**
- Double-check Client ID in both Info.plist and GoogleCalendarManager.swift
- Verify Bundle ID matches Google Cloud Console

**"No notifications appearing"**
- Check notification permissions in iOS Settings
- Verify sounds are in the app bundle
- Make sure events are more than 15 minutes in the future

**"Calendar API error"**
- Confirm Google Calendar API is enabled
- Check OAuth consent screen is configured
- Verify calendar.readonly scope is added

## Pro Tips

1. Test on a real device - notifications behave differently on simulator
2. Use the system Settings app to verify notification permissions
3. Check Console.app (macOS) for detailed logs when debugging
4. Create a test calendar with near-future events for testing
5. Background sync works best when you use the app regularly

## Next Steps

Once everything works:
1. Customize notification timing if needed (change 60 and 15 minutes)
2. Consider adding more notification intervals
3. Test with various event types (all-day events, recurring events, etc.)
4. Publish to TestFlight for testing before App Store submission

## Support Resources

- Google Calendar API: https://developers.google.com/calendar
- iOS Notifications: https://developer.apple.com/documentation/usernotifications
- Google Sign-In: https://developers.google.com/identity/sign-in/ios

Good luck! 🎉
