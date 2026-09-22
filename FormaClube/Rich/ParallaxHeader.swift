import SwiftUI

/// Header art that lags the scroll. Drop it at the top of a `ScreenScaffold` scroll.
struct ParallaxHeader<Content: View>: View {
    var height: CGFloat
    @ViewBuilder var content: () -> Content

    var body: some View {
        GeometryReader { geo in
            let offset = geo.frame(in: .global).minY
            content()
                .frame(width: geo.size.width, height: height + max(0, offset))
                .clipped()
                .offset(y: offset > 0 ? -offset * 0.45 : 0)
        }
        .frame(height: height)
    }
}
