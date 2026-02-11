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
        case .extendedExhale:
            ExtendedExhaleView()
        case .thoughtDefusion:
            ThoughtDefusionView()
        case .coherentBreathing:
            CoherentBreathingView()
        // V2: Breathing
        case .fourSevenEight:
            GenericBreathingView(practiceType: .fourSevenEight, title: "4-7-8 Breathing")
        case .bellyBreathing:
            GenericBreathingView(practiceType: .bellyBreathing, title: "Belly Breathing")
        case .alternateNostril:
            GenericBreathingView(practiceType: .alternateNostril, title: "Alternate Nostril")
        case .resonanceBreathing:
            GenericBreathingView(practiceType: .resonanceBreathing, title: "Resonance Breathing")
        // V2: Body + Mind (step-based)
        case .bodyScan:
            GenericStepPracticeView(practiceType: .bodyScan, practice: PracticeCatalog.bodyScan)
        case .progressiveRelaxation:
            GenericStepPracticeView(practiceType: .progressiveRelaxation, practice: PracticeCatalog.progressiveRelaxation)
        case .gentleStretching:
            GenericStepPracticeView(practiceType: .gentleStretching, practice: PracticeCatalog.gentleStretching)
        case .groundingFeet:
            GenericStepPracticeView(practiceType: .groundingFeet, practice: PracticeCatalog.groundingFeet)
        case .lovingKindness:
            GenericStepPracticeView(practiceType: .lovingKindness, practice: PracticeCatalog.lovingKindness)
        case .worryTime:
            GenericStepPracticeView(practiceType: .worryTime, practice: PracticeCatalog.worryTime)
        case .mindfulListening:
            GenericStepPracticeView(practiceType: .mindfulListening, practice: PracticeCatalog.mindfulListening)
        case .visualization:
            GenericStepPracticeView(practiceType: .visualization, practice: PracticeCatalog.visualization)
        }
    }
}

#Preview {
    PracticeRouterView(practiceType: .boxBreathing)
        .environment(AppState())
}
