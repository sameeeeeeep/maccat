import Foundation
import Combine

enum CatMood: String {
    case happy = "Happy"
    case content = "Content"
    case hungry = "Hungry"
    case tired = "Tired"
    case sad = "Sad"
    case sleeping = "Sleeping"
    case eating = "Eating"
    case playing = "Playing"

    var emoji: String {
        switch self {
        case .happy: return "😸"
        case .content: return "🐱"
        case .hungry: return "😿"
        case .tired: return "😪"
        case .sad: return "😾"
        case .sleeping: return "😴"
        case .eating: return "😋"
        case .playing: return "😺"
        }
    }

    var menuBarIcon: String {
        switch self {
        case .happy, .content, .playing: return "🐱"
        case .hungry: return "🙀"
        case .tired, .sleeping: return "😴"
        case .sad: return "😿"
        case .eating: return "😋"
        }
    }
}

class CatState: ObservableObject {
    @Published var name: String {
        didSet { UserDefaults.standard.set(name, forKey: "catName") }
    }
    @Published var hunger: Double {
        didSet { UserDefaults.standard.set(hunger, forKey: "catHunger") }
    }
    @Published var happiness: Double {
        didSet { UserDefaults.standard.set(happiness, forKey: "catHappiness") }
    }
    @Published var energy: Double {
        didSet { UserDefaults.standard.set(energy, forKey: "catEnergy") }
    }
    @Published var mood: CatMood = .content
    @Published var isAnimating: Bool = false
    @Published var actionText: String? = nil
    @Published var activeAction: String? = nil // "feed", "play", "pet", "nap" - observed by walking cat
    @Published var catColor: String {
        didSet { UserDefaults.standard.set(catColor, forKey: "catColor") }
    }

    private var decayTimer: Timer?
    private var actionTimer: Timer?
    var onMoodChanged: ((CatMood) -> Void)?

    init() {
        self.name = UserDefaults.standard.string(forKey: "catName") ?? "Mac"
        self.hunger = UserDefaults.standard.object(forKey: "catHunger") as? Double ?? 80.0
        self.happiness = UserDefaults.standard.object(forKey: "catHappiness") as? Double ?? 80.0
        self.energy = UserDefaults.standard.object(forKey: "catEnergy") as? Double ?? 80.0
        self.catColor = UserDefaults.standard.string(forKey: "catColor") ?? "original"
        updateMood()
        startDecayTimer()
    }

    func startDecayTimer() {
        decayTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.decay()
        }
    }

    private func decay() {
        hunger = max(0, hunger - 2)
        happiness = max(0, happiness - 1.5)
        energy = max(0, energy - 1)
        updateMood()

        // Random idle meow when hungry or wanting attention
        if needsAttention && Int.random(in: 0...2) == 0 {
            SoundManager.shared.randomMeow(volume: 0.25)
        }
    }

    func wake() {
        actionTimer?.invalidate()
        actionText = nil
        isAnimating = false
        activeAction = nil
        mood = .content
        updateMood()
        onMoodChanged?(mood)
        SoundManager.shared.randomMeow(volume: 0.3)
    }

    func feed() {
        if mood == .sleeping { wake() }
        hunger = min(100, hunger + 25)
        happiness = min(100, happiness + 5)
        activeAction = "feed"
        SoundManager.shared.randomMeow(volume: 0.4)
        showAction("Yummy! 🐟", temporaryMood: .eating)
    }

    func play() {
        if mood == .sleeping { wake() }
        guard energy > 10 else { return }
        happiness = min(100, happiness + 20)
        energy = max(0, energy - 10)
        hunger = max(0, hunger - 5)
        activeAction = "play"
        SoundManager.shared.play("chirp", volume: 0.4)
        showAction("Wheee! 🧶", temporaryMood: .playing)
    }

    func pet() {
        if mood == .sleeping { wake() }
        happiness = min(100, happiness + 15)
        energy = min(100, energy + 5)
        activeAction = "pet"
        SoundManager.shared.play("purr", volume: 0.3)
        showAction("Purrrr... 💕", temporaryMood: .happy)
    }

    func nap() {
        activeAction = "nap"
        SoundManager.shared.play("purr", volume: 0.2)
        showAction("Zzz... 💤", temporaryMood: .sleeping, duration: 5)
        energy = min(100, energy + 30)
    }

    private func showAction(_ text: String, temporaryMood: CatMood, duration: TimeInterval = 2) {
        actionTimer?.invalidate()
        actionText = text
        mood = temporaryMood
        isAnimating = true
        onMoodChanged?(mood)

        actionTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            self?.actionText = nil
            self?.isAnimating = false
            self?.activeAction = nil
            self?.updateMood()
        }
    }

    func updateMood() {
        let avg = (hunger + happiness + energy) / 3.0

        let newMood: CatMood
        if energy < 20 {
            newMood = .tired
        } else if hunger < 20 {
            newMood = .hungry
        } else if avg < 30 {
            newMood = .sad
        } else if avg > 70 {
            newMood = .happy
        } else {
            newMood = .content
        }

        if mood != .eating && mood != .playing && mood != .sleeping {
            mood = newMood
            onMoodChanged?(mood)
        }
    }

    var needsAttention: Bool {
        hunger < 30 || happiness < 30 || energy < 20
    }
}
