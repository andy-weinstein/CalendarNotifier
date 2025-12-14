import SwiftUI
import BackgroundTasks
import Combine

struct DebugStatusView: View {
    @StateObject private var syncManager = CalendarSyncManager.shared
    @StateObject private var eventKitManager = EventKitManager.shared
    @State private var pendingTasks: [String] = []
    @State private var refreshTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationView {
            List {
                // Sync Status
                Section {
                    HStack {
                        Text("Syncing")
                        Spacer()
                        if syncManager.isSyncing {
                            ProgressView()
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }

                    HStack {
                        Text("Last Sync")
                        Spacer()
                        if let lastSync = syncManager.lastSyncDate {
                            Text(lastSync.formatted(.relative(presentation: .named)))
                                .foregroundColor(.secondary)
                        } else {
                            Text("Never")
                                .foregroundColor(.secondary)
                        }
                    }

                    HStack {
                        Text("Calendar Access")
                        Spacer()
                        Text(eventKitManager.isAuthorized ? "Granted" : "Denied")
                            .foregroundColor(eventKitManager.isAuthorized ? .green : .red)
                    }

                    HStack {
                        Text("Events Loaded")
                        Spacer()
                        Text("\(syncManager.events.count)")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Next Event")
                        Spacer()
                        if let next = syncManager.nextEvent {
                            Text(next.startDate.formatted(.relative(presentation: .named)))
                                .foregroundColor(.secondary)
                        } else {
                            Text("None")
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Calendar Sync Status")
                }

                // Background Tasks
                Section {
                    ForEach(pendingTasks, id: \.self) { task in
                        Text(task)
                            .font(.caption)
                    }

                    if pendingTasks.isEmpty {
                        Text("No pending tasks")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }

                    Button("Refresh Task List") {
                        loadPendingTasks()
                    }

                    Button("Schedule New Task") {
                        BackgroundTaskManager.shared.scheduleAppRefresh()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            loadPendingTasks()
                        }
                    }
                } header: {
                    Text("Background Tasks")
                } footer: {
                    Text("Background tasks are scheduled by iOS and may not run immediately. Use Xcode console commands to simulate them during testing.")
                }

                // Testing Instructions
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("To test background refresh in Xcode:")
                            .font(.caption)
                            .fontWeight(.semibold)

                        Text("1. Run app on device (not simulator)")
                            .font(.caption)

                        Text("2. Open Terminal and run:")
                            .font(.caption)

                        Text("e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@\"com.calendarnotifier.refresh\"]")
                            .font(.system(size: 10, design: .monospaced))
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(4)

                        Text("3. Check console for background sync logs")
                            .font(.caption)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Testing Instructions")
                }

                // Widget Status
                Section {
                    HStack {
                        Text("Widget Data")
                        Spacer()
                        if let sharedDefaults = UserDefaults(suiteName: "group.com.calendarnotifier.shared"),
                           let data = sharedDefaults.data(forKey: "syncedEvents") {
                            Text("\(data.count) bytes")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        } else {
                            Text("None")
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Widget Status")
                } footer: {
                    Text("Widget should update automatically when calendar syncs. If not, remove and re-add the widget.")
                }
            }
            .navigationTitle("Debug Status")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadPendingTasks()
            }
            .onReceive(refreshTimer) { _ in
                // Auto-refresh every second
            }
        }
    }

    private func loadPendingTasks() {
        BGTaskScheduler.shared.getPendingTaskRequests { requests in
            DispatchQueue.main.async {
                if requests.isEmpty {
                    pendingTasks = ["No tasks scheduled"]
                } else {
                    pendingTasks = requests.map { request in
                        var info = "ID: \(request.identifier)"
                        if let earliest = request.earliestBeginDate {
                            let interval = earliest.timeIntervalSinceNow
                            if interval > 0 {
                                info += "\nReady in: \(Int(interval / 60)) min"
                            } else {
                                info += "\nReady: Now"
                            }
                        }
                        return info
                    }
                }
            }
        }
    }
}
