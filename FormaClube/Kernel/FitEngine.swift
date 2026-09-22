import Foundation

enum FitEngine {
    static func parse(_ raw: String) -> Double? {
        let cleaned = raw
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = Double(cleaned), value.isFinite, value > 0 else { return nil }
        return value
    }

    static func millimetres(from text: String, inches: Bool) -> Double? {
        guard let value = parse(text) else { return nil }
        return inches ? value * 25.4 : value
    }

    static func poses(of box: FitBox) -> [Pose] {
        let dims: [(BoxAxis, Double)] = [
            (.width, box.width),
            (.depth, box.depth),
            (.height, box.height)
        ]
        var poses: [Pose] = []
        for (index, vertical) in dims.enumerated() {
            let rest = dims.enumerated().filter { $0.offset != index }.map(\.element)
            let orders = [rest, Array(rest.reversed())]
            for order in orders {
                poses.append(
                    Pose(
                        up: vertical.0,
                        across: order[0].0,
                        travel: order[1].0,
                        upMM: vertical.1,
                        acrossMM: order[0].1,
                        travelMM: order[1].1
                    )
                )
            }
        }
        return poses
    }

    static func gate(module: FitModule, box: FitBox, stop: RouteStop, parts: [RemovablePart]) -> GateReport {
        switch module {
        case .door, .vehicle:
            return opening(box: box, width: stop.primaryMM, height: stop.secondaryMM, margin: stop.tertiaryMM, parts: parts, place: stop.name)
        case .turn:
            return corner(box: box, hallA: stop.primaryMM, hallB: stop.secondaryMM, ceiling: stop.tertiaryMM, parts: parts, place: stop.name)
        case .stair:
            return stair(box: box, width: stop.primaryMM, headroom: stop.secondaryMM, run: stop.tertiaryMM, parts: parts, place: stop.name)
        case .cargo:
            return cargo(box: box, length: stop.primaryMM, width: stop.secondaryMM, height: stop.tertiaryMM, parts: parts, place: stop.name)
        case .spot:
            return spot(box: box, length: stop.primaryMM, depth: stop.secondaryMM, aisle: stop.tertiaryMM, parts: parts, place: stop.name)
        }
    }

    static func opening(box: FitBox, width: Double, height: Double, margin: Double, parts: [RemovablePart], place: String) -> GateReport {
        let usableW = width - margin
        let usableH = height - margin
        let intact = bestOpening(box: box, usableW: usableW, usableH: usableH)
        if intact.fits {
            let call: MoveCall = intact.pose.isNatural ? .proceed : .turnIt
            return report(
                call: call,
                clearance: intact.clearance,
                pose: intact.pose,
                count: 1,
                usedParts: false,
                note: openingNote(call: call, place: place, pose: intact.pose, clearance: intact.clearance, usableW: usableW, usableH: usableH, box: box)
            )
        }
        let stripped = box.reduced(by: parts)
        if stripped != box {
            let again = bestOpening(box: stripped, usableW: usableW, usableH: usableH)
            if again.fits {
                let names = parts.map(\.name).joined(separator: ", ")
                return report(
                    call: .splitParts,
                    clearance: again.clearance,
                    pose: again.pose,
                    count: 1,
                    usedParts: true,
                    note: "\(names) has to come off before \(place). Without that, the piece is \(FitFormat.mm(stripped.width)) × \(FitFormat.mm(stripped.depth)) × \(FitFormat.mm(stripped.height)) and clears by \(FitFormat.mm(again.clearance)). Intact, no face gets through \(FitFormat.mm(usableW)) by \(FitFormat.mm(usableH))."
                )
            }
        }
        return report(
            call: .leaveIt,
            clearance: intact.clearance,
            pose: intact.pose,
            count: 0,
            usedParts: false,
            note: "Nothing gets through \(place). The opening is \(FitFormat.mm(usableW)) by \(FitFormat.mm(usableH)) after the keep-clear. The closest face is still \(FitFormat.mm(abs(intact.clearance))) too big."
        )
    }

