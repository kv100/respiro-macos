import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query private var preferences: [UserPreferences]

    @State private var activeHoursStart: Int = 9
    @State private var activeHoursEnd: Int = 18
    @State private var soundEnabled: Bool = true
    @State private var showEncouragementNudges: Bool = true
    @State private var maxPracticeDuration: Int = 90
    @State private var apiKeyText: String = ""
    @State private var isApiKeyVisible: Bool = false
    @State private var hasLoaded: Bool = false
    @State private var showSavedIndicator: Bool = false

    private var currentPreferences: UserPreferences? {
        preferences.first
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            settingsHeader
                .frame(height: 52)

            Divider()
                .background(Color.white.opacity(0.06))

            // Scrollable settings content - INVISIBLE scroll
            ScrollView {
                VStack(spacing: 0) {
                    demoModeSection
                    sectionDivider

                    activeHoursSection
                    sectionDivider

                    preferencesSection
                    sectionDivider

                    apiKeySection
                    sectionDivider

                    aboutSection
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 20)
            }
            .scrollIndicators(.never) // INVISIBLE
            .frame(maxHeight: .infinity)
        }
        .frame(width: 360, height: 480)
        .background(Color(hex: "#142823"))
        .preferredColorScheme(.dark)
        .onAppear {
            loadPreferences()
        }
    }

    // MARK: - Header

    private var settingsHeader: some View {
        HStack {
            Button(action: {
                savePreferences()
                appState.showDashboard()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .medium))
                    Text("Back")
                        .font(.system(size: 13))
                }
                .foregroundStyle(Color.white.opacity(0.60))
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Settings")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.92))

            Spacer()

            Color.clear.frame(width: 50)
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Section Divider

    private var sectionDivider: some View {
        Divider()
            .background(Color.white.opacity(0.06))
            .padding(.vertical, 20)
    }

    // MARK: - Demo Mode

    private var demoModeSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "DEMO MODE", icon: "theatermasks")

            HStack {
                Text("Demo Mode")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.white.opacity(0.92))

                Spacer()

                Toggle("", isOn: Binding(
                    get: { appState.isDemoMode },
                    set: { newValue in
                        Task {
                            await appState.setDemoMode(newValue, modelContext: modelContext)
                        }
                    }
                ))
                .labelsHidden()
                .toggleStyle(.switch)
                .tint(Color(hex: "#10B981"))
            }

            Text("Simulates stress detection without API key. Uses pre-recorded scenarios for testing and demos.")
                .font(.system(size: 11))
                .foregroundStyle(Color.white.opacity(0.45))

            if appState.isDemoMode {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color(hex: "#10B981"))
                    Text("Using simulated responses")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(hex: "#10B981"))
                }
            }
        }
    }

    // MARK: - Active Hours

    private var activeHoursSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "ACTIVE HOURS", icon: "clock")

            HStack {
                Text("Start")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.white.opacity(0.92))

                Spacer()

                hourPickerButton(hour: $activeHoursStart)
            }

            HStack {
                Text("End")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.white.opacity(0.92))

                Spacer()

                hourPickerButton(hour: $activeHoursEnd)
            }
        }
    }

    // MARK: - Preferences

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "PREFERENCES", icon: "slider.horizontal.3")

            // Sound
            HStack {
                Text("Sound")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.white.opacity(0.92))

                Spacer()

                Toggle("", isOn: Binding(
                    get: { SoundService.shared.isEnabled },
                    set: { SoundService.shared.isEnabled = $0 }
                ))
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .tint(Color(hex: "#10B981"))
            }

            // Show encouragement nudges
            HStack {
                Text("Show encouragement nudges")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.white.opacity(0.92))

                Spacer()

                Toggle("", isOn: $showEncouragementNudges)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .tint(Color(hex: "#10B981"))
            }

            // Max practice duration - RIGHT-aligned pills
            HStack {
                Text("Max practice duration")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.white.opacity(0.92))

                Spacer()

                HStack(spacing: 6) {
                    ForEach([60, 90, 180], id: \.self) { duration in
                        Button(action: { maxPracticeDuration = duration }) {
                            Text(duration == 180 ? "3m" : "\(duration)s")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(maxPracticeDuration == duration ? .white : Color.white.opacity(0.50))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(maxPracticeDuration == duration ? Color(hex: "#10B981") : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - API Key

    private var apiKeySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "API KEY", icon: "key")

            HStack(spacing: 8) {
                Group {
                    if isApiKeyVisible {
                        TextField("sk-ant-...", text: $apiKeyText)
                    } else {
                        SecureField("sk-ant-...", text: $apiKeyText)
                    }
                }
                .textFieldStyle(.plain)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.92))
                .padding(8)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .onSubmit {
                    saveAPIKey()
                }

                // Eye toggle
                Button {
                    isApiKeyVisible.toggle()
                } label: {
                    Image(systemName: isApiKeyVisible ? "eye.slash" : "eye")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.white.opacity(0.60))
                        .frame(width: 28, height: 28)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)

                // Save icon button
                Button {
                    saveAPIKey()
                } label: {
                    Image(systemName: showSavedIndicator ? "checkmark" : "square.and.arrow.down")
                        .font(.system(size: 12))
                        .foregroundStyle(showSavedIndicator ? Color(hex: "#10B981") : Color.white.opacity(0.60))
                        .frame(width: 28, height: 28)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .disabled(apiKeyText.isEmpty)
            }

            if APIKeyManager.hasAPIKey {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color(hex: "#10B981"))
                    Text("API key configured")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.white.opacity(0.70))
                }
            }
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "ABOUT RESPIRO", icon: "info.circle")

            Text("Your AI-powered stress coach, living quietly in the menu bar.")
                .font(.system(size: 12))
                .foregroundStyle(Color.white.opacity(0.60))
                .fixedSize(horizontal: false, vertical: true)

            aboutRow(label: "Version", value: "1.0")
            aboutRow(label: "AI Engine", value: "Claude Opus 4.6")

            HStack(spacing: 6) {
                Image(systemName: "apple.logo")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.white.opacity(0.45))
                Text("Also available on iOS")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.white.opacity(0.60))
            }

            HStack(spacing: 6) {
                Image(systemName: "hammer")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.white.opacity(0.45))
                Text("Built with Opus 4.6 Hackathon \u{2014} Feb 2026")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.white.opacity(0.60))
            }

            HStack(spacing: 6) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: "#10B981").opacity(0.70))
                Text("Screenshots analyzed in memory only. Never stored to disk.")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.white.opacity(0.60))
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 6) {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.white.opacity(0.35))
                Text("Open Source on GitHub")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.white.opacity(0.35))
            }
        }
    }

    private func aboutRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(Color.white.opacity(0.70))
            Spacer()
            Text(value)
                .font(.system(size: 13))
                .foregroundStyle(Color.white.opacity(0.45))
        }
    }

    // MARK: - Helpers

    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(Color(hex: "#10B981"))
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .tracking(0.5)
                .foregroundStyle(Color.white.opacity(0.92))
        }
    }

    private func hourPickerButton(hour: Binding<Int>) -> some View {
        Menu {
            ForEach(0..<24, id: \.self) { h in
                Button(formatHour(h)) {
                    hour.wrappedValue = h
                }
            }
        } label: {
            Text(formatHour(hour.wrappedValue))
                .font(.system(size: 13))
                .foregroundStyle(Color.white.opacity(0.92))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .menuStyle(.borderlessButton)
        .buttonStyle(.plain)
    }

    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        var components = DateComponents()
        components.hour = hour
        let date = Calendar.current.date(from: components) ?? Date()
        return formatter.string(from: date)
    }

    // MARK: - Persistence

    private func loadPreferences() {
        guard !hasLoaded else { return }
        hasLoaded = true

        if let prefs = currentPreferences {
            activeHoursStart = prefs.activeHoursStart
            activeHoursEnd = prefs.activeHoursEnd
            soundEnabled = prefs.soundEnabled
            showEncouragementNudges = prefs.showEncouragementNudges
            maxPracticeDuration = prefs.maxPracticeDuration
        }

        // Load saved API key (show masked placeholder, not actual key)
        if let key = APIKeyManager.getAPIKey(), !key.isEmpty {
            apiKeyText = key
        }
    }

    private func savePreferences() {
        let prefs: UserPreferences
        if let existing = currentPreferences {
            prefs = existing
        } else {
            prefs = UserPreferences()
            modelContext.insert(prefs)
        }

        prefs.activeHoursStart = activeHoursStart
        prefs.activeHoursEnd = activeHoursEnd
        prefs.soundEnabled = soundEnabled
        prefs.showEncouragementNudges = showEncouragementNudges
        prefs.maxPracticeDuration = maxPracticeDuration

        try? modelContext.save()
    }

    private func saveAPIKey() {
        guard !apiKeyText.isEmpty else { return }
        APIKeyManager.saveAPIKey(apiKeyText)

        // Show brief "saved" indicator
        withAnimation {
            showSavedIndicator = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showSavedIndicator = false
            }
        }
    }
}

#Preview {
    SettingsView()
        .environment(AppState())
        .modelContainer(for: UserPreferences.self, inMemory: true)
}
