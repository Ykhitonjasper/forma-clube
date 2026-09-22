import Foundation

struct FaceRow: Identifiable, Hashable {
    var id: String { "\(pose.up.rawValue)-\(pose.across.rawValue)" }
    var pose: Pose
    var fits: Bool
    var clearanceMM: Double
    var holding: Bool
}

struct OpeningNeed: Hashable {
    var widthMM: Double
    var heightMM: Double
    var pose: Pose
    var note: String
}

struct PartWorth: Identifiable, Hashable {
    var id: String { part.id }
    var part: RemovablePart
    var clearanceGainMM: Double
    var callBefore: MoveCall
    var callAfter: MoveCall
}

struct LoadOrder: Identifiable, Hashable {
    var id: String { pieceID }
    var pieceID: String
    var name: String
    var tightStop: String
    var clearanceMM: Double
    var call: MoveCall
}

enum FitQuestions {
    static func faces(box: FitBox, stop: RouteStop, parts: [RemovablePart]) -> [FaceRow] {
        let winning = FitEngine.gate(module: stop.module, box: box, stop: stop, parts: parts)
        return FitEngine.poses(of: box).map { pose in
            let clearance = clearance(pose: pose, stop: stop)
            let fits = fits(pose: pose, stop: stop)
            return FaceRow(
                pose: pose,
                fits: fits,
                clearanceMM: clearance,
                holding: pose.spoken == winning.pose.spoken && winning.fits
            )
        }
    }

    static func openingNeeded(box: FitBox, margin: Double) -> OpeningNeed {
        var best: (Double, Pose)?
        var bestArea = Double.greatestFiniteMagnitude
        for pose in FitEngine.poses(of: box) {
            let width = pose.acrossMM + margin
            let height = pose.upMM + margin
            let area = width * height
            if area < bestArea {
                bestArea = area
                best = (area, pose)
            }
        }
        let pose = best?.1 ?? Pose(up: .height, across: .width, travel: .depth, upMM: box.height, acrossMM: box.width, travelMM: box.depth)
        let width = pose.acrossMM + margin
        let height = pose.upMM + margin
        return OpeningNeed(
            widthMM: width,
            heightMM: height,
            pose: pose,
            note: "The smallest opening that takes this box, with \(FitFormat.mm(margin)) kept clear, is \(FitFormat.mm(width)) by \(FitFormat.mm(height)), carried \(pose.spoken)."
        )
    }

    static func partWorth(piece: FurniturePiece, stop: RouteStop) -> [PartWorth] {
        let before = FitEngine.gate(module: stop.module, box: piece.box, stop: stop, parts: [])
        return piece.parts.map { part in
            let reduced = piece.box.reduced(by: [part])
            let after = FitEngine.gate(module: stop.module, box: reduced, stop: stop, parts: [])
            return PartWorth(
                part: part,
                clearanceGainMM: after.clearanceMM - before.clearanceMM,
                callBefore: before.call,
                callAfter: after.call
            )
        }
    }

    static func blanketLimit(piece: FurniturePiece, stop: RouteStop, stock: Stock) -> Int {
        var allowed = 0
        var blankets = 0
        while blankets < 8 {
            let brief = FitHandling.brief(piece: piece, stock: stock, blankets: blankets, stop: stop)
            let report = FitEngine.gate(module: stop.module, box: brief.wrapped, stop: stop, parts: piece.parts)
            if report.call == .leaveIt { break }
            allowed = blankets
            blankets += 1
        }
        return allowed
    }

    static func loadOrder(pieces: [FurniturePiece], stops: [RouteStop]) -> [LoadOrder] {
        let grid = FitMatrix.cells(pieces: pieces, stops: stops)
        return pieces.map { piece in
            let own = FitMatrix.forPiece(piece.id, in: grid)
            let tight = own.min { $0.report.clearanceMM < $1.report.clearanceMM }
            let worst = own.max { $0.report.call.rank < $1.report.call.rank }
            return LoadOrder(
                pieceID: piece.id,
                name: piece.name,
                tightStop: tight?.stopName ?? "No stop",
                clearanceMM: tight?.report.clearanceMM ?? 0,
                call: worst?.report.call ?? .leaveIt
            )
        }
        .sorted { lhs, rhs in
            if lhs.call.rank != rhs.call.rank { return lhs.call.rank > rhs.call.rank }
            return lhs.clearanceMM < rhs.clearanceMM
        }
    }

