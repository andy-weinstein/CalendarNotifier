import SwiftUI

struct EventListView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var syncManager = CalendarSyncManager.shared

    var body: some View {
        NavigationView {
            Text("Event list coming soon")
                .foregroundColor(.secondary)
                .navigationTitle("My Day")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }
}
