# Project Structure

## File Overview

```
CalendarNotifier/
├── CalendarNotifierApp.swift      # App entry point, handles app lifecycle
├── ContentView.swift               # Main UI showing connection status
├── GoogleAuthView.swift            # Authentication screen
├── GoogleCalendarManager.swift     # Handles Google Calendar API
├── NotificationManager.swift       # Schedules notifications with sounds
├── CalendarSyncManager.swift       # Coordinates sync and notifications
├── Info.plist                      # App configuration and permissions
├── notification_1hour.caf          # Custom sound for 1-hour notification
└── notification_15min.caf          # Custom sound for 15-min notification
```

## How It Works

### 1. App Launch (`CalendarNotifierApp.swift`)
- Requests notification permissions
- Sets up background fetch
- Initializes the app

### 2. Authentication Flow
```
User taps "Connect" 
  → GoogleAuthView shown
  → GoogleCalendarManager.signIn()
  → User grants access
  → Initial sync triggered
```

### 3. Calendar Sync Process
```
CalendarSyncManager.syncCalendar()
  → Calls GoogleCalendarManager.fetchEvents()
  → Gets events from Google Calendar
  → Compares with previously synced events
  → Cancels old notifications
  → Schedules new notifications via NotificationManager
  → Saves synced events to UserDefaults
```

### 4. Notification Scheduling
```
For each event:
  NotificationManager.scheduleNotifications()
    → Schedule 1-hour notification (notification_1hour.caf)
    → Schedule 15-min notification (notification_15min.caf)
    → Uses UNCalendarNotificationTrigger for precise timing
```

### 5. Background Updates
- iOS periodically wakes the app (based on usage patterns)
- App performs background fetch
- New events are synced
- Notifications are updated

## Key Components

### GoogleCalendarManager
**Purpose**: Interface to Google Calendar API
**Responsibilities**:
- Handle OAuth authentication
- Fetch calendar events
- Maintain auth session
**Dependencies**: GoogleSignIn, GoogleAPIClientForREST

### NotificationManager
**Purpose**: Schedule local notifications
**Responsibilities**:
- Create notification content
- Schedule with custom sounds
- Cancel outdated notifications
**Dependencies**: UserNotifications framework

### CalendarSyncManager
**Purpose**: Coordinate sync operations
**Responsibilities**:
- Fetch events from calendar
- Compare with local cache
- Update notification schedule
- Persist event data
**Dependencies**: GoogleCalendarManager, NotificationManager

### ContentView
**Purpose**: User interface
**Displays**:
- Authentication status
- Sync status
- Manual sync button
**Dependencies**: GoogleCalendarManager

## Data Flow

```
Google Calendar
      ↓
GoogleCalendarManager (fetch events)
      ↓
CalendarSyncManager (process events)
      ↓
NotificationManager (schedule notifications)
      ↓
iOS Notification System
      ↓
User receives notification with custom sound
```

## State Management

### Persistent Data
- **UserDefaults**: Stores synced events for comparison
- **Keychain**: Google Sign-In SDK stores auth tokens
- **System**: iOS manages scheduled notifications

### In-Memory State
- `GoogleCalendarManager.isAuthenticated`: Auth status
- `GoogleCalendarManager.lastSyncDate`: Last sync timestamp
- `calendarService.authorizer`: Current auth session

## Notification System

### Notification Identifiers
- Format: `{eventID}-1hour` for 1-hour notifications
- Format: `{eventID}-15min` for 15-minute notifications
- Allows individual notification cancellation

### Notification Content
```swift
Title: Event title
Body: "Starting in X minutes"
Subtitle: Event location (if available)
Sound: Custom CAF file
```

### Timing
- Calculates trigger date by subtracting minutes from event start
- Uses `UNCalendarNotificationTrigger` for precise scheduling
- Only schedules if trigger time is in the future

## Extension Points

### Adding More Notification Times
In `NotificationManager.swift`, add more calls in `scheduleNotifications()`:
```swift
scheduleNotification(for: event, minutesBefore: 120, 
                    identifier: "\(event.id)-2hour",
                    soundName: "notification_2hour.caf")
```

### Changing Calendar Source
In `GoogleCalendarManager.swift`, modify the query:
```swift
let query = GTLRCalendarQuery_EventsList.query(withCalendarId: "calendar_id_here")
```

### Custom Notification Content
Modify `NotificationManager.scheduleNotification()` to customize:
- Title formatting
- Body message
- Add custom user info

## Testing Tips

### Testing Notifications
1. Create test events 30-90 minutes in the future
2. Manually trigger sync
3. Check scheduled notifications in iOS Settings
4. Wait for notifications to fire

### Debugging
- Enable scheme environment variable: `OS_ACTIVITY_MODE=disable`
- Check Console.app for notification logs
- Use `print()` statements liberally during development
- Test on real device (not simulator)

### Common Test Scenarios
1. **New event**: Add event in Google Calendar, sync, verify notifications
2. **Modified event**: Change time, sync, verify old notifications cancelled
3. **Deleted event**: Delete event, sync, verify notifications removed
4. **Past events**: Events in the past should not schedule notifications

## Security Considerations

### Permissions
- **Calendar**: Read-only access to Google Calendar
- **Notifications**: Required for alert delivery
- **Background**: Limited to fetch operations

### Data Privacy
- Events stored locally only for notification scheduling
- No analytics or third-party tracking
- Auth tokens managed by Google SDK (stored in Keychain)

### API Keys
- Client ID not sensitive (public identifier)
- Keep OAuth client secret secure (not used in iOS apps)
- Don't commit real credentials to version control

## Performance

### Background Fetch Limits
- iOS controls fetch frequency based on usage
- Typical: Every 15 minutes to several hours
- Can be tested with Xcode debug menu

### API Rate Limits
- Google Calendar API: 1,000,000 queries/day
- More than sufficient for personal use
- Consider caching if scaling

### Battery Impact
- Background fetch uses minimal battery
- Notification scheduling is efficient
- Most work done when app is active

## Future Enhancements

Possible additions:
- Multiple calendar support
- Custom notification messages
- Snooze functionality
- Widget showing next event
- Watch app companion
- Event filtering by keywords
- Location-based notifications