    static func inches(_ millimetres: Double) -> String {
        let total = millimetres / 25.4
        let whole = Int(total.rounded(.down))
        let fraction = total - Double(whole)
        let eighths = Int((fraction * 8).rounded())
        if eighths == 0 { return "\(whole) in" }
        if eighths == 8 { return "\(whole + 1) in" }
        let reduced = reduce(eighths, 8)
        if whole == 0 { return "\(reduced.0)/\(reduced.1) in" }
        return "\(whole) \(reduced.0)/\(reduced.1) in"
    }

    static func tape(_ millimetres: Double) -> String {
        let snapped = (millimetres / 5).rounded() * 5
        return "\(FitFormat.mm(snapped)) on the tape · \(inches(snapped))"
    }

    static func stairDiagonal(headroom: Double, run: Double) -> Double {
        hypot(headroom, run)
    }

    static func longestPole(hallA: Double, hallB: Double) -> Double {
        let a = pow(max(hallA, 1), 2.0 / 3.0)
        let b = pow(max(hallB, 1), 2.0 / 3.0)
        return pow(a + b, 1.5)
    }

    static func planDelta(left: RouteReport, right: RouteReport) -> [String] {
        var lines = [FitEngine.compareRoutes(left, right)]
        let rightByID = Dictionary(uniqueKeysWithValues: right.gates.map { ($0.stop.id, $0.report) })
        for gate in left.gates {
            if let other = rightByID[gate.stop.id] {
                if gate.report.call != other.call {
                    lines.append("\(gate.stop.name): \(left.planName) says \(gate.report.headline.lowercased()), \(right.planName) says \(other.headline.lowercased()).")
                }
            } else {
                lines.append("\(gate.stop.name) is only on \(left.planName): \(gate.report.headline.lowercased()).")
            }
        }
        for gate in right.gates where !left.gates.contains(where: { $0.stop.id == gate.stop.id }) {
            lines.append("\(gate.stop.name) is only on \(right.planName): \(gate.report.headline.lowercased()).")
        }
        return lines
    }

    static func spareBudget(cells: [MatrixCell]) -> String {
        guard let tight = FitMatrix.tightest(cells) else { return "No checks yet." }
        let positive = cells.filter { $0.report.clearanceMM > 0 }.count
        return "\(positive) of \(cells.count) checks have spare. The tightest is \(tight.pieceName) at \(tight.stopName), \(FitFormat.signedMM(tight.report.clearanceMM))."
    }

    private static func clearance(pose: Pose, stop: RouteStop) -> Double {
        switch stop.module {
        case .door, .vehicle:
            let usableW = stop.primaryMM - stop.tertiaryMM
            let usableH = stop.secondaryMM - stop.tertiaryMM
            return min(usableW - pose.acrossMM, usableH - pose.upMM)
        case .stair:
            return min(stop.primaryMM - pose.acrossMM, stop.secondaryMM - pose.upMM)
        case .cargo:
            return min(stop.primaryMM - pose.travelMM, stop.secondaryMM - pose.acrossMM, stop.tertiaryMM - pose.upMM)
        case .spot:
            let avail = stop.primaryMM - stop.tertiaryMM
            return min(avail - pose.acrossMM, stop.secondaryMM - pose.travelMM)
        case .turn:
            let narrow = min(stop.primaryMM, stop.secondaryMM)
            return narrow - max(pose.acrossMM, pose.travelMM)
        }
    }

    private static func fits(pose: Pose, stop: RouteStop) -> Bool {
        switch stop.module {
        case .door, .vehicle:
            return pose.acrossMM <= stop.primaryMM - stop.tertiaryMM && pose.upMM <= stop.secondaryMM - stop.tertiaryMM
        case .stair:
            let limit = hypot(stop.secondaryMM, stop.tertiaryMM)
            return pose.acrossMM <= stop.primaryMM && pose.upMM <= stop.secondaryMM && pose.travelMM <= limit
        case .cargo:
            return pose.travelMM <= stop.primaryMM && pose.acrossMM <= stop.secondaryMM && pose.upMM <= stop.tertiaryMM
        case .spot:
            let avail = stop.primaryMM - stop.tertiaryMM
            return pose.acrossMM <= avail && pose.travelMM <= stop.secondaryMM
        case .turn:
            guard pose.upMM <= stop.tertiaryMM else { return false }
            let narrow = min(stop.primaryMM, stop.secondaryMM)
            let wide = max(stop.primaryMM, stop.secondaryMM)
            let short = min(pose.acrossMM, pose.travelMM)
            let long = max(pose.acrossMM, pose.travelMM)
            return short <= narrow && long <= wide
        }
    }

    private static func reduce(_ numerator: Int, _ denominator: Int) -> (Int, Int) {
        var a = numerator
        var b = denominator
        while b != 0 {
            let next = a % b
            a = b
            b = next
        }
        let divisor = max(a, 1)
        return (numerator / divisor, denominator / divisor)
    }
}
