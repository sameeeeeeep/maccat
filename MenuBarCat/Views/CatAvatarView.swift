import SwiftUI

struct CatAvatarView: View {
    @ObservedObject var cat: CatState
    @State private var bounceOffset: CGFloat = 0
    @State private var wiggleAngle: Double = 0
    @State private var eyeBlink: Bool = false
    @State private var tailAngle: Double = -20
    @State private var tongueOut: Bool = false

    var body: some View {
        ZStack {
            switch cat.animalTheme {
            case .cat:
                catBody
                    .offset(y: bounceOffset)
                    .rotationEffect(.degrees(wiggleAngle))
            case .dog:
                dogBody
                    .offset(y: bounceOffset)
                    .rotationEffect(.degrees(wiggleAngle))
            case .bird:
                birdBody
                    .offset(y: bounceOffset)
                    .rotationEffect(.degrees(wiggleAngle))
            }
        }
        .frame(width: 120, height: 120)
        .onChange(of: cat.isAnimating) { animating in
            if animating {
                startBounce()
            }
        }
        .onAppear {
            startIdleAnimations()
        }
    }

    // MARK: - Cat Avatar

    var catBody: some View {
        ZStack {
            // Body
            Ellipse()
                .fill(cat.animalTheme.avatarBodyColor)
                .frame(width: 70, height: 50)
                .offset(y: 20)

            // Tail
            TailShape()
                .stroke(cat.animalTheme.avatarBodyColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .frame(width: 30, height: 25)
                .rotationEffect(.degrees(tailAngle), anchor: .bottomLeading)
                .offset(x: 35, y: 15)

            // Head
            Circle()
                .fill(cat.animalTheme.avatarBodyColor)
                .frame(width: 55, height: 55)
                .offset(y: -10)

            // Left ear
            EarShape()
                .fill(cat.animalTheme.avatarBodyColor)
                .frame(width: 18, height: 22)
                .offset(x: -16, y: -35)

            // Right ear
            EarShape()
                .fill(cat.animalTheme.avatarBodyColor)
                .frame(width: 18, height: 22)
                .offset(x: 16, y: -35)

            // Inner ears
            EarShape()
                .fill(Color.pink.opacity(0.5))
                .frame(width: 10, height: 12)
                .offset(x: -16, y: -33)
            EarShape()
                .fill(Color.pink.opacity(0.5))
                .frame(width: 10, height: 12)
                .offset(x: 16, y: -33)

            // Eyes
            eyesView
                .offset(y: -12)

            // Nose
            Circle()
                .fill(Color.pink)
                .frame(width: 5, height: 5)
                .offset(y: -2)

            // Mouth
            mouthView
                .offset(y: 3)

            // Whiskers
            whiskers

            // Action text
            if let text = cat.actionText {
                Text(text)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
                    .offset(y: -55)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }

    // MARK: - Dog Avatar

    var dogBody: some View {
        let bodyColor = cat.animalTheme.avatarBodyColor
        let accentColor = cat.animalTheme.avatarAccentColor
        return ZStack {
            // Body
            Ellipse()
                .fill(bodyColor)
                .frame(width: 70, height: 50)
                .offset(y: 20)

            // Tail (curly, thicker)
            DogTailShape()
                .stroke(bodyColor, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                .frame(width: 25, height: 30)
                .rotationEffect(.degrees(tailAngle), anchor: .bottomLeading)
                .offset(x: 38, y: 10)

            // Head (rounder, slightly bigger)
            Ellipse()
                .fill(bodyColor)
                .frame(width: 58, height: 55)
                .offset(y: -10)

            // Snout
            Ellipse()
                .fill(accentColor.opacity(0.6))
                .frame(width: 28, height: 20)
                .offset(y: 2)

            // Floppy left ear
            FloppyEarShape()
                .fill(accentColor)
                .frame(width: 16, height: 28)
                .rotationEffect(.degrees(-15))
                .offset(x: -24, y: -18)

            // Floppy right ear
            FloppyEarShape()
                .fill(accentColor)
                .frame(width: 16, height: 28)
                .rotationEffect(.degrees(15))
                .offset(x: 24, y: -18)

            // Eyes
            eyesView
                .offset(y: -12)

            // Nose (bigger, black)
            Ellipse()
                .fill(Color.black)
                .frame(width: 8, height: 6)
                .offset(y: -1)

            // Tongue (when happy/playing)
            if tongueOut || cat.mood == .happy || cat.mood == .playing {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.pink)
                    .frame(width: 8, height: 12)
                    .offset(x: 3, y: 10)
            }

            // Action text
            if let text = cat.actionText {
                Text(text)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
                    .offset(y: -55)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }

    // MARK: - Bird Avatar

    var birdBody: some View {
        let bodyColor = cat.animalTheme.avatarBodyColor
        let accentColor = cat.animalTheme.avatarAccentColor
        return ZStack {
            // Body (round)
            Ellipse()
                .fill(bodyColor)
                .frame(width: 55, height: 45)
                .offset(y: 15)

            // Wing
            WingShape()
                .fill(bodyColor.opacity(0.7))
                .frame(width: 30, height: 25)
                .rotationEffect(.degrees(tailAngle * 0.5))
                .offset(x: 20, y: 10)

            // Tail feathers
            EarShape()
                .fill(bodyColor.opacity(0.8))
                .frame(width: 14, height: 20)
                .rotationEffect(.degrees(150))
                .offset(x: -30, y: 20)

            // Head
            Circle()
                .fill(bodyColor)
                .frame(width: 42, height: 42)
                .offset(y: -12)

            // Beak
            EarShape()
                .fill(Color.orange)
                .frame(width: 12, height: 10)
                .rotationEffect(.degrees(90))
                .offset(x: 22, y: -5)

            // Eye
            if eyeBlink {
                Text("—").font(.system(size: 8, weight: .bold))
                    .offset(x: 5, y: -15)
            } else {
                ZStack {
                    Circle().fill(Color.white).frame(width: 12, height: 12)
                    Circle().fill(Color.black).frame(width: 6, height: 6)
                        .offset(x: 1)
                    Circle().fill(Color.white).frame(width: 2, height: 2)
                        .offset(x: 2, y: -1)
                }
                .offset(x: 5, y: -15)
            }

            // Chest marking
            Ellipse()
                .fill(accentColor.opacity(0.3))
                .frame(width: 30, height: 25)
                .offset(y: 12)

            // Feet
            HStack(spacing: 8) {
                BirdFootShape()
                    .stroke(Color.orange, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 10, height: 8)
                BirdFootShape()
                    .stroke(Color.orange, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 10, height: 8)
            }
            .offset(y: 38)

            // Action text
            if let text = cat.actionText {
                Text(text)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
                    .offset(y: -55)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }


    // MARK: - Shared Eye/Mouth Views

    @ViewBuilder
    var eyesView: some View {
        HStack(spacing: 14) {
            switch cat.mood {
            case .sleeping:
                Text("—").font(.system(size: 10, weight: .bold))
                Text("—").font(.system(size: 10, weight: .bold))
            case .happy, .playing:
                Text("◠").font(.system(size: 14))
                Text("◠").font(.system(size: 14))
            case .sad, .hungry:
                Group {
                    Circle().fill(Color.black).frame(width: 8, height: 8)
                        .overlay(
                            Circle().fill(Color.blue.opacity(0.5)).frame(width: 4, height: 4)
                                .offset(y: 6)
                        )
                    Circle().fill(Color.black).frame(width: 8, height: 8)
                        .overlay(
                            Circle().fill(Color.blue.opacity(0.5)).frame(width: 4, height: 4)
                                .offset(y: 6)
                        )
                }
            default:
                if eyeBlink {
                    Text("—").font(.system(size: 10, weight: .bold))
                    Text("—").font(.system(size: 10, weight: .bold))
                } else {
                    Circle().fill(Color.black).frame(width: 8, height: 8)
                        .overlay(Circle().fill(Color.white).frame(width: 3, height: 3).offset(x: 1, y: -1))
                    Circle().fill(Color.black).frame(width: 8, height: 8)
                        .overlay(Circle().fill(Color.white).frame(width: 3, height: 3).offset(x: 1, y: -1))
                }
            }
        }
    }

    @ViewBuilder
    var mouthView: some View {
        switch cat.mood {
        case .happy, .playing, .eating:
            Text("ω").font(.system(size: 10)).foregroundColor(.pink)
        case .sad, .hungry:
            Text("︵").font(.system(size: 8))
        default:
            Text("ω").font(.system(size: 9)).foregroundColor(.gray)
        }
    }

    var whiskers: some View {
        Group {
            WhiskerLine()
                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                .frame(width: 20, height: 1)
                .rotationEffect(.degrees(-10))
                .offset(x: -28, y: 0)
            WhiskerLine()
                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                .frame(width: 20, height: 1)
                .rotationEffect(.degrees(10))
                .offset(x: -28, y: 5)
            WhiskerLine()
                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                .frame(width: 20, height: 1)
                .rotationEffect(.degrees(10))
                .offset(x: 28, y: 0)
            WhiskerLine()
                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                .frame(width: 20, height: 1)
                .rotationEffect(.degrees(-10))
                .offset(x: 28, y: 5)
        }
    }

    // MARK: - Animations

    func startBounce() {
        withAnimation(.easeInOut(duration: 0.15).repeatCount(6, autoreverses: true)) {
            bounceOffset = -8
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            withAnimation { bounceOffset = 0 }
        }
    }

    func startIdleAnimations() {
        // Blink timer
        Timer.scheduledTimer(withTimeInterval: 3.5, repeats: true) { _ in
            eyeBlink = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                eyeBlink = false
            }
        }
        // Tail wag / tongue flick
        Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5).repeatCount(3, autoreverses: true)) {
                tailAngle = 20
            }
            // Dog tongue toggle
            if cat.animalTheme == .dog {
                tongueOut.toggle()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation { tailAngle = -20 }
            }
        }
    }
}

// MARK: - Custom Shapes

struct EarShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct TailShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY),
            control1: CGPoint(x: rect.midX, y: rect.maxY),
            control2: CGPoint(x: rect.maxX, y: rect.midY)
        )
        return path
    }
}

