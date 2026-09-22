import SwiftUI

struct HandlingScreen: View {
    @Environment(FitStore.self) private var store
    @State private var stock: Stock = .pine
    @State private var blankets = 1

    var body: some View {
        ScreenScaffold {
            ScreenHeader(
                title: "Who carries it",
                subtitle: "The opening can be fine and the piece still too heavy for one person on the stair."
            )
            if store.pieces.isEmpty {
                EmptyStateCard(
                    title: "No piece yet",
                    message: "Add a piece before asking how many people it takes.",
                    systemImage: "person"
                )
            } else if let piece = store.activePiece {
                ChipRow {
                    ForEach(store.pieces) { item in
                        FilterChip(title: item.name, isSelected: store.activePieceID == item.id) {
                            store.usePiece(item.id)
                        }
                    }
                }
                ChipRow {
                    ForEach(Stock.allCases) { item in
                        FilterChip(title: item.title, isSelected: stock == item) {
                            stock = item
                        }
                    }
                }
                Stepper(value: $blankets, in: 0...6) {
                    Text(blankets == 0 ? "No blanket" : "\(blankets) blanket\(blankets == 1 ? "" : "s")")
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                }
                let door = store.stops.first { $0.module == .door }
                let brief = FitHandling.brief(piece: piece, stock: stock, blankets: blankets, stop: door)
                FieldReadout(
                    label: "Carry",
                    value: brief.call,
                    unit: "people",
                    context: FitHandling.mass(brief.kilograms),
                    note: brief.note
                )
                SectionCard(title: "On the tape") {
                    DetailRow(label: "Bare", value: piece.sizeLine, isProminent: true)
                    DetailRow(label: "With blankets", value: "\(FitFormat.mm(brief.wrapped.width)) × \(FitFormat.mm(brief.wrapped.depth)) × \(FitFormat.mm(brief.wrapped.height))")
                    DetailRow(label: "People", value: "\(brief.people)")
                    if let door {
                        DetailRow(label: "Blankets that still fit \(door.name)", value: "\(FitQuestions.blanketLimit(piece: piece, stop: door, stock: stock))")
                    }
                    DetailRow(label: "Width on a tape", value: FitQuestions.tape(piece.widthMM))
                }
                if let door {
                    let worth = FitQuestions.partWorth(piece: piece, stop: door)
                    if !worth.isEmpty {
                        SectionLabel(title: "What coming off is worth at \(door.name)")
                        ForEach(worth) { row in
                            DetailRow(
                                label: row.part.name,
                                value: "\(row.callBefore.title) → \(row.callAfter.title)"
                            )
                        }
                    }
                }
            }
        }
        .navigationTitle("Carry")
    }
}

#Preview {
    NavigationStack { HandlingScreen() }
        .environment(FitStore.preview())
}
