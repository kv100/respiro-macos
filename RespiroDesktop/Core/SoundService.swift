import AppKit

@MainActor
final class SoundService {
    static let shared = SoundService()

    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "respiro_sound_enabled") }
        set { UserDefaults.standard.set(newValue, forKey: "respiro_sound_enabled") }
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

    func playWeatherImproved() {
        guard isEnabled else { return }
        NSSound(named: "Purr")?.play()
    }
}
