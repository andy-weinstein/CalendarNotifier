import Foundation
import UIKit
import Combine
import GoogleSignIn
import GoogleAPIClientForRESTCore
import GoogleAPIClientForREST_Calendar

class GoogleCalendarManager: ObservableObject {
    static let shared = GoogleCalendarManager()

    @Published var isAuthenticated = false
    @Published var isRestoring = true  // Show loading while checking auth
    @Published var lastSyncDate: Date?

    private let calendarService = GTLRCalendarService()
    private let clientID = "688632885106-p0mle40kksuii21vgtt184cd65g1q6au.apps.googleusercontent.com"

    private init() {
        // One-time fix: Clear potentially corrupted auth from old app version
        if !UserDefaults.standard.bool(forKey: "didClearCorruptedAuth_v1") {
            print("Clearing potentially corrupted auth state from previous version")
            GIDSignIn.sharedInstance.signOut()
            calendarService.authorizer = nil
            UserDefaults.standard.set(true, forKey: "didClearCorruptedAuth_v1")
            isAuthenticated = false
            isRestoring = false
        } else {
            // Always try to restore previous sign-in on init
            restoreAuthSession()
        }
    }

    func checkAuthStatus() {
        isAuthenticated = GIDSignIn.sharedInstance.currentUser != nil
    }

    func signIn(completion: @escaping (Bool) -> Void) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            completion(false)
            return
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        GIDSignIn.sharedInstance.signIn(
            withPresenting: rootViewController,
            hint: nil,
            additionalScopes: ["https://www.googleapis.com/auth/calendar.readonly"]
        ) { [weak self] result, error in
            guard error == nil, let user = result?.user else {
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }

            // Set authorizer on main thread to avoid threading issues
            DispatchQueue.main.async {
                self?.calendarService.authorizer = user.fetcherAuthorizer
                self?.isAuthenticated = true
                // Small delay to ensure authorizer is fully initialized
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    completion(true)
                }
            }
        }
    }

    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        isAuthenticated = false
        calendarService.authorizer = nil
    }

    private func restoreAuthSession() {
        GIDSignIn.sharedInstance.restorePreviousSignIn { [weak self] user, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Failed to restore auth session: \(error)")
                    // Sign out to clear potentially corrupted auth state
                    GIDSignIn.sharedInstance.signOut()
                    self?.isAuthenticated = false
                    self?.calendarService.authorizer = nil
                } else if let user = user {
                    self?.calendarService.authorizer = user.fetcherAuthorizer
                    self?.isAuthenticated = true
                } else {
                    self?.isAuthenticated = false
                }
                self?.isRestoring = false  // Done restoring
            }
        }
    }
    
    func fetchEvents(completion: @escaping ([CalendarEvent]) -> Void) {
        // Ensure we have an authorizer before fetching
        guard calendarService.authorizer != nil else {
            print("No authorizer set, cannot fetch events")
            completion([])
            return
        }

        let query = GTLRCalendarQuery_EventsList.query(withCalendarId: "primary")
        query.timeMin = GTLRDateTime(date: Date())
        query.timeMax = GTLRDateTime(date: Calendar.current.date(byAdding: .day, value: 30, to: Date())!)
        query.singleEvents = true
        query.orderBy = kGTLRCalendarOrderByStartTime

        calendarService.executeQuery(query) { [weak self] (ticket, response, error) in
            if let error = error {
                print("Error fetching events: \(error)")
                // If auth error, clear the session
                if (error as NSError).domain == "com.google.GTLRErrorObjectDomain" {
                    DispatchQueue.main.async {
                        self?.signOut()
                    }
                }
                completion([])
                return
            }

            guard let events = (response as? GTLRCalendar_Events)?.items else {
                completion([])
                return
            }
            
            let calendarEvents = events.compactMap { event -> CalendarEvent? in
                guard let start = event.start?.dateTime?.date ?? event.start?.date?.date,
                      let title = event.summary else {
                    return nil
                }
                
                return CalendarEvent(
                    id: event.identifier ?? UUID().uuidString,
                    title: title,
                    startDate: start,
                    location: event.location,
                    eventDescription: event.descriptionProperty
                )
            }
            
            DispatchQueue.main.async {
                self?.lastSyncDate = Date()
            }
            
            completion(calendarEvents)
        }
    }
}

struct CalendarEvent: Identifiable, Codable {
    let id: String
    let title: String
    let startDate: Date
    let location: String?
    let eventDescription: String?
}
