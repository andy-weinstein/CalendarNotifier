import Foundation
import EventKit
import Combine

class EventKitManager: ObservableObject {
    static let shared = EventKitManager()

    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined
    @Published var isAuthorized = false

    let eventStore = EKEventStore()

    private init() {
        updateAuthorizationStatus()
    }

    // MARK: - Authorization

    func updateAuthorizationStatus() {
        let status = EKEventStore.authorizationStatus(for: .event)
        DispatchQueue.main.async {
            self.authorizationStatus = status
            self.isAuthorized = (status == .fullAccess || status == .authorized)
        }
    }

    func requestAccess() async -> Bool {
        print("\n🔐 REQUESTING CALENDAR ACCESS")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        do {
            // iOS 17+ uses requestFullAccessToEvents, earlier versions use requestAccess
            let granted: Bool
            if #available(iOS 17.0, *) {
                granted = try await eventStore.requestFullAccessToEvents()
            } else {
                granted = try await eventStore.requestAccess(to: .event)
            }

            await MainActor.run {
                self.isAuthorized = granted
                self.updateAuthorizationStatus()
            }

            if granted {
                print("✅ Calendar access granted")
            } else {
                print("❌ Calendar access denied")
            }

            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
            return granted
        } catch {
            print("❌ Error requesting calendar access: \(error)")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
            return false
        }
    }

    // MARK: - Fetching Events

    func fetchEvents(completion: @escaping ([CalendarEvent]) -> Void) {
        guard isAuthorized else {
            print("❌ Not authorized to access calendar")
            completion([])
            return
        }

        let now = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 30, to: now)!

        print("\n📡 FETCHING EVENTS FROM LOCAL CALENDAR")
        print("   Time range: \(now) to \(endDate)")

        // Get all calendars the user has access to
        let calendars = eventStore.calendars(for: .event)
        print("   Found \(calendars.count) calendars")

        // Create predicate for date range
        let predicate = eventStore.predicateForEvents(
            withStart: now,
            end: endDate,
            calendars: calendars
        )

        // Fetch events
        let ekEvents = eventStore.events(matching: predicate)
        print("   ✅ Fetched \(ekEvents.count) raw events from EventKit")

        // Convert to CalendarEvent
        let calendarEvents = ekEvents.compactMap { ekEvent -> CalendarEvent? in
            guard let startDate = ekEvent.startDate,
                  let title = ekEvent.title, !title.isEmpty else {
                return nil
            }

            return CalendarEvent(
                id: ekEvent.eventIdentifier ?? UUID().uuidString,
                title: title,
                startDate: startDate,
                location: ekEvent.location,
                eventDescription: ekEvent.notes
            )
        }

        // Sort by start date
        let sortedEvents = calendarEvents.sorted { $0.startDate < $1.startDate }

        print("   ✅ Parsed \(sortedEvents.count) valid calendar events\n")

        completion(sortedEvents)
    }

    // Async version for convenience
    func fetchEvents() async -> [CalendarEvent] {
        await withCheckedContinuation { continuation in
            fetchEvents { events in
                continuation.resume(returning: events)
            }
        }
    }
}
