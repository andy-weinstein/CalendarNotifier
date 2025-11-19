import SwiftUI

struct ContentView: View {
    @StateObject private var calendarManager = GoogleCalendarManager.shared
    @StateObject private var syncManager = CalendarSyncManager.shared
    @StateObject private var soundSettings = SoundSettingsManager.shared
    @State private var showingAuth = false
    @State private var showingSettings = false
    @State private var showingEventList = false

    // Computed properties for bigger mode
    private var isBigger: Bool { soundSettings.biggerMode }
    private var buttonPadding: CGFloat { isBigger ? 50 : 40 }
    private var buttonSpacing: CGFloat { isBigger ? 16 : 12 }
    private var sectionSpacing: CGFloat { isBigger ? 24 : 16 }

    var body: some View {
        NavigationView {
            if calendarManager.isRestoring {
                restoringView
            } else if calendarManager.isAuthenticated {
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

    // MARK: - Restoring View

    private var restoringView: some View {
        VStack(spacing: isBigger ? 24 : 16) {
            ProgressView()
                .scaleEffect(isBigger ? 2.0 : 1.5)

            Text("Connecting...")
                .font(isBigger ? .title2 : .headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Calendar Notifier")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Authenticated View

    private var authenticatedView: some View {
        VStack(spacing: 0) {
            // Next Event Section
            nextEventSection
                .padding(.top, isBigger ? 30 : 20)

            Spacer()

            // Sync Status
            if syncManager.isSyncing {
                HStack(spacing: isBigger ? 12 : 8) {
                    ProgressView()
                        .scaleEffect(isBigger ? 1.2 : 1.0)
                    Text("Syncing...")
                        .font(isBigger ? .body : .caption)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, isBigger ? 12 : 8)
            } else if let count = syncManager.lastSyncCount {
                Text("\(count) event\(count == 1 ? "" : "s") synced")
                    .font(isBigger ? .body : .caption)
                    .foregroundColor(.green)
                    .padding(.bottom, isBigger ? 12 : 8)
            }

            // Action Buttons
            VStack(spacing: buttonSpacing) {
                Button {
                    Task {
                        await syncManager.syncCalendar()
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .font(isBigger ? .title3 : .body)
                        Text("Sync Now")
                            .font(isBigger ? .title3 : .body)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, isBigger ? 8 : 0)
                }
                .buttonStyle(.borderedProminent)
                .disabled(syncManager.isSyncing)

                Button {
                    showingEventList = true
                } label: {
                    HStack {
                        Image(systemName: "list.bullet.rectangle")
                            .font(isBigger ? .title3 : .body)
                        Text("Show My Day")
                            .font(isBigger ? .title3 : .body)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, isBigger ? 8 : 0)
                }
                .buttonStyle(.bordered)

                Button {
                    showingSettings = true
                } label: {
                    HStack {
                        Image(systemName: "gearshape")
                            .font(isBigger ? .title3 : .body)
                        Text("Settings")
                            .font(isBigger ? .title3 : .body)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, isBigger ? 8 : 0)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, buttonPadding)
            .padding(.bottom, isBigger ? 40 : 30)
        }
        .navigationTitle("Calendar Notifier")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Auto-sync when app launches
            Task {
                await syncManager.syncCalendar()
            }
        }
    }

    // MARK: - Next Event Section

    private var nextEventSection: some View {
        VStack(spacing: sectionSpacing) {
            if let event = syncManager.nextEvent {
                Text("NEXT EVENT")
                    .font(isBigger ? .body : .caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .tracking(1.5)

                VStack(spacing: isBigger ? 12 : 8) {
                    // Day of week
                    Text(event.startDate.formatted(.dateTime.weekday(.wide)))
                        .font(isBigger ? .title.weight(.light) : .title2.weight(.light))
                        .minimumScaleFactor(0.7)

                    // Date
                    Text(event.startDate.formatted(.dateTime.month(.wide).day()))
                        .font(isBigger ? .largeTitle.weight(.bold) : .title.weight(.bold))
                        .minimumScaleFactor(0.7)

                    // Time
                    Text(event.startDate.formatted(.dateTime.hour().minute()))
                        .font(isBigger ? .system(size: 48, weight: .bold) : .largeTitle.weight(.bold))
                        .foregroundColor(.blue)
                        .minimumScaleFactor(0.7)
                        .accessibilityLabel("Event time: \(event.startDate.formatted(.dateTime.hour().minute()))")
                }

                // Event details
                VStack(spacing: isBigger ? 8 : 4) {
                    Text(event.title)
                        .font(isBigger ? .title2 : .title3)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)

                    if let location = event.location, !location.isEmpty {
                        HStack(spacing: isBigger ? 6 : 4) {
                            Image(systemName: "mappin")
                                .font(isBigger ? .body : .caption)
                            Text(location)
                                .font(isBigger ? .body : .subheadline)
                        }
                        .foregroundColor(.secondary)
                    }
                }
                .padding(.top, isBigger ? 12 : 8)

            } else {
                VStack(spacing: isBigger ? 16 : 12) {
                    Image(systemName: "calendar")
                        .font(isBigger ? .system(size: 48) : .largeTitle)
                        .foregroundColor(.secondary)
                        .accessibilityHidden(true)

                    Text("No Upcoming Events")
                        .font(isBigger ? .title : .title2)
                        .fontWeight(.medium)

                    Text("Tap Sync Now to refresh your calendar")
                        .font(isBigger ? .body : .subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, isBigger ? 50 : 40)
                .accessibilityElement(children: .combine)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Unauthenticated View

    private var unauthenticatedView: some View {
        VStack(spacing: isBigger ? 20 : 15) {
            Image(systemName: "calendar.badge.clock")
                .font(isBigger ? .system(size: 48) : .largeTitle)
                .imageScale(.large)
                .foregroundColor(.blue)
                .accessibilityHidden(true)

            Text("Calendar Notifier")
                .font(isBigger ? .largeTitle : .title)
                .bold()

            Text("Get notifications 1 hour and 15 minutes before your events")
                .font(isBigger ? .body : .subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            Button {
                showingAuth = true
            } label: {
                Text("Connect Google Calendar")
                    .font(isBigger ? .title3 : .body)
                    .padding(.vertical, isBigger ? 8 : 0)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top)
            .accessibilityHint("Opens Google sign-in")
        }
        .padding()
        .navigationTitle("Calendar Notifier")
        .navigationBarTitleDisplayMode(.inline)
    }
}
