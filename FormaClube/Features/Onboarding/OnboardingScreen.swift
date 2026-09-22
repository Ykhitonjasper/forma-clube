import SwiftUI

struct OnboardingScreen: View {
    @Environment(FitStore.self) private var store
    @State private var page = 0

    var body: some View {
        OnboardingPager(
            page: $page,
            count: 3,
            advanceTitle: page < 2 ? "Next" : "Get started",
            onAdvance: advance
        ) { index in
            pageBody(index)
        }
        .sensoryFeedback(.success, trigger: store.hasCompletedOnboarding)
    }

    @ViewBuilder
    private func pageBody(_ index: Int) -> some View {
        switch index {
        case 0:
            VStack(alignment: .leading, spacing: AppMetrics.sectionSpacing) {
                ScreenHeader(
                    title: "Will it fit the way out?",
                    subtitle: "Measure the piece, then every opening between it and the van."
                )
                SectionCard(title: "One pickup") {
                    DetailRow(label: "Piece", value: "Width, depth, height", isProminent: true)
                    DetailRow(label: "Stops", value: "Door, corner, stair, van")
                    DetailRow(label: "Call", value: "Load, turn, take apart, or leave")
                }
                Text("The answer is for the piece in front of you, against openings you measured.")
                    .font(.body)
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        case 1:
            VStack(alignment: .leading, spacing: AppMetrics.sectionSpacing) {
                ScreenHeader(
                    title: "Measure a stop once",
                    subtitle: "The van and the storage bay stay on the phone for the next pickup."
                )
                SectionCard {
                    DetailRow(label: "Seller door", value: "810 × 2030 mm")
                    DetailRow(label: "Front stair", value: "820 mm wide")
                    DetailRow(label: "Van rear", value: "1220 × 1480 mm")
                }
            }
        default:
            VStack(alignment: .leading, spacing: AppMetrics.sectionSpacing) {
                ScreenHeader(
                    title: "Stored on this phone",
                    subtitle: "Nothing is uploaded."
                )
                SectionCard(title: "What stays here") {
                    DetailRow(label: "Pieces", value: "Sizes you entered")
                    DetailRow(label: "Stops", value: "Openings you measured")
                    DetailRow(label: "Wipe", value: "From Settings")
                }
            }
        }
    }

    private func advance() {
        if page < 2 {
            page += 1
        } else {
            store.completeOnboarding()
        }
    }
}

#Preview {
    OnboardingScreen()
        .environment(FitStore())
}
