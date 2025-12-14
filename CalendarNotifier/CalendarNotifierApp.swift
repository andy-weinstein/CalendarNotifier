import SwiftUI
import UserNotifications
import EventKit

@main
struct CalendarNotifierApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .active:
                print("\n🟢 APP BECAME ACTIVE")
                print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

                // Check/update calendar authorization status
                EventKitManager.shared.updateAuthorizationStatus()

                // Sync calendar when app becomes active for fresh data
                if EventKitManager.shared.isAuthorized {
                    Task {
                        await CalendarSyncManager.shared.syncCalendar()
                    }
                }

                // Log current state
                NotificationManager.shared.logPendingNotifications()
                BackgroundTaskManager.shared.logScheduledTasks()

                print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")

            case .background:
                print("\n⚫ APP ENTERED BACKGROUND")
                print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

                // Schedule next background refresh when app goes to background
                BackgroundTaskManager.shared.scheduleAppRefresh()

                print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")

            case .inactive:
                // Transitional state, no action needed
                break

            @unknown default:
                break
            }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        print("\n🚀 APP LAUNCHED")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📅 Current date: \(Date())")
        print("🌍 Timezone: \(TimeZone.current.identifier)")
        print("🌍 Timezone offset: \(TimeZone.current.secondsFromGMT() / 3600) hours")
        print("📱 Device locale: \(Locale.current.identifier)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")

        // Set notification delegate to show notifications in foreground
        UNUserNotificationCenter.current().delegate = self

        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ Notification permission granted")
            } else {
                print("❌ Notification permission denied: \(error?.localizedDescription ?? "Unknown error")")
            }
        }

        // Register modern background tasks (BGTaskScheduler)
        BackgroundTaskManager.shared.registerBackgroundTasks()

        // Schedule initial background refresh
        BackgroundTaskManager.shared.scheduleAppRefresh()

        // Observe calendar changes - this works when app is running or suspended
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(calendarDidChange),
            name: .EKEventStoreChanged,
            object: EventKitManager.shared.eventStore
        )

        return true
    }

    // MARK: - Calendar Change Observer

    @objc func calendarDidChange(_ notification: Notification) {
        print("\n📅 CALENDAR CHANGED (EKEventStoreChanged)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        // Sync calendar when local calendar changes
        // This works when app is running or suspended in background
        if EventKitManager.shared.isAuthorized {
            Task {
                await CalendarSyncManager.shared.syncCalendar()
            }
        }

        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
    }

    // MARK: - UNUserNotificationCenterDelegate

    // Show notifications even when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }

    // Handle notification tap
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}
