import SwiftUI

struct EventListView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var syncManager = CalendarSyncManager.shared

    var body: some View {
        NavigationView {
            Group {
                if todayEvents.isEmpty && upcomingEvents.isEmpty {
                    emptyState
                } else {
                    eventList
                }
            }
            .navigationTitle("My Day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var todayEvents: [CalendarEvent] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        return syncManager.events
            .filter { $0.startDate >= today && $0.startDate < tomorrow }
            .sorted { $0.startDate < $1.startDate }
    }

    private var upcomingEvents: [CalendarEvent] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        return syncManager.events
            .filter { $0.startDate >= tomorrow }
            .sorted { $0.startDate < $1.startDate }
    }

    // MARK: - Views

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar")
                .font(.system(size: 50))
                .foregroundColor(.secondary)

            Text("No Events")
                .font(.title2)
                .fontWeight(.medium)

            Text("Your calendar is clear")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var eventList: some View {
        List {
            if !todayEvents.isEmpty {
                Section("Today") {
                    ForEach(todayEvents) { event in
                        EventRow(event: event, showDate: false)
                    }
                }
            }

            if !upcomingEvents.isEmpty {
                Section("Upcoming") {
                    ForEach(upcomingEvents) { event in
                        EventRow(event: event, showDate: true)
                    }
                }
            }
        }
    }
}

// MARK: - Event Row

struct EventRow: View {
    let event: CalendarEvent
    let showDate: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Time and optional date
            HStack {
                Text(event.startDate.formatted(.dateTime.hour().minute()))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)

                if showDate {
                    Text("•")
                        .foregroundColor(.secondary)
                    Text(event.startDate.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Title
            Text(event.title)
                .font(.body)
                .fontWeight(.medium)

            // Location
            if let location = event.location, !location.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "mappin")
                        .font(.caption2)
                    Text(location)
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }

            // Description preview
            if let description = event.eventDescription, !description.isEmpty {
                let cleanDescription = description
                    .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                if !cleanDescription.isEmpty {
                    Text(cleanDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
