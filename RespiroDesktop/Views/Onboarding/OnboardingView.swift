import SwiftUI
import ScreenCaptureKit

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @State private var currentPage = 0
    @State private var permissionGranted = false
    @State private var permissionRequested = false

    private let totalPages = 3

    var body: some View {
        ZStack {
            Color(hex: "#142823")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    if currentPage < totalPages - 1 {
                        Button("Skip") {
                            completeOnboarding()
                        }
                        .font(.system(size: 13))
                        .foregroundStyle(Color.white.opacity(0.60))
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .frame(height: 36)

                // Page content (no TabView — manual switching)
                Group {
                    switch currentPage {
                    case 0: pageOne
                    case 1: pageTwo
                    default: pageThree
                    }
                }
                .frame(maxHeight: .infinity)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.3), value: currentPage)

                // Page dots
                HStack(spacing: 8) {
                    ForEach(0..<totalPages, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color(hex: "#10B981") : Color.white.opacity(0.20))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom, 16)

                // Navigation buttons
                navigationButtons
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
            }
        }
        .frame(width: 420, height: 560)
    }

    // MARK: - Page 1: What is Respiro?

    private var pageOne: some View {
        VStack(spacing: 20) {
            Spacer()

            HStack(spacing: 20) {
                weatherIcon("sun.max", color: Color(hex: "#10B981"))
                weatherIcon("cloud", color: Color(hex: "#8BA4B0"))
                weatherIcon("cloud.bolt.rain", color: Color(hex: "#7B6B9E"))
            }
            .padding(.bottom, 8)

            Text("What is Respiro?")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.white)

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
                .foregroundStyle(Color(hex: "#10B981"))
                .padding(.bottom, 8)

            Text("How it works")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.white)

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
                .foregroundStyle(Color(hex: "#10B981"))
                .padding(.bottom, 8)

            Text("Privacy first")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.white)

            VStack(spacing: 10) {
                onboardingText("Screenshots analyzed in memory, immediately deleted")
                onboardingText("No data leaves your Mac except to Claude API")
                onboardingText("You control everything")
            }

            // Screen Recording Permission Button
            Button(action: {
                requestScreenRecordingPermission()
            }) {
                HStack(spacing: 8) {
                    if permissionGranted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color(hex: "#10B981"))
                    } else {
                        Image(systemName: "rectangle.dashed.badge.record")
                            .foregroundStyle(Color.white.opacity(0.80))
                    }
                    Text(permissionGranted ? "Permission Granted" : "Enable Screen Recording")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(permissionGranted ? Color(hex: "#10B981") : Color.white.opacity(0.80))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(permissionGranted ? Color(hex: "#10B981") : Color.white.opacity(0.30), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(permissionGranted)

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private func requestScreenRecordingPermission() {
        permissionRequested = true
        Task.detached {
            do {
                _ = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
                await MainActor.run { permissionGranted = true }
            } catch {
                // Permission denied or not yet granted — expected
            }
        }
    }

    // MARK: - Navigation

    private var navigationButtons: some View {
        Group {
            if currentPage < totalPages - 1 {
                Button(action: {
                    withAnimation { currentPage += 1 }
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

    private func weatherIcon(_ symbol: String, color: Color) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 32))
            .foregroundStyle(color)
    }

    private func onboardingText(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14))
            .foregroundStyle(Color.white.opacity(0.80))
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
