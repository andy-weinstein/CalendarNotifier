import SwiftUI

struct ContentView: View {
    @StateObject private var calendarManager = GoogleCalendarManager.shared
    @StateObject private var syncManager = CalendarSyncManager.shared
    @State private var showingAuth = false
    @State private var showingSettings = false
    @State private var showingEventList = false

    var body: some View {
        NavigationView {
            if calendarManager.isAuthenticated {
                authenticatedView
            } else {
                unauthenticatedView
            }
        }
        .sheet(isPresented: $showingAuth) {
            GoogleAuthView()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingEventList) {
            EventListView()
        }
    }

    // MARK: - Authenticated View

    private var authenticatedView: some View {
        VStack(spacing: 0) {
            // Next Event Section
            nextEventSection
                .padding(.top, 20)

            Spacer()

            // Action Buttons
            VStack(spacing: 12) {
                Button {
                    Task {
                        await syncManager.syncCalendar()
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Sync Now")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    showingEventList = true
                } label: {
                    HStack {
                        Image(systemName: "list.bullet.rectangle")
                        Text("Show My Day")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    showingSettings = true
                } label: {
                    HStack {
                        Image(systemName: "gearshape")
                        Text("Settings")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 30)
        }
        .navigationTitle("Calendar Notifier")
        .onAppear {
            // Auto-sync when app launches
            Task {
                await syncManager.syncCalendar()
            }
        }
    }

    // MARK: - Next Event Section

    private var nextEventSection: some View {
        VStack(spacing: 16) {
            if let event = syncManager.nextEvent {
                Text("NEXT EVENT")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .tracking(1.5)

                VStack(spacing: 8) {
                    // Day of week
                    Text(event.startDate.formatted(.dateTime.weekday(.wide)))
                        .font(.system(size: 28, weight: .light))

                    // Date
                    Text(event.startDate.formatted(.dateTime.month(.wide).day()))
                        .font(.system(size: 34, weight: .bold))

                    // Time
                    Text(event.startDate.formatted(.dateTime.hour().minute()))
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.blue)
                }

                // Event details
                VStack(spacing: 4) {
                    Text(event.title)
                        .font(.title3)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)

                    if let location = event.location, !location.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin")
                                .font(.caption)
                            Text(location)
                                .font(.subheadline)
                        }
                        .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 8)

            } else {
                VStack(spacing: 12) {
                    Image(systemName: "calendar")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)

                    Text("No Upcoming Events")
                        .font(.title2)
                        .fontWeight(.medium)

                    Text("Tap Sync Now to refresh your calendar")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Unauthenticated View

    private var unauthenticatedView: some View {
        VStack(spacing: 15) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            Text("Calendar Notifier")
                .font(.title)
                .bold()

            Text("Get notifications 1 hour and 15 minutes before your events")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            Button("Connect Google Calendar") {
                showingAuth = true
            }
            .buttonStyle(.borderedProminent)
            .padding(.top)
        }
        .padding()
        .navigationTitle("Calendar Notifier")
    }
}
