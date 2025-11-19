import SwiftUI

struct EventListView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var syncManager = CalendarSyncManager.shared
    @StateObject private var soundSettings = SoundSettingsManager.shared

    private var isBigger: Bool { soundSettings.biggerMode }

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
        VStack(spacing: isBigger ? 24 : 16) {
            Image(systemName: "calendar")
                .font(isBigger ? .system(size: 48) : .largeTitle)
                .foregroundColor(.secondary)
                .accessibilityHidden(true)

            Text("No Events")
                .font(isBigger ? .title : .title2)
                .fontWeight(.medium)

            Text("Your calendar is clear")
                .font(isBigger ? .body : .subheadline)
                .foregroundColor(.secondary)
        }
        .accessibilityElement(children: .combine)
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
    @StateObject private var soundSettings = SoundSettingsManager.shared

    private var isBigger: Bool { soundSettings.biggerMode }

    var body: some View {
        VStack(alignment: .leading, spacing: isBigger ? 10 : 6) {
            // Time and optional date
            HStack {
                Text(event.startDate.formatted(.dateTime.hour().minute()))
                    .font(isBigger ? .body : .subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)

                if showDate {
                    Text("•")
                        .foregroundColor(.secondary)
                        .accessibilityHidden(true)
                    Text(event.startDate.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                        .font(isBigger ? .subheadline : .caption)
                        .foregroundColor(.secondary)
                }
            }

            // Title
            Text(event.title)
                .font(isBigger ? .title3 : .body)
                .fontWeight(.medium)

            // Location
            if let location = event.location, !location.isEmpty {
                HStack(spacing: isBigger ? 6 : 4) {
                    Image(systemName: "mappin")
                        .font(isBigger ? .caption : .caption2)
                        .accessibilityHidden(true)
                    Text(location)
                        .font(isBigger ? .subheadline : .caption)
                }
                .foregroundColor(.secondary)
                .accessibilityLabel("Location: \(location)")
            }

            // Description preview
            if let description = event.eventDescription, !description.isEmpty {
                let cleanDescription = description
                    .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                if !cleanDescription.isEmpty {
                    Text(cleanDescription)
                        .font(isBigger ? .subheadline : .caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, isBigger ? 8 : 4)
        .accessibilityElement(children: .combine)
    }
}
