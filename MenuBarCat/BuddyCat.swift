import Cocoa
import SwiftUI
import Combine

/// Maps frontmost app to a buddy cat color
struct BuddyCatConfig {
    let color: Color
    let name: String

    /// Browser bundle IDs
    static let browserBundleIDs: Set<String> = [
        "com.google.Chrome",
        "com.apple.Safari",
        "com.brave.Browser",
        "org.mozilla.firefox",
        "com.microsoft.edgemac",
        "company.thebrowser.Browser", // Arc
        "com.operasoftware.Opera",
        "com.vivaldi.Vivaldi",
    ]

    /// Website-specific buddy cats (matched against URL or tab title)
    static let websiteBuddies: [(keywords: [String], color: Color, name: String)] = [
        (["instagram.com", "Instagram"], Color(red: 0.9, green: 0.3, blue: 0.5), "Insta Cat"),
        (["youtube.com", "YouTube"], Color(red: 1.0, green: 0.2, blue: 0.2), "YouTube Cat"),
        (["twitter.com", "x.com", "Twitter", "/ X"], Color(red: 0.2, green: 0.2, blue: 0.2), "X Cat"),
        (["reddit.com", "Reddit"], Color(red: 1.0, green: 0.4, blue: 0.2), "Reddit Cat"),
        (["tiktok.com", "TikTok"], Color(red: 0.0, green: 0.0, blue: 0.0), "TikTok Cat"),
        (["facebook.com", "Facebook"], Color(red: 0.2, green: 0.4, blue: 0.9), "FB Cat"),
        (["netflix.com", "Netflix"], Color(red: 0.9, green: 0.1, blue: 0.1), "Netflix Cat"),
        (["twitch.tv", "Twitch"], Color(red: 0.6, green: 0.2, blue: 0.9), "Twitch Cat"),
        (["github.com", "GitHub"], Color(red: 0.5, green: 0.5, blue: 0.55), "GitHub Cat"),
        (["chatgpt.com", "ChatGPT"], Color(red: 0.3, green: 0.8, blue: 0.6), "GPT Cat"),
        (["claude.ai", "Claude"], Color(red: 1.0, green: 0.6, blue: 0.2), "Claude Cat"),
        (["google.com", "Google"], Color(red: 0.3, green: 0.6, blue: 1.0), "Google Cat"),
        (["open.spotify.com", "Spotify"], Color(red: 0.3, green: 0.85, blue: 0.4), "Spotify Cat"),
        (["linkedin.com", "LinkedIn"], Color(red: 0.0, green: 0.4, blue: 0.8), "LinkedIn Cat"),
        (["figma.com", "Figma"], Color(red: 0.6, green: 0.3, blue: 1.0), "Figma Cat"),
        (["notion.so", "Notion"], Color(red: 0.9, green: 0.9, blue: 0.9), "Notion Cat"),
        (["discord.com", "Discord"], Color(red: 0.4, green: 0.4, blue: 0.9), "Discord Cat"),
        (["threads.net", "Threads"], Color(red: 0.1, green: 0.1, blue: 0.1), "Threads Cat"),
        (["amazon.com", "Amazon"], Color(red: 1.0, green: 0.7, blue: 0.2), "Amazon Cat"),
        (["stackoverflow.com", "Stack Overflow"], Color(red: 1.0, green: 0.5, blue: 0.0), "SO Cat"),
    ]

    /// App-specific buddy cats
    static let appBuddies: [String: (Color, String)] = [
        "com.anthropic.claudefordesktop": (Color(red: 1.0, green: 0.6, blue: 0.2), "Claude Cat"),
        "com.microsoft.VSCode": (Color(red: 0.3, green: 0.5, blue: 1.0), "VS Cat"),
        "com.apple.dt.Xcode": (Color(red: 0.3, green: 0.6, blue: 1.0), "Xcode Cat"),
        "com.tinyspeck.slackmacgap": (Color(red: 0.6, green: 0.3, blue: 0.7), "Slack Cat"),
        "com.spotify.client": (Color(red: 0.3, green: 0.85, blue: 0.4), "Spotify Cat"),
        "com.apple.Terminal": (Color(red: 0.3, green: 0.3, blue: 0.35), "Terminal Cat"),
        "com.apple.finder": (Color(red: 0.7, green: 0.7, blue: 0.75), "Finder Cat"),
        "com.apple.mail": (Color(red: 0.3, green: 0.6, blue: 1.0), "Mail Cat"),
        "com.apple.MobileSMS": (Color(red: 0.3, green: 0.85, blue: 0.4), "Messages Cat"),
        "com.figma.Desktop": (Color(red: 0.6, green: 0.3, blue: 1.0), "Figma Cat"),
        "md.obsidian": (Color(red: 0.6, green: 0.4, blue: 0.8), "Obsidian Cat"),
        "com.hnc.Discord": (Color(red: 0.4, green: 0.4, blue: 0.9), "Discord Cat"),
        "notion.id": (Color(red: 0.9, green: 0.9, blue: 0.9), "Notion Cat"),
        "com.linear": (Color(red: 0.4, green: 0.4, blue: 0.9), "Linear Cat"),
    ]

    static func forApp(_ bundleID: String, windowTitle: String?, tabURL: String? = nil) -> BuddyCatConfig? {
        // Check browser - match against URL and title
        if browserBundleIDs.contains(bundleID) {
            let searchStrings = [tabURL, windowTitle].compactMap { $0 }
            for site in websiteBuddies {
                for keyword in site.keywords {
                    for s in searchStrings {
                        if s.localizedCaseInsensitiveContains(keyword) {
                            return BuddyCatConfig(color: site.color, name: site.name)
                        }
                    }
                }
            }
            // Generic browser buddy
            return BuddyCatConfig(color: Color(red: 0.6, green: 0.6, blue: 0.65), name: "Browser Cat")
        }

        if let (color, name) = appBuddies[bundleID] {
            return BuddyCatConfig(color: color, name: name)
        }

        // Fallback: show a buddy for any app
        return BuddyCatConfig(color: Color(red: 0.7, green: 0.7, blue: 0.75), name: "Buddy")
    }
}

