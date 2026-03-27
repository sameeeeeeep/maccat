import AVFoundation

class SoundManager {
    static let shared = SoundManager()

    var isMuted: Bool {
        get { UserDefaults.standard.bool(forKey: "soundMuted") }
        set { UserDefaults.standard.set(newValue, forKey: "soundMuted") }
    }

    private var players: [String: AVAudioPlayer] = [:]

    /// Fallback mappings: if a theme sound file doesn't exist, use these cat sounds
    private let fallbackSounds: [String: String] = [
        // Dog fallbacks
        "bark1": "meow1",
        "bark2": "meow2",
        "bark3": "meow3",
        "pant": "purr",
        "growl": "hiss",
        "yip": "chirp",
        // Bird fallbacks
        "tweet1": "chirp",
        "tweet2": "chirp",
        "tweet3": "chirp",
        "coo": "purr",
    ]

    private init() {
        // Load default cat sounds
        let catSounds = ["meow1", "meow2", "meow3", "purr", "hiss", "chirp"]
        for name in catSounds {
            loadSound(name)
        }

        // Load current theme sounds
        let savedTheme = UserDefaults.standard.string(forKey: "animalTheme") ?? "cat"
        if let theme = AnimalTheme(rawValue: savedTheme) {
            loadThemeSounds(theme)
        }
    }

    func loadThemeSounds(_ theme: AnimalTheme) {
        for name in theme.allSounds {
            if players[name] == nil {
                loadSound(name)
            }
        }
    }

    private func loadSound(_ name: String) {
        // Try loading the actual sound file
        if let path = Bundle.main.path(forResource: name, ofType: "wav", inDirectory: "Sounds") {
            let url = URL(fileURLWithPath: path)
            if let player = try? AVAudioPlayer(contentsOf: url) {
                player.prepareToPlay()
                players[name] = player
                return
            }
        }

        // Try fallback
        if let fallbackName = fallbackSounds[name],
           let fallbackPlayer = players[fallbackName] {
            // Create a new player from the same URL
            if let path = Bundle.main.path(forResource: fallbackName, ofType: "wav", inDirectory: "Sounds"),
               let player = try? AVAudioPlayer(contentsOf: URL(fileURLWithPath: path)) {
                player.prepareToPlay()
                players[name] = player
            }
        }
    }

    func play(_ name: String, volume: Float = 0.5) {
        guard !isMuted, let player = players[name] else { return }
        player.volume = volume
        player.currentTime = 0
        player.play()
    }

    func randomVoice(theme: AnimalTheme, volume: Float = 0.5) {
        let voices = theme.voiceSounds
        play(voices.randomElement()!, volume: volume)
    }

    // Legacy support
    func randomMeow(volume: Float = 0.5) {
        randomVoice(theme: .cat, volume: volume)
    }

    func stopAll() {
        for (_, player) in players {
            player.stop()
        }
    }
}
