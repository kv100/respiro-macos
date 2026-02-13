import SwiftUI

struct WeatherPickerView: View {
    @Environment(AppState.self) private var appState

    let isBefore: Bool

    private var title: String {
        isBefore ? "How are you feeling?" : "How do you feel now?"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with back button
            header
                .padding(.top, 12)
                .padding(.bottom, 8)

            // Title
            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.92))
                .padding(.bottom, 16)

            // Weather cards row
            HStack(spacing: 16) {
                ForEach(InnerWeather.allCases, id: \.self) { weather in
                    WeatherCard(
                        weather: weather,
                        isSelected: selectedWeather == weather,
                        action: { selectWeather(weather) }
                    )
                }
            }

            Spacer(minLength: 0)

            // Keyboard hint
            Text("Press 1, 2, or 3 to select")
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.40))
                .padding(.bottom, 24)
        }
        .padding(.horizontal, 16)
        .frame(width: 360, height: 480)
        .background(Color(hex: "#142823"))
        .onKeyPress(characters: .init(charactersIn: "123")) { press in
            let cases = InnerWeather.allCases
            guard let index = Int(String(press.characters.first ?? "0")),
                  index >= 1, index <= cases.count else {
                return .ignored
            }
            selectWeather(cases[index - 1])
            return .handled
        }
    }

    private var selectedWeather: InnerWeather? {
        isBefore ? appState.selectedWeatherBefore : appState.selectedWeatherAfter
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button(action: {
                if isBefore {
                    appState.showDashboard()
                } else {
                    appState.showPractice()
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .medium))
                    Text("Back")
                        .font(.system(size: 13))
                }
                .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.60))
            }
            .buttonStyle(.plain)

            Spacer()

            Text(isBefore ? "Before Practice" : "After Practice")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.92))

            Spacer()

            Color.clear.frame(width: 50)
        }
    }

    // MARK: - Actions

    private func selectWeather(_ weather: InnerWeather) {
        if isBefore {
            appState.selectedWeatherBefore = weather
            appState.showPractice()
        } else {
            appState.selectedWeatherAfter = weather
            appState.showCompletion()
        }
    }
}

// MARK: - Weather Card

struct WeatherCard: View {
    let weather: InnerWeather
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: weather.sfSymbol)
                    .font(.system(size: 32))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(iconColor)

                Text(weather.displayName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.92))
            }
            .frame(width: 96, height: 112)
            .background(isSelected ? Color(hex: "#10B981").opacity(0.08) : Color(hex: "#C7E8DE").opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color(hex: "#10B981") : Color.clear, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.easeOut(duration: 0.15), value: isHovered)
            .onHover { isHovered = $0 }
        }
        .buttonStyle(.plain)
    }

    private var iconColor: Color {
        switch weather {
        case .clear: return Color(hex: "#10B981")
        case .cloudy: return Color(hex: "#8BA4B0")
        case .stormy: return Color(hex: "#7B6B9E")
        }
    }
}

#Preview("Before") {
    WeatherPickerView(isBefore: true)
        .environment(AppState())
}

#Preview("After") {
    WeatherPickerView(isBefore: false)
        .environment(AppState())
}
