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

    private var currentPreferences: UserPreferences? {
        preferences.first
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            settingsHeader
                .frame(height: 52)

            Divider()
                .background(Color(hex: "#C0E0D6").opacity(0.10))

            // Scrollable settings content
            ScrollView {
                VStack(spacing: 16) {
                    activeHoursSection
                    preferencesSection
                    apiKeySection
                    aboutSection
                }
                .padding(16)
            }
            .frame(maxHeight: .infinity)
        }
        .frame(width: 360, height: 480)
        .background(Color(hex: "#0A1F1A"))
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
                .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.60))
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Settings")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.92))

            Spacer()

            Color.clear.frame(width: 50)
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Active Hours

    private var activeHoursSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: "Active Hours", icon: "clock")

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Start")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.60))

                    Picker("", selection: $activeHoursStart) {
                        ForEach(0..<24, id: \.self) { hour in
                            Text(formatHour(hour)).tag(hour)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 90)
                    .tint(Color(hex: "#10B981"))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("End")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.60))

                    Picker("", selection: $activeHoursEnd) {
                        ForEach(0..<24, id: \.self) { hour in
                            Text(formatHour(hour)).tag(hour)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 90)
                    .tint(Color(hex: "#10B981"))
                }

                Spacer()
            }
            .padding(.horizontal, 4)
        }
        .padding(12)
        .background(Color(hex: "#C7E8DE").opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Preferences

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: "Preferences", icon: "slider.horizontal.3")

            VStack(spacing: 8) {
                settingsToggle(title: "Sound", isOn: $soundEnabled)
                settingsToggle(title: "Show encouragement nudges", isOn: $showEncouragementNudges)

                HStack {
                    Text("Max practice duration")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.84))

                    Spacer()

                    Picker("", selection: $maxPracticeDuration) {
                        Text("60s").tag(60)
                        Text("90s").tag(90)
                        Text("180s").tag(180)
                    }
                    .labelsHidden()
                    .frame(width: 80)
                    .tint(Color(hex: "#10B981"))
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(12)
        .background(Color(hex: "#C7E8DE").opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - API Key

    private var apiKeySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: "API Key", icon: "key")

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
                .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.84))
                .padding(8)
                .background(Color(hex: "#C7E8DE").opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 6))

                Button {
                    isApiKeyVisible.toggle()
                } label: {
                    Image(systemName: isApiKeyVisible ? "eye.slash" : "eye")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.60))
                        .frame(width: 28, height: 28)
                        .background(Color(hex: "#C7E8DE").opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }

            Button(action: {
                if !apiKeyText.isEmpty {
                    APIKeyManager.saveAPIKey(apiKeyText)
                }
            }) {
                Text("Save Key")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(apiKeyText.isEmpty ? Color(hex: "#E0F4EE").opacity(0.30) : .white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(apiKeyText.isEmpty ? Color(hex: "#C7E8DE").opacity(0.05) : Color(hex: "#10B981"))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
            .disabled(apiKeyText.isEmpty)

            if APIKeyManager.hasAPIKey {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color(hex: "#10B981"))
                    Text("API key configured")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(hex: "#10B981"))
                }
            }
        }
        .padding(12)
        .background(Color(hex: "#C7E8DE").opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - About

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(title: "About Respiro", icon: "info.circle")

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Version")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.84))
                    Spacer()
                    Text("1.0")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.60))
                }

                HStack {
                    Text("AI Engine")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.84))
                    Spacer()
                    Text("Claude Opus 4.6")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.60))
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(12)
        .background(Color(hex: "#C7E8DE").opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Helpers

    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: "#10B981"))
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.92))
        }
    }

    private func settingsToggle(title: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(title)
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.84))
        }
        .toggleStyle(.switch)
        .tint(Color(hex: "#10B981"))
        .padding(.horizontal, 4)
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
}

#Preview {
    SettingsView()
        .environment(AppState())
        .modelContainer(for: UserPreferences.self, inMemory: true)
}