struct WhiskerLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}

// MARK: - Dog Shapes

struct FloppyEarShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addCurve(
            to: CGPoint(x: rect.midX, y: rect.maxY),
            control1: CGPoint(x: rect.maxX + 4, y: rect.midY * 0.5),
            control2: CGPoint(x: rect.maxX, y: rect.maxY)
        )
        path.addCurve(
            to: CGPoint(x: rect.midX, y: rect.minY),
            control1: CGPoint(x: rect.minX, y: rect.maxY),
            control2: CGPoint(x: rect.minX - 4, y: rect.midY * 0.5)
        )
        path.closeSubpath()
        return path
    }
}

struct DogTailShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY),
            control1: CGPoint(x: rect.maxX, y: rect.maxY + 10),
            control2: CGPoint(x: rect.minX, y: rect.minY - 5)
        )
        return path
    }
}

// MARK: - Bird Shapes

struct WingShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY),
            control1: CGPoint(x: rect.midX, y: rect.maxY),
            control2: CGPoint(x: rect.maxX, y: rect.midY)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX, y: rect.midY),
            control1: CGPoint(x: rect.maxX, y: rect.minY - 5),
            control2: CGPoint(x: rect.midX, y: rect.minY)
        )
        path.closeSubpath()
        return path
    }
}

struct BirdFootShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.move(to: CGPoint(x: rect.midX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.move(to: CGPoint(x: rect.midX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        return path
    }
}

