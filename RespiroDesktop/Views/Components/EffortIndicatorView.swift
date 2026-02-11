import SwiftUI

struct EffortIndicatorView: View {
    let level: EffortLevel

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 11))
                .foregroundStyle(accentColor)

            HStack(spacing: 2) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(index < filledDots ? accentColor : accentColor.opacity(0.2))
                        .frame(width: 5, height: 5)
                }
            }

            Text(level.displayName)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(accentColor)
        }
    }

    private var filledDots: Int {
        switch level {
        case .low:  return 1
        case .high: return 2
        case .max:  return 3
        }
    }

    private var accentColor: Color {
        switch level {
        case .low:  return Color(hex: "#E0F4EE").opacity(0.60)
        case .high: return Color(hex: "#10B981")
        case .max:  return Color(hex: "#D4AF37")
        }
    }
}

#Preview("Effort Levels") {
    VStack(spacing: 12) {
        EffortIndicatorView(level: .low)
        EffortIndicatorView(level: .high)
        EffortIndicatorView(level: .max)
    }
    .padding()
    .background(Color(hex: "#0A1F1A"))
}
