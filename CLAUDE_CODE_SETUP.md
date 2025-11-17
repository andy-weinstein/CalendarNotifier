# Using This Project with Claude Code

This repository is ready to use with Claude Code! Here's how to continue development.

## Getting Started with Claude Code

### 1. Clone this repository (if not already done)
```bash
git clone <your-repo-url>
cd CalendarNotifier
```

### 2. Start Claude Code
```bash
claude-code
```

### 3. What Claude Code Can Help With

Claude Code is perfect for:
- **Setting up the Xcode project**: "Create an Xcode project with these Swift files"
- **Adding dependencies**: "Add the Google Sign-In Swift package"
- **Configuring Info.plist**: "Update Info.plist with my Client ID: [YOUR_ID]"
- **Creating sound files**: "Help me convert audio files to CAF format"
- **Debugging**: "Why aren't my notifications appearing?"
- **Testing**: "Create test calendar events for notification testing"
- **Customization**: "Change the notification times to 2 hours and 30 minutes"

## Recommended First Steps with Claude Code

### Step 1: Create Xcode Project
Ask Claude Code:
```
"Create a new Xcode iOS app project in this directory with:
- Target name: CalendarNotifier
- Bundle ID: com.[yourname].CalendarNotifier
- Minimum iOS version: 16.0
- Add all the Swift files from this repo to the project"
```

### Step 2: Configure Dependencies
Ask Claude Code:
```
"Add Swift Package Manager dependencies:
1. GoogleSignIn-iOS (7.0.0+)
2. google-api-objectivec-client-for-rest (3.0.0+) with GoogleAPIClientForREST product"
```

### Step 3: Set Up Google Cloud
Ask Claude Code:
```
"Walk me through setting up Google Cloud Console for this app.
I need to enable Calendar API and create iOS OAuth credentials."
```

### Step 4: Configure Credentials
Ask Claude Code:
```
"Update my Info.plist and GoogleCalendarManager.swift with my Google Client ID: [paste your ID]"
```

## Project Structure

```
CalendarNotifier/
├── .git/                           # Git repository
├── .gitignore                      # Xcode/Swift gitignore
├── README.md                       # Main project documentation
├── QUICKSTART.md                   # Setup checklist
├── SOUND_GUIDE.md                  # Audio setup instructions
├── PROJECT_STRUCTURE.md            # Architecture details
├── CLAUDE_CODE_SETUP.md           # This file
├── Info.plist                     # App configuration
├── CalendarNotifierApp.swift      # App entry point
├── ContentView.swift              # Main UI
├── GoogleAuthView.swift           # Auth screen
├── GoogleCalendarManager.swift    # Calendar API
├── NotificationManager.swift      # Notification scheduling
└── CalendarSyncManager.swift      # Sync coordinator
```

## Common Claude Code Tasks

### Add New Features
```
"Add a settings screen where users can customize notification times"
"Add support for multiple calendars"
"Create a widget showing the next upcoming event"
```

### Debug Issues
```
"The notifications aren't firing, help me debug"
"Google sign-in is failing, what could be wrong?"
"Background sync isn't working, how do I fix it?"
```

### Improve Code
```
"Refactor NotificationManager to use async/await"
"Add error handling to the calendar sync"
"Write unit tests for CalendarSyncManager"
```

### Create Sound Files
```
"Help me create notification sound files from these audio files: [file paths]"
"Convert these MP3s to CAF format for iOS notifications"
```

## Tips for Working with Claude Code

1. **Be specific**: "Add logging to GoogleCalendarManager to debug API calls"
2. **Ask for explanations**: "Explain how the notification scheduling works"
3. **Request iterations**: "The UI looks good, but make the buttons larger"
4. **Test as you go**: "Create a test that verifies notifications are scheduled correctly"
5. **Ask for best practices**: "Is there a better way to handle background fetch?"

## Git Workflow

Claude Code works great with git:
```bash
# Claude Code can help with commits
# Ask: "Review my changes and create a meaningful commit"

# Or do it manually:
git add .
git commit -m "Add dual notification feature"
git push origin main
```

## Configuration Files to Update

Before testing, you MUST update these with your actual values:

1. **Info.plist**
   - `GIDClientID`: Your Google Client ID
   - `CFBundleURLSchemes`: Your reversed client ID

2. **GoogleCalendarManager.swift**
   - `clientID`: Your Google Client ID

Ask Claude Code: "Show me exactly what I need to update in Info.plist and GoogleCalendarManager.swift"

## Testing with Claude Code

Ask Claude Code to help with testing:
```
"Create a shell script that uses xcrun to build this project"
"Help me set up fastlane for automated testing"
"Create test calendar events using the Google Calendar API"
```

## Next Steps

1. **Initial Setup**: Follow QUICKSTART.md checklist
2. **Development**: Use Claude Code for implementation
3. **Testing**: Test on real device with Claude Code's help
4. **Iteration**: Refine features with Claude Code assistance

## Resources

- Claude Code docs: https://docs.claude.com/en/docs/claude-code
- This project's README: [README.md](README.md)
- Quick start guide: [QUICKSTART.md](QUICKSTART.md)

## Example Claude Code Sessions

### Session 1: Initial Setup
```
You: "I have this CalendarNotifier project. Help me create an Xcode project."
Claude: [creates project structure]
You: "Now add the Google Sign-In dependency"
Claude: [adds package dependency]
You: "My Client ID is: 123456.apps.googleusercontent.com"
Claude: [updates configuration files]
```

### Session 2: Customization
```
You: "I want 3 notifications: 2 hours, 1 hour, and 15 minutes before"
Claude: [modifies NotificationManager]
You: "Also add a third custom sound"
Claude: [updates notification scheduling code]
```

### Session 3: Debugging
```
You: "Notifications aren't working, here's the error: [paste error]"
Claude: [analyzes and suggests fixes]
You: "That didn't work, can you check the notification permissions?"
Claude: [reviews permission handling code]
```

Happy coding! 🚀
