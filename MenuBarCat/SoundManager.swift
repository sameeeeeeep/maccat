import AVFoundation

class SoundManager {
    static let shared = SoundManager()

    private var players: [String: AVAudioPlayer] = [:]

    private init() {
        // Preload all sounds
        let soundNames = ["meow1", "meow2", "meow3", "purr", "hiss", "chirp"]
        for name in soundNames {
            if let path = Bundle.main.path(forResource: name, ofType: "wav", inDirectory: "Sounds") {
                let url = URL(fileURLWithPath: path)
                if let player = try? AVAudioPlayer(contentsOf: url) {
                    player.prepareToPlay()
                    players[name] = player
                }
            }
        }
    }

    func play(_ name: String, volume: Float = 0.5) {
        guard let player = players[name] else { return }
        player.volume = volume
        player.currentTime = 0
        player.play()
    }

    func randomMeow(volume: Float = 0.5) {
        let meows = ["meow1", "meow2", "meow3"]
        play(meows.randomElement()!, volume: volume)
    }

    func stopAll() {
        for (_, player) in players {
            player.stop()
        }
    }
}
