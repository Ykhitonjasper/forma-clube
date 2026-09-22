import SwiftUI

struct SpotScreen: View {
    var body: some View {
        ModuleCheckScreen(module: .spot)
            .navigationTitle("Floor spot")
    }
}

#Preview {
    NavigationStack { SpotScreen() }
        .environment(FitStore.preview())
}
