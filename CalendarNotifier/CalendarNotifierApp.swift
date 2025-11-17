import SwiftUI

@main
struct CalendarNotifierApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            }
        }
        
        // Register for background fetch
        UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
        
        return true
    }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Sync calendar in background
        Task {
            await CalendarSyncManager.shared.syncCalendar()
            completionHandler(.newData)
        }
    }
}
