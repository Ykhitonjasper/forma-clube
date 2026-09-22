import SwiftUI

struct ExportScreen: View {
    @Environment(FitStore.self) private var store

    var body: some View {
        ScreenScaffold {
            ScreenHeader(
                title: "Text for the driver",
                subtitle: "Copy this into a message. It is the calls for the piece on the route."
            )
            if let piece = store.activePiece {
                let message = script(for: store.measured(piece))
                SectionCard(title: piece.name) {
                    Text(message)
                        .font(.body.monospaced())
                        .foregroundStyle(AppTheme.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                ShareLink(item: message) {
                    Text("Send to the driver")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.accent)
            } else {
                EmptyStateCard(
                    title: "No piece on the route",
                    message: "Pick a piece, then come back.",
                    systemImage: "doc.text"
                )
            }
        }
        .navigationTitle("Export")
    }

    private func script(for piece: FurniturePiece) -> String {
        var lines = ["\(piece.name) — \(piece.sizeLine)"]
        let plan = store.activePlan
        let report = FitEngine.route(plan: plan, piece: piece, stops: store.stops)
        lines.append("\(plan.name): \(report.headline)")
        if !report.blockerName.isEmpty {
            lines.append("Decided by \(report.blockerName)")
        }
        for gate in report.gates {
            lines.append("\(gate.stop.name): \(gate.report.headline) (\(FitFormat.signedMM(gate.report.clearanceMM)))")
        }
        return lines.joined(separator: "\n")
    }
}

#Preview {
    NavigationStack { ExportScreen() }
        .environment(FitStore.preview())
}
