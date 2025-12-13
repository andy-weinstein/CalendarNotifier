import SwiftUI

struct ContentView: View {
    @StateObject private var calendarManager = GoogleCalendarManager.shared
    @StateObject private var syncManager = CalendarSyncManager.shared
    @StateObject private var soundSettings = SoundSettingsManager.shared
    @State private var showingAuth = false
    @State private var showingSettings = false
    @State private var showingEventList = false
    @State private var currentTime = Date()

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
            // Next Event Section - now with more space
            nextEventSection
                .padding(.top, isBigger ? 40 : 30)

            Spacer()

            // Sync Status (subtle, at bottom)
            VStack(spacing: 4) {
                if syncManager.isSyncing {
                    HStack(spacing: isBigger ? 12 : 8) {
                        ProgressView()
                            .scaleEffect(isBigger ? 1.2 : 1.0)
                        Text("Syncing...")
                            .font(isBigger ? .body : .caption)
                            .foregroundColor(.secondary)
                    }
                } else if let lastSync = calendarManager.lastSyncDate {
                    Text("Last synced \(lastSync.formatted(.relative(presentation: .named)))")
                        .font(isBigger ? .caption : .caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.bottom, isBigger ? 16 : 12)
            .onAppear {
                // Refresh time every minute to update relative time
                Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
                    currentTime = Date()
                }
            }

            // Action Buttons - Side by side
            HStack(spacing: isBigger ? 20 : 16) {
                // Settings button - gear icon only
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(isBigger ? .system(size: 32) : .system(size: 28))
                        .foregroundColor(.blue)
                        .frame(width: isBigger ? 70 : 60, height: isBigger ? 70 : 60)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Circle())
                }
                .accessibilityLabel("Settings")

                // Show My Day button
                Button {
                    showingEventList = true
                } label: {
                    HStack(spacing: isBigger ? 12 : 10) {
                        Image(systemName: "list.bullet.rectangle")
                            .font(isBigger ? .title2 : .title3)
                        Text("Show My Day")
                            .font(isBigger ? .title2 : .title3)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, isBigger ? 18 : 16)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, isBigger ? 30 : 24)
            .padding(.bottom, isBigger ? 50 : 40)
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
                    .font(isBigger ? .title3 : .body)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .tracking(2.0)

                VStack(spacing: isBigger ? 16 : 12) {
                    // Day of week - larger
                    Text(event.startDate.formatted(.dateTime.weekday(.wide)))
                        .font(isBigger ? .system(size: 36, weight: .light) : .system(size: 28, weight: .light))
                        .minimumScaleFactor(0.7)

                    // Date - much larger
                    Text(event.startDate.formatted(.dateTime.month(.wide).day()))
                        .font(isBigger ? .system(size: 44, weight: .bold) : .system(size: 36, weight: .bold))
                        .minimumScaleFactor(0.7)

                    // Time - extra large and high contrast
                    Text(event.startDate.formatted(.dateTime.hour().minute()))
                        .font(isBigger ? .system(size: 64, weight: .bold) : .system(size: 52, weight: .bold))
                        .foregroundColor(.primary)
                        .minimumScaleFactor(0.7)
                        .accessibilityLabel("Event time: \(event.startDate.formatted(.dateTime.hour().minute()))")
                }

                // Event details - larger and clearer
                VStack(spacing: isBigger ? 12 : 8) {
                    Text(event.title)
                        .font(isBigger ? .system(size: 28, weight: .semibold) : .system(size: 24, weight: .semibold))
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.85)

                    if let location = event.location, !location.isEmpty {
                        HStack(spacing: isBigger ? 8 : 6) {
                            Image(systemName: "mappin.circle.fill")
                                .font(isBigger ? .title2 : .title3)
                            Text(location)
                                .font(isBigger ? .title3 : .body)
                        }
                        .foregroundColor(.secondary)
                    }
                }
                .padding(.top, isBigger ? 20 : 16)

            } else {
                VStack(spacing: isBigger ? 20 : 16) {
                    Image(systemName: "calendar")
                        .font(isBigger ? .system(size: 60) : .system(size: 50))
                        .foregroundColor(.secondary)
                        .accessibilityHidden(true)

                    Text("No Upcoming Events")
                        .font(isBigger ? .system(size: 32, weight: .bold) : .system(size: 28, weight: .bold))

                    Text("Open Settings to sync your calendar")
                        .font(isBigger ? .title3 : .body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, isBigger ? 60 : 50)
                .accessibilityElement(children: .combine)
            }
        }
        .padding(.horizontal, isBigger ? 24 : 20)
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
