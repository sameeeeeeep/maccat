import SwiftUI
import Cocoa

extension View {
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

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

/// A toy dropped on screen for the pet to chase
struct PetToy: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    let emoji: String
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

    // MARK: - Interaction State
    @State private var isDragging: Bool = false
    @State private var isTossed: Bool = false
    @State private var tossVelX: CGFloat = 0
    @State private var tossVelY: CGFloat = 0
    @State private var tossTimer: Timer?
    @State private var dragHistory: [(x: CGFloat, y: CGFloat, time: TimeInterval)] = []
    @State private var clickMonitor: Any?
    @State private var dragMonitor: Any?
    @State private var upMonitor: Any?
    @State private var squishScale: CGFloat = 1.0

    // MARK: - Hearts
    @State private var hearts: [(id: UUID, x: CGFloat, y: CGFloat, opacity: Double)] = []
    @State private var heartTimer: Timer?

    // MARK: - Focus Timer
    @State private var focusTimerDisplay: String = ""
    @State private var focusTimerTick: Timer?
    @State private var wasFocusTimerActive: Bool = false

    // MARK: - Toys
    @State private var toys: [PetToy] = []
    @State private var isChasingToy: Bool = false

    let screenWidth: CGFloat
    let screenHeight: CGFloat
    let platformHeight: CGFloat = 60

    var body: some View {
        ZStack {
            // Focus mode: dark overlay, cats fight on top
            if buddyManager.focusModeEnabled && buddyManager.isDistracted {
                Color.black.opacity(0.75)
                    .ignoresSafeArea()

                Text(cat.animalTheme.focusModeText)
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
                        SoundManager.shared.play(cat.animalTheme.fightSound, volume: 0.5)
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

            // Focus timer display
            if cat.isFocusTimerActive {
                Text(focusTimerDisplay)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.black.opacity(0.6)))
                    .position(x: catX, y: catY - 45)
            }

            // Toys on screen
            ForEach(toys) { toy in
                Text(toy.emoji)
                    .font(.system(size: 24))
                    .position(x: toy.x, y: toy.y)
            }

            // Floating hearts
            ForEach(hearts, id: \.id) { heart in
                Text("💕")
                    .font(.system(size: 16))
                    .opacity(heart.opacity)
                    .position(x: heart.x, y: heart.y)
            }

            // Buddy cat
            BuddyCatView(
                buddyManager: buddyManager,
                mainPos: mainPos,
                animalTheme: cat.animalTheme,
                screenWidth: screenWidth,
                screenHeight: screenHeight
            )

            spriteImage
                .interpolation(.none)
                .resizable()
                .frame(width: cat.animalTheme.spriteSize, height: cat.animalTheme.spriteSize)
                .if(!cat.animalTheme.hasColoredSprites) { view in
                    view.colorMultiply(catTintColor)
                }
                .scaleEffect(x: facingRight ? 1 : -1, y: squishScale)
                .scaleEffect(y: squishScale == 1.0 ? 1.0 : (2.0 - squishScale))  // widen when squished
                .position(x: catX, y: catY)
                .onAppear {
                    startAnimationLoop()
                    startBehaviorLoop()
                    startMouseTracking()
                    startInteractionMonitors()
                    startFocusTimerTick()
                }
                .onDisappear {
                    frameTimer?.invalidate()
                    idleTimer?.invalidate()
                    walkTimer?.invalidate()
                    mouseTracker?.invalidate()
                    tossTimer?.invalidate()
                    heartTimer?.invalidate()
                    focusTimerTick?.invalidate()
                    if let m = mouseMonitor { NSEvent.removeMonitor(m) }
                    removeInteractionMonitors()
                }
                .onChange(of: cat.activeAction) { action in
                    guard let action = action else { return }
                    handleAction(action)
                }
                .onChange(of: cat.pendingToy) { toy in
                    if let toy = toy {
                        dropToy(toy)
                        cat.pendingToy = nil
                    }
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
        default: return cat.animalTheme.defaultTint // theme-specific default
        }
    }

    // MARK: - Sprites

