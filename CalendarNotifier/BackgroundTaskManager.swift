import Foundation
import BackgroundTasks
import UIKit

class BackgroundTaskManager {
    static let shared = BackgroundTaskManager()

    // Task identifier must match Info.plist BGTaskSchedulerPermittedIdentifiers
    private let appRefreshTaskIdentifier = "com.calendarnotifier.refresh"

    private init() {}

    // MARK: - Registration

    func registerBackgroundTasks() {
        print("\n📋 REGISTERING BACKGROUND TASKS")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        // Register app refresh task
        let registered = BGTaskScheduler.shared.register(
            forTaskWithIdentifier: appRefreshTaskIdentifier,
            using: nil // Use main queue
        ) { task in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }

        if registered {
            print("✅ Successfully registered background refresh task")
            print("   Identifier: \(appRefreshTaskIdentifier)")
        } else {
            print("❌ Failed to register background refresh task")
            print("   Make sure identifier is in Info.plist BGTaskSchedulerPermittedIdentifiers")
        }

        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
    }

    // MARK: - Task Scheduling

    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: appRefreshTaskIdentifier)

        // Request to run as soon as possible, but system decides based on:
        // - Battery level
        // - Network connectivity
        // - User usage patterns
        // - Thermal state
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes minimum

        do {
            try BGTaskScheduler.shared.submit(request)
            print("✅ Background refresh scheduled")
            print("   Next refresh: ~15-30 minutes (system-determined)")
        } catch {
            print("❌ Failed to schedule background refresh: \(error.localizedDescription)")

            // Log specific error types
            if let bgError = error as? BGTaskScheduler.Error {
                switch bgError.code {
                case .unavailable:
                    print("   Reason: Background tasks unavailable")
                case .tooManyPendingTaskRequests:
                    print("   Reason: Too many pending requests")
                case .notPermitted:
                    print("   Reason: Not permitted - check Info.plist")
                default:
                    print("   Reason: Unknown error code")
                }
            }
        }
    }

    // MARK: - Task Handling

    private func handleAppRefresh(task: BGAppRefreshTask) {
        print("\n🔄 BACKGROUND REFRESH TRIGGERED")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("⏰ Time: \(Date())")
        print("📱 App State: Background")

        // Schedule the next refresh immediately
        scheduleAppRefresh()

        // Check if we have calendar access
        EventKitManager.shared.updateAuthorizationStatus()
        guard EventKitManager.shared.isAuthorized else {
            print("⚠️  No calendar access - skipping sync")
            task.setTaskCompleted(success: false)
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
            return
        }

        // Create a task to perform the sync
        let syncTask = Task {
            // Perform calendar sync - with EventKit this is instant (no network needed)
            await CalendarSyncManager.shared.syncCalendar()

            print("✅ Background sync completed successfully")
            task.setTaskCompleted(success: true)
        }

        // Handle expiration - BGAppRefreshTask gives ~30 seconds
        // With EventKit, we should never hit this since reads are instant
        task.expirationHandler = {
            print("⚠️  Background task expired - cancelling sync")
            syncTask.cancel()
            task.setTaskCompleted(success: false)
        }

        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
    }

    // MARK: - Debug Helpers

    func logScheduledTasks() {
        BGTaskScheduler.shared.getPendingTaskRequests { requests in
            print("\n📊 PENDING BACKGROUND TASKS")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

            if requests.isEmpty {
                print("No pending tasks")
            } else {
                for request in requests {
                    print("Task: \(request.identifier)")
                    if let earliestDate = request.earliestBeginDate {
                        print("  Earliest: \(earliestDate)")
                        let interval = earliestDate.timeIntervalSinceNow
                        if interval > 0 {
                            print("  In: \(Int(interval / 60)) minutes")
                        } else {
                            print("  Ready to run")
                        }
                    }
                }
            }

            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
        }
    }
}
