import Foundation
import Combine

class CalendarSyncManager: ObservableObject {
    static let shared = CalendarSyncManager()

    @Published var events: [CalendarEvent] = []

    private let userDefaults = UserDefaults.standard
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
        await withCheckedContinuation { continuation in
            GoogleCalendarManager.shared.fetchEvents { [weak self] events in
                self?.processEvents(events)
                continuation.resume()
            }
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
            userDefaults.set(data, forKey: syncedEventsKey)
        }
    }
}
