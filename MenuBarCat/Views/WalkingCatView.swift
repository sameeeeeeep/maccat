import SwiftUI
import Cocoa

enum CatAction: Equatable {
    case idle          // sit_0-3
    case sitting       // sit_alt_0-3
    case walking       // run_0-3 (best leg cycle)
    case sleeping      // sleep_loop_0-3
    case lieDown       // liedown_0-7 (transition to sleep)
    case grooming      // groom_0-5
    case playing       // play_0-6 (pounce)
    case stretch       // stretch_0-7
    case jumping       // play_2-3 (mid-air frames)
}

/// Shared position so buddy cat can track the main cat
class MainCatPosition: ObservableObject {
    @Published var x: CGFloat = 300
    @Published var y: CGFloat = 600
    @Published var action: CatAction = .idle
}

struct WalkingCatView: View {
    @ObservedObject var cat: CatState
    @ObservedObject var buddyManager: BuddyCatManager
    @StateObject private var mainPos = MainCatPosition()
    @State private var catX: CGFloat = 300
    @State private var catY: CGFloat = 600
    @State private var catAction: CatAction = .idle
    @State private var frame: Int = 0
    @State private var facingRight: Bool = true
    @State private var isFollowingMouse: Bool = false
    @State private var isNearMouse: Bool = false

    @State private var idleTimer: Timer?
    @State private var frameTimer: Timer?
    @State private var walkTimer: Timer?
    @State private var mouseTracker: Timer?
    @State private var mouseMonitor: Any?

    let screenWidth: CGFloat
    let screenHeight: CGFloat
    let platformHeight: CGFloat = 60

    var body: some View {
        ZStack {
            // Focus mode: dark overlay, cats fight on top
            if buddyManager.focusModeEnabled && buddyManager.isDistracted {
                Color.black.opacity(0.75)
                    .ignoresSafeArea()

                Text("get back to work")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .position(x: screenWidth / 2, y: screenHeight / 2 - 60)
            }

            // Stop fight sounds when overlay disappears
            EmptyView()
                .onChange(of: buddyManager.isDistracted) { distracted in
                    if !distracted {
                        SoundManager.shared.stopAll()
                        catAction = .idle
                    } else {
                        // Start fighting
                        catAction = .playing
                        SoundManager.shared.play("hiss", volume: 0.5)
                    }
                }
                .onChange(of: buddyManager.focusModeEnabled) { enabled in
                    if !enabled {
                        SoundManager.shared.stopAll()
                        catAction = .idle
                    }
                }

            if let text = cat.actionText {
                Text(text)
                    .font(.system(size: 16, weight: .bold))
                    .shadow(color: .white, radius: 3)
                    .position(x: catX, y: catY - 50)
                    .transition(.scale.combined(with: .opacity))
                    .animation(.spring(response: 0.3), value: cat.actionText)
            }

            // Buddy cat
            BuddyCatView(
                buddyManager: buddyManager,
                mainPos: mainPos,
                screenWidth: screenWidth,
                screenHeight: screenHeight
            )

            spriteImage
                .interpolation(.none)
                .resizable()
                .frame(width: 72, height: 72)
                .colorMultiply(catTintColor)
                .scaleEffect(x: facingRight ? 1 : -1, y: 1)
                .position(x: catX, y: catY)
                .onAppear {
                    startAnimationLoop()
                    startBehaviorLoop()
                    startMouseTracking()
                }
                .onDisappear {
                    frameTimer?.invalidate()
                    idleTimer?.invalidate()
                    walkTimer?.invalidate()
                    mouseTracker?.invalidate()
                    if let m = mouseMonitor { NSEvent.removeMonitor(m) }
                }
                .onChange(of: cat.activeAction) { action in
                    guard let action = action else { return }
                    handleAction(action)
                }
        }
        .frame(width: screenWidth, height: screenHeight)
    }

    // MARK: - Color

