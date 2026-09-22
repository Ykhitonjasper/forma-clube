import SwiftUI

struct RouteScreen: View {
    @Environment(FitStore.self) private var store
    @Binding var path: [FitRoute]

    var body: some View {
        @Bindable var store = store
        ScreenScaffold {
            ScreenHeader(
                title: "Will this piece fit the whole route?",
                subtitle: store.activePiece?.name ?? "Add a piece"
            )

            if let piece = store.activePiece {
                SectionCard {
                    DetailRow(label: "Size", value: piece.sizeLine, isProminent: true)
                    DetailRow(label: "Kind", value: piece.kind)
                    if let part = piece.parts.first {
                        DetailRow(label: part.name, value: "Comes off, \(FitFormat.mm(part.reliefMM))")
                    }
                }
            }

            ChipRow {
                ForEach(store.pieces) { piece in
                    FilterChip(title: piece.name, isSelected: store.activePieceID == piece.id) {
                        withAnimation(.spring(duration: 0.35)) {
                            store.usePiece(piece.id)
                        }
                    }
                }
            }

            if let piece = store.activePiece, !piece.parts.isEmpty {
                FilterChip(title: store.partsOffIDs.contains(piece.id) ? "Parts are off" : "Parts still on", isSelected: store.partsOffIDs.contains(piece.id)) {
                    withAnimation(.spring(duration: 0.35)) {
                        store.toggleParts(for: piece.id)
                    }
                }
                .sensoryFeedback(.selection, trigger: store.partsOffIDs)
            }

            CTAButton(title: "Start fit check", systemImage: "ruler") {
                store.revealDoor()
            }
            .accessibilityIdentifier("smoke.route.openDoor")

            if store.doorVisible, let report = store.doorReport {
                FieldReadout(
                    label: "Doorway",
                    value: report.headline,
                    unit: nil,
                    context: FitFormat.signedMM(report.clearanceMM),
                    note: report.note
                )
                .accessibilityIdentifier("smoke.door.readout")
                .transition(.move(edge: .top).combined(with: .opacity))

                if store.doorSaved {
                    Text("Doorway saved")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .accessibilityIdentifier("smoke.door.savedMark")
                } else {
                    CTAButton(title: "Save this doorway", systemImage: "square.and.arrow.down", emphasis: .secondary) {
                        store.saveDoor()
                    }
                    .accessibilityIdentifier("smoke.door.save")
                }
            }

            SectionLabel(title: "Next constriction")

            ChipRow {
                FilterChip(title: "Corner", isSelected: store.turnVisible) {
                    store.revealTurn()
                }
                .accessibilityIdentifier("smoke.route.openTurn")
            }

            if store.turnVisible, let report = store.turnReport {
                FieldReadout(
                    label: "Corner",
                    value: report.headline,
                    unit: nil,
                    context: FitFormat.signedMM(report.clearanceMM),
                    note: report.note
                )
                .accessibilityIdentifier("smoke.turn.readout")
                .transition(.move(edge: .top).combined(with: .opacity))

                if store.turnSaved {
                    Text("Corner saved")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .accessibilityIdentifier("smoke.turn.savedMark")
                } else {
                    CTAButton(title: "Save this corner", systemImage: "square.and.arrow.down", emphasis: .secondary) {
                        store.saveTurn()
                    }
                    .accessibilityIdentifier("smoke.turn.save")
                }
            }

            if let piece = store.activeMeasured {
                routeBoard(piece)
                routePlans(piece)
            }

            SectionLabel(title: "Every stop")

            ForEach(FitModule.allCases) { module in
                let stops = store.stops(for: module)
                NavigationRow(
                    title: module.title,
                    subtitle: stops.isEmpty ? "No opening saved" : stops.map(\.name).joined(separator: ", "),
                    systemImage: module.symbol,
                    action: { path.append(.module(module)) }
                )
            }

            NavigationRow(
                title: "Whole pickup in the van",
                subtitle: "Every piece, placed in the bay, and the order to carry them.",
                systemImage: "truck.box",
                action: { path.append(.loadPlan) }
            )
            NavigationRow(
                title: "Who carries it",
                subtitle: "Weight, blankets, and whether one person can take the stair.",
                systemImage: "person.2",
                action: { path.append(.handling) }
            )
            NavigationRow(
                title: "Start from a form",
                subtitle: "Sofa, table, fridge, mattress. Feet and doors come off.",
                systemImage: "cube",
                action: { path.append(.forms) }
            )
            NavigationRow(
                title: "Compare two checks",
                subtitle: "Same piece, two openings, or two pieces at one door.",
                systemImage: "rectangle.split.2x1",
                action: { path.append(.compare) }
            )
            NavigationRow(
                title: "Text for the driver",
                subtitle: "The calls, in order, as plain text.",
                systemImage: "doc.text",
                action: { path.append(.export) }
            )
        }
        .navigationTitle("Route")
        .animation(.spring(duration: 0.35), value: store.doorVisible)
        .animation(.spring(duration: 0.35), value: store.turnVisible)
        .animation(.spring(duration: 0.35), value: store.partsOffIDs)
        .animation(.spring(duration: 0.35), value: store.skippedStopIDs)
        .sensoryFeedback(.success, trigger: store.doorSaved)
        .sensoryFeedback(.success, trigger: store.turnSaved)
        .sensoryFeedback(.impact(weight: .medium), trigger: store.doorReport?.call)
        .sensoryFeedback(.impact(weight: .medium), trigger: store.turnReport?.call)
    }

