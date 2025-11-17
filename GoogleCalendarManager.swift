import Foundation
import GoogleSignIn
import GoogleAPIClientForREST

class GoogleCalendarManager: ObservableObject {
    static let shared = GoogleCalendarManager()
    
    @Published var isAuthenticated = false
    @Published var lastSyncDate: Date?
    
    private let calendarService = GTLRCalendarService()
    private let clientID = "YOUR_CLIENT_ID.apps.googleusercontent.com" // Replace with your client ID
    
    private init() {
        checkAuthStatus()
    }
    
    func checkAuthStatus() {
        isAuthenticated = GIDSignIn.sharedInstance.currentUser != nil
        if isAuthenticated {
            restoreAuthSession()
        }
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
                completion(false)
                return
            }
            
            self?.calendarService.authorizer = user.fetcherAuthorizer
            DispatchQueue.main.async {
                self?.isAuthenticated = true
            }
            completion(true)
        }
    }
    
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        isAuthenticated = false
    }
    
    private func restoreAuthSession() {
        GIDSignIn.sharedInstance.restorePreviousSignIn { [weak self] user, error in
            guard error == nil, let user = user else { return }
            self?.calendarService.authorizer = user.fetcherAuthorizer
        }
    }
    
    func fetchEvents(completion: @escaping ([CalendarEvent]) -> Void) {
        let query = GTLRCalendarQuery_EventsList.query(withCalendarId: "primary")
        query.timeMin = GTLRDateTime(date: Date())
        query.timeMax = GTLRDateTime(date: Calendar.current.date(byAdding: .day, value: 30, to: Date())!)
        query.singleEvents = true
        query.orderBy = kGTLRCalendarOrderByStartTime
        
        calendarService.executeQuery(query) { [weak self] (ticket, response, error) in
            guard error == nil,
                  let events = (response as? GTLRCalendar_Events)?.items else {
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
                    location: event.location
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
}
