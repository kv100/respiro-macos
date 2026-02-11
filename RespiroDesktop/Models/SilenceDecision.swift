import Foundation

struct SilenceDecision: Identifiable, Sendable {
    let id: UUID
    let timestamp: Date
    let thinkingText: String
    let effortLevel: EffortLevel
    let detectedWeather: InnerWeather
    let signals: [String]
    let flowDuration: TimeInterval?

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        thinkingText: String,
        effortLevel: EffortLevel,
        detectedWeather: InnerWeather,
        signals: [String],
        flowDuration: TimeInterval? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.thinkingText = thinkingText
        self.effortLevel = effortLevel
        self.detectedWeather = detectedWeather
        self.signals = signals
        self.flowDuration = flowDuration
    }
}
