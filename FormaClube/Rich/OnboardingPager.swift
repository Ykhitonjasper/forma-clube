import SwiftUI

/// Three-page intro with a slide. The button stays put so the walkthrough can tap it.
struct OnboardingPager<Content: View>: View {
    @Binding var page: Int
    var count: Int
    var advanceTitle: String
    var onAdvance: () -> Void
    @ViewBuilder var content: (Int) -> Content

    var body: some View {
        ScreenScaffold {
            ZStack {
                content(page)
                    .id(page)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        )
                    )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .animation(.spring(duration: 0.35), value: page)

            PageDots(count: count, index: page)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(alignment: .leading, spacing: AppMetrics.tightSpacing) {
                Text("Page \(page + 1) of \(count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                CTAButton(
                    title: advanceTitle,
                    systemImage: page + 1 < count ? "arrow.right" : "checkmark",
                    action: onAdvance
                )
            }
            .padding(.horizontal, AppMetrics.screenPadding)
            .padding(.bottom, AppMetrics.tightSpacing)
            .background(AppTheme.bgBase)
        }
        .sensoryFeedback(.selection, trigger: page)
    }
}

struct PageDots: View {
    var count: Int
    var index: Int

    var body: some View {
        HStack(spacing: AppMetrics.tightSpacing) {
            ForEach(0..<count, id: \.self) { dot in
                Capsule()
                    .fill(dot == index ? AppTheme.accent : AppTheme.hairline)
                    .frame(width: dot == index ? 18 : 6, height: 6)
                    .animation(.spring(duration: 0.3), value: index)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityLabel("Page \(index + 1) of \(count)")
    }
}