    static func corner(box: FitBox, hallA: Double, hallB: Double, ceiling: Double, parts: [RemovablePart], place: String) -> GateReport {
        if let upright = uprightCorner(box: box, hallA: hallA, hallB: hallB, ceiling: ceiling) {
            return report(
                call: .proceed,
                clearance: upright.spare,
                pose: naturalPose(box),
                count: 1,
                usedParts: false,
                note: "Walk it upright through \(place). The footprint is \(FitFormat.mm(box.width)) by \(FitFormat.mm(box.depth)), and the tighter hall still has \(FitFormat.mm(upright.spare)). Ceiling is \(FitFormat.mm(ceiling))."
            )
        }
        if let turned = turnedCorner(box: box, hallA: hallA, hallB: hallB, ceiling: ceiling) {
            return report(
                call: .turnIt,
                clearance: turned.spare,
                pose: turned.pose,
                count: 1,
                usedParts: false,
                note: "It only gets around \(place) with \(turned.pose.spoken). Upright, the footprint does not sit inside both halls (\(FitFormat.mm(hallA)) and \(FitFormat.mm(hallB)))."
            )
        }
        let stripped = box.reduced(by: parts)
        if stripped != box, uprightCorner(box: stripped, hallA: hallA, hallB: hallB, ceiling: ceiling) != nil || turnedCorner(box: stripped, hallA: hallA, hallB: hallB, ceiling: ceiling) != nil {
            let names = parts.map(\.name).joined(separator: ", ")
            let follow = uprightCorner(box: stripped, hallA: hallA, hallB: hallB, ceiling: ceiling)?.spare
                ?? turnedCorner(box: stripped, hallA: hallA, hallB: hallB, ceiling: ceiling)?.spare
                ?? 0
            return report(
                call: .splitParts,
                clearance: follow,
                pose: naturalPose(stripped),
                count: 1,
                usedParts: true,
                note: "\(names) has to come off to get around \(place). The halls are \(FitFormat.mm(hallA)) and \(FitFormat.mm(hallB))."
            )
        }
        return report(
            call: .leaveIt,
            clearance: min(hallA, hallB) - max(box.width, box.depth),
            pose: naturalPose(box),
            count: 0,
            usedParts: false,
            note: "It does not get around \(place). Halls are \(FitFormat.mm(hallA)) and \(FitFormat.mm(hallB)). The piece's plan is larger than both, even pivoted."
        )
    }

    static func stair(box: FitBox, width: Double, headroom: Double, run: Double, parts: [RemovablePart], place: String) -> GateReport {
        let limit = hypot(headroom, run)
        let intact = bestStair(box: box, width: width, headroom: headroom, diagonal: limit)
        if intact.fits {
            let call: MoveCall = intact.pose.isNatural ? .proceed : .turnIt
            return report(
                call: call,
                clearance: intact.clearance,
                pose: intact.pose,
                count: 1,
                usedParts: false,
                note: stairNote(call: call, place: place, pose: intact.pose, clearance: intact.clearance, width: width, headroom: headroom)
            )
        }
        let stripped = box.reduced(by: parts)
        if stripped != box {
            let again = bestStair(box: stripped, width: width, headroom: headroom, diagonal: limit)
            if again.fits {
                let names = parts.map(\.name).joined(separator: ", ")
                return report(
                    call: .splitParts,
                    clearance: again.clearance,
                    pose: again.pose,
                    count: 1,
                    usedParts: true,
                    note: "\(names) has to come off for \(place). The stair is \(FitFormat.mm(width)) wide with \(FitFormat.mm(headroom)) of headroom. Intact, every face is wider than the stair."
                )
            }
        }
        return report(
            call: .leaveIt,
            clearance: intact.clearance,
            pose: intact.pose,
            count: 0,
            usedParts: false,
            note: "It does not go up \(place). Width \(FitFormat.mm(width)), headroom \(FitFormat.mm(headroom)). The long diagonal of the flight is \(FitFormat.mm(limit)), and no face fits the width."
        )
    }

