import SwiftUI

struct TurnScreen: View {
    var body: some View {
        ModuleCheckScreen(module: .turn)
            .navigationTitle("Corner")
    }
}

#Preview {
    NavigationStack { TurnScreen() }
        .environment(FitStore.preview())
}
