import SwiftUI

struct VehicleScreen: View {
    var body: some View {
        ModuleCheckScreen(module: .vehicle)
            .navigationTitle("Van opening")
    }
}

#Preview {
    NavigationStack { VehicleScreen() }
        .environment(FitStore.preview())
}