    @ViewBuilder
    private func routeBoard(_ piece: FurniturePiece) -> some View {
        SectionLabel(title: "Every opening on this way")
        let plan = FitSeed.haulPlans.first { $0.id == store.activePlanID } ?? FitSeed.haulPlans[0]
        let stops = plan.stopIDs.compactMap { store.stop($0) }
        ForEach(stops) { stop in
            let skipped = store.skippedStopIDs.contains(stop.id)
            let report = store.check(module: stop.module, stop: stop, piece: piece)
            HStack(alignment: .center, spacing: AppMetrics.contentSpacing) {
                Image(systemName: stop.module.symbol)
                    .font(.title3)
                    .foregroundStyle(AppTheme.accent)
                    .symbolEffect(.bounce, value: report.call)
                VStack(alignment: .leading, spacing: AppMetrics.tightSpacing) {
                    Text(stop.name)
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(skipped ? "Skipped this trip" : report.headline)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .contentTransition(.interpolate)
                }
                Spacer(minLength: AppMetrics.contentSpacing)
                if !skipped {
                    Text(FitFormat.signedMM(report.clearanceMM))
                        .font(.body.monospacedDigit().weight(.semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .contentTransition(.numericText())
                }
                Button(skipped ? "Use" : "Skip") {
                    withAnimation(.spring(duration: 0.35)) {
                        store.toggleSkip(stop.id)
                    }
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.accent)
            }
            .cardSurface()
            .opacity(skipped ? 0.45 : 1)
        }
        CTAButton(title: "Save every stop", systemImage: "square.and.arrow.down", emphasis: .secondary) {
            store.saveActiveRoute()
        }
    }

    @ViewBuilder
    private func routePlans(_ piece: FurniturePiece) -> some View {
        SectionLabel(title: "Two ways out")
        ForEach(FitSeed.haulPlans) { plan in
            let filtered = HaulPlan(
                id: plan.id,
                name: plan.name,
                stopIDs: plan.stopIDs.filter { !store.skippedStopIDs.contains($0) }
            )
            let report = FitEngine.route(plan: filtered, piece: piece, stops: store.stops)
            SectionCard(title: plan.name) {
                DetailRow(label: "Call", value: report.headline, isProminent: true)
                DetailRow(label: "Decided by", value: report.blockerName)
            }
        }
        if FitSeed.haulPlans.count == 2 {
            let leftPlan = HaulPlan(id: FitSeed.haulPlans[0].id, name: FitSeed.haulPlans[0].name, stopIDs: FitSeed.haulPlans[0].stopIDs.filter { !store.skippedStopIDs.contains($0) })
            let rightPlan = HaulPlan(id: FitSeed.haulPlans[1].id, name: FitSeed.haulPlans[1].name, stopIDs: FitSeed.haulPlans[1].stopIDs.filter { !store.skippedStopIDs.contains($0) })
            let left = FitEngine.route(plan: leftPlan, piece: piece, stops: store.stops)
            let right = FitEngine.route(plan: rightPlan, piece: piece, stops: store.stops)
            Text(FitEngine.compareRoutes(left, right))
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    RoutePreview()
}

private struct RoutePreview: View {
    @State private var path: [FitRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            RouteScreen(path: $path)
        }
        .environment(FitStore.preview())
    }
}
