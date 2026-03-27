import SwiftUI

enum AnimalTheme: String, CaseIterable {
    case cat
    case dog
    case bird

    var displayName: String {
        switch self {
        case .cat: return "Cat"
        case .dog: return "Dog"
        case .bird: return "Bird"
        }
    }

    var defaultName: String {
        switch self {
        case .cat: return "Mac"
        case .dog: return "Buddy"
        case .bird: return "Tweety"
        }
    }

    var menuBarIcon: String {
        switch self {
        case .cat: return "cat.fill"
        case .dog: return "dog.fill"
        case .bird: return "bird.fill"
        }
    }

    var statusBarSymbol: String {
        switch self {
        case .cat: return "pawprint.fill"
        case .dog: return "pawprint.fill"
        case .bird: return "bird.fill"
        }
    }

    /// Whether sprites already have color and should NOT be tinted
    var hasColoredSprites: Bool {
        switch self {
        case .cat: return false
        case .dog, .bird: return true
        }
    }

    /// Sprite size for rendering
    var spriteSize: CGFloat {
        switch self {
        case .cat: return 72
        case .dog: return 40
        case .bird: return 40
        }
    }

    var buddySpriteSize: CGFloat {
        switch self {
        case .cat: return 56
        case .dog: return 32
        case .bird: return 32
        }
    }

    // MARK: - Mood Emojis

    func moodEmoji(for mood: CatMood) -> String {
        switch self {
        case .cat:
            switch mood {
            case .happy: return "😸"
            case .content: return "🐱"
            case .hungry: return "😿"
            case .tired: return "😪"
            case .sad: return "😾"
            case .sleeping: return "😴"
            case .eating: return "😋"
            case .playing: return "😺"
            }
        case .dog:
            switch mood {
            case .happy: return "🐶"
            case .content: return "🐕"
            case .hungry: return "🥺"
            case .tired: return "😴"
            case .sad: return "🐕‍🦺"
            case .sleeping: return "💤"
            case .eating: return "🦴"
            case .playing: return "🎾"
            }
        case .bird:
            switch mood {
            case .happy: return "🐦"
            case .content: return "🐤"
            case .hungry: return "🐦‍⬛"
            case .tired: return "😴"
            case .sad: return "🪶"
            case .sleeping: return "💤"
            case .eating: return "🌾"
            case .playing: return "🪺"
            }
        }
    }

    func menuBarMoodIcon(for mood: CatMood) -> String {
        switch self {
        case .cat:
            switch mood {
            case .happy, .content, .playing: return "🐱"
            case .hungry: return "🙀"
            case .tired, .sleeping: return "😴"
            case .sad: return "😿"
            case .eating: return "😋"
            }
        case .dog:
            switch mood {
            case .happy, .content, .playing: return "🐶"
            case .hungry: return "🥺"
            case .tired, .sleeping: return "💤"
            case .sad: return "🐕‍🦺"
            case .eating: return "🦴"
            }
        case .bird:
            switch mood {
            case .happy, .content, .playing: return "🐦"
            case .hungry: return "🐦‍⬛"
            case .tired, .sleeping: return "💤"
            case .sad: return "🪶"
            case .eating: return "🌾"
            }
        }
    }

    // MARK: - Action Text

    var feedText: String {
        switch self {
        case .cat: return "Yummy! 🐟"
        case .dog: return "Yummy! 🦴"
        case .bird: return "Yummy! 🌾"
        }
    }

    var playText: String {
        switch self {
        case .cat: return "Wheee! 🧶"
        case .dog: return "Fetch! 🎾"
        case .bird: return "Flap flap! 🪺"
        }
    }

    var petText: String {
        switch self {
        case .cat: return "Purrrr... 💕"
        case .dog: return "Woof woof! 💕"
        case .bird: return "Chirp chirp! 💕"
        }
    }

    var napText: String {
        switch self {
        case .cat: return "Zzz... 💤"
        case .dog: return "Zzz... 💤"
        case .bird: return "Nesting... 💤"
        }
    }

    // MARK: - Sounds

    var voiceSounds: [String] {
        switch self {
        case .cat: return ["meow1", "meow2", "meow3"]
        case .dog: return ["bark1", "bark2", "bark3"]
        case .bird: return ["tweet1", "tweet2", "tweet3"]
        }
    }

    var contentSound: String {
        switch self {
        case .cat: return "purr"
        case .dog: return "pant"
        case .bird: return "coo"
        }
    }

    var playSound: String {
        switch self {
        case .cat: return "chirp"
        case .dog: return "yip"
        case .bird: return "chirp"
        }
    }

    var fightSound: String {
        switch self {
        case .cat: return "hiss"
        case .dog: return "growl"
        case .bird: return "hiss"
        }
    }

    var allSounds: [String] {
        return voiceSounds + [contentSound, playSound, fightSound]
    }

    // MARK: - Default Tint

    var defaultTint: Color {
        switch self {
        case .cat: return .white
        case .dog: return .white
        case .bird: return .white
        }
    }

    // MARK: - Sprite Directory

    var spriteDirectory: String {
        switch self {
        case .cat: return "Sprites"
        case .dog: return "Sprites/dog"
        case .bird: return "Sprites/bird"
        }
    }

    static let fallbackSpriteDirectory = "Sprites"

    // MARK: - Buddy naming

    func buddyName(for baseName: String) -> String {
        return baseName.replacingOccurrences(of: "Cat", with: displayName)
    }

    // MARK: - Avatar Colors

    var avatarBodyColor: Color {
        switch self {
        case .cat: return .orange
        case .dog: return Color(red: 0.75, green: 0.55, blue: 0.3)
        case .bird: return Color(red: 0.3, green: 0.35, blue: 0.6)
        }
    }

    var avatarAccentColor: Color {
        switch self {
        case .cat: return .pink
        case .dog: return Color(red: 0.5, green: 0.35, blue: 0.2)
        case .bird: return Color(red: 0.7, green: 0.2, blue: 0.2)
        }
    }

    // MARK: - Focus Mode Text

    var focusModeText: String {
        switch self {
        case .cat: return "get back to work"
        case .dog: return "bad human! get back to work"
        case .bird: return "tweet tweet! get back to work"
        }
    }

    // MARK: - Needs Bar Icons

    var hungerIcon: String {
        switch self {
        case .cat: return "🐟"
        case .dog: return "🦴"
        case .bird: return "🌾"
        }
    }
}
