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

    @Published var biggerMode: Bool {
        didSet {
            UserDefaults.standard.set(biggerMode, forKey: "biggerMode")
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
    // Format: (filename without extension, display name)
    static let availableSounds: [(id: String, name: String)] = [
        ("default", "Default"),
        ("alert_high", "Alert (High)"),
        ("alert_low", "Alert (Low)"),
        ("chime", "Chime"),
        ("glass", "Glass"),
        ("horn", "Horn"),
        ("bell", "Bell"),
        ("electronic", "Electronic"),
        ("marimba_times_four", "Marimba Times Four"),
        ("arpeggio", "Arpeggio")
    ]

    private init() {
        oneHourSound = UserDefaults.standard.string(forKey: "oneHourSound") ?? "default"
        fifteenMinSound = UserDefaults.standard.string(forKey: "fifteenMinSound") ?? "bell"

        let savedFirst = UserDefaults.standard.integer(forKey: "firstReminderMinutes")
        firstReminderMinutes = savedFirst > 0 ? savedFirst : 60

        let savedSecond = UserDefaults.standard.integer(forKey: "secondReminderMinutes")
        secondReminderMinutes = savedSecond > 0 ? savedSecond : 15

        // Bigger mode defaults to true for visually impaired users
        if UserDefaults.standard.object(forKey: "biggerMode") == nil {
            biggerMode = true
        } else {
            biggerMode = UserDefaults.standard.bool(forKey: "biggerMode")
        }
    }
}

// MARK: - Sound Settings View

struct SoundSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var settings = SoundSettingsManager.shared
    @State private var audioPlayer: AVAudioPlayer?

    private var isBigger: Bool { settings.biggerMode }

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
                                playBundledSound(sound.id)
                            }
                        )
                    }
                } header: {
                    Text("First Reminder Sound")
                        .font(isBigger ? .subheadline : .footnote)
                } footer: {
                    Text("Sound for your first reminder")
                        .font(isBigger ? .subheadline : .footnote)
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
                                playBundledSound(sound.id)
                            }
                        )
                    }
                } header: {
                    Text("Second Reminder Sound")
                        .font(isBigger ? .subheadline : .footnote)
                } footer: {
                    Text("Sound for your second reminder")
                        .font(isBigger ? .subheadline : .footnote)
                }
            }
            .navigationTitle("Configure Sounds")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(isBigger ? .body : .body)
                }
            }
        }
    }

    private func playBundledSound(_ soundId: String) {
        // Stop any currently playing sound
        audioPlayer?.stop()

        if soundId == "default" {
            // Play default system notification sound
            AudioServicesPlaySystemSound(1007)
            return
        }

        // Play the bundled .caf file
        guard let url = Bundle.main.url(forResource: soundId, withExtension: "caf") else {
            print("Could not find bundled sound: \(soundId).caf")
            // Fallback to system sound
            AudioServicesPlaySystemSound(1007)
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            print("Error playing sound: \(error)")
            AudioServicesPlaySystemSound(1007)
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
    @StateObject private var soundSettings = SoundSettingsManager.shared

    private var isBigger: Bool { soundSettings.biggerMode }

    var body: some View {
        HStack {
            Button {
                onSelect()
            } label: {
                HStack {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .blue : .gray)
                        .font(isBigger ? .title3 : .body)

                    Text(soundName)
                        .font(isBigger ? .body : .body)
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
                    .font(isBigger ? .title3 : .body)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, isBigger ? 4 : 0)
    }
}
