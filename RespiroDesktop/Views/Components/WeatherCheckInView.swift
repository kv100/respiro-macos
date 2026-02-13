import SwiftUI

struct WeatherCheckInView: View {
    var onSelect: (InnerWeather) -> Void
    var onSkip: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "hand.wave")
                    .font(.system(size: 28))
                    .foregroundStyle(Color(hex: "#10B981"))

                Text("How are you feeling?")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.92))

                Text("Quick check-in before we start")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.60))

                HStack(spacing: 20) {
                    weatherButton(weather: .clear, icon: "sun.max.fill", label: "Good", color: "#10B981")
                    weatherButton(weather: .cloudy, icon: "cloud.fill", label: "Meh", color: "#8BA4B0")
                    weatherButton(weather: .stormy, icon: "cloud.bolt.rain.fill", label: "Rough", color: "#7B6B9E")
                }
                .padding(.top, 8)

                Button("Skip") {
                    onSkip()
                }
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.40))
                .buttonStyle(.plain)
                .padding(.top, 4)
            }

            Spacer()
        }
        .frame(width: 320, height: 260)
        .background(Color(hex: "#0A1F1A"))
        .preferredColorScheme(.dark)
    }

    private func weatherButton(weather: InnerWeather, icon: String, label: String, color: String) -> some View {
        Button {
            onSelect(weather)
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                Text(label)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(Color(hex: color))
            .frame(width: 80, height: 80)
            .background(Color(hex: color).opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    WeatherCheckInView(
        onSelect: { _ in },
        onSkip: {}
    )
}
