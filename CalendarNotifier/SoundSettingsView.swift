import SwiftUI
import AVFoundation

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

    // Available system sounds
    static let availableSounds: [(id: String, name: String)] = [
        ("default", "Default"),
        ("Tri-tone", "Tri-tone"),
        ("Chime", "Chime"),
        ("Glass", "Glass"),
        ("Horn", "Horn"),
        ("Bell", "Bell"),
        ("Electronic", "Electronic"),
        ("Anticipate", "Anticipate"),
        ("Bloom", "Bloom"),
        ("Calypso", "Calypso"),
        ("Choo_Choo", "Choo Choo"),
        ("Descent", "Descent"),
        ("Ding", "Ding"),
        ("Fanfare", "Fanfare"),
        ("Ladder", "Ladder"),
        ("Minuet", "Minuet"),
        ("News_Flash", "News Flash"),
        ("Noir", "Noir"),
        ("Sherwood_Forest", "Sherwood Forest"),
        ("Spell", "Spell"),
        ("Suspense", "Suspense"),
        ("Telegraph", "Telegraph"),
        ("Tiptoes", "Tiptoes"),
        ("Typewriters", "Typewriters"),
        ("Update", "Update")
    ]

    private init() {
        oneHourSound = UserDefaults.standard.string(forKey: "oneHourSound") ?? "default"
        fifteenMinSound = UserDefaults.standard.string(forKey: "fifteenMinSound") ?? "Tri-tone"
    }
}

// MARK: - Sound Settings View

struct SoundSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var settings = SoundSettingsManager.shared
    @State private var audioPlayer: AVAudioPlayer?

    var body: some View {
        NavigationView {
            List {
                // 1-Hour Reminder Section
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
                                playSound(sound.id)
                            }
                        )
                    }
                } header: {
                    Text("1-Hour Reminder")
                } footer: {
                    Text("Sound played 1 hour before events")
                }

                // 15-Minute Reminder Section
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
                                playSound(sound.id)
                            }
                        )
                    }
                } header: {
                    Text("15-Minute Reminder")
                } footer: {
                    Text("Sound played 15 minutes before events")
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

    private func playSound(_ soundId: String) {
        // Stop any currently playing sound
        audioPlayer?.stop()

        if soundId == "default" {
            // Play system default sound
            AudioServicesPlaySystemSound(1007) // Default notification sound
            return
        }

        // Try to play system sound by ID
        // System sounds are in /System/Library/Audio/UISounds/
        let soundName = soundId

        // Try common system sound locations
        let possiblePaths = [
            "/System/Library/Audio/UISounds/\(soundName).caf",
            "/System/Library/Audio/UISounds/New/\(soundName).caf",
            "/System/Library/Audio/UISounds/nano/\(soundName).caf"
        ]

        for path in possiblePaths {
            let url = URL(fileURLWithPath: path)
            if FileManager.default.fileExists(atPath: path) {
                do {
                    audioPlayer = try AVAudioPlayer(contentsOf: url)
                    audioPlayer?.play()
                    return
                } catch {
                    print("Error playing sound: \(error)")
                }
            }
        }

        // Fallback: use system sound ID
        // These are some common system sound IDs
        let systemSoundIds: [String: SystemSoundID] = [
            "Tri-tone": 1007,
            "Chime": 1008,
            "Glass": 1009,
            "Horn": 1010,
            "Bell": 1011,
            "Electronic": 1012,
            "Anticipate": 1020,
            "Bloom": 1021,
            "Calypso": 1022,
            "Choo_Choo": 1023,
            "Descent": 1024,
            "Ding": 1025,
            "Fanfare": 1026,
            "Ladder": 1027,
            "Minuet": 1028,
            "News_Flash": 1029,
            "Noir": 1030,
            "Sherwood_Forest": 1031,
            "Spell": 1032,
            "Suspense": 1033,
            "Telegraph": 1034,
            "Tiptoes": 1035,
            "Typewriters": 1036,
            "Update": 1037
        ]

        if let soundID = systemSoundIds[soundId] {
            AudioServicesPlaySystemSound(soundID)
        } else {
            // Default fallback
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
