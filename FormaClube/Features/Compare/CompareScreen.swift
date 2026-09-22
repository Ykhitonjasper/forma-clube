import SwiftUI

struct CompareScreen: View {
    @Environment(FitStore.self) private var store

    var body: some View {
        ScreenScaffold {
            ScreenHeader(
                title: "Compare",
                subtitle: "Two checks, and which one should change the move."
            )
            if pairs.isEmpty {
                EmptyStateCard(
                    title: "Nothing to compare",
                    message: "Save two checks first.",
                    systemImage: "rectangle.split.2x1"
                )
            } else {
                ForEach(pairs) { pair in
                    pairCard(pair)
                }
            }
        }
        .navigationTitle("Compare")
    }

    private var pairs: [ComparePair] {
        FitSeed.comparePairs.filter { store.reading($0.leftID) != nil && store.reading($0.rightID) != nil }
    }

    @ViewBuilder
    private func pairCard(_ pair: ComparePair) -> some View {
        if let left = store.reading(pair.leftID), let right = store.reading(pair.rightID) {
            SectionCard(title: pair.title, footnote: pair.reason) {
                DetailRow(label: label(left), value: left.call.title, isProminent: true)
                DetailRow(label: "Spare", value: FitFormat.signedMM(left.clearanceMM))
                DetailRow(label: label(right), value: right.call.title, isProminent: true)
                DetailRow(label: "Spare", value: FitFormat.signedMM(right.clearanceMM))
                DetailRow(label: "Gap between them", value: FitFormat.signedMM(left.clearanceMM - right.clearanceMM))
            }
        }
    }

    private func label(_ reading: FitReading) -> String {
        let piece = store.piece(reading.pieceID)?.name ?? "Piece"
        let stop = store.stop(reading.stopID)?.name ?? reading.module.title
        return "\(piece) · \(stop)"
    }
}

#Preview {
    NavigationStack { CompareScreen() }
        .environment(FitStore.preview())
}