    static func cargo(box: FitBox, length: Double, width: Double, height: Double, parts: [RemovablePart], place: String) -> GateReport {
        let intact = bestCargo(box: box, length: length, width: width, height: height)
        if intact.fits {
            let call: MoveCall = intact.pose.isNatural ? .proceed : .turnIt
            return report(
                call: call,
                clearance: intact.clearance,
                pose: intact.pose,
                count: intact.count,
                usedParts: false,
                note: cargoNote(call: call, place: place, pose: intact.pose, count: intact.count, clearance: intact.clearance, length: length, width: width, height: height)
            )
        }
        let stripped = box.reduced(by: parts)
        if stripped != box {
            let again = bestCargo(box: stripped, length: length, width: width, height: height)
            if again.fits {
                let names = parts.map(\.name).joined(separator: ", ")
                return report(
                    call: .splitParts,
                    clearance: again.clearance,
                    pose: again.pose,
                    count: again.count,
                    usedParts: true,
                    note: "\(names) has to come off before it sits in \(place). Then \(again.count) fit, with \(FitFormat.mm(again.clearance)) left on the tight axis."
                )
            }
        }
        return report(
            call: .leaveIt,
            clearance: intact.clearance,
            pose: intact.pose,
            count: 0,
            usedParts: false,
            note: "It does not sit in \(place). The bay is \(FitFormat.mm(length)) × \(FitFormat.mm(width)) × \(FitFormat.mm(height)). Every orientation still sticks out."
        )
    }

    static func spot(box: FitBox, length: Double, depth: Double, aisle: Double, parts: [RemovablePart], place: String) -> GateReport {
        let avail = length - aisle
        let intact = bestSpot(box: box, length: avail, depth: depth)
        if intact.fits {
            let call: MoveCall = intact.pose.isNatural ? .proceed : .turnIt
            return report(
                call: call,
                clearance: intact.clearance,
                pose: intact.pose,
                count: 1,
                usedParts: false,
                note: "\(place) has \(FitFormat.mm(avail)) by \(FitFormat.mm(depth)) once a \(FitFormat.mm(aisle)) aisle is left. \(call == .proceed ? "The piece sits as measured." : "Turn the footprint.") Spare \(FitFormat.mm(intact.clearance))."
            )
        }
        let stripped = box.reduced(by: parts)
        if stripped != box {
            let again = bestSpot(box: stripped, length: avail, depth: depth)
            if again.fits {
                let names = parts.map(\.name).joined(separator: ", ")
                return report(
                    call: .splitParts,
                    clearance: again.clearance,
                    pose: again.pose,
                    count: 1,
                    usedParts: true,
                    note: "\(names) has to come off or \(place) cannot take the footprint. Usable floor is \(FitFormat.mm(avail)) by \(FitFormat.mm(depth))."
                )
            }
        }
        return report(
            call: .leaveIt,
            clearance: intact.clearance,
            pose: intact.pose,
            count: 0,
            usedParts: false,
            note: "The footprint does not land in \(place). Usable floor is \(FitFormat.mm(avail)) by \(FitFormat.mm(depth)) after the aisle."
        )
    }

    static func route(plan: HaulPlan, piece: FurniturePiece, stops: [RouteStop]) -> RouteReport {
        let chosen = plan.stopIDs.compactMap { id in stops.first { $0.id == id } }
        var gates: [(stop: RouteStop, report: GateReport)] = []
        var worst = MoveCall.proceed
        var blocker = chosen.first?.name ?? plan.name
        for stop in chosen {
            let result = gate(module: stop.module, box: piece.box, stop: stop, parts: piece.parts)
            gates.append((stop, result))
            if result.call.rank > worst.rank {
                worst = result.call
                blocker = stop.name
            }
        }
        return RouteReport(planName: plan.name, call: worst, blockerName: blocker, gates: gates)
    }

