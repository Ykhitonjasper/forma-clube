import SwiftUI

struct CargoScreen: View {
    var body: some View {
        ModuleCheckScreen(module: .cargo)
            .navigationTitle("Cargo bay")
    }
}

#Preview {
    NavigationStack { CargoScreen() }
        .environment(FitStore.preview())
}
