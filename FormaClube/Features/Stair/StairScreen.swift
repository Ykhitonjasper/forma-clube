import SwiftUI

struct StairScreen: View {
    var body: some View {
        ModuleCheckScreen(module: .stair)
            .navigationTitle("Stairs")
    }
}

#Preview {
    NavigationStack { StairScreen() }
        .environment(FitStore.preview())
}