    static func compareRoutes(_ left: RouteReport, _ right: RouteReport) -> String {
        if left.call == right.call && left.blockerName == right.blockerName {
            return "Both ways end at \(left.call.title.lowercased()). The stop that decides it is \(left.blockerName). Skipping a later stop does not change that."
        }
        if left.call.rank == right.call.rank {
            return "\(left.planName) is blocked at \(left.blockerName). \(right.planName) is blocked at \(right.blockerName). Same kind of call, different stop."
        }
        let harder = left.call.rank >= right.call.rank ? left : right
        let easier = left.call.rank >= right.call.rank ? right : left
        return "\(easier.planName) is the better way: \(easier.call.title.lowercased()). \(harder.planName) is worse because of \(harder.blockerName)."
    }

    static func upgrade(call: MoveCall, piece: FurniturePiece, stop: RouteStop, stops: [RouteStop]) -> MoveCall {
        guard call == .leaveIt else { return call }
        let alternates = stops.filter { $0.module == stop.module && $0.id != stop.id }
        for other in alternates {
            let result = gate(module: other.module, box: piece.box, stop: other, parts: piece.parts)
            if result.call.rank < MoveCall.leaveIt.rank {
                return .otherRoute
            }
        }
        return .leaveIt
    }

    private struct Candidate {
        var fits: Bool
        var pose: Pose
        var clearance: Double
        var count: Int
    }

    private struct CornerHit {
        var spare: Double
        var pose: Pose
    }

    private static func bestOpening(box: FitBox, usableW: Double, usableH: Double) -> Candidate {
        var best: Candidate?
        for pose in poses(of: box) {
            let gapW = usableW - pose.acrossMM
            let gapH = usableH - pose.upMM
            let fits = gapW >= -0.001 && gapH >= -0.001
            let candidate = Candidate(fits: fits, pose: pose, clearance: min(gapW, gapH), count: fits ? 1 : 0)
            best = prefer(best, candidate)
        }
        return best ?? Candidate(fits: false, pose: naturalPose(box), clearance: 0, count: 0)
    }

    private static func bestStair(box: FitBox, width: Double, headroom: Double, diagonal: Double) -> Candidate {
        var best: Candidate?
        for pose in poses(of: box) {
            let fits = pose.acrossMM <= width && pose.upMM <= headroom && pose.travelMM <= diagonal
            let clearance = min(width - pose.acrossMM, headroom - pose.upMM)
            let candidate = Candidate(fits: fits, pose: pose, clearance: clearance, count: fits ? 1 : 0)
            best = prefer(best, candidate)
        }
        return best ?? Candidate(fits: false, pose: naturalPose(box), clearance: 0, count: 0)
    }

    private static func bestCargo(box: FitBox, length: Double, width: Double, height: Double) -> Candidate {
        var best: Candidate?
        for pose in poses(of: box) where pose.travelMM > 0 && pose.acrossMM > 0 && pose.upMM > 0 {
            let along = Int(length / pose.travelMM)
            let across = Int(width / pose.acrossMM)
            let up = Int(height / pose.upMM)
            let fits = along >= 1 && across >= 1 && up >= 1
            let count = fits ? along * across * up : 0
            let clearance = fits
                ? min(length - pose.travelMM * Double(along), width - pose.acrossMM * Double(across), height - pose.upMM * Double(up))
                : min(length - pose.travelMM, width - pose.acrossMM, height - pose.upMM)
            let candidate = Candidate(fits: fits, pose: pose, clearance: clearance, count: count)
            if best == nil || cargoRank(candidate) > cargoRank(best!) {
                best = candidate
            }
        }
        return best ?? Candidate(fits: false, pose: naturalPose(box), clearance: 0, count: 0)
    }

