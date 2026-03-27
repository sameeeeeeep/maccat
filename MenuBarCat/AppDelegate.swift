import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var catState: CatState!
    var buddyManager: BuddyCatManager!
    var catWindow: CatWindow!
    var iconTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        catState = CatState()
        buddyManager = BuddyCatManager()

        // Create the status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateStatusBarIcon()

        // Build the menu
        let menu = NSMenu()
        menu.autoenablesItems = false

        // Cat name + mood header
        let headerItem = NSMenuItem(title: "\(catState.name) - \(catState.mood.rawValue)", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        menu.addItem(headerItem)

        menu.addItem(NSMenuItem.separator())

        // Stats
        let hungerItem = NSMenuItem(title: "Hunger: \(Int(catState.hunger))%", action: nil, keyEquivalent: "")
        hungerItem.isEnabled = false
        hungerItem.tag = 100
        menu.addItem(hungerItem)

        let happyItem = NSMenuItem(title: "Happiness: \(Int(catState.happiness))%", action: nil, keyEquivalent: "")
        happyItem.isEnabled = false
        happyItem.tag = 101
        menu.addItem(happyItem)

        let energyItem = NSMenuItem(title: "Energy: \(Int(catState.energy))%", action: nil, keyEquivalent: "")
        energyItem.isEnabled = false
        energyItem.tag = 102
        menu.addItem(energyItem)

        menu.addItem(NSMenuItem.separator())

        // Actions
        let feedItem = NSMenuItem(title: "Feed", action: #selector(feedCat), keyEquivalent: "f")
        feedItem.target = self
        menu.addItem(feedItem)

        let playItem = NSMenuItem(title: "Play", action: #selector(playCat), keyEquivalent: "p")
        playItem.target = self
        menu.addItem(playItem)

        let petItem = NSMenuItem(title: "Pet", action: #selector(petCat), keyEquivalent: "e")
        petItem.target = self
        menu.addItem(petItem)

        let napItem = NSMenuItem(title: "Nap", action: #selector(napCat), keyEquivalent: "n")
        napItem.target = self
        menu.addItem(napItem)

        let wakeItem = NSMenuItem(title: "Wake Up", action: #selector(wakeCat), keyEquivalent: "w")
        wakeItem.target = self
        menu.addItem(wakeItem)

        let toyItem = NSMenuItem(title: "Drop Toy", action: #selector(dropToy), keyEquivalent: "t")
        toyItem.target = self
        menu.addItem(toyItem)

        // Focus timer submenu
        let timerItem = NSMenuItem(title: "Focus Timer", action: nil, keyEquivalent: "")
        let timerMenu = NSMenu()
        for mins in [5, 10, 15, 25, 30, 45, 60] {
            let label = mins < 60 ? "\(mins) min" : "1 hour"
            let item = NSMenuItem(title: label, action: #selector(startTimer(_:)), keyEquivalent: "")
            item.target = self
            item.tag = mins
            timerMenu.addItem(item)
        }
        timerMenu.addItem(NSMenuItem.separator())
        let cancelItem = NSMenuItem(title: "Cancel Timer", action: #selector(cancelTimer), keyEquivalent: "")
        cancelItem.target = self
        cancelItem.tag = 400
        timerMenu.addItem(cancelItem)
        timerItem.submenu = timerMenu
        timerItem.tag = 401
        menu.addItem(timerItem)

        menu.addItem(NSMenuItem.separator())

        // Rename
        let renameItem = NSMenuItem(title: "Rename...", action: #selector(renameCat), keyEquivalent: "r")
        renameItem.target = self
        menu.addItem(renameItem)

        // Theme submenu
        let themeItem = NSMenuItem(title: "Theme", action: nil, keyEquivalent: "")
        let themeMenu = NSMenu()
        for theme in AnimalTheme.allCases {
            let item = NSMenuItem(title: "\(themeMenuEmoji(theme)) \(theme.displayName)", action: #selector(changeTheme(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = theme.rawValue
            item.tag = 300 + AnimalTheme.allCases.firstIndex(of: theme)!
            themeMenu.addItem(item)
        }
        themeItem.submenu = themeMenu
        menu.addItem(themeItem)

        // Color submenu
        let colorItem = NSMenuItem(title: "Color", action: nil, keyEquivalent: "")
        let colorMenu = NSMenu()
        let colors = [
            ("Original", "original"),
            ("Orange", "orange"),
            ("Ginger", "ginger"),
            ("Golden", "golden"),
            ("Black", "black"),
            ("White", "white"),
            ("Blue", "blue"),
            ("Pink", "pink"),
        ]
        for (label, value) in colors {
            let item = NSMenuItem(title: label, action: #selector(changeColor(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = value
            colorMenu.addItem(item)
        }
        colorItem.submenu = colorMenu
        menu.addItem(colorItem)

        menu.addItem(NSMenuItem.separator())

        // Buddy cat toggle
        let buddyItem = NSMenuItem(title: "Buddy", action: #selector(toggleBuddy(_:)), keyEquivalent: "b")
        buddyItem.target = self
        buddyItem.tag = 200
        menu.addItem(buddyItem)

        // Focus mode toggle
        let focusItem = NSMenuItem(title: "Focus Mode", action: #selector(toggleFocus(_:)), keyEquivalent: "d")
        focusItem.target = self
        focusItem.tag = 202
        menu.addItem(focusItem)

        // Sound toggle
        let soundItem = NSMenuItem(title: "Mute Sound", action: #selector(toggleSound(_:)), keyEquivalent: "m")
        soundItem.target = self
        soundItem.tag = 201
        menu.addItem(soundItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)

        menu.delegate = self
        statusItem.menu = menu

        // Create the walking cat window
        catWindow = CatWindow(catState: catState, buddyManager: buddyManager)
        catWindow.orderFront(nil)
    }

    func updateStatusBarIcon() {
        if let button = statusItem.button {
            let symbolName = catState.animalTheme.statusBarSymbol
            let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .medium)
            if let img = NSImage(systemSymbolName: symbolName, accessibilityDescription: "macthecat")?.withSymbolConfiguration(config) {
                img.isTemplate = true
                button.image = img
            } else {
                button.title = "~"
                button.font = NSFont.systemFont(ofSize: 14)
            }
        }
    }

    func themeMenuEmoji(_ theme: AnimalTheme) -> String {
        switch theme {
        case .cat: return "🐱"
        case .dog: return "🐶"
        case .bird: return "🐦"
        }
    }

    // MARK: - Actions

    @objc func feedCat() { catState.feed() }
    @objc func playCat() { catState.play() }
    @objc func petCat() { catState.pet() }
    @objc func napCat() { catState.nap() }
    @objc func wakeCat() { catState.wake() }

    @objc func startTimer(_ sender: NSMenuItem) {
        catState.startFocusTimer(minutes: sender.tag)
    }

    @objc func cancelTimer() {
        catState.cancelFocusTimer()
    }

    @objc func dropToy() {
        let toys: [String]
        switch catState.animalTheme {
        case .cat: toys = ["🧶", "🐟", "🪶", "🐭"]
        case .dog: toys = ["🎾", "🦴", "🥏", "🧸"]
        case .bird: toys = ["🪱", "🌻", "🫐", "🪺"]
        }
        catState.pendingToy = toys.randomElement()!
    }

    @objc func changeColor(_ sender: NSMenuItem) {
        if let color = sender.representedObject as? String {
            catState.catColor = color
        }
    }

    @objc func changeTheme(_ sender: NSMenuItem) {
        if let themeRaw = sender.representedObject as? String,
           let theme = AnimalTheme(rawValue: themeRaw) {
            catState.animalTheme = theme
            updateStatusBarIcon()
        }
    }

    @objc func toggleBuddy(_ sender: NSMenuItem) {
        buddyManager.isEnabled.toggle()
    }

    @objc func toggleFocus(_ sender: NSMenuItem) {
        buddyManager.focusModeEnabled.toggle()
        // Trigger AppleScript permission prompt on first enable
        if buddyManager.focusModeEnabled {
            buddyManager.requestBrowserAccess()
        }
    }

    @objc func toggleSound(_ sender: NSMenuItem) {
        SoundManager.shared.isMuted.toggle()
    }

    @objc func renameCat() {
        let alert = NSAlert()
        alert.messageText = "Rename your \(catState.animalTheme.displayName.lowercased())"
        alert.informativeText = "Enter a new name:"
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")

        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        input.stringValue = catState.name
        alert.accessoryView = input

        if alert.runModal() == .alertFirstButtonReturn {
            let newName = input.stringValue.trimmingCharacters(in: .whitespaces)
            if !newName.isEmpty {
                catState.name = newName
            }
        }
    }
}

// MARK: - Menu Delegate

extension AppDelegate: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        let theme = catState.animalTheme
        if let header = menu.items.first {
            header.title = "\(catState.name) - \(catState.mood.rawValue)"
        }
        if let hunger = menu.item(withTag: 100) {
            hunger.title = "Hunger: \(Int(catState.hunger))%"
        }
        if let happy = menu.item(withTag: 101) {
            happy.title = "Happiness: \(Int(catState.happiness))%"
        }
        if let energy = menu.item(withTag: 102) {
            energy.title = "Energy: \(Int(catState.energy))%"
        }
        if let buddyItem = menu.item(withTag: 200) {
            buddyItem.state = buddyManager.isEnabled ? .on : .off
        }
        if let focusItem = menu.item(withTag: 202) {
            focusItem.state = buddyManager.focusModeEnabled ? .on : .off
        }
        if let soundItem = menu.item(withTag: 201) {
            soundItem.title = SoundManager.shared.isMuted ? "Unmute Sound" : "Mute Sound"
            soundItem.state = SoundManager.shared.isMuted ? .on : .off
        }
        // Update timer menu
        if let timerItem = menu.item(withTag: 401) {
            if catState.isFocusTimerActive {
                timerItem.title = "Focus Timer (\(catState.focusTimerText))"
            } else {
                timerItem.title = "Focus Timer"
            }
            // Enable/disable cancel
            if let sub = timerItem.submenu, let cancel = sub.item(withTag: 400) {
                cancel.isEnabled = catState.isFocusTimerActive
            }
        }
        // Update theme checkmarks
        for (index, animalTheme) in AnimalTheme.allCases.enumerated() {
            if let themeItem = menu.item(withTag: 300 + index) {
                themeItem.state = animalTheme == theme ? .on : .off
            }
        }
    }
}
