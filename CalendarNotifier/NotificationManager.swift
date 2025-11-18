import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    func scheduleNotifications(for event: CalendarEvent) {
        let settings = SoundSettingsManager.shared

        // Schedule first reminder with configured time and sound
        scheduleNotification(
            for: event,
            minutesBefore: settings.firstReminderMinutes,
            identifier: "\(event.id)-first",
            sound: soundForId(settings.oneHourSound)
        )

        // Schedule second reminder with configured time and sound
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
        return UNNotificationSound(named: UNNotificationSoundName(rawValue: soundId))
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
            return
        }
        
        // Only schedule if in the future
        guard triggerDate > Date() else {
            return
        }
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    func cancelNotifications(for eventID: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
            "\(eventID)-first",
            "\(eventID)-second"
        ])
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