    private static func bestSpot(box: FitBox, length: Double, depth: Double) -> Candidate {
        let naturalFit = box.width <= length && box.depth <= depth
        let naturalClear = min(length - box.width, depth - box.depth)
        let natural = Candidate(fits: naturalFit, pose: naturalPose(box), clearance: naturalClear, count: naturalFit ? 1 : 0)
        let swapPose = Pose(up: .height, across: .depth, travel: .width, upMM: box.height, acrossMM: box.depth, travelMM: box.width)
        let swapFit = box.depth <= length && box.width <= depth
        let swapClear = min(length - box.depth, depth - box.width)
        let swap = Candidate(fits: swapFit, pose: swapPose, clearance: swapClear, count: swapFit ? 1 : 0)
        return prefer(.some(natural), swap) ?? natural
    }

    private static func uprightCorner(box: FitBox, hallA: Double, hallB: Double, ceiling: Double) -> CornerHit? {
        guard box.height <= ceiling else { return nil }
        let narrow = min(hallA, hallB)
        let wide = max(hallA, hallB)
        let short = min(box.width, box.depth)
        let long = max(box.width, box.depth)
        if long <= narrow {
            return CornerHit(spare: narrow - long, pose: naturalPose(box))
        }
        if short <= narrow && long <= wide {
            return CornerHit(spare: min(narrow - short, wide - long), pose: naturalPose(box))
        }
        if rectangleTurns(length: long, width: short, hallA: hallA, hallB: hallB) {
            return CornerHit(spare: 0, pose: naturalPose(box))
        }
        return nil
    }

    private static func turnedCorner(box: FitBox, hallA: Double, hallB: Double, ceiling: Double) -> CornerHit? {
        let options: [(BoxAxis, Double, Double, Double)] = [
            (.width, box.width, box.depth, box.height),
            (.depth, box.depth, box.width, box.height)
        ]
        for option in options {
            let vertical = option.1
            guard vertical <= ceiling else { continue }
            let planA = option.2
            let planB = option.3
            let pose = Pose(
                up: option.0,
                across: .depth,
                travel: .height,
                upMM: vertical,
                acrossMM: min(planA, planB),
                travelMM: max(planA, planB)
            )
            let narrow = min(hallA, hallB)
            let wide = max(hallA, hallB)
            let short = min(planA, planB)
            let long = max(planA, planB)
            if long <= narrow {
                return CornerHit(spare: narrow - long, pose: pose)
            }
            if short <= narrow && long <= wide {
                return CornerHit(spare: min(narrow - short, wide - long), pose: pose)
            }
            if rectangleTurns(length: long, width: short, hallA: hallA, hallB: hallB) {
                return CornerHit(spare: 0, pose: pose)
            }
        }
        return nil
    }

    static func rectangleTurns(length: Double, width: Double, hallA: Double, hallB: Double) -> Bool {
        if min(length, width) <= 0 { return false }
        if max(length, width) <= min(hallA, hallB) { return true }
        let steps = 12
        let angles = 18
        for row in 0..<steps {
            for column in 0..<steps {
                let centerX = hallB * (Double(column) + 0.5) / Double(steps)
                let centerY = hallA * (Double(row) + 0.5) / Double(steps)
                for step in 0..<angles {
                    let angle = Double(step) / Double(angles) * .pi / 2
                    if poseFits(cx: centerX, cy: centerY, length: length, width: width, angle: angle, hallA: hallA, hallB: hallB) {
                        return true
                    }
                    if poseFits(cx: centerX, cy: centerY, length: width, width: length, angle: angle, hallA: hallA, hallB: hallB) {
                        return true
                    }
                }
            }
        }
        return false
    }

