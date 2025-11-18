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
        let nextEvent = loadNextEvent()

        let currentDate = Date()
        var entries: [CalendarEntry] = []

        // Create entry for now
        entries.append(CalendarEntry(date: currentDate, event: nextEvent))

        // If there's an event, create entries for key times
        if let event = nextEvent {
            // Entry when event starts (to show next event after this one)
            if event.startDate > currentDate {
                entries.append(CalendarEntry(date: event.startDate, event: nil))
            }
        }

        // Request refresh every 15 minutes for sync
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate) ?? currentDate.addingTimeInterval(900)

        let timeline = Timeline(entries: entries, policy: .after(refreshDate))
        completion(timeline)
    }

    private func loadNextEvent() -> WidgetEvent? {
        // Load from shared App Group UserDefaults
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.calendarnotifier.shared"),
              let data = sharedDefaults.data(forKey: "syncedEvents"),
              let events = try? JSONDecoder().decode([SharedCalendarEvent].self, from: data) else {
            return nil
        }

        let now = Date()
        let nextEvent = events
            .filter { $0.startDate > now }
            .sorted { $0.startDate < $1.startDate }
            .first

        guard let event = nextEvent else { return nil }

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
            VStack(alignment: .leading, spacing: 4) {
                Text("NEXT")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                Text(event.startDate, style: .time)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.blue)

                Text(event.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(2)

                if let location = event.location, !location.isEmpty {
                    Text(location)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Text(timeUntilEvent(event.startDate))
                    .font(.caption2)
                    .foregroundColor(.orange)
            }
            .padding()
            .containerBackground(.fill.tertiary, for: .widget)
        } else {
            VStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.title)
                    .foregroundColor(.secondary)

                Text("No Events")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .containerBackground(.fill.tertiary, for: .widget)
        }
    }

    private func timeUntilEvent(_ date: Date) -> String {
        let interval = date.timeIntervalSince(Date())
        if interval < 0 {
            return "Now"
        }

        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if hours > 0 {
            return "in \(hours)h \(minutes)m"
        } else {
            return "in \(minutes)m"
        }
    }
}

struct MediumWidgetView: View {
    let event: WidgetEvent?

    var body: some View {
        if let event = event {
            HStack(spacing: 16) {
                // Time column
                VStack(alignment: .center, spacing: 4) {
                    Text(event.startDate.formatted(.dateTime.weekday(.abbreviated)))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(event.startDate.formatted(.dateTime.day()))
                        .font(.title)
                        .fontWeight(.bold)

                    Text(event.startDate, style: .time)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .frame(width: 60)

                // Event details
                VStack(alignment: .leading, spacing: 4) {
                    Text("NEXT EVENT")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)

                    Text(event.title)
                        .font(.headline)
                        .lineLimit(2)

                    if let location = event.location, !location.isEmpty {
                        HStack(spacing: 2) {
                            Image(systemName: "mappin")
                                .font(.caption2)
                            Text(location)
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    }

                    Spacer()

                    Text(timeUntilEvent(event.startDate))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                }

                Spacer()
            }
            .padding()
            .containerBackground(.fill.tertiary, for: .widget)
        } else {
            HStack {
                Image(systemName: "calendar")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)

                VStack(alignment: .leading) {
                    Text("No Upcoming Events")
                        .font(.headline)
                    Text("Open app to sync calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding()
            .containerBackground(.fill.tertiary, for: .widget)
        }
    }

    private func timeUntilEvent(_ date: Date) -> String {
        let interval = date.timeIntervalSince(Date())
        if interval < 0 {
            return "Now"
        }

        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if hours > 0 {
            return "in \(hours)h \(minutes)m"
        } else {
            return "in \(minutes)m"
        }
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
