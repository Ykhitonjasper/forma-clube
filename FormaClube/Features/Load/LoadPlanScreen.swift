import SwiftUI

struct LoadPlanScreen: View {
    @Environment(FitStore.self) private var store

    var body: some View {
        ScreenScaffold {
            ScreenHeader(
                title: "Whole pickup in the van",
                subtitle: "Not one piece at a time. Everything you have saved, in the bay."
            )
            if let bay = store.stops.first(where: { $0.module == .cargo }) {
                let plan = FitPacker.pack(pieces: store.pieces, bay: bay)
                FieldReadout(
                    label: "Bay",
                    value: plan.headline,
                    context: plan.method,
                    note: FitPacker.lines(for: plan, bay: bay).joined(separator: " ")
                )
                ForEach(FitPacker.lines(for: plan, bay: bay), id: \.self) { line in
                    Text(line)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                EmptyStateCard(
                    title: "No bay measured",
                    message: "Add a cargo stop with length, width, and height.",
                    systemImage: "square.stack.3d.up"
                )
            }

            let order = FitQuestions.loadOrder(pieces: store.pieces, stops: store.stops)
            if !order.isEmpty {
                SectionLabel(title: "What to move first")
                ForEach(order) { row in
                    DetailRow(
                        label: row.name,
                        value: "\(row.call.title) · \(row.tightStop)",
                        isProminent: true
                    )
                }
                Text(FitQuestions.spareBudget(cells: FitMatrix.cells(pieces: store.pieces, stops: store.stops)))
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let piece = store.activePiece {
                SectionLabel(title: "How to carry \(piece.name)")
                let lines = FitCarry.script(piece: piece, stops: store.stops)
                ForEach(lines, id: \.self) { line in
                    Text(line)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .navigationTitle("Van plan")
    }
}

#Preview {
    NavigationStack { LoadPlanScreen() }
        .environment(FitStore.preview())
}
