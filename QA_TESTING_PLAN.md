# QA Testing Plan - Background Sync & Notifications

## Critical: Background Task Testing Limitations

**⚠️ IMPORTANT:** Background tasks behave differently during development vs. production:

- **During Xcode debugging:** Background tasks are heavily restricted and may not run at all
- **Production (TestFlight/App Store):** Background tasks run normally based on iOS scheduling
- **Simulator:** BGTaskScheduler does NOT work reliably - use physical device only

## Pre-Testing Setup

### 1. Enable Debug Logging
1. Open Settings → Debug Status in the app
2. This shows:
   - Last sync time
   - Number of events loaded
   - Next event timing
   - Pending background tasks
   - Widget data status

### 2. Reset Test Environment
```bash
# Clear app data on device
# Settings → General → iPhone Storage → Calendar Notifier → Delete App
# Reinstall from Xcode
```

---

## Test Suite 1: Manual Sync (Critical Path)

### Test 1.1: Initial Sync After Login
**Goal:** Verify calendar syncs immediately after Google authentication

**Steps:**
1. Fresh install of app
2. Sign in with Google
3. Grant calendar permissions
4. App should auto-sync immediately

**Expected Results:**
- ✅ Sync indicator appears
- ✅ Events load within 5 seconds
- ✅ "Last synced X seconds ago" appears at bottom of main screen
- ✅ Next event displays correctly
- ✅ Widget updates (check home screen)

**Verification:**
- Open Settings → Debug Status
- Confirm "Last Sync" shows recent time
- Confirm "Events Loaded" matches Google Calendar

---

### Test 1.2: Manual Sync from Settings
**Goal:** Verify manual sync button works

**Steps:**
1. Open Settings
2. Tap "Sync Now" at top
3. Watch for progress indicator

**Expected Results:**
- ✅ Button shows loading spinner
- ✅ Sync completes within 5 seconds
- ✅ Event count updates if calendar changed
- ✅ Main screen updates with new data
- ✅ Widget refreshes

**Verification:**
- Add a new event to Google Calendar via web
- Tap "Sync Now"
- Confirm new event appears in "Show My Day"

---

## Test Suite 2: App Lifecycle Sync

### Test 2.1: Sync on App Launch
**Goal:** Verify app syncs when opened from background

**Steps:**
1. Open app
2. Close app (swipe up to background)
3. Wait 30 seconds
4. Reopen app from home screen

**Expected Results:**
- ✅ App syncs immediately on launch
- ✅ Console shows "🟢 APP BECAME ACTIVE"
- ✅ Console shows sync activity

**Verification:**
- Check Xcode console for sync logs
- Check "Last synced" time updates

---

### Test 2.2: Sync When Returning from Background
**Goal:** Verify sync when app returns to foreground

**Steps:**
1. Open app
2. Press home button (app to background)
3. Wait 1 minute
4. Open app again

**Expected Results:**
- ✅ Immediate sync on return
- ✅ Fresh calendar data loaded

---

## Test Suite 3: Background Task Scheduling (Advanced)

### Test 3.1: Verify Background Task Registration
**Goal:** Confirm background tasks are registered with iOS

**Steps:**
1. Launch app
2. Check Xcode console for:
   ```
   📋 REGISTERING BACKGROUND TASKS
   ✅ Successfully registered background refresh task
   ```

**Expected Results:**
- ✅ No registration errors in console
- ✅ Settings → Debug Status shows pending task

**Red Flags:**
- ❌ "Failed to register" message
- ❌ "Not permitted - check Info.plist" error

---

### Test 3.2: Schedule Background Refresh
**Goal:** Verify background refresh gets scheduled

**Steps:**
1. Open app
2. Send app to background (home button)
3. Open Settings → Debug Status
4. Check "Background Tasks" section

**Expected Results:**
- ✅ Shows scheduled task with ID: com.calendarnotifier.refresh
- ✅ Shows "Ready in: X min" (15+ minutes)

