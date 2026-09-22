import SwiftUI

struct DoorScreen: View {
    var body: some View {
        ModuleCheckScreen(module: .door)
            .navigationTitle("Doorway")
    }
}

#Preview {
    NavigationStack { DoorScreen() }
        .environment(FitStore.preview())
}
