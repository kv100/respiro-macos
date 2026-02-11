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
                    Text(text)
                        .font(.system(size: 12).italic())
                        .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.60))

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
