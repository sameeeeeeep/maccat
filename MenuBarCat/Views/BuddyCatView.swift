import SwiftUI

/// A companion cat that follows the player's cat and interacts with it
struct BuddyCatView: View {
    @ObservedObject var buddyManager: BuddyCatManager
    @ObservedObject var mainPos: MainCatPosition
    let screenWidth: CGFloat
    let screenHeight: CGFloat

    @State private var x: CGFloat = 500
    @State private var y: CGFloat = 600
    @State private var frame: Int = 0
    @State private var facingRight: Bool = false
    @State private var action: CatAction = .idle
    @State private var moveTimer: Timer?
    @State private var frameTimer: Timer?
    @State private var behaviorTimer: Timer?
    @State private var appeared = false
    @State private var isHopping = false

    private let followDistance: CGFloat = 90
    private let platformHeight: CGFloat = 60

    var body: some View {
        Group {
            if let buddy = buddyManager.currentBuddy, buddyManager.isEnabled {
                spriteImage
                    .interpolation(.none)
                    .resizable()
                    .frame(width: 56, height: 56)
                    .colorMultiply(buddy.color)
                    .scaleEffect(x: facingRight ? 1 : -1, y: 1)
                    .position(x: x, y: y)
                    .onAppear {
                        guard !appeared else { return }
                        appeared = true
                        x = mainPos.x + 120
                        y = mainPos.y
                        startFrameLoop()
                        startFollowLoop()
                    }
                    .onDisappear {
                        frameTimer?.invalidate()
                        moveTimer?.invalidate()
                        behaviorTimer?.invalidate()
                    }
            }
        }
    }

    var spriteImage: Image {
        let name = spriteNameForAction()
        if let path = Bundle.main.path(forResource: name, ofType: "png", inDirectory: "Sprites"),
           let nsImage = NSImage(contentsOfFile: path) {
            return Image(nsImage: nsImage)
        }
        return Image(systemName: "cat.fill")
    }

    func spriteNameForAction() -> String {
        switch action {
        case .idle:
            return "sit_\(frame % 4)"
        case .sitting:
            return "sit_alt_\(frame % 4)"
        case .walking:
            let walkFrames = [3, 4, 5, 6]
            return "stretch_\(walkFrames[frame % 4])"
        case .sleeping:
            return "sleep_loop_\(frame % 4)"
        case .grooming:
            return "groom_\(frame % 6)"
        case .playing:
            return "play_\(frame % 7)"
        case .jumping:
            return "play_\(2 + (frame % 2))"
        case .lieDown:
            return "liedown_\(min(frame % 8, 7))"
        case .stretch:
            return "stretch_\(frame % 8)"
        }
    }

    func startFrameLoop() {
        frameTimer = Timer.scheduledTimer(withTimeInterval: 0.18, repeats: true) { _ in
            frame += 1
        }
    }