**If No Tasks Show:**
- Tap "Schedule New Task" button
- Tap "Refresh Task List"
- Task should appear

---

### Test 3.3: Simulate Background Task Execution (Xcode Only)
**Goal:** Force background task to run for testing

**⚠️ Requirements:**
- Physical iOS device (not simulator)
- Connected to Mac via USB
- App installed via Xcode

**Steps:**

1. **Build and run app on device**
2. **Send app to background** (home button)
3. **Keep device connected to Mac**
4. **Open Xcode Debug Console** (View → Debug Area → Activate Console)
5. **Pause debugger** (pause button in Xcode)
6. **In LLDB console, type:**
   ```
   e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.calendarnotifier.refresh"]
   ```
7. **Press Continue** in debugger
8. **Watch console output**

**Expected Console Output:**
```
🔄 BACKGROUND REFRESH TRIGGERED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⏰ Time: [current time]
📱 App State: Background
✅ Background refresh scheduled
🔄 STARTING EVENT SYNC
...
✅ Background sync completed successfully
```

**Expected Results:**
- ✅ Background task executes
- ✅ Calendar syncs
- ✅ New task scheduled for 15+ min later
- ✅ Widget updates

---

## Test Suite 4: Production Background Sync Testing

**⚠️ This is the REAL test - background tasks only work properly in production**

### Test 4.1: TestFlight Background Sync
**Goal:** Verify background sync in production environment

**Setup:**
1. Archive app in Xcode
2. Upload to TestFlight
3. Install via TestFlight on device
4. **DO NOT** connect to Xcode

**Steps:**
1. Launch app and sign in
2. Verify manual sync works
3. Send app to background
4. **Wait 30-60 minutes** (do other things on device)
5. Add a new event to Google Calendar via web
6. **Do NOT open app yet**
7. **Wait another 30-60 minutes**
8. Open app

**Expected Results:**
- ✅ App shows new event without manual sync
- ✅ "Last synced" shows time from when app was in background
- ✅ Widget shows new event

**Verification:**
- Settings → Debug Status
- Check "Last Sync" timestamp
- Should show sync happened while app was in background

---

## Test Suite 5: Widget Testing

### Test 5.1: Widget Initial Setup
**Goal:** Verify widget displays calendar data

**Steps:**
1. Sync calendar in app
2. Go to home screen
3. Long press to add widget
4. Add "Next Event" widget (small or medium)

**Expected Results:**
- ✅ Widget shows next upcoming event
- ✅ Time displays correctly
- ✅ Event title visible

---

### Test 5.2: Widget Updates After Sync
**Goal:** Verify widget refreshes when calendar syncs

**Steps:**
1. Note current widget content
2. Add new earlier event to Google Calendar
3. Open app → Settings → Sync Now
4. Return to home screen

**Expected Results:**
- ✅ Widget updates within 5 seconds
- ✅ Shows new earlier event

---

### Test 5.3: Widget Timeline Refresh
**Goal:** Verify widget refreshes on its own timeline

**Steps:**
1. Add widget to home screen
2. Close app completely (swipe up in app switcher)
3. Wait 15+ minutes
4. Check widget

**Expected Results:**
- ✅ Widget should request refresh from iOS
- ✅ May trigger background sync via widget budget

**Note:** Widget refresh is controlled by iOS and may not happen immediately

---

## Test Suite 6: Notification Testing

### Test 6.1: Notification Scheduling
**Goal:** Verify notifications are scheduled for events

**Steps:**
1. Sync calendar with upcoming events
2. Check console for notification logs:
   ```
   📅 Processing X events for notifications:
   [1/X]
   ✅ Scheduled 2 notifications for event...
   ```

**Expected Results:**
- ✅ 2 notifications per event (1 hour and 15 min before)
- ✅ Max 27 events get notifications (iOS 64 limit ÷ 2)

**Verification:**
- iOS Settings → Notifications → Calendar Notifier
- Check "Scheduled Summary" for pending notifications

---

### Test 6.2: Notification Delivery
**Goal:** Verify notifications fire at correct time

