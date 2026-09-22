import SwiftUI

@main
struct FormaClubeApp: App {
    @State private var store = FitStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .tint(AppTheme.accent)
        }
    }
}
