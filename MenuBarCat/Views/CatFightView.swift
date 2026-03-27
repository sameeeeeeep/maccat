import SwiftUI

/// Tracks all timers so they can be reliably killed
class FightTimers: ObservableObject {
    private var timers: [Timer] = []

    func add(_ timer: Timer) {
        timers.append(timer)
    }

    func stopAll() {
        for t in timers { t.invalidate() }
        timers.removeAll()
    }

    deinit { stopAll() }
}

/// Two cats fighting when user is on a distracting site in focus mode
struct CatFightView: View {
    let catColor: Color
    let buddyColor: Color
    let screenWidth: CGFloat
    let screenHeight: CGFloat

    @State private var frame: Int = 0
    @State private var fightPhase: Int = 0
    @State private var catX: CGFloat = 0
    @State private var buddyX: CGFloat = 0
    @State private var shakeOffset: CGFloat = 0
    @StateObject private var timers = FightTimers()

    var body: some View {
        ZStack {
            // Your cat
            fightSprite(color: catColor)
                .scaleEffect(x: 1, y: 1)
                .offset(x: shakeOffset)
                .position(x: catX, y: screenHeight / 2)

            // Buddy cat
            fightSprite(color: buddyColor)
                .scaleEffect(x: -1, y: 1)
                .offset(x: -shakeOffset)
                .position(x: buddyX, y: screenHeight / 2)

            Text("get back to work")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
                .position(x: screenWidth / 2, y: screenHeight / 2 - 80)
        }
        .onAppear {
            catX = screenWidth / 2 - 200
            buddyX = screenWidth / 2 + 200
            startFight()
        }
        .onDisappear {
            timers.stopAll()
            SoundManager.shared.stopAll()
        }
    }

    func fightSprite(color: Color) -> some View {
        let name: String
        switch fightPhase {
        case 0: name = "sit_\(frame % 4)"
        case 1: name = "stretch_\(3 + frame % 4)"
        default: name = "play_\(frame % 7)"
        }

        return spriteImage(name)
            .interpolation(.none)
            .resizable()
            .frame(width: 80, height: 80)
            .colorMultiply(color)
    }

    func spriteImage(_ name: String) -> Image {
        if let path = Bundle.main.path(forResource: name, ofType: "png", inDirectory: "Sprites"),
           let nsImage = NSImage(contentsOfFile: path) {
            return Image(nsImage: nsImage)
        }
        return Image(systemName: "cat.fill")
    }

    func startFight() {
        timers.add(Timer.scheduledTimer(withTimeInterval: 0.12, repeats: true) { _ in
            frame += 1
            if fightPhase >= 2 {
                shakeOffset = CGFloat.random(in: -4...4)
            }
        })

        fightPhase = 0
        SoundManager.shared.play("hiss", volume: 0.5)

        timers.add(Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [self] _ in
            fightPhase = 1
            SoundManager.shared.randomMeow(volume: 0.5)
            withAnimation(.easeInOut(duration: 1.2)) {
                catX = screenWidth / 2 - 40
                buddyX = screenWidth / 2 + 40
            }

            timers.add(Timer.scheduledTimer(withTimeInterval: 1.3, repeats: false) { _ in
                fightPhase = 2
                SoundManager.shared.play("hiss", volume: 0.6)
                loopFight()
            })
        })
    }

    func loopFight() {
        timers.add(Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            if Bool.random() {
                SoundManager.shared.play("hiss", volume: 0.4)
            } else {
                SoundManager.shared.randomMeow(volume: 0.5)
            }

            withAnimation(.easeInOut(duration: 0.4)) {
                catX = screenWidth / 2 - CGFloat.random(in: 60...120)
                buddyX = screenWidth / 2 + CGFloat.random(in: 60...120)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                SoundManager.shared.play("hiss", volume: 0.3)
                withAnimation(.easeInOut(duration: 0.5)) {
                    catX = screenWidth / 2 - CGFloat.random(in: 20...45)
                    buddyX = screenWidth / 2 + CGFloat.random(in: 20...45)
                }
            }
        })
    }
}
