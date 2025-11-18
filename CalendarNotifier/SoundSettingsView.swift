import SwiftUI

struct SoundSettingsView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "speaker.wave.2")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                Text("Sound Configuration")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Coming soon - configure notification sounds for 1-hour and 15-minute reminders")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding()
            .navigationTitle("Configure Sounds")
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
