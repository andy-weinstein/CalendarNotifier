import SwiftUI
import EventKit

struct CalendarPermissionView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var soundSettings = SoundSettingsManager.shared
    @StateObject private var eventKitManager = EventKitManager.shared
    @State private var isRequesting = false
    @State private var showDeniedAlert = false

    private var isBigger: Bool { soundSettings.biggerMode }

    var body: some View {
        NavigationView {
            VStack(spacing: isBigger ? 28 : 20) {
                Image(systemName: "calendar.badge.checkmark")
                    .font(isBigger ? .system(size: 48) : .largeTitle)
                    .imageScale(.large)
                    .foregroundColor(.blue)
                    .accessibilityHidden(true)

                Text("Calendar Access")
                    .font(isBigger ? .title : .title2)
                    .bold()

                Text("Grant access to your calendar to receive notifications for upcoming events")
                    .font(isBigger ? .body : .subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 12) {
                    featureRow(icon: "bell.fill", text: "Get reminders before events")
                    featureRow(icon: "rectangle.stack.fill", text: "See next event in widget")
                    featureRow(icon: "arrow.triangle.2.circlepath", text: "Auto-sync with your calendars")
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)

                if eventKitManager.authorizationStatus == .denied {
                    Text("Calendar access was denied. Please enable it in Settings.")
                        .font(isBigger ? .body : .caption)
                        .foregroundColor(.orange)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Button {
                    requestAccess()
                } label: {
                    HStack {
                        if isRequesting {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(isBigger ? 1.2 : 1.0)
                        } else {
                            Image(systemName: "calendar")
                                .font(isBigger ? .title3 : .body)
                                .accessibilityHidden(true)
                            Text(eventKitManager.authorizationStatus == .denied ? "Open Settings" : "Allow Calendar Access")
                                .font(isBigger ? .title3 : .body)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, isBigger ? 8 : 0)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isRequesting)
                .padding(.horizontal)
                .accessibilityHint("Requests access to your calendar")

                Spacer()
            }
            .padding(.top, 20)
            .navigationTitle("Setup")
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
        .alert("Calendar Access Denied", isPresented: $showDeniedAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please enable calendar access in Settings to use this app.")
        }
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            Text(text)
                .font(isBigger ? .body : .subheadline)
        }
    }

    private func requestAccess() {
        if eventKitManager.authorizationStatus == .denied {
            // Open settings if previously denied
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
            return
        }

        isRequesting = true

        Task {
            let granted = await eventKitManager.requestAccess()

            await MainActor.run {
                isRequesting = false

                if granted {
                    // Perform initial sync
                    Task {
                        await CalendarSyncManager.shared.syncCalendar()
                    }
                    dismiss()
                } else {
                    showDeniedAlert = true
                }
            }
        }
    }
}
