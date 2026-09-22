import SwiftUI

struct PieceDetailScreen: View {
    @Environment(FitStore.self) private var store
    let pieceID: String
    @State private var name = ""
    @State private var width = ""
    @State private var depth = ""
    @State private var height = ""
    @State private var used = false
    @State private var savedSize = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScreenScaffold {
            if let piece = store.piece(pieceID) {
                ScreenHeader(title: piece.name, subtitle: piece.kind)
                TextField("Name", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                if let latest = store.readings(for: piece.id).first {
                    FieldReadout(
                        label: latest.module.title,
                        value: latest.call.title,
                        context: latest.orientation,
                        note: latest.note
                    )
                }
                NumberField(title: "Width", value: $width, unit: "mm", prompt: "0")
                NumberField(title: "Depth", value: $depth, unit: "mm", prompt: "0")
                NumberField(title: "Height", value: $height, unit: "mm", prompt: "0")
                CTAButton(title: savedSize ? "Size saved" : "Save this size", emphasis: .secondary, isEnabled: !savedSize) {
                    guard var updated = store.piece(pieceID),
                          let widthMM = FitEngine.parse(width),
                          let depthMM = FitEngine.parse(depth),
                          let heightMM = FitEngine.parse(height) else { return }
                    updated.name = name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? updated.name : name.trimmingCharacters(in: .whitespacesAndNewlines)
                    updated.widthMM = widthMM
                    updated.depthMM = depthMM
                    updated.heightMM = heightMM
                    store.updatePiece(updated)
                    savedSize = true
                }
                if !piece.parts.isEmpty {
                    FilterChip(
                        title: store.partsOffIDs.contains(piece.id) ? "Parts are off" : "Parts still on",
                        isSelected: store.partsOffIDs.contains(piece.id)
                    ) {
                        withAnimation(.spring(duration: 0.35)) {
                            store.toggleParts(for: piece.id)
                        }
                    }
                    .sensoryFeedback(.selection, trigger: store.partsOffIDs)
                    SectionCard(title: "Comes off") {
                        ForEach(piece.parts) { part in
                            DetailRow(label: part.name, value: "\(part.axis.title) − \(FitFormat.mm(part.reliefMM))")
                        }
                    }
                }
                CTAButton(title: "Duplicate", systemImage: "plus.square.on.square", emphasis: .secondary) {
                    store.duplicatePiece(piece.id)
                }
                CTAButton(title: used ? "This is the piece on the route" : "Check this on the route", isEnabled: !used) {
                    store.usePiece(piece.id)
                    used = store.activePieceID == piece.id
                }
                let history = store.readings(for: piece.id)
                if !history.isEmpty {
                    SectionLabel(title: "Checks")
                    ForEach(history) { reading in
                        VStack(alignment: .leading, spacing: AppMetrics.tightSpacing) {
                            Text(store.stop(reading.stopID)?.name ?? reading.module.title)
                                .font(.headline)
                                .foregroundStyle(AppTheme.textPrimary)
                            Text("\(reading.call.title) · \(FitFormat.signedMM(reading.clearanceMM))")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.textSecondary)
                            Text(reading.note)
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                            Button("Remove this check") {
                                withAnimation(.spring(duration: 0.3)) {
                                    store.removeReading(reading.id)
                                }
                            }
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.danger)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .cardSurface()
                    }
                }
                CTAButton(title: "Remove this piece", systemImage: "trash", emphasis: .secondary) {
                    store.removePiece(piece.id)
                    dismiss()
                }
            } else {
                EmptyStateCard(title: "Piece missing", message: "It is not on this phone.", systemImage: "questionmark")
            }
        }
        .navigationTitle("Piece")
        .onAppear(perform: load)
        .animation(.spring(duration: 0.35), value: store.partsOffIDs)
        .sensoryFeedback(.success, trigger: used)
        .sensoryFeedback(.warning, trigger: store.pieces.count)
    }

    private func load() {
        guard let piece = store.piece(pieceID), width.isEmpty else { return }
        name = piece.name
        width = String(format: "%.0f", piece.widthMM)
        depth = String(format: "%.0f", piece.depthMM)
        height = String(format: "%.0f", piece.heightMM)
        used = store.activePieceID == piece.id
    }
}

#Preview {
    NavigationStack { PieceDetailScreen(pieceID: "case") }
        .environment(FitStore.preview())
}
