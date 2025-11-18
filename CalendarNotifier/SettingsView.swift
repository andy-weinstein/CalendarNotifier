import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var calendarManager = GoogleCalendarManager.shared
    @State private var showingSoundSettings = false

    var body: some View {
        NavigationView {
            List {
                // Notifications Section
                Section("Notifications") {
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
