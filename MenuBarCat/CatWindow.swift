import Cocoa
import SwiftUI

class CatWindow: NSWindow {
    init(catState: CatState) {
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
            screenWidth: screenFrame.width,
            screenHeight: screenFrame.height
        )
        let hostingView = NSHostingView(rootView: walkingView)
        hostingView.frame = NSRect(origin: .zero, size: screenFrame.size)
        self.contentView = hostingView
    }
}