    var spriteImage: Image {
        let name = spriteNameForAction()
        // Try theme-specific sprites first, fall back to cat sprites
        let themeDir = cat.animalTheme.spriteDirectory
        if let path = Bundle.main.path(forResource: name, ofType: "png", inDirectory: themeDir),
           let nsImage = NSImage(contentsOfFile: path) {
            return Image(nsImage: nsImage)
        }
        // Fallback to default sprites
        if let path = Bundle.main.path(forResource: name, ofType: "png", inDirectory: AnimalTheme.fallbackSpriteDirectory),
           let nsImage = NSImage(contentsOfFile: path) {
            return Image(nsImage: nsImage)
        }
        return Image(systemName: cat.animalTheme.menuBarIcon)
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

    // MARK: - Click / Drag / Toss Interactions

    func startInteractionMonitors() {
        // Mouse down - check if near pet to start drag or click-to-pet
        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { event in
            let screen = NSScreen.main!
            let mouseX = event.locationInWindow.x
            let mouseY = screen.frame.height - event.locationInWindow.y

            let dx = mouseX - catX
            let dy = mouseY - catY
            let dist = sqrt(dx * dx + dy * dy)

            if dist < 50 {
                // Start drag
                isDragging = true
                isTossed = false
                tossTimer?.invalidate()
                idleTimer?.invalidate()
                walkTimer?.invalidate()
                isFollowingMouse = false
                catAction = .jumping
                dragHistory = [(x: mouseX, y: mouseY, time: ProcessInfo.processInfo.systemUptime)]
            }
        }

        // Mouse dragged - move pet with cursor
        dragMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDragged) { event in
            guard isDragging else { return }
            let screen = NSScreen.main!
            let mouseX = event.locationInWindow.x
            let mouseY = screen.frame.height - event.locationInWindow.y

            catX = mouseX
            catY = mouseY
            catAction = .jumping

            let now = ProcessInfo.processInfo.systemUptime
            dragHistory.append((x: mouseX, y: mouseY, time: now))
            // Keep last 5 samples for velocity calculation
            if dragHistory.count > 5 {
                dragHistory.removeFirst()
            }
        }

        // Mouse up - release pet with velocity
        upMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseUp) { event in
            guard isDragging else { return }
            isDragging = false

            let screen = NSScreen.main!
            let mouseX = event.locationInWindow.x
            let mouseY = screen.frame.height - event.locationInWindow.y

            // Calculate velocity from drag history
            if dragHistory.count >= 2 {
                let recent = dragHistory.last!
                let older = dragHistory.first!
                let dt = recent.time - older.time
                if dt > 0.01 {
                    tossVelX = (recent.x - older.x) / CGFloat(dt) * 0.016  // per-frame velocity
                    tossVelY = (recent.y - older.y) / CGFloat(dt) * 0.016
                    // Clamp max velocity
                    tossVelX = max(-25, min(25, tossVelX))
                    tossVelY = max(-25, min(25, tossVelY))
                    startTossPhysics()
                } else {
                    // No real drag, treat as click-to-pet
                    clickPet()
                }
            } else {
                clickPet()
            }
            dragHistory = []
        }
    }

    func removeInteractionMonitors() {
        if let m = clickMonitor { NSEvent.removeMonitor(m) }
        if let m = dragMonitor { NSEvent.removeMonitor(m) }
        if let m = upMonitor { NSEvent.removeMonitor(m) }
    }

    func clickPet() {
        // Trigger pet reaction
        cat.pet()
        spawnHearts()
    }

    func spawnHearts() {
        let baseX = catX
        let baseY = catY - 30
        for i in 0..<3 {
            let heartID = UUID()
            let offsetX = CGFloat.random(in: -20...20)
            let heart = (id: heartID, x: baseX + offsetX, y: baseY - CGFloat(i * 12), opacity: 1.0)
            hearts.append(heart)
        }

        // Animate hearts floating up and fading
        heartTimer?.invalidate()
        var elapsed = 0
        heartTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            elapsed += 1
            for i in hearts.indices {
                hearts[i].y -= 1.5
                hearts[i].opacity = max(0, hearts[i].opacity - 0.03)
            }
            hearts.removeAll { $0.opacity <= 0 }
            if hearts.isEmpty {
                timer.invalidate()
            }
        }
    }

    // MARK: - Focus Timer

    func startFocusTimerTick() {
        focusTimerTick = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            let isActive = cat.isFocusTimerActive

            if isActive {
                focusTimerDisplay = cat.focusTimerText

                // Keep pet sitting still during focus
                if !isDragging && !isTossed {
                    if catAction != .idle && catAction != .sitting {
                        walkTimer?.invalidate()
                        idleTimer?.invalidate()
                        isFollowingMouse = false
                        isChasingToy = false
                        catAction = .sitting
                    }
                }
            }

            // Timer just ended
            if wasFocusTimerActive && !isActive {
                focusTimerDisplay = ""
                // Celebrate!
                catAction = .playing
                frame = 0
                SoundManager.shared.randomVoice(theme: cat.animalTheme, volume: 0.4)
                spawnHearts()
                cat.happiness = min(100, cat.happiness + 15)
                scheduleNext(after: 2.5) {
                    catAction = .idle
                    scheduleNext(after: 1)
                }
            }

            wasFocusTimerActive = isActive
        }
    }

    // MARK: - Toss Physics

    func startTossPhysics() {
        isTossed = true
        catAction = .jumping
        let gravity: CGFloat = 0.8
        let bounceDamping: CGFloat = 0.6
        let friction: CGFloat = 0.98
        let groundY = screenHeight - 40

        tossTimer?.invalidate()
        tossTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { timer in
            // Apply gravity
            tossVelY += gravity

            // Apply friction to X
            tossVelX *= friction

            // Move
            catX += tossVelX
            catY += tossVelY

            // Face direction of movement
            if abs(tossVelX) > 1 {
                facingRight = tossVelX > 0
            }

            // Bounce off walls
            if catX < 40 {
                catX = 40
                tossVelX = abs(tossVelX) * bounceDamping
            } else if catX > screenWidth - 40 {
                catX = screenWidth - 40
                tossVelX = -abs(tossVelX) * bounceDamping
            }

            // Bounce off floor
            if catY > groundY {
                catY = groundY
                tossVelY = -abs(tossVelY) * bounceDamping

                // Squish on landing
                if abs(tossVelY) > 2 {
                    withAnimation(.spring(response: 0.15, dampingFraction: 0.3)) {
                        squishScale = 0.7
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                            squishScale = 1.0
                        }
                    }
                    SoundManager.shared.randomVoice(theme: cat.animalTheme, volume: 0.3)
                }
            }

            // Bounce off ceiling
            if catY < 40 {
                catY = 40
                tossVelY = abs(tossVelY) * bounceDamping
            }

            // Stop when velocity is negligible
            if abs(tossVelX) < 0.3 && abs(tossVelY) < 0.3 && catY >= groundY - 5 {
                timer.invalidate()
                isTossed = false
                catAction = .idle
                SoundManager.shared.randomVoice(theme: cat.animalTheme, volume: 0.25)
                // Resume normal behavior after a beat
                scheduleNext(after: 1.5)
            }
        }
    }

    // MARK: - Toys

    func dropToy(_ emoji: String) {
        let toyX = CGFloat.random(in: 100...(screenWidth - 100))
        let toyY = CGFloat.random(in: 200...(screenHeight - 100))
        let toy = PetToy(x: toyX, y: toyY, emoji: emoji)
        toys.append(toy)

        SoundManager.shared.play(cat.animalTheme.playSound, volume: 0.3)

        // Pet chases the toy
        chaseToy(toy)

        // Toy disappears after 8 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
            toys.removeAll { $0.id == toy.id }
        }
    }

    func chaseToy(_ toy: PetToy) {
        guard !isDragging && !isTossed else { return }
        isChasingToy = true
        idleTimer?.invalidate()
        walkTimer?.invalidate()
        isFollowingMouse = false

        walkTo(x: toy.x, y: toy.y) {
            // Arrived at toy - play!
            catAction = .playing
            frame = 0
            cat.happiness = min(100, cat.happiness + 10)
            SoundManager.shared.play(cat.animalTheme.playSound, volume: 0.4)

            scheduleNext(after: 2) {
                catAction = .idle
                isChasingToy = false
                // Remove the toy
                toys.removeAll { $0.id == toy.id }
                scheduleNext(after: 1)
            }
        }
    }

    // MARK: - Mouse Following (Platformer)

    func startMouseTracking() {
        var lastMousePos: CGPoint = .zero

        mouseTracker = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
            // Skip mouse tracking during interactions or focus timer
            if isDragging || isTossed || isChasingToy || cat.isFocusTimerActive { return }

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
        guard !isDragging && !isTossed else { return }
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
            spawnHearts()
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

        if isDragging || isTossed || isChasingToy || cat.isFocusTimerActive { return }
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
            if ownerName == "MenuBarCat" || ownerName == "macthecat" || ownerName == "Window Server" { continue }

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
