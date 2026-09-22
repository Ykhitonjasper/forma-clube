import SwiftUI

struct PiecesScreen: View {
    @Environment(FitStore.self) private var store
    @State private var name = ""
    @State private var width = "800"
    @State private var depth = "400"
    @State private var height = "700"
    @State private var added = false

    var body: some View {
        ScreenScaffold {
            if store.pieces.isEmpty {
                EmptyStateCard(
                    title: "No pieces yet",
                    message: "Enter the width, depth, and height of the thing you are about to move.",
                    systemImage: "cube"
                )
            } else {
                Text("\(store.pieces.count) pieces on this phone")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                LazyVStack(spacing: AppMetrics.contentSpacing) {
                    ForEach(store.pieces) { piece in
                        NavigationLink(value: FitRoute.piece(piece.id)) {
                            pieceRow(piece)
                        }
                        .buttonStyle(.plain)
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                    }
                }
                .animation(.spring(duration: 0.35), value: store.pieces.map(\.id))
            }

            SectionLabel(title: "Add a piece")
            TextField("Name", text: $name)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
            NumberField(title: "Width", value: $width, unit: "mm", prompt: "800")
            NumberField(title: "Depth", value: $depth, unit: "mm", prompt: "400")
            NumberField(title: "Height", value: $height, unit: "mm", prompt: "700")
            CTAButton(title: added ? "Added" : "Add this piece", systemImage: "plus", isEnabled: canAdd && !added) {
                guard let widthMM = FitEngine.parse(width),
                      let depthMM = FitEngine.parse(depth),
                      let heightMM = FitEngine.parse(height) else { return }
                let title = name.trimmingCharacters(in: .whitespacesAndNewlines)
                store.addPiece(name: title.isEmpty ? "Piece" : title, width: widthMM, depth: depthMM, height: heightMM)
                added = true
            }
        }
        .navigationTitle("Pieces")
        .navigationBarTitleDisplayMode(.large)
        .sensoryFeedback(.success, trigger: added)
    }

    private var canAdd: Bool {
        FitEngine.parse(width) != nil && FitEngine.parse(depth) != nil && FitEngine.parse(height) != nil
    }

    private func pieceRow(_ piece: FurniturePiece) -> some View {
        HStack(alignment: .center, spacing: AppMetrics.contentSpacing) {
            VStack(alignment: .leading, spacing: AppMetrics.tightSpacing) {
                Text(piece.name)
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)
                Text(piece.kind)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer(minLength: AppMetrics.contentSpacing)
            Text(piece.sizeLine)
                .font(.caption.monospacedDigit())
                .foregroundStyle(AppTheme.textPrimary)
                .multilineTextAlignment(.trailing)
        }
        .cardSurface()
    }
}

#Preview {
    NavigationStack { PiecesScreen() }
        .environment(FitStore.preview())
}
