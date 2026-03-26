import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var catState: CatState!
    var catWindow: CatWindow!
    var iconTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        catState = CatState()

        // Create the status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.title = "🐾"
            button.font = NSFont.systemFont(ofSize: 14)
        }

        // Build the menu
        let menu = NSMenu()
        menu.autoenablesItems = false

        // Cat name + mood header
        let headerItem = NSMenuItem(title: "\(catState.name) - \(catState.mood.emoji) \(catState.mood.rawValue)", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        menu.addItem(headerItem)

        menu.addItem(NSMenuItem.separator())

        // Stats
        let hungerItem = NSMenuItem(title: "🐟 Hunger: \(Int(catState.hunger))%", action: nil, keyEquivalent: "")
        hungerItem.isEnabled = false
        hungerItem.tag = 100
        menu.addItem(hungerItem)

        let happyItem = NSMenuItem(title: "💖 Happiness: \(Int(catState.happiness))%", action: nil, keyEquivalent: "")
        happyItem.isEnabled = false
        happyItem.tag = 101
        menu.addItem(happyItem)

        let energyItem = NSMenuItem(title: "⚡ Energy: \(Int(catState.energy))%", action: nil, keyEquivalent: "")
        energyItem.isEnabled = false
        energyItem.tag = 102
        menu.addItem(energyItem)

        menu.addItem(NSMenuItem.separator())

        // Actions
        let feedItem = NSMenuItem(title: "🐟 Feed", action: #selector(feedCat), keyEquivalent: "f")
        feedItem.target = self
        menu.addItem(feedItem)

        let playItem = NSMenuItem(title: "🧶 Play", action: #selector(playCat), keyEquivalent: "p")
        playItem.target = self
        menu.addItem(playItem)

        let petItem = NSMenuItem(title: "🤚 Pet", action: #selector(petCat), keyEquivalent: "e")
        petItem.target = self
        menu.addItem(petItem)

        let napItem = NSMenuItem(title: "💤 Nap", action: #selector(napCat), keyEquivalent: "n")
        napItem.target = self
        menu.addItem(napItem)

        let wakeItem = NSMenuItem(title: "☀️ Wake Up", action: #selector(wakeCat), keyEquivalent: "w")
        wakeItem.target = self
        menu.addItem(wakeItem)

        menu.addItem(NSMenuItem.separator())

        // Rename
        let renameItem = NSMenuItem(title: "✏️ Rename...", action: #selector(renameCat), keyEquivalent: "r")
        renameItem.target = self
        menu.addItem(renameItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)

        // Set menu delegate to update stats before showing
        menu.delegate = self

        statusItem.menu = menu

        // Create the walking cat window
        catWindow = CatWindow(catState: catState)
        catWindow.orderFront(nil)

        // No icon animation - just a simple paw print
    }

    func loadSprite(_ name: String) -> NSImage? {
        guard let path = Bundle.main.path(forResource: name, ofType: "png", inDirectory: "Sprites"),
              let img = NSImage(contentsOfFile: path) else { return nil }
        img.size = NSSize(width: 110, height: 110) // jumbo cat
        img.isTemplate = false
        return img
    }

    func updateMenuBarIcon() {
        guard let button = statusItem.button else { return }
        if let img = loadSprite("sit_0") {
            button.image = img
        }
    }

    func startIconAnimation() {
        var iconFrame = 0
        iconTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { [weak self] _ in
            guard let self = self, let button = self.statusItem.button else { return }

            let spriteName: String
            switch self.catState.mood {
            case .sleeping:
                spriteName = "sleep_loop_\(iconFrame % 4)"
            case .happy, .content, .playing:
                spriteName = "sit_\(iconFrame % 4)"
            case .hungry, .sad:
                spriteName = "sit_\(iconFrame % 4)"
            case .eating:
                spriteName = "groom_\(iconFrame % 6)"
            case .tired:
                spriteName = "sit_\(iconFrame % 4)"
            }

            if let img = self.loadSprite(spriteName) {
                button.image = img
            }

            iconFrame += 1
        }
    }

    // MARK: - Actions

    @objc func feedCat() {
        catState.feed()
    }

    @objc func playCat() {
        catState.play()
    }

    @objc func petCat() {
        catState.pet()
    }

    @objc func napCat() {
        catState.nap()
    }

    @objc func wakeCat() {
        catState.wake()
    }

    @objc func renameCat() {
        let alert = NSAlert()
        alert.messageText = "Rename your cat"
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
        // Update header
        if let header = menu.items.first {
            header.title = "\(catState.name) - \(catState.mood.emoji) \(catState.mood.rawValue)"
        }
        // Update stats
        if let hunger = menu.item(withTag: 100) {
            hunger.title = "🐟 Hunger: \(Int(catState.hunger))%"
        }
        if let happy = menu.item(withTag: 101) {
            happy.title = "💖 Happiness: \(Int(catState.happiness))%"
        }
        if let energy = menu.item(withTag: 102) {
            energy.title = "⚡ Energy: \(Int(catState.energy))%"
        }
    }
}
