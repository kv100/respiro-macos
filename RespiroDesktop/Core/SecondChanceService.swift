import Foundation

struct SecondChanceService: Sendable {
    /// Suggest an alternative practice when the current one didn't help enough.
    /// Returns nil if no alternative is available or weather improved.
    func suggestAlternative(
        completedPracticeID: String,
        weatherBefore: InnerWeather,
        weatherAfter: InnerWeather
    ) -> Practice? {
        // Only suggest if weather didn't improve
        guard !didImprove(before: weatherBefore, after: weatherAfter) else { return nil }

        // Find current practice category
        guard let current = PracticeCatalog.practice(for: completedPracticeID) else { return nil }

        // Pick a practice from a DIFFERENT category
        let alternatives = PracticeCatalog.all.filter {
            $0.category != current.category && $0.id != completedPracticeID
        }

        // Prefer shorter practices (user already spent time)
        return alternatives.sorted { $0.duration < $1.duration }.first
    }

    private func didImprove(before: InnerWeather, after: InnerWeather) -> Bool {
        let order: [InnerWeather: Int] = [.stormy: 0, .cloudy: 1, .clear: 2]
        return (order[after] ?? 0) > (order[before] ?? 0)
    }
}
