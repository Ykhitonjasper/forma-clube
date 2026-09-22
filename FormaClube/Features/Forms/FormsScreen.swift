import SwiftUI

struct FormsScreen: View {
    @Environment(FitStore.self) private var store
    @State private var addedID = ""

    var body: some View {
        ScreenScaffold {
            ScreenHeader(
                title: "Start from a form",
                subtitle: "A box you can edit. Feet, doors, and cushions come off when the opening is the problem."
            )
            ForEach(FitAssembly.forms) { form in
                let box = form.box()
                SectionCard(title: form.name, footnote: form.kind) {
                    DetailRow(label: "Intact", value: "\(FitFormat.mm(box.width)) × \(FitFormat.mm(box.depth)) × \(FitFormat.mm(box.height))", isProminent: true)
                    ForEach(form.members) { member in
                        DetailRow(
                            label: member.name,
                            value: member.removable ? "Can come off" : "Stays on"
                        )
                    }
                    if let door = store.stops.first(where: { $0.module == .door }) {
                        let choice = FitAssembly.choice(assembly: form, stop: door)
                        DetailRow(label: door.name, value: choice.report.headline, isProminent: true)
                        if !choice.removed.isEmpty {
                            DetailRow(label: "Off first", value: choice.removed.joined(separator: ", "))
                        }
                    }
                    CTAButton(title: addedID == form.id ? "On the route" : "Use this form", emphasis: .secondary, isEnabled: addedID != form.id) {
                        let piece = FitAssembly.piece(from: form, omitting: [])
                        store.addPiece(name: piece.name, width: piece.widthMM, depth: piece.depthMM, height: piece.heightMM)
                        if var saved = store.activePiece {
                            saved.kind = piece.kind
                            saved.parts = piece.parts
                            store.updatePiece(saved)
                        }
                        addedID = form.id
                    }
                }
            }
        }
        .navigationTitle("Forms")
        .sensoryFeedback(.success, trigger: addedID)
    }
}

#Preview {
    NavigationStack { FormsScreen() }
        .environment(FitStore.preview())
}
