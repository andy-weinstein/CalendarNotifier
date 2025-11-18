import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var calendarManager = GoogleCalendarManager.shared
    @StateObject private var soundSettings = SoundSettingsManager.shared
    @State private var showingSoundSettings = false

    var body: some View {
        NavigationView {
            List {
                // Reminder Times Section
                Section {
                    Picker("First Reminder", selection: $soundSettings.firstReminderMinutes) {
                        ForEach(SoundSettingsManager.availableReminderTimes, id: \.minutes) { time in
                            Text(time.label).tag(time.minutes)
                        }
                    }

                    Picker("Second Reminder", selection: $soundSettings.secondReminderMinutes) {
                        ForEach(SoundSettingsManager.availableReminderTimes, id: \.minutes) { time in
                            Text(time.label).tag(time.minutes)
                        }
                    }
                } header: {
                    Text("Reminder Times")
                } footer: {
                    Text("Choose when to be notified before each event")
                }

                // Sounds Section
                Section("Sounds") {
                    Button {
                        showingSoundSettings = true
                    } label: {
                        HStack {
                            Image(systemName: "speaker.wave.2")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            Text("Configure Sounds")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Test Notifications Section
                Section {
                    Button {
                        NotificationManager.shared.sendTestNotification(for: "first")
                    } label: {
                        HStack {
                            Image(systemName: "bell.badge")
                                .foregroundColor(.orange)
                                .frame(width: 24)
                            Text("Test First Reminder")
                                .foregroundColor(.primary)
                        }
                    }

                    Button {
                        NotificationManager.shared.sendTestNotification(for: "second")
                    } label: {
                        HStack {
                            Image(systemName: "bell.badge")
                                .foregroundColor(.red)
                                .frame(width: 24)
                            Text("Test Second Reminder")
                                .foregroundColor(.primary)
                        }
                    }
                } header: {
                    Text("Test Notifications")
                } footer: {
                    Text("Send a test notification to verify sounds work correctly with your device")
                }

                // Account Section
                Section("Account") {
                    HStack {
                        Image(systemName: "person.circle")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        Text("Connected to Google Calendar")
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }

                    if let lastSync = calendarManager.lastSyncDate {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            Text("Last synced")
                            Spacer()
                            Text(lastSync.formatted(.relative(presentation: .named)))
                                .foregroundColor(.secondary)
                        }
                    }

                    Button(role: .destructive) {
                        calendarManager.signOut()
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .frame(width: 24)
                            Text("Sign Out")
                        }
                    }
                }

                // About Section
                Section("About") {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
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
