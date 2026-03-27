import Cocoa
import SwiftUI
import Combine

class CatWindow: NSWindow {
    private var buddyManager: BuddyCatManager
    private var cancellable: AnyCancellable?

    init(catState: CatState, buddyManager: BuddyCatManager) {
        self.buddyManager = buddyManager
        let screen = NSScreen.main!
        let screenFrame = screen.frame

        super.init(
            contentRect: screenFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .stationary]
        self.ignoresMouseEvents = true
        self.isMovableByWindowBackground = false
        self.hidesOnDeactivate = false

        let walkingView = WalkingCatView(
            cat: catState,
            buddyManager: buddyManager,
            screenWidth: screenFrame.width,
            screenHeight: screenFrame.height
        )
        let hostingView = NSHostingView(rootView: walkingView)
        hostingView.frame = NSRect(origin: .zero, size: screenFrame.size)
        self.contentView = hostingView

        // When distracted in focus mode, block mouse events but keep below menu bar
        cancellable = buddyManager.$isDistracted.sink { [weak self] distracted in
            guard let self = self else { return }
            let shouldBlock = buddyManager.focusModeEnabled && distracted
            self.ignoresMouseEvents = !shouldBlock
            // Use .floating level even when blocking so menu bar stays accessible
            self.level = shouldBlock ? .modalPanel : .floating
        }
    }
}
