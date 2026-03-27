import SwiftUI

struct CatPopoverView: View {
    @ObservedObject var cat: CatState
    @State private var isEditingName = false
    @State private var editedName = ""

    var body: some View {
        VStack(spacing: 12) {
            // Header with name + mood
            HStack {
                if isEditingName {
                    TextField("Name", text: $editedName, onCommit: {
                        cat.name = editedName
                        isEditingName = false
                    })
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
                } else {
                    Text(cat.name)
                        .font(.system(size: 16, weight: .bold))
                        .onTapGesture {
                            editedName = cat.name
                            isEditingName = true
                        }
                }

                Spacer()

                Text(cat.animalTheme.moodEmoji(for: cat.mood) + " " + cat.mood.rawValue)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule().fill(moodBadgeColor.opacity(0.15))
                    )
            }
            .padding(.horizontal, 4)

            // Cat avatar
            CatAvatarView(cat: cat)
                .frame(height: 130)

            Divider()

            // Need bars
            VStack(spacing: 6) {
                NeedsBarView(label: "Hunger", icon: cat.animalTheme.hungerIcon, value: cat.hunger, color: .green)
                NeedsBarView(label: "Happiness", icon: "💖", value: cat.happiness, color: .pink)
                NeedsBarView(label: "Energy", icon: "⚡", value: cat.energy, color: .blue)
            }

            Divider()

            // Action buttons
            HStack(spacing: 10) {
                ActionButton(title: "Feed", icon: "🐟", color: .green) {
                    cat.feed()
                }
                ActionButton(title: "Play", icon: "🧶", color: .orange) {
                    cat.play()
                }
                ActionButton(title: "Pet", icon: "🤚", color: .pink) {
                    cat.pet()
                }
                ActionButton(title: "Nap", icon: "💤", color: .blue) {
                    cat.nap()
                }
            }

            Divider()

            // Footer
            HStack {
                if cat.needsAttention {
                    Text("Your cat needs attention!")
                        .font(.system(size: 10))
                        .foregroundColor(.red)
                }
                Spacer()
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .frame(width: 280)
    }

    var moodBadgeColor: Color {
        switch cat.mood {
        case .happy, .playing: return .green
        case .content, .eating: return .blue
        case .hungry, .sad: return .red
        case .tired, .sleeping: return .purple
        }
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            isPressed = true
            action()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                isPressed = false
            }
        }) {
            VStack(spacing: 4) {
                Text(icon)
                    .font(.system(size: 20))
                    .scaleEffect(isPressed ? 1.3 : 1.0)
                    .animation(.spring(response: 0.2, dampingFraction: 0.5), value: isPressed)
                Text(title)
                    .font(.system(size: 10, weight: .medium))
            }
            .frame(width: 52, height: 48)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(isPressed ? 0.25 : 0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
