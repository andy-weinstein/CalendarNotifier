import Foundation
import Combine
import WidgetKit
import UIKit

class CalendarSyncManager: ObservableObject {
    static let shared = CalendarSyncManager()

    @Published var events: [CalendarEvent] = []
    @Published var lastSyncCount: Int?
    @Published var isSyncing = false

    private let userDefaults = UserDefaults.standard
    private let sharedDefaults = UserDefaults(suiteName: "group.com.calendarnotifier.shared")
    private let syncedEventsKey = "syncedEvents"

    private init() {
        // Load cached events on init
        events = loadSyncedEvents()
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

        await withCheckedContinuation { continuation in
            GoogleCalendarManager.shared.fetchEvents { [weak self] events in
                self?.processEvents(events)
                continuation.resume()
            }
        }

        await MainActor.run {
            isSyncing = false
        }
    }
    
    private func processEvents(_ newEvents: [CalendarEvent]) {
        // Get previously synced events
        let previousEvents = loadSyncedEvents()
        let previousEventIDs = Set(previousEvents.map { $0.id })
        let newEventIDs = Set(newEvents.map { $0.id })
        
        // Cancel notifications for removed events
        let removedEventIDs = previousEventIDs.subtracting(newEventIDs)
        for eventID in removedEventIDs {
            NotificationManager.shared.cancelNotifications(for: eventID)
        }
        
        // Schedule notifications for new or updated events
        for event in newEvents {
            // Cancel existing notifications for this event
            NotificationManager.shared.cancelNotifications(for: event.id)
            
            // Schedule new notifications
            NotificationManager.shared.scheduleNotifications(for: event)
        }
        
        // Save synced events
        saveSyncedEvents(newEvents)

        // Update published events on main thread
        DispatchQueue.main.async {
            self.events = newEvents
            self.lastSyncCount = newEvents.count

            // Haptic feedback on successful sync
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

            // Clear the count after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.lastSyncCount = nil
            }
        }

        print("Synced \(newEvents.count) events")
    }
    
    private func loadSyncedEvents() -> [CalendarEvent] {
        guard let data = userDefaults.data(forKey: syncedEventsKey),
              let events = try? JSONDecoder().decode([CalendarEvent].self, from: data) else {
            return []
        }
        return events
    }
    
    private func saveSyncedEvents(_ events: [CalendarEvent]) {
        if let data = try? JSONEncoder().encode(events) {
            // Save to standard UserDefaults
            userDefaults.set(data, forKey: syncedEventsKey)

            // Save to shared App Group for widget access
            sharedDefaults?.set(data, forKey: syncedEventsKey)

            // Tell widget to refresh
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}
