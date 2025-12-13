import WidgetKit
import SwiftUI

// MARK: - Widget Entry

struct CalendarEntry: TimelineEntry {
    let date: Date
    let event: WidgetEvent?
}

struct WidgetEvent {
    let id: String
    let title: String
    let startDate: Date
    let location: String?
}

// MARK: - Timeline Provider

struct CalendarTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> CalendarEntry {
        CalendarEntry(
            date: Date(),
            event: WidgetEvent(
                id: "placeholder",
                title: "Sample Event",
                startDate: Date().addingTimeInterval(3600),
                location: nil
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (CalendarEntry) -> Void) {
        let entry = CalendarEntry(
            date: Date(),
            event: loadNextEvent()
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CalendarEntry>) -> Void) {
        // Load events and trigger sync
        let allEvents = loadAllEvents()
        let currentDate = Date()

        print("📊 Widget Timeline: Loading timeline with \(allEvents.count) events")

        let nextEvent = allEvents
            .filter { $0.startDate > currentDate }
            .sorted { $0.startDate < $1.startDate }
            .first

        var entries: [CalendarEntry] = []

        // Create entry for now
        entries.append(CalendarEntry(date: currentDate, event: nextEvent))
        print("✅ Widget Timeline: Entry 1 - Now with event: \(nextEvent?.title ?? "nil")")

        // If there's an event, create entry for when it starts to show the NEXT event
        if let currentEvent = nextEvent {
            if currentEvent.startDate > currentDate {
                // Find the event AFTER the current one
                let eventAfterCurrent = allEvents
                    .filter { $0.startDate > currentEvent.startDate }
                    .sorted { $0.startDate < $1.startDate }
                    .first

                let nextEntry = WidgetEvent(
                    id: eventAfterCurrent?.id ?? "",
                    title: eventAfterCurrent?.title ?? "",
                    startDate: eventAfterCurrent?.startDate ?? Date.distantFuture,
                    location: eventAfterCurrent?.location
                )

                entries.append(CalendarEntry(
                    date: currentEvent.startDate,
                    event: eventAfterCurrent != nil ? nextEntry : nil
                ))
                print("✅ Widget Timeline: Entry 2 - At \(currentEvent.startDate) with event: \(eventAfterCurrent?.title ?? "nil")")
            }
        }

        // Request refresh every 15 minutes for sync
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate) ?? currentDate.addingTimeInterval(900)
        print("✅ Widget Timeline: Next refresh at \(refreshDate)")

        let timeline = Timeline(entries: entries, policy: .after(refreshDate))
        completion(timeline)
    }

    private func loadAllEvents() -> [SharedCalendarEvent] {
        print("📊 Widget loadAllEvents: Starting to load events")

        guard let sharedDefaults = UserDefaults(suiteName: "group.com.calendarnotifier.shared") else {
            print("⚠️ Widget loadAllEvents: Failed to load shared UserDefaults")
            return []
        }

        guard let data = sharedDefaults.data(forKey: "syncedEvents") else {
            print("⚠️ Widget loadAllEvents: No data found for syncedEvents")
            return []
        }

        print("📊 Widget loadAllEvents: Found \(data.count) bytes of event data")

        guard let events = try? JSONDecoder().decode([SharedCalendarEvent].self, from: data) else {
            print("❌ Widget loadAllEvents: Failed to decode events from data")
            return []
        }

        print("📊 Widget loadAllEvents: Decoded \(events.count) total events")
        for (index, event) in events.enumerated() {
            print("   Event \(index + 1): '\(event.title)' at \(event.startDate)")
        }

        return events
    }

    private func loadNextEvent() -> WidgetEvent? {
        let allEvents = loadAllEvents()
        let now = Date()
        let futureEvents = allEvents.filter { $0.startDate > now }

        print("📊 Widget loadNextEvent: Found \(futureEvents.count) future events out of \(allEvents.count) total")

        let nextEvent = futureEvents
            .sorted { $0.startDate < $1.startDate }
            .first

        guard let event = nextEvent else {
            print("⚠️ Widget loadNextEvent: No future events to display")
            return nil
        }

        print("✅ Widget loadNextEvent: Returning event '\(event.title)' at \(event.startDate)")

        return WidgetEvent(
            id: event.id,
            title: event.title,
            startDate: event.startDate,
            location: event.location
        )
    }
}

