import SwiftUI

struct AppBackground: View {
    var body: some View {
        ZStack {
            AppTheme.bgBase

            LinearGradient(
                colors: [AppTheme.bgElevated.opacity(0.32), .clear],
                startPoint: .top,
                endPoint: .center
            )

            RadialGradient(
                colors: [AppTheme.backgroundGlow.opacity(0.32), .clear],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 420
            )
        }
        .ignoresSafeArea()
    }
}

#Preview {
    AppBackground()
}
