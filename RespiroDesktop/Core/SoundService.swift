import AppKit

@MainActor
final class SoundService {
    static let shared = SoundService()

    private static let soundEnabledKey = "respiro_sound_enabled"
    private static let soundDefaultSetKey = "respiro_sound_default_set"

    var isEnabled: Bool {
        get {
            // Default to true on first launch (UserDefaults.bool returns false for unset keys)
            if !UserDefaults.standard.bool(forKey: Self.soundDefaultSetKey) {
                UserDefaults.standard.set(true, forKey: Self.soundDefaultSetKey)
                UserDefaults.standard.set(true, forKey: Self.soundEnabledKey)
                return true
            }
            return UserDefaults.standard.bool(forKey: Self.soundEnabledKey)
        }
        set { UserDefaults.standard.set(newValue, forKey: Self.soundEnabledKey) }
    }

    func playNudge() {
        guard isEnabled else { return }
        NSSound(named: "Tink")?.play()
    }

    func playPracticeStart() {
        guard isEnabled else { return }
        NSSound(named: "Blow")?.play()
    }

    func playPracticeComplete() {
        guard isEnabled else { return }
        NSSound(named: "Glass")?.play()
    }

    func playPhaseChange() {
        guard isEnabled else { return }
        NSSound(named: "Tink")?.play()
    }

    func playWeatherImproved() {
        guard isEnabled else { return }
        NSSound(named: "Purr")?.play()
    }
}
