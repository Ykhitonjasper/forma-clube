import SwiftUI

struct ModuleCheckScreen: View {
    @Environment(FitStore.self) private var store
    let module: FitModule

    @State private var stopID = ""
    @State private var pieceID = ""
    @State private var inches = "mm"
    @State private var primary = ""
    @State private var secondary = ""
    @State private var tertiary = ""
    @State private var report: GateReport?
    @State private var saved = false

    var body: some View {
        ScreenScaffold {
            ScreenHeader(title: module.title, subtitle: module.prompt)

            if store.pieces.isEmpty {
                EmptyStateCard(
                    title: "No piece yet",
                    message: "Add a piece with its width, depth, and height, then come back.",
                    systemImage: "cube"
                )
            } else {
                ChipRow {
                    ForEach(store.pieces) { piece in
                        FilterChip(title: piece.name, isSelected: pieceID == piece.id) {
                            pieceID = piece.id
                            saved = false
                            report = nil
                        }
                    }
                }
            }

            if moduleStops.isEmpty {
                EmptyStateCard(
                    title: "No \(module.title.lowercased()) yet",
                    message: "Add this kind of stop from the Stops tab, with the opening you measured.",
                    systemImage: module.symbol
                )
            } else {
                ChipRow {
                    ForEach(moduleStops) { stop in
                        FilterChip(title: stop.name, isSelected: stopID == stop.id) {
                            select(stop)
                        }
                    }
                }
            }

            SegmentedPicker(
                title: "Units",
                options: [SegmentOption("Millimetres", id: "mm"), SegmentOption("Inches", id: "in")],
                selection: $inches
            )

            NumberField(
                title: module.primaryLabel,
                value: $primary,
                unit: inches,
                prompt: "0",
                help: "The clear measure, not the trim around it.",
                error: parsed(primary) == nil ? "Enter a measure greater than zero." : nil
            )
            NumberField(
                title: module.secondaryLabel,
                value: $secondary,
                unit: inches,
                prompt: "0",
                help: "The second clear measure.",
                error: parsed(secondary) == nil ? "Enter a measure greater than zero." : nil
            )
            NumberField(
                title: module.tertiaryLabel,
                value: $tertiary,
                unit: inches,
                prompt: "0",
                help: tertiaryHelp,
                error: parsed(tertiary) == nil ? "Enter a measure greater than zero." : nil
            )

            CTAButton(title: "Check \(module.title.lowercased())", systemImage: module.symbol, isEnabled: canCheck) {
                run()
            }

            if let report, let piece = selectedPiece, let stop = selectedStop {
                FieldReadout(
                    label: module.title,
                    value: report.headline,
                    unit: module == .cargo ? "fit" : nil,
                    context: context(report),
                    note: report.note
                )
                SectionCard(title: "How it is carried") {
                    DetailRow(label: "Piece", value: piece.sizeLine, isProminent: true)
                    DetailRow(label: "Stop", value: stop.sizeLine)
                    DetailRow(label: "Face", value: report.pose.spoken)
                    DetailRow(label: "Spare", value: FitFormat.signedMM(report.clearanceMM), isProminent: true)
                    if module == .cargo {
                        DetailRow(label: "Count", value: FitFormat.count(report.count))
                    }
                }
                CTAButton(
                    title: saved ? "Saved" : "Save this check",
                    systemImage: "square.and.arrow.down",
                    emphasis: .secondary,
                    isEnabled: !saved
                ) {
                    store.save(module: module, stop: stop, piece: piece, report: report)
                    saved = true
                }
            }
        }
        .onAppear(perform: loadDefaults)
        .onChange(of: inches) { _, _ in
            saved = false
        }
        .sensoryFeedback(.success, trigger: saved)
    }

    private var moduleStops: [RouteStop] {
        store.stops(for: module)
    }

    private var selectedPiece: FurniturePiece? {
        store.piece(pieceID)
    }

    private var selectedStop: RouteStop? {
        store.stop(stopID)
    }

    private var canCheck: Bool {
        selectedPiece != nil && selectedStop != nil && parsed(primary) != nil && parsed(secondary) != nil && parsed(tertiary) != nil
    }

    private var tertiaryHelp: String {
        switch module {
        case .door, .vehicle: "Subtracted from both sides of the opening before the check."
        case .turn: "The piece's height has to stay under this."
        case .stair: "Horizontal length of the flight. The long diagonal is taken from this and the headroom."
        case .cargo: "Floor to the lining, not to the outside roof."
        case .spot: "Left open so you can still walk past the piece."
        }
    }

    private func loadDefaults() {
        if pieceID.isEmpty {
            pieceID = store.activePieceID
        }
        if stopID.isEmpty, let stop = moduleStops.first {
            select(stop)
        }
    }

    private func select(_ stop: RouteStop) {
        stopID = stop.id
        primary = display(stop.primaryMM)
        secondary = display(stop.secondaryMM)
        tertiary = display(stop.tertiaryMM)
        report = nil
        saved = false
    }

    private func display(_ millimetres: Double) -> String {
        if inches == "in" {
            return String(format: "%.1f", millimetres / 25.4)
        }
        return String(format: "%.0f", millimetres.rounded())
    }

    private func parsed(_ text: String) -> Double? {
        FitEngine.millimetres(from: text, inches: inches == "in")
    }

    private func run() {
        guard var stop = selectedStop, let piece = selectedPiece,
              let primaryMM = parsed(primary),
              let secondaryMM = parsed(secondary),
              let tertiaryMM = parsed(tertiary) else { return }
        stop.primaryMM = primaryMM
        stop.secondaryMM = secondaryMM
        stop.tertiaryMM = tertiaryMM
        store.updateStop(stop)
        report = store.check(module: module, stop: stop, piece: piece)
        saved = false
    }

    private func context(_ report: GateReport) -> String {
        if module == .cargo {
            return "\(report.count) in the bay · \(FitFormat.signedMM(report.clearanceMM))"
        }
        return FitFormat.signedMM(report.clearanceMM)
    }
}

#Preview {
    NavigationStack { ModuleCheckScreen(module: .door) }
        .environment(FitStore.preview())
}
