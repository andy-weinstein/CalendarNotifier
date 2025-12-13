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
            VStack(alignment: .center, spacing: 8) {
                // Large, high-contrast time
                Text(event.startDate, style: .time)
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.primary)
                    .minimumScaleFactor(0.8)

                // Event title - larger and bolder
                Text(event.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(3)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.85)

                Spacer()

                // Time until - larger and high contrast
                Text(timeUntilEvent(event.startDate))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange)
                    .cornerRadius(8)
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
                // Large time display
                VStack(alignment: .center, spacing: 6) {
                    Text(event.startDate.formatted(.dateTime.weekday(.abbreviated)).uppercased())
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary)

                    Text(event.startDate.formatted(.dateTime.day()))
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(.primary)
                        .minimumScaleFactor(0.8)

                    Text(event.startDate, style: .time)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                        .minimumScaleFactor(0.8)
                }
                .frame(width: 90)

                // Event details - larger and clearer
                VStack(alignment: .leading, spacing: 8) {
                    Text(event.title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(3)
                        .minimumScaleFactor(0.85)

                    Spacer()

                    // Time until - high contrast badge
                    HStack {
                        Text(timeUntilEvent(event.startDate))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.orange)
                            .cornerRadius(10)

                        Spacer()
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
