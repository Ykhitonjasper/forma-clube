import Foundation

enum FitCarry {
    static func steps(piece: FurniturePiece, stop: RouteStop, report: GateReport) -> [String] {
        var lines = intro(piece: piece, stop: stop, report: report)
        lines.append(contentsOf: moduleSteps(piece: piece, stop: stop, report: report))
        lines.append(contentsOf: after(report: report, stop: stop))
        return lines
    }

    static func script(piece: FurniturePiece, stops: [RouteStop]) -> [String] {
        var lines = ["\(piece.name), \(piece.sizeLine)."]
        for stop in stops {
            let report = FitEngine.gate(module: stop.module, box: piece.box, stop: stop, parts: piece.parts)
            lines.append("\(stop.name) — \(report.headline).")
            lines.append(contentsOf: steps(piece: piece, stop: stop, report: report).map { "  \($0)" })
        }
        return lines
    }

    private static func intro(piece: FurniturePiece, stop: RouteStop, report: GateReport) -> [String] {
        var lines = ["At \(stop.name), the call is \(report.headline.lowercased())."]
        lines.append("The piece is \(piece.sizeLine).")
        if report.usedParts {
            let names = piece.parts.map(\.name).joined(separator: " and ")
            lines.append("Take off \(names) before you lift it.")
        } else if !piece.parts.isEmpty && report.call == .proceed {
            lines.append("Leave \(piece.parts.map(\.name).joined(separator: " and ")) on. It fits with them attached.")
        }
        return lines
    }

    private static func moduleSteps(piece: FurniturePiece, stop: RouteStop, report: GateReport) -> [String] {
        switch stop.module {
        case .door: return doorSteps(piece: piece, stop: stop, report: report)
        case .turn: return cornerSteps(piece: piece, stop: stop, report: report)
        case .stair: return stairSteps(piece: piece, stop: stop, report: report)
        case .vehicle: return vanSteps(piece: piece, stop: stop, report: report)
        case .cargo: return baySteps(stop: stop, report: report)
        case .spot: return floorSteps(piece: piece, stop: stop, report: report)
        }
    }

    private static func doorSteps(piece: FurniturePiece, stop: RouteStop, report: GateReport) -> [String] {
        let usableW = stop.primaryMM - stop.tertiaryMM
        let usableH = stop.secondaryMM - stop.tertiaryMM
        switch report.call {
        case .proceed:
            return [
                "Face the \(FitFormat.mm(piece.widthMM)) side to the opening.",
                "The opening is \(FitFormat.mm(usableW)) wide and \(FitFormat.mm(usableH)) high after the keep-clear.",
                "Walk it through upright. Spare is \(FitFormat.mm(report.clearanceMM)).",
                "Do not tilt. Tilting spends the spare you have."
            ]
        case .turnIt:
            return [
                "Do not face the \(FitFormat.mm(piece.widthMM)) side to the door. It is wider than \(FitFormat.mm(usableW)).",
                "Turn it so it is \(report.pose.spoken).",
                "The face that meets the opening then clears by \(FitFormat.mm(report.clearanceMM)).",
                "Go through on that face and turn it back only after the frame is behind you."
            ]
        case .splitParts:
            return [
                "No face of the intact piece gets through \(FitFormat.mm(usableW)) by \(FitFormat.mm(usableH)).",
                "Remove \(piece.parts.map(\.name).joined(separator: " and ")) on this side of the door.",
                "Carry the rest \(report.pose.spoken). Spare becomes \(FitFormat.mm(report.clearanceMM)).",
                "The parts follow as their own pieces, or they stay for a second trip."
            ]
        case .otherRoute:
            return [
                "This opening does not take the piece.",
                "You already have another \(stop.module.title.lowercased()) that does. Use that one."
            ]
        case .leaveIt:
            return [
                "Measure the opening again if you think the tape caught the trim.",
                "If \(FitFormat.mm(usableW)) by \(FitFormat.mm(usableH)) is really the clear hole, leave the piece."
            ]
        }
    }

