import SwiftUI

struct GoogleAuthView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var soundSettings = SoundSettingsManager.shared
    @State private var isAuthenticating = false
    @State private var errorMessage: String?

    private var isBigger: Bool { soundSettings.biggerMode }

    var body: some View {
        NavigationView {
            VStack(spacing: isBigger ? 28 : 20) {
                Image(systemName: "person.badge.key.fill")
                    .font(isBigger ? .system(size: 48) : .largeTitle)
                    .imageScale(.large)
                    .foregroundColor(.blue)
                    .accessibilityHidden(true)

                Text("Sign in with Google")
                    .font(isBigger ? .title : .title2)
                    .bold()

                Text("Grant access to your Google Calendar to receive notifications")
                    .font(isBigger ? .body : .subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                if let error = errorMessage {
                    Text(error)
                        .font(isBigger ? .body : .caption)
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
                                .scaleEffect(isBigger ? 1.2 : 1.0)
                        } else {
                            Image(systemName: "g.circle.fill")
                                .font(isBigger ? .title3 : .body)
                                .accessibilityHidden(true)
                            Text("Sign in with Google")
                                .font(isBigger ? .title3 : .body)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, isBigger ? 8 : 0)
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
                    .font(isBigger ? .body : .body)
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