    private static func poseFits(cx: Double, cy: Double, length: Double, width: Double, angle: Double, hallA: Double, hallB: Double) -> Bool {
        let dx = cos(angle) * length / 2
        let dy = sin(angle) * length / 2
        let px = -sin(angle) * width / 2
        let py = cos(angle) * width / 2
        var points: [(Double, Double)] = []
        for sx in [-1.0, 1.0] {
            for sy in [-1.0, 1.0] {
                points.append((cx + sx * dx + sy * px, cy + sx * dy + sy * py))
            }
            points.append((cx + sx * dx, cy + sx * dy))
        }
        for sy in [-1.0, 1.0] {
            points.append((cx + sy * px, cy + sy * py))
        }
        return points.allSatisfy { walkable(x: $0.0, y: $0.1, hallA: hallA, hallB: hallB) }
    }

    private static func walkable(x: Double, y: Double, hallA: Double, hallB: Double) -> Bool {
        if x < -1 || y < -1 { return false }
        if y <= hallA + 1 { return true }
        return x <= hallB + 1
    }

    private static func prefer(_ current: Candidate?, _ next: Candidate) -> Candidate? {
        guard let current else { return next }
        if rank(next) > rank(current) { return next }
        return current
    }

    private static func rank(_ candidate: Candidate) -> (Int, Int, Double) {
        (candidate.fits ? 1 : 0, candidate.pose.isNatural && candidate.fits ? 1 : 0, candidate.clearance)
    }

    private static func cargoRank(_ candidate: Candidate) -> (Int, Int, Int, Double) {
        (candidate.fits ? 1 : 0, candidate.pose.isNatural && candidate.fits ? 1 : 0, candidate.count, candidate.clearance)
    }

    private static func naturalPose(_ box: FitBox) -> Pose {
        Pose(up: .height, across: .width, travel: .depth, upMM: box.height, acrossMM: box.width, travelMM: box.depth)
    }

    private static func report(call: MoveCall, clearance: Double, pose: Pose, count: Int, usedParts: Bool, note: String) -> GateReport {
        GateReport(
            call: call,
            clearanceMM: clearance,
            pose: pose,
            headline: call.title,
            note: note,
            count: count,
            usedParts: usedParts
        )
    }

    private static func openingNote(call: MoveCall, place: String, pose: Pose, clearance: Double, usableW: Double, usableH: Double, box: FitBox) -> String {
        let opening = "\(place) is \(FitFormat.mm(usableW)) by \(FitFormat.mm(usableH)) after the keep-clear."
        if call == .proceed {
            return "\(opening) It goes through as measured, \(pose.spoken), with \(FitFormat.mm(clearance)) to spare."
        }
        return "\(opening) Carry it \(pose.spoken). As measured (\(FitFormat.mm(box.width)) wide, \(FitFormat.mm(box.height)) tall) it does not face the opening. Spare on the turned face is \(FitFormat.mm(clearance))."
    }

    private static func stairNote(call: MoveCall, place: String, pose: Pose, clearance: Double, width: Double, headroom: Double) -> String {
        let stair = "\(place) is \(FitFormat.mm(width)) wide with \(FitFormat.mm(headroom)) of headroom."
        if call == .proceed {
            return "\(stair) It goes up as measured, with \(FitFormat.mm(clearance)) to spare."
        }
        return "\(stair) It only goes up \(pose.spoken), with \(FitFormat.mm(clearance)) to spare."
    }

    private static func cargoNote(call: MoveCall, place: String, pose: Pose, count: Int, clearance: Double, length: Double, width: Double, height: Double) -> String {
        let bay = "\(place) is \(FitFormat.mm(length)) × \(FitFormat.mm(width)) × \(FitFormat.mm(height))."
        let many = count == 1 ? "One fits" : "\(count) fit"
        if call == .proceed {
            return "\(bay) \(many) as measured, with \(FitFormat.mm(clearance)) left on the tight axis."
        }
        return "\(bay) \(many) only when carried \(pose.spoken). \(FitFormat.mm(clearance)) left on the tight axis."
    }
}
