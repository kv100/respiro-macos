import SwiftUI

struct ThinkingStreamView: View {
    let text: String
    let isStreaming: Bool

    @State private var cursorVisible = true

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header
            if isStreaming {
                HStack(spacing: 5) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 11))
                    Text("AI is thinking...")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.50))
            }

            // Thinking text with cursor
            ScrollView(.vertical, showsIndicators: false) {
                HStack(alignment: .bottom, spacing: 0) {
                    formatThinkingText(text)
                        .font(.system(size: 12).italic())

                    if isStreaming {
                        Text("\u{258C}")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: "#10B981").opacity(cursorVisible ? 0.8 : 0.0))
                    }

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 80)
        }
        .padding(8)
        .background(Color(hex: "#0A1F1A").opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .onAppear {
            startCursorBlink()
        }
    }

    private func startCursorBlink() {
        guard isStreaming else { return }
        withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
            cursorVisible.toggle()
        }
    }

    /// Highlights behavioral keywords in thinking text with jade green color
    private func formatThinkingText(_ text: String) -> Text {
        let behavioralKeywords = [
            "context switch", "baseline", "deviation", "session duration",
            "fragmented attention", "focused", "normal pattern",
            "switching rate", "app switches", "notification", "accumulated",
            "behavioral", "pattern", "unusual", "typical", "above normal",
            "below normal", "elevated", "calm", "steady", "frantic"
        ]

        var result = Text("")
        let lowercased = text.lowercased()
        var lastIndex = text.startIndex

        // Find all keyword matches with their ranges
        var matches: [(range: Range<String.Index>, keyword: String)] = []
        for keyword in behavioralKeywords {
            var searchRange = text.startIndex..<text.endIndex
            while let range = lowercased.range(of: keyword, range: searchRange) {
                matches.append((range: range, keyword: keyword))
                searchRange = range.upperBound..<text.endIndex
            }
        }

        // Sort matches by position
        matches.sort { $0.range.lowerBound < $1.range.lowerBound }

        // Build attributed text with highlights
        for match in matches {
            // Skip if this match overlaps with previous
            if match.range.lowerBound < lastIndex { continue }

            // Add text before match (normal color)
            if lastIndex < match.range.lowerBound {
                let beforeText = String(text[lastIndex..<match.range.lowerBound])
                result = result + Text(beforeText)
                    .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.60))
            }

            // Add matched keyword (jade green highlight)
            let matchedText = String(text[match.range])
            result = result + Text(matchedText)
                .foregroundStyle(Color(hex: "#10B981"))
                .bold()

            lastIndex = match.range.upperBound
        }

        // Add remaining text after last match
        if lastIndex < text.endIndex {
            let remainingText = String(text[lastIndex..<text.endIndex])
            result = result + Text(remainingText)
                .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.60))
        }

        // If no matches, return plain text
        if matches.isEmpty {
            result = Text(text)
                .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.60))
        }

        return result
    }
}

#Preview("Streaming") {
    ThinkingStreamView(
        text: "I noticed 12 open browser tabs, rapid switching between apps every few seconds...",
        isStreaming: true
    )
    .frame(width: 300)
    .padding()
    .background(Color(hex: "#142823"))
}

#Preview("Complete") {
    ThinkingStreamView(
        text: "I noticed 12 open browser tabs, rapid switching between apps every few seconds, and the inbox shows 47 unread messages. The user's screen context suggests elevated cognitive load.",
        isStreaming: false
    )
    .frame(width: 300)
    .padding()
    .background(Color(hex: "#142823"))
}

#Preview("With Behavioral Keywords") {
    ThinkingStreamView(
        text: "Context switch rate of 6.2/min is above normal baseline. Session duration of 2.5 hours with fragmented attention across Slack, Xcode, and Safari. Deviation from typical pattern suggests elevated stress.",
        isStreaming: false
    )
    .frame(width: 300)
    .padding()
    .background(Color(hex: "#142823"))
}
