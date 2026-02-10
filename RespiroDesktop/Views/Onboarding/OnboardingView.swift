import SwiftUI

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @State private var currentPage = 0

    private let totalPages = 3

    var body: some View {
        VStack(spacing: 0) {
            // Skip button
            HStack {
                Spacer()
                if currentPage < totalPages - 1 {
                    Button("Skip") {
                        completeOnboarding()
                    }
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.60))
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .frame(height: 36)

            // Page content
            TabView(selection: $currentPage) {
                pageOne.tag(0)
                pageTwo.tag(1)
                pageThree.tag(2)
            }
            .tabViewStyle(.automatic)
            .frame(maxHeight: .infinity)

            // Page dots
            HStack(spacing: 8) {
                ForEach(0..<totalPages, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? Color(hex: "#10B981") : Color(hex: "#C7E8DE").opacity(0.20))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut(duration: 0.2), value: currentPage)
                }
            }
            .padding(.bottom, 16)

            // Navigation buttons
            navigationButtons
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
        }
        .frame(width: 360, height: 480)
        .background(Color(hex: "#0A1F1A"))
    }

    // MARK: - Page 1: What is Respiro?

    private var pageOne: some View {
        VStack(spacing: 20) {
            Spacer()

            // Weather icon trio
            HStack(spacing: 20) {
                weatherIcon("sun.max", color: "#10B981")
                weatherIcon("cloud", color: "#8BA4B0")
                weatherIcon("cloud.bolt.rain", color: "#7B6B9E")
            }
            .padding(.bottom, 8)

            Text("What is Respiro?")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.92))

            VStack(spacing: 10) {
                onboardingText("Your AI stress companion that lives in the menu bar")
                onboardingText("Respiro watches your screen and detects stress patterns")
            }

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Page 2: How it works

    private var pageTwo: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "camera.viewfinder")
                .font(.system(size: 48))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color(hex: "#10B981"))
                .padding(.bottom, 8)

            Text("How it works")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.92))

            VStack(spacing: 10) {
                onboardingText("Periodic screenshots analyzed by AI (never stored)")
                onboardingText("Suggests breathing and mindfulness exercises")
                onboardingText("Learns when NOT to interrupt")
            }

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Page 3: Privacy first

    private var pageThree: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "lock.shield.fill")
                .font(.system(size: 48))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color(hex: "#10B981"))
                .padding(.bottom, 8)

            Text("Privacy first")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.92))

            VStack(spacing: 10) {
                onboardingText("Screenshots analyzed in memory, immediately deleted")
                onboardingText("No data leaves your Mac except to Claude API")
                onboardingText("You control everything")
            }

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Navigation

    private var navigationButtons: some View {
        Group {
            if currentPage < totalPages - 1 {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentPage += 1
                    }
                }) {
                    Text("Next")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(hex: "#10B981"))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            } else {
                Button(action: {
                    completeOnboarding()
                }) {
                    Text("Get Started")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(hex: "#10B981"))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.return, modifiers: [])
            }
        }
    }

    // MARK: - Helpers

    private func weatherIcon(_ symbol: String, color: String) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 32))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(Color(hex: color))
    }

    private func onboardingText(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14))
            .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.84))
            .multilineTextAlignment(.center)
    }

    private func completeOnboarding() {
        appState.isOnboardingComplete = true
        appState.showDashboard()
    }
}

#Preview {
    OnboardingView()
        .environment(AppState())
}
