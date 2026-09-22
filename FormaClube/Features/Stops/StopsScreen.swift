import SwiftUI

struct StopsScreen: View {
    @Environment(FitStore.self) private var store
    @State private var name = ""
    @State private var module: FitModule = .door
    @State private var primary = "800"
    @State private var secondary = "2000"
    @State private var tertiary = "15"
    @State private var added = false

    var body: some View {
        ScreenScaffold {
            if store.stops.isEmpty {
                EmptyStateCard(
                    title: "No stops yet",
                    message: "Measure a door, a corner, a stair, or the van, and keep it for the next pickup.",
                    systemImage: "door.left.hand.open"
                )
            } else {
                Text("\(store.stops.count) openings measured")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                LazyVStack(spacing: AppMetrics.contentSpacing) {
                    ForEach(store.stops) { stop in
                        NavigationLink(value: FitRoute.stop(stop.id)) {
                            stopRow(stop)
                        }
                        .buttonStyle(.plain)
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                    }
                }
                .animation(.spring(duration: 0.35), value: store.stops.map(\.id))
            }

            SectionLabel(title: "Add a stop")
            TextField("Name", text: $name)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
            ChipRow {
                ForEach(FitModule.allCases) { item in
                    FilterChip(title: item.title, isSelected: module == item) {
                        module = item
                        added = false
                    }
                }
            }
            NumberField(title: module.primaryLabel, value: $primary, unit: "mm", prompt: "0")
            NumberField(title: module.secondaryLabel, value: $secondary, unit: "mm", prompt: "0")
            NumberField(title: module.tertiaryLabel, value: $tertiary, unit: "mm", prompt: "0")
            CTAButton(title: added ? "Added" : "Add this stop", systemImage: "plus", isEnabled: canAdd && !added) {
                guard let primaryMM = FitEngine.parse(primary),
                      let secondaryMM = FitEngine.parse(secondary),
                      let tertiaryMM = FitEngine.parse(tertiary) else { return }
                let title = name.trimmingCharacters(in: .whitespacesAndNewlines)
                store.addStop(
                    name: title.isEmpty ? module.title : title,
                    module: module,
                    primary: primaryMM,
                    secondary: secondaryMM,
                    tertiary: tertiaryMM
                )
                added = true
            }
        }
        .navigationTitle("Stops")
        .navigationBarTitleDisplayMode(.large)
        .sensoryFeedback(.success, trigger: added)
    }

    private var canAdd: Bool {
        FitEngine.parse(primary) != nil && FitEngine.parse(secondary) != nil && FitEngine.parse(tertiary) != nil
    }

    private func stopRow(_ stop: RouteStop) -> some View {
        HStack(alignment: .center, spacing: AppMetrics.contentSpacing) {
            VStack(alignment: .leading, spacing: AppMetrics.tightSpacing) {
                Text(stop.name)
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)
                Text(stop.module.title)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer(minLength: AppMetrics.contentSpacing)
            Text(stop.sizeLine)
                .font(.body.monospacedDigit().weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)
        }
        .cardSurface()
    }
}

#Preview {
    NavigationStack { StopsScreen() }
        .environment(FitStore.preview())
}