    private static func cornerSteps(piece: FurniturePiece, stop: RouteStop, report: GateReport) -> [String] {
        switch report.call {
        case .proceed:
            return [
                "Keep it upright. Height \(FitFormat.mm(piece.heightMM)) is under the \(FitFormat.mm(stop.tertiaryMM)) ceiling.",
                "The footprint \(FitFormat.mm(piece.widthMM)) by \(FitFormat.mm(piece.depthMM)) sits in both halls.",
                "The tighter hall still has \(FitFormat.mm(report.clearanceMM)).",
                "Walk the corner. You do not need to pivot it onto a side."
            ]
        case .turnIt:
            return [
                "Upright, the footprint does not sit in both halls (\(FitFormat.mm(stop.primaryMM)) and \(FitFormat.mm(stop.secondaryMM))).",
                "Lay it \(report.pose.spoken) before the corner, not in it.",
                "Pivot in the corner, then stand it up again only if the next hall is wide enough.",
                "A pole of \(FitFormat.mm(FitQuestions.longestPole(hallA: stop.primaryMM, hallB: stop.secondaryMM))) is the longest that turns here. This piece is using a face, not that pole."
            ]
        case .splitParts:
            return [
                "The intact footprint will not turn.",
                "Take off \(piece.parts.map(\.name).joined(separator: " and ")) in the hall before the corner.",
                "The smaller box clears with \(FitFormat.mm(report.clearanceMM)) to spare."
            ]
        case .otherRoute, .leaveIt:
            return [
                "Neither hall is wide enough for a face of this piece, and pivoting does not create a wider hall.",
                "Find a way that does not use this corner, or leave the piece."
            ]
        }
    }

    private static func stairSteps(piece: FurniturePiece, stop: RouteStop, report: GateReport) -> [String] {
        let diagonal = FitQuestions.stairDiagonal(headroom: stop.secondaryMM, run: stop.tertiaryMM)
        switch report.call {
        case .proceed:
            return [
                "The stair is \(FitFormat.mm(stop.primaryMM)) wide with \(FitFormat.mm(stop.secondaryMM)) of headroom.",
                "Carry it as measured. The across face fits the width.",
                "Spare is \(FitFormat.mm(report.clearanceMM)). One person above, watching the top.",
                "The flight's long diagonal is \(FitFormat.mm(diagonal)), longer than this piece, so you do not need to angle it."
            ]
        case .turnIt:
            return [
                "As carried, a face is wider than the \(FitFormat.mm(stop.primaryMM)) stair or taller than the headroom.",
                "Turn it to \(report.pose.spoken) on the landing, before the first step.",
                "The across face then clears by \(FitFormat.mm(report.clearanceMM)).",
                "Keep that face across the whole flight. Do not twist it on the steps."
            ]
        case .splitParts:
            return [
                "Every face of the intact piece is wider than \(FitFormat.mm(stop.primaryMM)).",
                "Remove \(piece.parts.map(\.name).joined(separator: " and ")) at the top or the bottom, not on the steps.",
                "What remains goes up \(report.pose.spoken), spare \(FitFormat.mm(report.clearanceMM))."
            ]
        case .otherRoute, .leaveIt:
            return [
                "The stair cannot take this piece. Width \(FitFormat.mm(stop.primaryMM)), headroom \(FitFormat.mm(stop.secondaryMM)), diagonal \(FitFormat.mm(diagonal)).",
                "Use a way out with no stair, or leave it."
            ]
        }
    }

