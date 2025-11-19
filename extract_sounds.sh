#!/bin/bash

# Script to extract iOS system sounds for use in CalendarNotifier
# Run this on your Mac in the CalendarNotifier directory

SOUNDS_DIR="CalendarNotifier/Sounds"
mkdir -p "$SOUNDS_DIR"

echo "Extracting system sounds..."

# Multiple possible locations for system sounds
SOUND_PATHS=(
    "/System/Library/Audio/UISounds"
    "/System/Library/Sounds"
    "/System/Library/PrivateFrameworks/ToneLibrary.framework/Resources/AlertTones"
    "/System/Library/PrivateFrameworks/ToneLibrary.framework/Resources/Ringtones"
)

# Find a sound file in any of the paths
find_sound() {
    local name="$1"
    for base in "${SOUND_PATHS[@]}"; do
        # Try direct path
        if [ -f "$base/$name" ]; then
            echo "$base/$name"
            return 0
        fi
        # Try with different extensions
        for ext in caf aiff m4r; do
            local basename="${name%.*}"
            if [ -f "$base/$basename.$ext" ]; then
                echo "$base/$basename.$ext"
                return 0
            fi
        done
        # Search subdirectories
        local found=$(find "$base" -name "$name" 2>/dev/null | head -1)
        if [ -n "$found" ]; then
            echo "$found"
            return 0
        fi
    done
    return 1
}

# Copy sounds with conversion if needed
copy_sound() {
    local src_name="$1"
    local dest="$2"

    local src_path=$(find_sound "$src_name")
    if [ -n "$src_path" ]; then
        # Convert to caf if needed
        if [[ "$src_path" == *.m4r ]] || [[ "$src_path" == *.aiff ]]; then
            afconvert "$src_path" "$SOUNDS_DIR/$dest" -f caff -d LEI16
        else
            cp "$src_path" "$SOUNDS_DIR/$dest"
        fi
        echo "  Copied $src_name -> $dest"
        return 0
    fi
    return 1
}

# Try to find and copy sounds with fallbacks
echo ""
copy_sound "sms-received1.caf" "alert_high.caf" || \
copy_sound "ReceivedMessage.caf" "alert_high.caf" || \
copy_sound "Tink.caf" "alert_high.caf" || \
echo "  Warning: Could not find alert_high sound"

copy_sound "sms-received2.caf" "alert_low.caf" || \
copy_sound "SentMessage.caf" "alert_low.caf" || \
copy_sound "Tock.caf" "alert_low.caf" || \
echo "  Warning: Could not find alert_low sound"

copy_sound "new-mail.caf" "chime.caf" || \
copy_sound "mail-sent.caf" "chime.caf" || \
copy_sound "Chime.caf" "chime.caf" || \
echo "  Warning: Could not find chime sound"

copy_sound "payment_success.caf" "glass.caf" || \
copy_sound "Modern/calendar_alert_chord.caf" "glass.caf" || \
copy_sound "Glass.caf" "glass.caf" || \
echo "  Warning: Could not find glass sound"

copy_sound "nano/Alarm.caf" "horn.caf" || \
copy_sound "alarm.caf" "horn.caf" || \
copy_sound "Horn.caf" "horn.caf" || \
echo "  Warning: Could not find horn sound"

copy_sound "nano/3rdParty_DirectionUp_Haptic.caf" "bell.caf" || \
copy_sound "RingerChanged.caf" "bell.caf" || \
copy_sound "Bell.caf" "bell.caf" || \
echo "  Warning: Could not find bell sound"

copy_sound "key_press_click.caf" "electronic.caf" || \
copy_sound "Morse.caf" "electronic.caf" || \
copy_sound "Electronic.caf" "electronic.caf" || \
echo "  Warning: Could not find electronic sound"

# List what we actually have
echo ""
echo "Files in $SOUNDS_DIR:"
ls -la "$SOUNDS_DIR" 2>/dev/null || echo "  (none)"
echo ""

# If we couldn't find sounds, list available ones
if [ $(ls "$SOUNDS_DIR"/*.caf 2>/dev/null | wc -l) -eq 0 ]; then
    echo "Could not find expected sound files."
    echo "Listing available sounds in /System/Library/Sounds/:"
    ls /System/Library/Sounds/ 2>/dev/null
    echo ""
    echo "You may need to manually copy sound files to $SOUNDS_DIR"
fi

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
