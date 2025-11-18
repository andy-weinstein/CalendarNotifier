import SwiftUI

struct GoogleAuthView: View {
    @Environment(\.dismiss) var dismiss
    @State private var isAuthenticating = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "person.badge.key.fill")
                    .font(.largeTitle)
                    .imageScale(.large)
                    .foregroundColor(.blue)
                    .accessibilityHidden(true)

                Text("Sign in with Google")
                    .font(.title2)
                    .bold()

                Text("Grant access to your Google Calendar to receive notifications")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding()
                        .accessibilityLabel("Error: \(error)")
                }

                Button {
                    authenticateWithGoogle()
                } label: {
                    HStack {
                        if isAuthenticating {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "g.circle.fill")
                                .accessibilityHidden(true)
                            Text("Sign in with Google")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isAuthenticating)
                .padding(.horizontal)
                .accessibilityHint("Authenticates with your Google account")
            }
            .navigationTitle("Authentication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func authenticateWithGoogle() {
        isAuthenticating = true
        errorMessage = nil
        
        GoogleCalendarManager.shared.signIn { success in
            isAuthenticating = false
            if success {
                // Perform initial sync
                Task {
                    await CalendarSyncManager.shared.syncCalendar()
                }
                dismiss()
            } else {
                errorMessage = "Authentication failed. Please try again."
            }
        }
    }
}
