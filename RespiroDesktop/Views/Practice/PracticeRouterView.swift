import SwiftUI

struct PracticeRouterView: View {
    let practiceType: PracticeType

    var body: some View {
        switch practiceType {
        case .physiologicalSigh:
            BreathingPracticeView()
        case .boxBreathing:
            BoxBreathingView()
        case .grounding:
            GroundingView()
        case .stopTechnique:
            STOPTechniqueView()
        case .selfCompassion:
            SelfCompassionView()
        }
    }
}

#Preview {
    PracticeRouterView(practiceType: .boxBreathing)
        .environment(AppState())
}