**Steps:**
1. Create test event 20 minutes from now
2. Sync calendar
3. Wait for 15-minute notification
4. Wait for 1-hour notification (won't fire since event is <1hr away)

**Expected Results:**
- ✅ Notification appears 15 min before event
- ✅ Plays configured sound
- ✅ Shows event title and time

---

## Test Suite 7: Debugging Common Issues

### Issue: No Background Sync Happening

**Diagnosis Steps:**
1. Check Settings → Debug Status
   - Are tasks scheduled?
   - When is next task ready?

2. Check Xcode console for errors:
   - "Failed to register" = Info.plist issue
   - "Not permitted" = Missing BGTaskSchedulerPermittedIdentifiers
   - "Too many pending requests" = Clear and reschedule

3. Verify Info.plist contains:
   ```xml
   <key>UIBackgroundModes</key>
   <array>
       <string>processing</string>
   </array>
   <key>BGTaskSchedulerPermittedIdentifiers</key>
   <array>
       <string>com.calendarnotifier.refresh</string>
   </array>
   ```

**Fixes:**
- Force schedule: Settings → Debug Status → "Schedule New Task"
- Restart device
- Reinstall app
- Test in production (TestFlight)

---

### Issue: Widget Not Updating

**Diagnosis:**
1. Check Settings → Debug Status → Widget Status
   - Does it show data bytes?

2. Remove and re-add widget

3. Check that sync is actually happening:
   - Manual sync from Settings
   - Check "Last synced" timestamp

**Fixes:**
- Sync calendar manually
- Remove and re-add widget
- Restart device

---

### Issue: Notifications Not Firing

**Diagnosis:**
1. Check notification permissions:
   - iOS Settings → Notifications → Calendar Notifier → Allow

2. Check console logs:
   - Are notifications being scheduled?
   - Any errors during scheduling?

3. Verify event is in future:
   - Notifications only schedule for future events

**Fixes:**
- Re-grant notification permissions
- Sync calendar again
- Test with fresh event >15 min in future

---

## Production Testing Checklist

Before deploying to users:

- [ ] Manual sync works reliably
- [ ] App syncs on launch
- [ ] App syncs when returning from background
- [ ] Background tasks register without errors
- [ ] Widget displays and updates correctly
- [ ] Notifications schedule and fire on time
- [ ] Tested in TestFlight for 24+ hours with background sync
- [ ] Verified sync happens while app is backgrounded
- [ ] Accessibility features work (Bigger Mode, VoiceOver)
- [ ] No crashes in production logs

---

## Known Limitations

1. **Background sync frequency:**
   - iOS decides when to run background tasks
   - Typically 15-30 min intervals when conditions are good
   - May be delayed if battery is low, poor network, or device is busy

2. **Widget refresh:**
   - Widget has separate refresh budget from background tasks
   - iOS may throttle widget refreshes to save battery
   - Widget refresh is not guaranteed

3. **Notification limit:**
   - iOS allows max 64 pending notifications per app
   - App schedules 2 per event = 27 events max
   - Additional events won't have notifications

4. **Testing limitations:**
   - Background tasks don't run reliably during Xcode debugging
   - Must test in production (TestFlight) for accurate results
   - Simulator not supported for BGTaskScheduler

---

## Success Criteria

The background sync system is working correctly if:

1. ✅ Manual sync works every time
2. ✅ App syncs on launch within 5 seconds
3. ✅ Background tasks are scheduled (visible in Debug Status)
4. ✅ In TestFlight: Calendar updates appear without opening app
5. ✅ Widget updates after calendar syncs
6. ✅ Notifications fire at correct times
7. ✅ No errors in console logs
8. ✅ "Last synced" timestamp updates regularly

---

## Support & Debugging

If issues persist:

1. Check Xcode console for detailed logs
2. Use Debug Status screen to inspect state
3. Test in production environment (TestFlight)
4. Verify all Info.plist entries are correct
5. Ensure device has good network connection
6. Check iOS Settings → Battery for background activity restrictions