    var catTintColor: Color {
        switch cat.catColor {
        case "orange": return Color(red: 1.0, green: 0.8, blue: 0.5)
        case "black": return Color(red: 0.3, green: 0.3, blue: 0.35)
        case "white": return Color(red: 1.0, green: 1.0, blue: 1.0)
        case "ginger": return Color(red: 1.0, green: 0.7, blue: 0.3)
        case "blue": return Color(red: 0.6, green: 0.7, blue: 1.0)
        case "pink": return Color(red: 1.0, green: 0.7, blue: 0.8)
        case "golden": return Color(red: 1.0, green: 0.85, blue: 0.4)
        default: return .white // original = no tint
        }
    }

    // MARK: - Sprites

    var spriteImage: Image {
        let name = spriteNameForAction()
        let path = Bundle.main.path(forResource: name, ofType: "png", inDirectory: "Sprites")
        if let path = path, let nsImage = NSImage(contentsOfFile: path) {
            return Image(nsImage: nsImage)
        }
        return Image(systemName: "cat.fill")
    }

    func spriteNameForAction() -> String {
        switch catAction {
        case .idle:
            return "sit_\(frame % 4)"
        case .sitting:
            return "sit_alt_\(frame % 4)"
        case .walking:
            let walkFrames = [3, 4, 5, 6]
            return "stretch_\(walkFrames[frame % 4])"
        case .sleeping:
            return "sleep_loop_\(frame % 4)"
        case .lieDown:
            return "liedown_\(min(frame % 8, 7))"
        case .grooming:
            return "groom_\(frame % 6)"
        case .playing:
            return "play_\(frame % 7)"
        case .stretch:
            return "stretch_\(frame % 8)"
        case .jumping:
            return "play_\(2 + (frame % 2))" // play_2 and play_3 are mid-air
        }
    }

    func syncPosition() {
        mainPos.x = catX
        mainPos.y = catY
        mainPos.action = catAction
    }

    func startAnimationLoop() {
        frameTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { _ in
            frame += 1
            syncPosition()
        }
    }

    // MARK: - Mouse Following (Platformer)

