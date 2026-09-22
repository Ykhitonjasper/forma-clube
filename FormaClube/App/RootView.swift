import SwiftUI

struct RootView: View {
    @Environment(FitStore.self) private var store
    @Namespace private var hero
    @State private var routePath: [FitRoute] = []
    @State private var piecesPath: [FitRoute] = []
    @State private var stopsPath: [FitRoute] = []

    var body: some View {
        @Bindable var store = store
        Group {
            if store.hasCompletedOnboarding {
                TabView(selection: $store.selectedTab) {
                    NavigationStack(path: $routePath) {
                        RouteScreen(path: $routePath)
                            .navigationDestination(for: FitRoute.self) { route in
                                FitDestination(route: route)
                            }
                    }
                    .tabItem { Label(FitTab.route.label, systemImage: FitTab.route.symbol) }
                    .tag(FitTab.route)

                    NavigationStack(path: $piecesPath) {
                        PiecesScreen()
                            .navigationDestination(for: FitRoute.self) { route in
                                FitDestination(route: route)
                            }
                    }
                    .tabItem { Label(FitTab.pieces.label, systemImage: FitTab.pieces.symbol) }
                    .tag(FitTab.pieces)

                    NavigationStack(path: $stopsPath) {
                        StopsScreen()
                            .navigationDestination(for: FitRoute.self) { route in
                                FitDestination(route: route)
                            }
                    }
                    .tabItem { Label(FitTab.stops.label, systemImage: FitTab.stops.symbol) }
                    .tag(FitTab.stops)

                    NavigationStack {
                        SettingsScreen()
                    }
                    .tabItem { Label(FitTab.settings.label, systemImage: FitTab.settings.symbol) }
                    .tag(FitTab.settings)
                }
            } else {
                OnboardingScreen()
            }
        }
        .onAppear { FloatingTabChrome.apply() }
        .environment(\.heroNamespace, hero)
    }
}

struct FitDestination: View {
    let route: FitRoute

    var body: some View {
        switch route {
        case .module(let module):
            switch module {
            case .door: DoorScreen()
            case .turn: TurnScreen()
            case .stair: StairScreen()
            case .vehicle: VehicleScreen()
            case .cargo: CargoScreen()
            case .spot: SpotScreen()
            }
        case .piece(let id):
            PieceDetailScreen(pieceID: id)
        case .stop(let id):
            StopDetailScreen(stopID: id)
        case .compare:
            CompareScreen()
        case .export:
            ExportScreen()
        case .loadPlan:
            LoadPlanScreen()
        case .forms:
            FormsScreen()
        case .handling:
            HandlingScreen()
        }
    }
}

#Preview("Intro") {
    RootView()
        .environment(FitStore())
}

#Preview("Tabs") {
    RootView()
        .environment(FitStore.preview())
}
