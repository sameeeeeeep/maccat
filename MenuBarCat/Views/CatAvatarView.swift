import SwiftUI

struct CatAvatarView: View {
    @ObservedObject var cat: CatState
    @State private var bounceOffset: CGFloat = 0
    @State private var wiggleAngle: Double = 0
    @State private var eyeBlink: Bool = false
    @State private var tailAngle: Double = -20

    var body: some View {
        ZStack {
            catBody
                .offset(y: bounceOffset)
                .rotationEffect(.degrees(wiggleAngle))
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

    var catBody: some View {
        ZStack {
            // Body
            Ellipse()
                .fill(catColor)
                .frame(width: 70, height: 50)
                .offset(y: 20)

            // Tail
            TailShape()
                .stroke(catColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .frame(width: 30, height: 25)
                .rotationEffect(.degrees(tailAngle), anchor: .bottomLeading)
                .offset(x: 35, y: 15)

            // Head
            Circle()
                .fill(catColor)
                .frame(width: 55, height: 55)
                .offset(y: -10)

            // Left ear
            EarShape()
                .fill(catColor)
                .frame(width: 18, height: 22)
                .offset(x: -16, y: -35)

            // Right ear
            EarShape()
                .fill(catColor)
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

    var catColor: Color {
        Color.orange
    }

    @ViewBuilder
    var eyesView: some View {
        HStack(spacing: 14) {
            switch cat.mood {
            case .sleeping:
                // Closed eyes
                Text("—").font(.system(size: 10, weight: .bold))
                Text("—").font(.system(size: 10, weight: .bold))
            case .happy, .playing:
                // Happy squint eyes
                Text("◠").font(.system(size: 14))
                Text("◠").font(.system(size: 14))
            case .sad, .hungry:
                // Sad eyes
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
                // Normal eyes with blink
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
            // Left whiskers
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
            // Right whiskers
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
        // Tail wag
        Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5).repeatCount(3, autoreverses: true)) {
                tailAngle = 20
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