    private static func vanSteps(piece: FurniturePiece, stop: RouteStop, report: GateReport) -> [String] {
        let usableW = stop.primaryMM - stop.tertiaryMM
        let usableH = stop.secondaryMM - stop.tertiaryMM
        switch report.call {
        case .proceed:
            return [
                "\(stop.name) is \(FitFormat.mm(usableW)) by \(FitFormat.mm(usableH)) after the keep-clear.",
                "Push it in as measured. Spare \(FitFormat.mm(report.clearanceMM)).",
                "The person inside takes the weight once the balance is past the sill."
            ]
        case .turnIt:
            return [
                "The face you are holding does not match \(stop.name).",
                "Set it down and turn it to \(report.pose.spoken).",
                "That face clears by \(FitFormat.mm(report.clearanceMM)).",
                "Slide, do not drop it onto the sill."
            ]
        case .splitParts:
            return [
                "The intact piece does not enter \(stop.name).",
                "The removable parts ride separately.",
                "The carcass then enters \(report.pose.spoken)."
            ]
        case .otherRoute:
            return [
                "Use the other opening on this van. This one is the tight face."
            ]
        case .leaveIt:
            return [
                "\(stop.name) is \(FitFormat.mm(usableW)) by \(FitFormat.mm(usableH)). No face of the piece is that small.",
                "This van cannot take it."
            ]
        }
    }

    private static func baySteps(stop: RouteStop, report: GateReport) -> [String] {
        switch report.call {
        case .proceed:
            return [
                "Stand it in the bay as measured.",
                report.count == 1 ? "One fits." : "\(report.count) would fit if you were hauling a pile. This is the one in front of you.",
                "\(FitFormat.mm(report.clearanceMM)) stays free on the tight axis. That is where the straps go."
            ]
        case .turnIt:
            return [
                "It does not stand in a bay that is \(FitFormat.mm(stop.tertiaryMM)) high.",
                "Lay it \(report.pose.spoken).",
                "Put it against a wall of the bay so the next piece can use the length.",
                "\(FitFormat.mm(report.clearanceMM)) remains on the tight axis."
            ]
        case .splitParts:
            return [
                "Even laid down, the intact piece does not sit in the bay.",
                "Parts ride in the gaps. The carcass takes the floor."
            ]
        case .otherRoute, .leaveIt:
            return [
                "The bay is \(FitFormat.mm(stop.primaryMM)) × \(FitFormat.mm(stop.secondaryMM)) × \(FitFormat.mm(stop.tertiaryMM)).",
                "Nothing you do with the orientation puts this piece inside it."
            ]
        }
    }

    private static func floorSteps(piece: FurniturePiece, stop: RouteStop, report: GateReport) -> [String] {
        let avail = stop.primaryMM - stop.tertiaryMM
        switch report.call {
        case .proceed:
            return [
                "Leave a \(FitFormat.mm(stop.tertiaryMM)) aisle. Usable floor is \(FitFormat.mm(avail)) by \(FitFormat.mm(stop.secondaryMM)).",
                "Set \(piece.name) down as measured. Spare \(FitFormat.mm(report.clearanceMM)).",
                "The aisle stays open back to the door."
            ]
        case .turnIt:
            return [
                "The footprint does not match the floor the way you are holding it.",
                "Turn it \(report.pose.spoken) before you set it down.",
                "Spare on the tight side is \(FitFormat.mm(report.clearanceMM))."
            ]
        case .splitParts:
            return [
                "The intact footprint covers the aisle.",
                "Leave the removable parts out, or stand them in the aisle only if you can still pass."
            ]
        case .otherRoute, .leaveIt:
            return [
                "Usable floor is \(FitFormat.mm(avail)) by \(FitFormat.mm(stop.secondaryMM)). The piece's footprint is larger.",
                "This spot cannot take it."
            ]
        }
    }

    private static func after(report: GateReport, stop: RouteStop) -> [String] {
        switch report.call {
        case .proceed:
            return ["Once it is through \(stop.name), the next stop is a new check. Do not assume the spare carries over."]
        case .turnIt:
            return ["Mark the face that worked, with tape, so the next person does not turn it back."]
        case .splitParts:
            return ["Bag the fixings with the part. The piece is no use at the other end if the part stays here."]
        case .otherRoute:
            return ["Change the stop, not the piece."]
        case .leaveIt:
            return ["Tell the seller before you have it off the wall."]
        }
    }
}