/// Distracting sites for focus mode - matched against actual tab URLs
struct FocusMode {
    static let distractingDomains = [
        "instagram.com",
        "youtube.com",
        "twitter.com",
        "x.com",
        "reddit.com",
        "tiktok.com",
        "facebook.com",
        "netflix.com",
        "twitch.tv",
        "linkedin.com/feed",
        "threads.net",
        "snapchat.com",
    ]

    static func isDistractingURL(_ url: String?) -> Bool {
        guard let url = url?.lowercased() else { return false }
        return distractingDomains.contains { url.contains($0) }
    }
}

/// Watches frontmost app and publishes buddy cat info + focus mode
class BuddyCatManager: ObservableObject {
    @Published var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: "buddyCatEnabled") }
    }
    @Published var focusModeEnabled: Bool {
        didSet { UserDefaults.standard.set(focusModeEnabled, forKey: "focusModeEnabled") }
    }
    @Published var currentBuddy: BuddyCatConfig?
    @Published var currentAppName: String = ""
    @Published var isDistracted: Bool = false

    private var timer: Timer?

    init() {
        self.isEnabled = UserDefaults.standard.object(forKey: "buddyCatEnabled") as? Bool ?? true
        self.focusModeEnabled = UserDefaults.standard.object(forKey: "focusModeEnabled") as? Bool ?? false
        startWatching()
    }

    func startWatching() {
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkFrontmostApp()
        }
        checkFrontmostApp()
    }

    /// Get the active browser tab URL via AppleScript
    private func getBrowserTabURL(bundleID: String) -> String? {
        let script: String
        switch bundleID {
        case "com.google.Chrome", "com.brave.Browser", "com.microsoft.edgemac", "com.vivaldi.Vivaldi", "com.operasoftware.Opera":
            script = "tell application id \"\(bundleID)\" to get URL of active tab of front window"
        case "company.thebrowser.Browser": // Arc
            script = "tell application id \"\(bundleID)\" to get URL of active tab of front window"
        case "com.apple.Safari":
            script = "tell application \"Safari\" to get URL of front document"
        default:
            return nil
        }

        guard let appleScript = NSAppleScript(source: script) else { return nil }
        var error: NSDictionary?
        let result = appleScript.executeAndReturnError(&error)
        if error != nil { return nil }
        return result.stringValue
    }

    /// Get the active browser tab title via AppleScript
    private func getBrowserTabTitle(bundleID: String) -> String? {
        let script: String
        switch bundleID {
        case "com.google.Chrome", "com.brave.Browser", "com.microsoft.edgemac", "com.vivaldi.Vivaldi", "com.operasoftware.Opera":
            script = "tell application id \"\(bundleID)\" to get title of active tab of front window"
        case "company.thebrowser.Browser":
            script = "tell application id \"\(bundleID)\" to get title of active tab of front window"
        case "com.apple.Safari":
            script = "tell application \"Safari\" to get name of front document"
        default:
            return nil
        }

        guard let appleScript = NSAppleScript(source: script) else { return nil }
        var error: NSDictionary?
        let result = appleScript.executeAndReturnError(&error)
        if error != nil { return nil }
        return result.stringValue
    }

    private func checkFrontmostApp() {
        guard let app = NSWorkspace.shared.frontmostApplication,
              let bundleID = app.bundleIdentifier else { return }

        // Skip our own app but always clear distraction
        if bundleID == Bundle.main.bundleIdentifier {
            isDistracted = false
            return
        }

        let appName = app.localizedName ?? ""
        let isBrowser = BuddyCatConfig.browserBundleIDs.contains(bundleID)

        var tabURL: String?
        var tabTitle: String?

        // Only call AppleScript for browsers
        if isBrowser && focusModeEnabled {
            tabURL = getBrowserTabURL(bundleID: bundleID)
            tabTitle = getBrowserTabTitle(bundleID: bundleID)
        } else if isBrowser && isEnabled {
            tabTitle = getBrowserTabTitle(bundleID: bundleID)
            tabURL = getBrowserTabURL(bundleID: bundleID)
        }

        // Focus mode: check URL, clear when not on distracting site or not in browser
        if focusModeEnabled {
            if isBrowser {
                isDistracted = FocusMode.isDistractingURL(tabURL)
            } else {
                isDistracted = false
            }
        } else {
            isDistracted = false
        }

        // Buddy cat
        guard isEnabled else {
            if currentBuddy != nil {
                currentBuddy = nil
                currentAppName = ""
            }
            return
        }

        let identifier = tabTitle ?? appName
        if identifier != currentAppName {
            currentAppName = identifier
            currentBuddy = BuddyCatConfig.forApp(bundleID, windowTitle: tabTitle, tabURL: tabURL)
        }
    }

    /// Trigger the macOS automation permission dialog for Chrome/Safari
    func requestBrowserAccess() {
        // This will prompt "MenuBarCat wants to control Google Chrome"
        let script = NSAppleScript(source: "tell application \"Google Chrome\" to get title of front window")
        var error: NSDictionary?
        script?.executeAndReturnError(&error)
        // Also try Safari
        let safariScript = NSAppleScript(source: "tell application \"Safari\" to get name of front document")
        safariScript?.executeAndReturnError(&error)
    }

    deinit {
        timer?.invalidate()
    }
}
