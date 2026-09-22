import SwiftUI
import UIKit

/// Colors the system tab bar without replacing it.
/// The walkthrough finds tabs through the real tab bar, so this must stay a `TabView`.
enum FloatingTabChrome {
    static func apply() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = UIColor(AppTheme.bgElevated).withAlphaComponent(0.94)
        appearance.shadowColor = UIColor(AppTheme.hairline)

        let item = UITabBarItemAppearance()
        item.normal.iconColor = UIColor(AppTheme.textSecondary)
        item.normal.titleTextAttributes = [.foregroundColor: UIColor(AppTheme.textSecondary)]
        item.selected.iconColor = UIColor(AppTheme.accent)
        item.selected.titleTextAttributes = [.foregroundColor: UIColor(AppTheme.accent)]
        appearance.stackedLayoutAppearance = item
        appearance.inlineLayoutAppearance = item
        appearance.compactInlineLayoutAppearance = item

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().tintColor = UIColor(AppTheme.accent)
    }
}

struct StackedDeck<Content: View>: View {
    var count: Int
    @ViewBuilder var content: (Int) -> Content

    var body: some View {
        ZStack {
            ForEach(0..<count, id: \.self) { index in
                content(index)
                    .scaleEffect(1 - CGFloat(index) * 0.05)
                    .offset(y: CGFloat(index) * 12)
                    .zIndex(Double(count - index))
            }
        }
        .padding(.bottom, CGFloat(max(count - 1, 0)) * 12)
    }
}

private struct HeroNamespaceKey: EnvironmentKey {
    static let defaultValue: Namespace.ID? = nil
}

extension EnvironmentValues {
    var heroNamespace: Namespace.ID? {
        get { self[HeroNamespaceKey.self] }
        set { self[HeroNamespaceKey.self] = newValue }
    }
}

private struct HeroMatch<ID: Hashable>: ViewModifier {
    var id: ID
    @Environment(\.heroNamespace) private var namespace

    @ViewBuilder
    func body(content: Content) -> some View {
        if let namespace {
            content.matchedGeometryEffect(id: id, in: namespace)
        } else {
            content
        }
    }
}

extension View {
    func heroMatch<ID: Hashable>(id: ID) -> some View {
        modifier(HeroMatch(id: id))
    }
}
