import SwiftUI

struct StopDetailScreen: View {
    @Environment(FitStore.self) private var store
    let stopID: String
    @State private var primary = ""
    @State private var secondary = ""
    @State private var tertiary = ""
    @State private var saved = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScreenScaffold {
            if let stop = store.stop(stopID) {
                ScreenHeader(title: stop.name, subtitle: stop.module.title)
                Text(stop.note)
                    .font(.body)
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                NumberField(title: stop.module.primaryLabel, value: $primary, unit: "mm", prompt: "0")
                NumberField(title: stop.module.secondaryLabel, value: $secondary, unit: "mm", prompt: "0")
                NumberField(title: stop.module.tertiaryLabel, value: $tertiary, unit: "mm", prompt: "0")
                CTAButton(title: saved ? "Saved" : "Save this opening", isEnabled: !saved) {
                    guard var updated = store.stop(stopID),
                          let primaryMM = FitEngine.parse(primary),
                          let secondaryMM = FitEngine.parse(secondary),
                          let tertiaryMM = FitEngine.parse(tertiary) else { return }
                    updated.primaryMM = primaryMM
                    updated.secondaryMM = secondaryMM
                    updated.tertiaryMM = tertiaryMM
                    store.updateStop(updated)
                    saved = true
                }
                if let piece = store.activePiece {
                    let report = store.check(module: stop.module, stop: stop, piece: piece)
                    FieldReadout(
                        label: piece.name,
                        value: report.headline,
                        context: report.pose.spoken,
                        note: report.note
                    )
                }
                let related = store.readings.filter { $0.stopID == stop.id }
                if !related.isEmpty {
                    SectionLabel(title: "Checks at this stop")
                    ForEach(related) { reading in
                        DetailRow(
                            label: store.piece(reading.pieceID)?.name ?? reading.pieceID,
                            value: reading.call.title
                        )
                    }
                }
                CTAButton(title: "Remove this stop", systemImage: "trash", emphasis: .secondary) {
                    store.removeStop(stop.id)
                    dismiss()
                }
            } else {
                EmptyStateCard(title: "Stop missing", message: "That opening is not on this phone.", systemImage: "questionmark")
            }
        }
        .navigationTitle("Stop")
        .onAppear(perform: load)
        .sensoryFeedback(.success, trigger: saved)
    }

    private func load() {
        guard let stop = store.stop(stopID), primary.isEmpty else { return }
        primary = String(format: "%.0f", stop.primaryMM)
        secondary = String(format: "%.0f", stop.secondaryMM)
        tertiary = String(format: "%.0f", stop.tertiaryMM)
    }
}

#Preview {
    NavigationStack { StopDetailScreen(stopID: "seller-door") }
        .environment(FitStore.preview())
}