    func startMouseTracking() {
        var lastMousePos: CGPoint = .zero

        mouseTracker = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
            let screen = NSScreen.main!
            let mouseInCG = NSEvent.mouseLocation
            let mouseX = mouseInCG.x
            let mouseY = screen.frame.height - mouseInCG.y

            let mouseMoved = abs(mouseX - lastMousePos.x) > 3 || abs(mouseY - lastMousePos.y) > 3
            lastMousePos = CGPoint(x: mouseX, y: mouseY)

            // Fight mode: ignore cursor, chase around screen
            if buddyManager.focusModeEnabled && buddyManager.isDistracted {
                catAction = .playing
                // Run around erratically
                let fightX = catX + CGFloat.random(in: -40...40)
                let fightY = catY + CGFloat.random(in: -20...20)
                catX = max(40, min(screenWidth - 40, fightX))
                catY = max(40, min(screenHeight - 40, fightY))
                facingRight = Bool.random()
                return
            }

            if cat.activeAction != nil { return }
            if catAction == .sleeping || catAction == .lieDown { return }
            guard mouseMoved else { return }

            let dx = mouseX - catX
            let dy = mouseY - catY
            let dist = sqrt(dx * dx + dy * dy)

            // Close enough - sit and face cursor
            if dist < 70 {
                if catAction == .walking || catAction == .jumping {
                    walkTimer?.invalidate()
                    catAction = .idle
                    facingRight = dx > 0
                    isFollowingMouse = false
                }
                return
            }

            // Always interrupt idle behavior to follow cursor
            // Even if already following, re-target to current mouse position
            idleTimer?.invalidate()
            walkTimer?.invalidate()
            isFollowingMouse = true

            if abs(dy) < platformHeight * 0.6 {
                let targetX = clampX(catX + dx * 0.7)
                platformWalk(to: targetX) {
                    catAction = .idle
                    isFollowingMouse = false
                }
            } else {
                staircaseTo(targetX: mouseX, targetY: mouseY) {
                    catAction = .idle
                    isFollowingMouse = false
                }
            }
        }
    }

    // Hop one platform at a time like stairs - each hop moves diagonally
    func staircaseTo(targetX: CGFloat, targetY: CGFloat, completion: @escaping () -> Void) {
        let dy = targetY - catY

        // Close enough vertically? Just walk the rest.
        if abs(dy) < platformHeight * 0.5 {
            let finalX = clampX(catX + (targetX - catX) * 0.6)
            platformWalk(to: finalX, completion: completion)
            return
        }

        // How many steps to get there
        let stepsNeeded = Int(ceil(abs(dy) / platformHeight))
        let goingUp = dy < 0

        // Each hop covers this much X and Y
        let totalDx = targetX - catX
        let hopDx = totalDx / CGFloat(stepsNeeded)
        let hopDy: CGFloat = goingUp ? -platformHeight : platformHeight

        // Do one diagonal hop
        let hopTargetX = clampX(catX + hopDx)
        let hopTargetY = max(40, min(screenHeight - 40, catY + hopDy))

        diagonalHop(toX: hopTargetX, toY: hopTargetY) {
            // More hops needed?
            let remaining = targetY - catY
            if abs(remaining) < platformHeight * 0.5 {
                // Done hopping, walk to final position
                let finalX = clampX(catX + (targetX - catX) * 0.6)
                platformWalk(to: finalX, completion: completion)
            } else {
                staircaseTo(targetX: targetX, targetY: targetY, completion: completion)
            }
        }
    }

    // Single diagonal hop - moves X and Y together with an arc
    func diagonalHop(toX targetX: CGFloat, toY targetY: CGFloat, completion: @escaping () -> Void) {
        let startX = catX
        let startY = catY
        let arcHeight: CGFloat = 20
        let totalSteps = 14

        facingRight = targetX > catX
        catAction = .jumping
        var stepCount = 0

        walkTimer?.invalidate()
        walkTimer = Timer.scheduledTimer(withTimeInterval: 0.018, repeats: true) { timer in
            stepCount += 1
            let progress = CGFloat(stepCount) / CGFloat(totalSteps)

            // Linear X movement
            catX = startX + (targetX - startX) * progress

            // Linear Y movement + parabolic arc on top
            let arc = 4.0 * arcHeight * progress * (1.0 - progress)
            catY = startY + (targetY - startY) * progress - arc

            if stepCount >= totalSteps {
                timer.invalidate()
                catX = targetX
                catY = targetY
                completion()
            }
        }
    }

    func platformWalk(to targetX: CGFloat, completion: @escaping () -> Void) {
        let dx = targetX - catX
        let speed: CGFloat = 2.2
        let steps = Int(abs(dx) / speed)

        guard steps > 1 else {
            completion()
            return
        }

        let stepX = dx / CGFloat(steps)
        facingRight = dx > 0
        catAction = .walking

        var stepCount = 0
        walkTimer?.invalidate()
        walkTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { timer in
            catX += stepX
            stepCount += 1
            if stepCount >= steps {
                timer.invalidate()
                catX = targetX
                completion()
            }
        }
    }

    func platformJump(to targetY: CGFloat, completion: @escaping () -> Void) {
        // Small horizontal shift during jump so it looks natural
        let hopX = clampX(catX + CGFloat.random(in: -30...30))
        diagonalHop(toX: hopX, toY: targetY, completion: completion)
    }

    func clampX(_ x: CGFloat) -> CGFloat {
        return max(40, min(screenWidth - 40, x))
    }

    // MARK: - Action Reactions (Feed/Play/Pet/Nap)

    func handleAction(_ action: String) {
        idleTimer?.invalidate()
        walkTimer?.invalidate()
        isFollowingMouse = false

        switch action {
        case "feed":
            catAction = .grooming
            scheduleNext(after: 2) {
                catAction = .idle
                scheduleNext(after: 2)
            }
        case "play":
            catAction = .playing
            frame = 0
            scheduleNext(after: 2.5) {
                catAction = .stretch
                frame = 0
                scheduleNext(after: 1.5) {
                    catAction = .idle
                    scheduleNext(after: 1.5)
                }
            }
        case "pet":
            catAction = .grooming
            scheduleNext(after: 2) {
                catAction = .idle
                scheduleNext(after: 2)
            }
        case "nap":
            catAction = .lieDown
            frame = 0
            scheduleNext(after: 1.5) {
                catAction = .sleeping
                scheduleNext(after: 5)
            }
        default:
            break
        }
    }

    // MARK: - Idle Behavior

    func startBehaviorLoop() {
        pickNextAction()
    }

    func pickNextAction() {
        idleTimer?.invalidate()
        walkTimer?.invalidate()

        if isFollowingMouse { return }

        if cat.mood == .sleeping {
            catAction = .sleeping
            scheduleNext(after: 6)
            return
        }

        let roll = Int.random(in: 0...100)

        if roll < 25 {
            // Walk to a window top
            let windows = getWindowTops()
            if let target = windows.randomElement() {
                let tx = clampX(CGFloat.random(in: (target.minX + 40)...max(target.minX + 41, target.minX + target.width - 40)))
                walkTo(x: tx, y: target.minY) {
                    catAction = .idle
                    let sub = Int.random(in: 0...3)
                    if sub == 0 {
                        scheduleNext(after: Double.random(in: 3...6)) {
                            catAction = .grooming
                            scheduleNext(after: 3)
                        }
                    } else if sub == 1 {
                        scheduleNext(after: Double.random(in: 2...4)) {
                            catAction = .lieDown
                            frame = 0
                            scheduleNext(after: 2) {
                                catAction = .sleeping
                                scheduleNext(after: Double.random(in: 4...8))
                            }
                        }
                    } else {
                        scheduleNext(after: Double.random(in: 3...7))
                    }
                }
                return
            }
        }

        if roll < 50 {
            let goRight = Bool.random()
            let distance = CGFloat.random(in: 80...250)
            let targetX = clampX(goRight ? catX + distance : catX - distance)
            platformWalk(to: targetX) {
                catAction = .idle
                scheduleNext(after: Double.random(in: 1.5...4))
            }
        } else if roll < 62 {
            catAction = .grooming
            scheduleNext(after: Double.random(in: 2...4)) {
                catAction = .sitting
                scheduleNext(after: 1)
            }
        } else if roll < 74 && cat.energy > 20 {
            catAction = .playing
            frame = 0
            scheduleNext(after: Double.random(in: 2...3)) {
                catAction = .idle
                scheduleNext(after: 1)
            }
        } else if roll < 85 {
            catAction = .stretch
            frame = 0
            scheduleNext(after: 2) {
                catAction = .idle
                scheduleNext(after: 1.5)
            }
        } else {
            catAction = .sitting
            scheduleNext(after: Double.random(in: 2...5))
        }
    }

    // MARK: - Helpers

    func walkTo(x targetX: CGFloat, y targetY: CGFloat, completion: @escaping () -> Void) {
        let dy = targetY - catY

        if abs(dy) > platformHeight * 0.5 {
            staircaseTo(targetX: targetX, targetY: targetY, completion: completion)
        } else {
            platformWalk(to: targetX, completion: completion)
        }
    }

    func getWindowTops() -> [CGRect] {
        guard let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
            return []
        }

        var tops: [CGRect] = []
        let screen = NSScreen.main!
        let screenH = screen.frame.height

        for window in windowList {
            guard let boundsDict = window[kCGWindowBounds as String] as? [String: CGFloat],
                  let layer = window[kCGWindowLayer as String] as? Int,
                  let ownerName = window[kCGWindowOwnerName as String] as? String else { continue }

            if layer != 0 { continue }
            if ownerName == "MenuBarCat" || ownerName == "Window Server" { continue }

            let x = boundsDict["X"] ?? 0
            let y = boundsDict["Y"] ?? 0
            let w = boundsDict["Width"] ?? 0
            let h = boundsDict["Height"] ?? 0

            let flippedY = screenH - y

            if w > 100 && h > 50 && flippedY > 60 && flippedY < screenH - 40 {
                tops.append(CGRect(x: x, y: flippedY, width: w, height: 30))
            }
        }
        return tops
    }

    func scheduleNext(after seconds: Double, action: (() -> Void)? = nil) {
        idleTimer?.invalidate()
        idleTimer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { _ in
            if let action = action {
                action()
            } else {
                pickNextAction()
            }
        }
    }
}
