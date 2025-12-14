import Foundation
import Combine
import WidgetKit
import UIKit

class CalendarSyncManager: ObservableObject {
    static let shared = CalendarSyncManager()

    @Published var events: [CalendarEvent] = []
    @Published var lastSyncCount: Int?
    @Published var lastSyncDate: Date?
    @Published var isSyncing = false

    private let userDefaults = UserDefaults.standard
    private let sharedDefaults = UserDefaults(suiteName: "group.com.calendarnotifier.shared")
    private let syncedEventsKey = "syncedEvents"
    private let lastSyncDateKey = "lastSyncDate"

    private init() {
        // Load cached events on init
        events = loadSyncedEvents()
        lastSyncDate = userDefaults.object(forKey: lastSyncDateKey) as? Date
    }

    var nextEvent: CalendarEvent? {
        let now = Date()
        return events
            .filter { $0.startDate > now }
            .sorted { $0.startDate < $1.startDate }
            .first
    }

    func syncCalendar() async {
        await MainActor.run {
            isSyncing = true
        }

        // Use EventKit to fetch events from local calendar
        let fetchedEvents = await EventKitManager.shared.fetchEvents()
        processEvents(fetchedEvents)

        await MainActor.run {
            isSyncing = false
            lastSyncDate = Date()
            userDefaults.set(lastSyncDate, forKey: lastSyncDateKey)
        }
    }
    
    private func processEvents(_ newEvents: [CalendarEvent]) {
        print("\n🔄 STARTING EVENT SYNC")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        // Filter to only FUTURE events
        let now = Date()
        let futureEvents = newEvents.filter { $0.startDate > now }

        print("📊 Total events from Google: \(newEvents.count)")
        print("📊 Future events: \(futureEvents.count)")

        // Get previously synced events
        let previousEvents = loadSyncedEvents()
        let previousEventIDs = Set(previousEvents.map { $0.id })
        let newEventIDs = Set(futureEvents.map { $0.id })

        print("📊 Previous synced events: \(previousEvents.count)")
        print("📊 New synced events: \(futureEvents.count)")

        // Cancel notifications for removed events
        let removedEventIDs = previousEventIDs.subtracting(newEventIDs)
        if !removedEventIDs.isEmpty {
            print("\n🗑️  Removing \(removedEventIDs.count) deleted events")
            for eventID in removedEventIDs {
                NotificationManager.shared.cancelNotifications(for: eventID)
            }
        }

        // iOS has a limit of 64 pending notifications per app
        // We schedule 2 notifications per event, so limit to 27 events (54 notifications)
        // This leaves buffer room for other apps that may also need to schedule notifications
        let maxEventsForNotifications = 27

        // Sort events by start date and take the nearest ones for notification scheduling
        let sortedEvents = futureEvents.sorted { $0.startDate < $1.startDate }
        let eventsForNotifications = Array(sortedEvents.prefix(maxEventsForNotifications))
        let eventsToSkipNotifications = Set(sortedEvents.dropFirst(maxEventsForNotifications).map { $0.id })

        if sortedEvents.count > maxEventsForNotifications {
            print("\n⚠️  iOS 64 notification limit: Scheduling notifications for nearest \(maxEventsForNotifications) events only")
            print("   Total events: \(sortedEvents.count)")
            print("   Events with notifications: \(maxEventsForNotifications)")
            print("   Events without notifications: \(sortedEvents.count - maxEventsForNotifications)")
        }

        // Schedule notifications for new or updated events
        print("\n📅 Processing \(futureEvents.count) events for notifications:")
        for (index, event) in sortedEvents.enumerated() {
            print("\n[\(index + 1)/\(sortedEvents.count)]")

            // Cancel existing notifications for this event
            NotificationManager.shared.cancelNotifications(for: event.id)

            // Only schedule notifications for the nearest events to stay within iOS limit
            if eventsToSkipNotifications.contains(event.id) {
                print("   ⏭️  Skipping notification scheduling (beyond 64 notification iOS limit)")
            } else {
                // Schedule new notifications
                NotificationManager.shared.scheduleNotifications(for: event)
            }
        }

        // Save synced events (only future events)
        saveSyncedEvents(futureEvents)

        print("\n✅ Sync complete - processed \(futureEvents.count) future events")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        // Log all pending notifications after sync
        NotificationManager.shared.logPendingNotifications()

        // Update published events on main thread
        DispatchQueue.main.async {
            self.events = futureEvents
            self.lastSyncCount = futureEvents.count

            // Haptic feedback on successful sync
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

            // Clear the count after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.lastSyncCount = nil
            }
        }
    }
    
    private func loadSyncedEvents() -> [CalendarEvent] {
        guard let data = userDefaults.data(forKey: syncedEventsKey),
              let events = try? JSONDecoder().decode([CalendarEvent].self, from: data) else {
            return []
        }
        return events
    }
    
    private func saveSyncedEvents(_ events: [CalendarEvent]) {
        print("\n📲 SAVING EVENTS TO WIDGET")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📊 Saving \(events.count) events to shared UserDefaults")
        for (index, event) in events.enumerated() {
            print("   [\(index + 1)] '\(event.title)' at \(event.startDate)")
        }

        if let data = try? JSONEncoder().encode(events) {
            print("📦 Encoded \(data.count) bytes of event data")

            // Save to standard UserDefaults
            userDefaults.set(data, forKey: syncedEventsKey)
            print("✅ Saved to standard UserDefaults")

            // Save to shared App Group for widget access
            if let sharedDefaults = sharedDefaults {
                sharedDefaults.set(data, forKey: syncedEventsKey)
                print("✅ Saved to App Group: group.com.calendarnotifier.shared")
            } else {
                print("❌ Failed to save to App Group - sharedDefaults is nil")
            }

            // Tell widget to refresh
            WidgetCenter.shared.reloadAllTimelines()
            print("🔄 Widget reload requested via WidgetCenter.shared.reloadAllTimelines()")
        } else {
            print("❌ Failed to encode events to JSON")
        }
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
    }
}

// MARK: - Calendar Event Model

struct CalendarEvent: Identifiable, Codable {
    let id: String
    let title: String
    let startDate: Date
    let location: String?
    let eventDescription: String?
}
