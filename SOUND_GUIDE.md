# Creating Custom Notification Sounds

## Quick Method (macOS)

You can use the built-in `afconvert` tool on macOS to convert audio files to the required CAF format.

### Step 1: Get your audio files
- Find or create two different audio files (MP3, WAV, AIFF, etc.)
- Keep them under 30 seconds (iOS requirement)
- Name them something memorable like `tone1.mp3` and `tone2.mp3`

### Step 2: Convert to CAF format
Open Terminal and run:

```bash
# Convert first tone (for 1-hour notification)
afconvert -f caff -d LEI16 tone1.mp3 notification_1hour.caf

# Convert second tone (for 15-minute notification)
afconvert -f caff -d LEI16 tone2.mp3 notification_15min.caf
```

### Step 3: Add to Xcode
1. Drag both `.caf` files into your Xcode project
2. Check "Copy items if needed"
3. Ensure your app target is selected
4. The files should appear in your project navigator

## Alternative Methods

### Using GarageBand (Free, macOS)
1. Open GarageBand
2. Create a new project
3. Record or import your sound
4. Export as: Share > Export Song to Disk
5. Choose AIFF format
6. Convert using afconvert as shown above

### Using Audacity (Free, Cross-platform)
1. Download Audacity from https://www.audacityteam.org/
2. Open/create your audio file
3. Ensure it's 30 seconds or less
4. Export as WAV (16-bit PCM)
5. Convert using afconvert (macOS) or use the WAV directly

## Using Default iOS Sounds (Alternative)

If you don't want to create custom sounds, you can use iOS system sounds by modifying `NotificationManager.swift`:

Replace:
```swift
content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: soundName))
```

With:
```swift
// For 1-hour notification
if minutesBefore == 60 {
    content.sound = .default
} else {
    // For 15-minute notification
    content.sound = .defaultCritical
}
```

Or use specific system sounds:
```swift
content.sound = UNNotificationSound(named: UNNotificationSoundName("Apex.caf"))
```

Available system sound names (some examples):
- "Anticipate.caf"
- "Bloom.caf"
- "Calypso.caf"
- "Chime.caf"
- "Choo.caf"
- "Descent.caf"
- "Fanfare.caf"
- "Ladder.caf"
- "Minuet.caf"
- "News.caf"
- "Noir.caf"
- "Sherwood.caf"
- "Spell.caf"
- "Suspense.caf"
- "Telegraph.caf"
- "Tiptoes.caf"
- "Typewriters.caf"
- "Update.caf"

## Sound Requirements

iOS has specific requirements for notification sounds:
- **Format**: CAF, WAV, or AIFF
- **Duration**: 30 seconds or less
- **Sample Rate**: 8, 16, 22.05, 24, 32, 44.1, or 48 kHz
- **Channels**: Mono or stereo
- **Bit Depth**: 8 or 16-bit (linear PCM) or IMA4 (compressed)
- **Location**: Must be in the app's main bundle

## Tips for Good Notification Sounds

1. **Keep it short**: 1-3 seconds is ideal for notifications
2. **Clear and distinct**: Make sure the two tones are easily distinguishable
3. **Not too loud**: iOS will adjust volume, but start with moderate levels
4. **Test on device**: Sounds may sound different on iPhone speakers
5. **Consider context**: The 1-hour warning could be gentler, the 15-minute more urgent

## Example Sound Sources

Free sound resources:
- **Freesound.org**: Large library of Creative Commons sounds
- **Zapsplat.com**: Free sound effects (requires attribution)
- **GarageBand**: Comes with many built-in sounds on Mac
- **System Sounds**: iOS has many built-in notification sounds you can reference

## Troubleshooting

### Sound doesn't play
- Check that the file is properly added to the app bundle
- Verify the filename matches exactly (case-sensitive)
- Make sure the device isn't in silent mode
- Test with a system sound first to rule out code issues

### Sound is too quiet/loud
- iOS controls the volume through system settings
- You can normalize your audio in editing software
- The "critical" sound variant plays louder on iOS

### Wrong sound plays
- Verify the filename in NotificationManager.swift matches your files exactly
- Check that both sound files are in the project (not just referenced)
- Clean build folder and rebuild: Product > Clean Build Folder
