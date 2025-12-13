import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var calendarManager = GoogleCalendarManager.shared
    @StateObject private var syncManager = CalendarSyncManager.shared
    @StateObject private var soundSettings = SoundSettingsManager.shared
    @State private var showingSoundSettings = false

    private var isBigger: Bool { soundSettings.biggerMode }

    var body: some View {
        NavigationView {
            List {
                // Sync Section
                Section {
                    Button {
                        Task {
                            await syncManager.syncCalendar()
                        }
                    } label: {
                        HStack {
                            if syncManager.isSyncing {
                                ProgressView()
                                    .frame(width: isBigger ? 28 : 24)
                            } else {
                                Image(systemName: "arrow.clockwise")
                                    .foregroundColor(.blue)
                                    .frame(width: isBigger ? 28 : 24)
                                    .font(isBigger ? .title3 : .body)
                            }
                            Text("Sync Now")
                                .font(isBigger ? .body : .body)
                                .foregroundColor(.primary)
                            Spacer()
                            if let count = syncManager.lastSyncCount {
                                Text("\(count) event\(count == 1 ? "" : "s")")
                                    .font(isBigger ? .body : .callout)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .disabled(syncManager.isSyncing)
                } header: {
                    Text("Calendar Sync")
                        .font(isBigger ? .subheadline : .footnote)
                } footer: {
                    Text("Manually sync your Google Calendar events")
                        .font(isBigger ? .subheadline : .footnote)
                }

                // Accessibility Section
                Section {
                    Toggle(isOn: $soundSettings.biggerMode) {
                        HStack {
                            Image(systemName: "textformat.size.larger")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            Text("Bigger Mode")
                                .font(isBigger ? .body : .body)
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                } header: {
                    Text("Accessibility")
                        .font(isBigger ? .subheadline : .footnote)
                } footer: {
                    Text("Makes all text and controls larger for better visibility")
                        .font(isBigger ? .subheadline : .footnote)
                }

                // Reminder Times Section
                Section {
                    Picker("First Reminder", selection: $soundSettings.firstReminderMinutes) {
                        ForEach(SoundSettingsManager.availableReminderTimes, id: \.minutes) { time in
                            Text(time.label)
                                .font(isBigger ? .body : .body)
                                .tag(time.minutes)
                        }
                    }
                    .font(isBigger ? .body : .body)

                    Picker("Second Reminder", selection: $soundSettings.secondReminderMinutes) {
                        ForEach(SoundSettingsManager.availableReminderTimes, id: \.minutes) { time in
                            Text(time.label)
                                .font(isBigger ? .body : .body)
                                .tag(time.minutes)
                        }
                    }
                    .font(isBigger ? .body : .body)
                } header: {
                    Text("Reminder Times")
                        .font(isBigger ? .subheadline : .footnote)
                } footer: {
                    Text("Choose when to be notified before each event")
                        .font(isBigger ? .subheadline : .footnote)
                }

                // Sounds Section
                Section {
                    Button {
                        showingSoundSettings = true
                    } label: {
                        HStack {
                            Image(systemName: "speaker.wave.2")
                                .foregroundColor(.blue)
                                .frame(width: isBigger ? 28 : 24)
                                .font(isBigger ? .title3 : .body)
                            Text("Configure Sounds")
                                .font(isBigger ? .body : .body)
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(isBigger ? .body : .caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Sounds")
                        .font(isBigger ? .subheadline : .footnote)
                }

                // Test Notifications Section
                Section {
                    Button {
                        NotificationManager.shared.sendTestNotification(for: "first")
                    } label: {
                        HStack {
                            Image(systemName: "bell.badge")
                                .foregroundColor(.orange)
                                .frame(width: isBigger ? 28 : 24)
                                .font(isBigger ? .title3 : .body)
                            Text("Test First Reminder")
                                .font(isBigger ? .body : .body)
                                .foregroundColor(.primary)
                        }
                    }

                    Button {
                        NotificationManager.shared.sendTestNotification(for: "second")
                    } label: {
                        HStack {
                            Image(systemName: "bell.badge")
                                .foregroundColor(.red)
                                .frame(width: isBigger ? 28 : 24)
                                .font(isBigger ? .title3 : .body)
                            Text("Test Second Reminder")
                                .font(isBigger ? .body : .body)
                                .foregroundColor(.primary)
                        }
                    }
                } header: {
                    Text("Test Notifications")
                        .font(isBigger ? .subheadline : .footnote)
                } footer: {
                    Text("Send a test notification to verify sounds work correctly with your device")
                        .font(isBigger ? .subheadline : .footnote)
                }

                // Account Section
                Section {
                    HStack {
                        Image(systemName: "person.circle")
                            .foregroundColor(.blue)
                            .frame(width: isBigger ? 28 : 24)
                            .font(isBigger ? .title3 : .body)
                        Text("Connected to Google Calendar")
                            .font(isBigger ? .body : .body)
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(isBigger ? .title3 : .body)
                    }

                    if let lastSync = calendarManager.lastSyncDate {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.blue)
                                .frame(width: isBigger ? 28 : 24)
                                .font(isBigger ? .title3 : .body)
                            Text("Last synced")
                                .font(isBigger ? .body : .body)
                            Spacer()
                            Text(lastSync.formatted(.relative(presentation: .named)))
                                .font(isBigger ? .body : .body)
                                .foregroundColor(.secondary)
                        }
                    }

                    Button(role: .destructive) {
                        calendarManager.signOut()
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .frame(width: isBigger ? 28 : 24)
                                .font(isBigger ? .title3 : .body)
                            Text("Sign Out")
                                .font(isBigger ? .body : .body)
                        }
                    }
                } header: {
                    Text("Account")
                        .font(isBigger ? .subheadline : .footnote)
                }

                // About Section
                Section {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                            .frame(width: isBigger ? 28 : 24)
                            .font(isBigger ? .title3 : .body)
                        Text("Version")
                            .font(isBigger ? .body : .body)
                        Spacer()
                        Text("1.0.0")
                            .font(isBigger ? .body : .body)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("About")
                        .font(isBigger ? .subheadline : .footnote)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingSoundSettings) {
                SoundSettingsView()
            }
        }
    }
}