// Shared event structure (must match main app)
struct SharedCalendarEvent: Codable {
    let id: String
    let title: String
    let startDate: Date
    let location: String?
    let eventDescription: String?
}

// MARK: - Widget Views

struct CalendarWidgetEntryView: View {
    var entry: CalendarEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(event: entry.event)
        case .systemMedium:
            MediumWidgetView(event: entry.event)
        default:
            SmallWidgetView(event: entry.event)
        }
    }
}

struct SmallWidgetView: View {
    let event: WidgetEvent?

    var body: some View {
        if let event = event {
            VStack(alignment: .center, spacing: 8) {
                // Large, high-contrast time
                Text(event.startDate, style: .time)
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.primary)
                    .minimumScaleFactor(0.8)

                // Event title - wraps to fill available space
                Text(event.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(6)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: false)
                    .frame(maxHeight: .infinity)
            }
            .padding(12)
            .containerBackground(.fill, for: .widget)
        } else {
            VStack(spacing: 12) {
                Image(systemName: "calendar")
                    .font(.system(size: 44))
                    .foregroundColor(.primary)

                Text("No Events")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
            }
            .containerBackground(.fill, for: .widget)
        }
    }
}

struct MediumWidgetView: View {
    let event: WidgetEvent?

    var body: some View {
        if let event = event {
            HStack(spacing: 16) {
                // Large time display
                VStack(alignment: .center, spacing: 4) {
                    // Show Today/Tomorrow or weekday
                    Text(smartDayText(for: event.startDate))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                        .minimumScaleFactor(0.8)

                    // Only show day number if NOT today/tomorrow
                    if !isToday(event.startDate) && !isTomorrow(event.startDate) {
                        Text(event.startDate.formatted(.dateTime.day()))
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.primary)
                            .minimumScaleFactor(0.8)
                    }

                    // Larger time display
                    Text(event.startDate, style: .time)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                        .minimumScaleFactor(0.8)
                }
                .frame(width: 90)

                // Event details - wraps to fill available space
                VStack(alignment: .leading, spacing: 6) {
                    Text(event.title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(7)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: false)
                        .frame(maxHeight: .infinity, alignment: .top)

                    if let location = event.location, !location.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 14))
                            Text(location)
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    }
                }

                Spacer(minLength: 4)
            }
            .padding(14)
            .containerBackground(.fill, for: .widget)
        } else {
            HStack(spacing: 16) {
                Image(systemName: "calendar")
                    .font(.system(size: 50))
                    .foregroundColor(.primary)

                VStack(alignment: .leading, spacing: 4) {
                    Text("No Events")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.primary)
                    Text("Open app to sync")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(14)
            .containerBackground(.fill, for: .widget)
        }
    }

    private func smartDayText(for date: Date) -> String {
        if isToday(date) {
            return "TODAY"
        } else if isTomorrow(date) {
            return "TOMORROW"
        } else {
            return date.formatted(.dateTime.weekday(.abbreviated)).uppercased()
        }
    }

    private func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }

    private func isTomorrow(_ date: Date) -> Bool {
        Calendar.current.isDateInTomorrow(date)
    }
}

// MARK: - Widget Configuration

@main
struct CalendarNotifierWidget: Widget {
    let kind: String = "CalendarNotifierWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CalendarTimelineProvider()) { entry in
            CalendarWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Next Event")
        .description("Shows your next calendar event.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Previews

#Preview(as: .systemSmall) {
    CalendarNotifierWidget()
} timeline: {
    CalendarEntry(
        date: Date(),
        event: WidgetEvent(
            id: "1",
            title: "Doctor Appointment",
            startDate: Date().addingTimeInterval(3600),
            location: "123 Main St"
        )
    )
    CalendarEntry(date: Date(), event: nil)
}

#Preview(as: .systemMedium) {
    CalendarNotifierWidget()
} timeline: {
    CalendarEntry(
        date: Date(),
        event: WidgetEvent(
            id: "1",
            title: "Team Meeting",
            startDate: Date().addingTimeInterval(5400),
            location: "Conference Room A"
        )
    )
}
