import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    func scheduleNotifications(for event: CalendarEvent) {
        let settings = SoundSettingsManager.shared

        print("📅 Scheduling notifications for event: \(event.title)")
        print("   Event ID: \(event.id)")
        print("   Start date: \(event.startDate)")

        // Schedule first reminder with configured time and sound
        print("   First reminder: \(settings.firstReminderMinutes) min before, sound: \(settings.oneHourSound)")
        scheduleNotification(
            for: event,
            minutesBefore: settings.firstReminderMinutes,
            identifier: "\(event.id)-first",
            sound: soundForId(settings.oneHourSound)
        )

        // Schedule second reminder with configured time and sound
        print("   Second reminder: \(settings.secondReminderMinutes) min before, sound: \(settings.fifteenMinSound)")
        scheduleNotification(
            for: event,
            minutesBefore: settings.secondReminderMinutes,
            identifier: "\(event.id)-second",
            sound: soundForId(settings.fifteenMinSound)
        )
    }

    private func soundForId(_ soundId: String) -> UNNotificationSound {
        if soundId == "default" {
            return .default
        }
        // Reference bundled sound file (must be .caf, .aiff, or .wav in app bundle)
        // Sound files are at the root of the bundle
        return UNNotificationSound(named: UNNotificationSoundName(rawValue: "\(soundId).caf"))
    }

    private func scheduleNotification(
        for event: CalendarEvent,
        minutesBefore: Int,
        identifier: String,
        sound: UNNotificationSound
    ) {
        let content = UNMutableNotificationContent()
        content.title = event.title

        // Build subtitle with time and location
        var subtitleParts: [String] = ["Starting in \(minutesBefore) minutes"]
        if let location = event.location, !location.isEmpty {
            subtitleParts.append(location)
        }
        content.subtitle = subtitleParts.joined(separator: " • ")

        // Body shows the event description if available
        if let description = event.eventDescription, !description.isEmpty {
            // Strip HTML tags that might be in the description
            let cleanDescription = description
                .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !cleanDescription.isEmpty {
                content.body = cleanDescription
            }
        }

        content.sound = sound
        // Calculate trigger date
        guard let triggerDate = Calendar.current.date(byAdding: .minute, value: -minutesBefore, to: event.startDate) else {
            print("   ❌ Failed to calculate trigger date for \(minutesBefore) min notification")
            return
        }

        let now = Date()
        let timeInterval = triggerDate.timeIntervalSince(now)

        // Only schedule if in the future
        guard triggerDate > now else {
            print("   ⏭️  Skipping \(minutesBefore) min notification - trigger date is in the past")
            print("      Trigger date: \(triggerDate)")
            print("      Current time: \(now)")
            print("      Time difference: \(timeInterval) seconds")
            return
        }

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        print("   ✅ Scheduling \(minutesBefore) min notification")
        print("      ID: \(identifier)")
        print("      Trigger date: \(triggerDate)")
        print("      Time until trigger: \(Int(timeInterval / 60)) minutes (\(timeInterval) seconds)")
        print("      Components: year=\(components.year ?? 0), month=\(components.month ?? 0), day=\(components.day ?? 0), hour=\(components.hour ?? 0), minute=\(components.minute ?? 0)")

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("      ❌ Error scheduling notification \(identifier): \(error)")
            } else {
                print("      ✅ Successfully added notification \(identifier) to queue")
            }
        }
    }
    
    func cancelAllNotifications() {
        print("🗑️  Cancelling all pending notifications")
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    func cancelNotifications(for eventID: String) {
        print("🗑️  Cancelling notifications for event: \(eventID)")
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
            "\(eventID)-first",
            "\(eventID)-second"
        ])
    }

    func logPendingNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            print("\n📋 PENDING NOTIFICATIONS COUNT: \(requests.count)")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

            if requests.isEmpty {
                print("⚠️  No pending notifications found!")
            } else {
                for (index, request) in requests.enumerated() {
                    print("\n[\(index + 1)/\(requests.count)] \(request.identifier)")
                    print("   Title: \(request.content.title)")

                    if let trigger = request.trigger as? UNCalendarNotificationTrigger,
                       let nextTriggerDate = trigger.nextTriggerDate() {
                        let now = Date()
                        let timeInterval = nextTriggerDate.timeIntervalSince(now)
                        let minutesUntil = Int(timeInterval / 60)

                        print("   Trigger: \(nextTriggerDate)")
                        print("   Time until: \(minutesUntil) minutes (\(timeInterval) seconds)")
                        print("   Status: \(timeInterval > 0 ? "✅ Future" : "⚠️ Past")")
                    } else {
                        print("   Trigger: Unable to determine")
                    }
                }
            }

            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
        }
    }

    func sendTestNotification(for reminderType: String) {
        let settings = SoundSettingsManager.shared
        let sound: UNNotificationSound
        let title: String
        let body: String

        if reminderType == "first" {
            sound = soundForId(settings.oneHourSound)
            let timeLabel = SoundSettingsManager.availableReminderTimes.first { $0.minutes == settings.firstReminderMinutes }?.label ?? "\(settings.firstReminderMinutes) min"
            title = "Test: First Reminder"
            body = "This is how your \(timeLabel) reminder will sound"
        } else {
            sound = soundForId(settings.fifteenMinSound)
            let timeLabel = SoundSettingsManager.availableReminderTimes.first { $0.minutes == settings.secondReminderMinutes }?.label ?? "\(settings.secondReminderMinutes) min"
            title = "Test: Second Reminder"
            body = "This is how your \(timeLabel) reminder will sound"
        }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = sound

        // Trigger in 1 second
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "test-\(reminderType)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending test notification: \(error)")
            }
        }
    }
}