    func startFollowLoop() {
        moveTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { _ in
            // Safety: unstick after 1 second
            if isHopping {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    if isHopping { isHopping = false; action = .idle }
                }
            }
            followMainCat()
        }
    }

    func followMainCat() {
        if isHopping { return }

        let mainAction = mainPos.action

        // FIGHT MODE: chase main cat aggressively
        if mainAction == .playing && buddyManager.isDistracted {
            action = .playing
            facingRight = mainPos.x > x

            let dx = mainPos.x - x
            let dy = mainPos.y - y
            let dist = sqrt(dx * dx + dy * dy)

            // Rush toward main cat
            if dist > 30 {
                if abs(dy) > platformHeight * 0.5 {
                    action = .jumping
                    let hopX = x + (dx > 0 ? 1 : -1) * min(abs(dx) * 0.5, 80)
                    let hopY = y + (dy > 0 ? platformHeight : -platformHeight)
                    animateHop(toX: clamp(hopX), toY: clampY(hopY))
                } else {
                    x += (dx > 0 ? 1 : -1) * min(abs(dx) * 0.3, 10)
                }
            } else {
                // Close - bounce around fighting
                x += CGFloat.random(in: -15...15)
                y += CGFloat.random(in: -8...8)
                y = clampY(y)
                x = clamp(x)
                // Random fight sounds
                if Int.random(in: 0...12) == 0 {
                    if Bool.random() {
                        SoundManager.shared.play("hiss", volume: 0.3)
                    } else {
                        SoundManager.shared.randomMeow(volume: 0.4)
                    }
                }
            }
            return
        }

        // Mirror main cat's sleep/nap
        if mainAction == .sleeping || mainAction == .lieDown {
            if action != .sleeping && action != .lieDown {
                action = .lieDown
                behaviorTimer?.invalidate()
                behaviorTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { _ in
                    action = .sleeping
                }
            }
            return
        }

        // If main cat is playing, buddy plays too
        if mainAction == .playing {
            if action != .playing {
                action = .playing
                frame = 0
            }
            let jitter = CGFloat.random(in: -20...20)
            x += jitter * 0.3
            return
        }

        // Follow cursor with offset (opposite side from main cat)
        let screen = NSScreen.main!
        let mouseInCG = NSEvent.mouseLocation
        let mouseX = mouseInCG.x
        let mouseY = screen.frame.height - mouseInCG.y

        // Buddy hangs out on the other side of the cursor from main cat
        let offsetX: CGFloat = mainPos.x > mouseX ? 60 : -60
        let targetX = mouseX + offsetX
        let targetY = mouseY + 30

        let dx = targetX - x
        let dy = targetY - y
        let dist = sqrt(dx * dx + dy * dy)

        // Close enough - idle or do cute stuff
        if dist < followDistance {
            if action == .walking || action == .jumping {
                action = .idle
                facingRight = dx > 0
            }
            // Random cute behaviors when near main cat
            if Int.random(in: 0...8) == 0 {
                let roll = Int.random(in: 0...2)
                if roll == 0 {
                    action = .grooming
                    behaviorTimer?.invalidate()
                    behaviorTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
                        action = .idle
                    }
                } else if roll == 1 {
                    action = .stretch
                    frame = 0
                    behaviorTimer?.invalidate()
                    behaviorTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { _ in
                        action = .idle
                    }
                }
            }
            return
        }

        // Need to catch up
        facingRight = dx > 0
        let needsVertical = abs(dy) > platformHeight * 0.5

        if needsVertical {
            action = .jumping
            let hopX = x + (dx > 0 ? 1 : -1) * min(abs(dx) * 0.4, 60)
            let hopY = y + (dy > 0 ? platformHeight : -platformHeight)
            animateHop(toX: clamp(hopX), toY: clampY(hopY))
        } else {
            action = .walking
            let speed: CGFloat = 8.0
            let step = (dx > 0 ? 1 : -1) * min(abs(dx) * 0.3, speed)
            x += step
        }
    }

    func animateHop(toX targetX: CGFloat, toY targetY: CGFloat) {
        let startX = x
        let startY = y
        let arcHeight: CGFloat = 15
        let totalSteps = 12
        var stepCount = 0
        isHopping = true

        behaviorTimer?.invalidate()
        behaviorTimer = Timer.scheduledTimer(withTimeInterval: 0.018, repeats: true) { timer in
            stepCount += 1
            let progress = CGFloat(stepCount) / CGFloat(totalSteps)
            x = startX + (targetX - startX) * progress
            let arc = 4.0 * arcHeight * progress * (1.0 - progress)
            y = startY + (targetY - startY) * progress - arc

            if stepCount >= totalSteps {
                timer.invalidate()
                x = targetX
                y = targetY
                action = .idle
                isHopping = false
            }
        }
    }

    func clamp(_ val: CGFloat) -> CGFloat {
        max(40, min(screenWidth - 40, val))
    }

    func clampY(_ val: CGFloat) -> CGFloat {
        max(40, min(screenHeight - 40, val))
    }
}
