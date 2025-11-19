#!/bin/bash

# Script to extract iOS system sounds for use in CalendarNotifier
# Run this on your Mac in the CalendarNotifier directory

SOUNDS_DIR="CalendarNotifier/Sounds"
mkdir -p "$SOUNDS_DIR"

echo "Extracting system sounds..."

# Source directory for system sounds
SYS_SOUNDS="/System/Library/Audio/UISounds"

# Define sound mappings (source name -> our name)
declare -A sounds
sounds["sms-received1.caf"]="alert_high.caf"
sounds["sms-received2.caf"]="alert_low.caf"
sounds["new-mail.caf"]="chime.caf"
sounds["mail-sent.caf"]="glass.caf"
sounds["Tink.caf"]="horn.caf"
sounds["Tock.caf"]="bell.caf"
sounds["Morse.caf"]="electronic.caf"

# Copy and rename sounds
for src in "${!sounds[@]}"; do
    dest="${sounds[$src]}"
    if [ -f "$SYS_SOUNDS/$src" ]; then
        cp "$SYS_SOUNDS/$src" "$SOUNDS_DIR/$dest"
        echo "  Copied $src -> $dest"
    elif [ -f "$SYS_SOUNDS/New/$src" ]; then
        cp "$SYS_SOUNDS/New/$src" "$SOUNDS_DIR/$dest"
        echo "  Copied New/$src -> $dest"
    else
        echo "  Warning: $src not found"
    fi
done

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
