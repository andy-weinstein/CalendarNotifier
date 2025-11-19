import SwiftUI
import AVFoundation
import Combine

// MARK: - Sound Settings Manager

class SoundSettingsManager: ObservableObject {
    static let shared = SoundSettingsManager()

    @Published var oneHourSound: String {
        didSet {
            UserDefaults.standard.set(oneHourSound, forKey: "oneHourSound")
        }
    }

    @Published var fifteenMinSound: String {
        didSet {
            UserDefaults.standard.set(fifteenMinSound, forKey: "fifteenMinSound")
        }
    }

    @Published var firstReminderMinutes: Int {
        didSet {
            UserDefaults.standard.set(firstReminderMinutes, forKey: "firstReminderMinutes")
        }
    }

    @Published var secondReminderMinutes: Int {
        didSet {
            UserDefaults.standard.set(secondReminderMinutes, forKey: "secondReminderMinutes")
        }
    }

    // Available reminder times
    static let availableReminderTimes: [(minutes: Int, label: String)] = [
        (5, "5 minutes"),
        (10, "10 minutes"),
        (15, "15 minutes"),
        (30, "30 minutes"),
        (60, "1 hour"),
        (120, "2 hours"),
        (1440, "1 day")
    ]

    // Available bundled sounds (must be added to Xcode project)
    // Format: (filename without extension, display name, system sound ID for preview)
    static let availableSounds: [(id: String, name: String, previewId: SystemSoundID)] = [
        ("default", "Default", 1007),
        ("alert_high", "Alert (High)", 1005),
        ("alert_low", "Alert (Low)", 1006),
        ("chime", "Chime", 1008),
        ("glass", "Glass", 1009),
        ("horn", "Horn", 1010),
        ("bell", "Bell", 1011),
        ("electronic", "Electronic", 1012)
    ]

    private init() {
        oneHourSound = UserDefaults.standard.string(forKey: "oneHourSound") ?? "default"
        fifteenMinSound = UserDefaults.standard.string(forKey: "fifteenMinSound") ?? "bell"

        let savedFirst = UserDefaults.standard.integer(forKey: "firstReminderMinutes")
        firstReminderMinutes = savedFirst > 0 ? savedFirst : 60

        let savedSecond = UserDefaults.standard.integer(forKey: "secondReminderMinutes")
        secondReminderMinutes = savedSecond > 0 ? savedSecond : 15
    }
}

// MARK: - Sound Settings View

struct SoundSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var settings = SoundSettingsManager.shared

    var body: some View {
        NavigationView {
            List {
                // First Reminder Section
                Section {
                    ForEach(SoundSettingsManager.availableSounds, id: \.id) { sound in
                        SoundRow(
                            soundId: sound.id,
                            soundName: sound.name,
                            isSelected: settings.oneHourSound == sound.id,
                            onSelect: {
                                settings.oneHourSound = sound.id
                            },
                            onPreview: {
                                AudioServicesPlaySystemSound(sound.previewId)
                            }
                        )
                    }
                } header: {
                    Text("First Reminder Sound")
                } footer: {
                    Text("Sound for your first reminder")
                }

                // Second Reminder Section
                Section {
                    ForEach(SoundSettingsManager.availableSounds, id: \.id) { sound in
                        SoundRow(
                            soundId: sound.id,
                            soundName: sound.name,
                            isSelected: settings.fifteenMinSound == sound.id,
                            onSelect: {
                                settings.fifteenMinSound = sound.id
                            },
                            onPreview: {
                                AudioServicesPlaySystemSound(sound.previewId)
                            }
                        )
                    }
                } header: {
                    Text("Second Reminder Sound")
                } footer: {
                    Text("Sound for your second reminder")
                }
            }
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

// MARK: - Sound Row

struct SoundRow: View {
    let soundId: String
    let soundName: String
    let isSelected: Bool
    let onSelect: () -> Void
    let onPreview: () -> Void

    var body: some View {
        HStack {
            Button {
                onSelect()
            } label: {
                HStack {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .blue : .gray)

                    Text(soundName)
                        .foregroundColor(.primary)

                    Spacer()
                }
            }
            .buttonStyle(.plain)

            Button {
                onPreview()
            } label: {
                Image(systemName: "speaker.wave.2")
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
        }
    }
}
