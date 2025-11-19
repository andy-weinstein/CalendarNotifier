#!/bin/bash

# Script to extract iOS system sounds for use in CalendarNotifier
# Run this on your Mac in the CalendarNotifier directory

SOUNDS_DIR="CalendarNotifier/Sounds"
mkdir -p "$SOUNDS_DIR"

echo "Extracting system sounds..."

# Source directory for system sounds
SYS_SOUNDS="/System/Library/Audio/UISounds"

# Copy sounds with simple approach
copy_sound() {
    local src="$1"
    local dest="$2"

    if [ -f "$SYS_SOUNDS/$src" ]; then
        cp "$SYS_SOUNDS/$src" "$SOUNDS_DIR/$dest"
        echo "  Copied $src -> $dest"
    elif [ -f "$SYS_SOUNDS/New/$src" ]; then
        cp "$SYS_SOUNDS/New/$src" "$SOUNDS_DIR/$dest"
        echo "  Copied New/$src -> $dest"
    else
        echo "  Warning: $src not found"
    fi
}

# Copy each sound
copy_sound "sms-received1.caf" "alert_high.caf"
copy_sound "sms-received2.caf" "alert_low.caf"
copy_sound "new-mail.caf" "chime.caf"
copy_sound "mail-sent.caf" "glass.caf"
copy_sound "Tink.caf" "horn.caf"
copy_sound "Tock.caf" "bell.caf"
copy_sound "Morse.caf" "electronic.caf"

echo ""
echo "Sound files created in $SOUNDS_DIR"
echo ""
echo "Next steps:"
echo "1. Open your Xcode project"
echo "2. Right-click on the CalendarNotifier group"
echo "3. Select 'Add Files to CalendarNotifier'"
echo "4. Navigate to and select the 'Sounds' folder"
echo "5. Make sure 'Copy items if needed' is checked"
echo "6. Make sure 'Add to targets: CalendarNotifier' is checked"
echo "7. Click Add"
echo ""
echo "Then rebuild the app and test notifications!"
