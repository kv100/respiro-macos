import SwiftUI

struct PracticeLibraryView: View {
    @Environment(AppState.self) private var appState

    // Group practices by category
    private var breathingPractices: [Practice] {
        PracticeCatalog.all.filter { $0.category == .breathing }
    }
    private var bodyPractices: [Practice] {
        PracticeCatalog.all.filter { $0.category == .body }
    }
    private var mindPractices: [Practice] {
        PracticeCatalog.all.filter { $0.category == .mind }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
                .padding(.top, 8)
                .padding(.horizontal, 16)

            Divider()
                .background(Color(hex: "#C0E0D6").opacity(0.10))
                .padding(.top, 6)

            // Scrollable content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    categorySection(title: "Breathing", icon: "wind", practices: breathingPractices)
                    categorySection(title: "Body", icon: "figure.mind.and.body", practices: bodyPractices)
                    categorySection(title: "Mind", icon: "brain.head.profile", practices: mindPractices)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
        }
        .frame(width: 360, height: 480)
        .background(Color(hex: "#142823"))
    }

    // Header with back button
    private var header: some View {
        HStack {
            Button(action: { appState.showDashboard() }) {
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

            Text("Practice Library")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.92))

            Spacer()

            Color.clear.frame(width: 50)
        }
    }

    // Category section with grid of practice cards
    @ViewBuilder
    private func categorySection(title: String, icon: String, practices: [Practice]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Category header
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "#10B981"))
                Text("\(title)")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.92))
                Text("(\(practices.count))")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.50))
            }

            // 2-column grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10)
            ], spacing: 10) {
                ForEach(practices, id: \.id) { practice in
                    practiceCard(practice)
                }
            }
        }
    }

    // Individual practice card - tapping starts the practice
    private func practiceCard(_ practice: Practice) -> some View {
        Button {
            appState.selectedPracticeID = practice.id
            appState.lastPracticeCategory = practice.category
            appState.cameFromPracticeLibrary = true
            appState.showWeatherBefore()
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text(practice.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.92))
                    .lineLimit(1)

                Text(formatDuration(practice.duration))
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.50))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(hex: "#C7E8DE").opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        if secs == 0 {
            return "\(minutes) min"
        }
        return "\(minutes):\(String(format: "%02d", secs))"
    }
}

#Preview {
    PracticeLibraryView()
        .environment(AppState())
}
