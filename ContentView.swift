import SwiftUI

struct ContentView: View {
    @StateObject private var calendarManager = GoogleCalendarManager.shared
    @State private var showingAuth = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if calendarManager.isAuthenticated {
                    VStack(spacing: 15) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("Connected to Google Calendar")
                            .font(.headline)
                        
                        Text("Last synced: \(calendarManager.lastSyncDate?.formatted() ?? "Never")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button("Sync Now") {
                            Task {
                                await CalendarSyncManager.shared.syncCalendar()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("Sign Out") {
                            calendarManager.signOut()
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(.red)
                    }
                } else {
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
                }
            }
            .padding()
            .navigationTitle("Calendar Notifier")
            .sheet(isPresented: $showingAuth) {
                GoogleAuthView()
            }
        }
    }
}
