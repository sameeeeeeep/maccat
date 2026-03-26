import SwiftUI

struct NeedsBarView: View {
    let label: String
    let icon: String
    let value: Double
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Text(icon)
                .font(.system(size: 14))
                .frame(width: 20)

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 65, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor)
                        .frame(width: geo.size.width * CGFloat(value / 100.0), height: 8)
                        .animation(.easeInOut(duration: 0.3), value: value)
                }
            }
            .frame(height: 8)

            Text("\(Int(value))%")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 32, alignment: .trailing)
        }
        .frame(height: 20)
    }

    var barColor: Color {
        if value < 25 {
            return .red
        } else if value < 50 {
            return .orange
        } else {
            return color
        }
    }
}
