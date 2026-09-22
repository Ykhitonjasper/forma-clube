import Foundation

struct MatrixCell: Identifiable, Hashable {
    var id: String { "\(pieceID)-\(stopID)" }
    var pieceID: String
    var stopID: String
    var pieceName: String
    var stopName: String
    var module: FitModule
    var report: GateReport
}

struct PieceVerdict: Identifiable, Hashable {
    var id: String { pieceID }
    var pieceID: String
    var name: String
    var call: MoveCall
    var blocker: String
    var tightestMM: Double
}

struct PickupVerdict: Hashable {
    var call: MoveCall
    var headline: String
    var pieces: [PieceVerdict]
    var note: String
}

enum FitMatrix {
    static func cells(pieces: [FurniturePiece], stops: [RouteStop]) -> [MatrixCell] {
        var rows: [MatrixCell] = []
        for piece in pieces {
            for stop in stops {
                var report = FitEngine.gate(module: stop.module, box: piece.box, stop: stop, parts: piece.parts)
                report.call = FitEngine.upgrade(call: report.call, piece: piece, stop: stop, stops: stops)
                report.headline = report.call.title
                rows.append(
                    MatrixCell(
                        pieceID: piece.id,
                        stopID: stop.id,
                        pieceName: piece.name,
                        stopName: stop.name,
                        module: stop.module,
                        report: report
                    )
                )
            }
        }
        return rows
    }

    static func verdict(pieces: [FurniturePiece], stops: [RouteStop]) -> PickupVerdict {
        let grid = cells(pieces: pieces, stops: stops)
        let grouped = Dictionary(grouping: grid, by: \.pieceID)
        var pieceCalls: [PieceVerdict] = []
        for piece in pieces {
            let own = grouped[piece.id] ?? []
            let worst = own.max { $0.report.call.rank < $1.report.call.rank }
            let tight = own.min { $0.report.clearanceMM < $1.report.clearanceMM }
            pieceCalls.append(
                PieceVerdict(
                    pieceID: piece.id,
                    name: piece.name,
                    call: worst?.report.call ?? .leaveIt,
                    blocker: worst?.stopName ?? "No stop",
                    tightestMM: tight?.report.clearanceMM ?? 0
                )
            )
        }
        let worstPiece = pieceCalls.max { $0.call.rank < $1.call.rank }
        let call = worstPiece?.call ?? .leaveIt
        let splits = pieceCalls.filter { $0.call == .splitParts }.map(\.name)
        let turns = pieceCalls.filter { $0.call == .turnIt }.map(\.name)
        let leaves = pieceCalls.filter { $0.call == .leaveIt || $0.call == .otherRoute }.map(\.name)
        let note = summary(call: call, splits: splits, turns: turns, leaves: leaves, blocker: worstPiece?.blocker ?? "")
        return PickupVerdict(call: call, headline: call.title, pieces: pieceCalls, note: note)
    }

    static func tightest(_ cells: [MatrixCell]) -> MatrixCell? {
        cells.min { $0.report.clearanceMM < $1.report.clearanceMM }
    }

    static func forPiece(_ pieceID: String, in cells: [MatrixCell]) -> [MatrixCell] {
        cells.filter { $0.pieceID == pieceID }
    }

    static func forStop(_ stopID: String, in cells: [MatrixCell]) -> [MatrixCell] {
        cells.filter { $0.stopID == stopID }
    }

    private static func summary(call: MoveCall, splits: [String], turns: [String], leaves: [String], blocker: String) -> String {
        var lines: [String] = []
        lines.append("The pickup is “\(call.title.lowercased())”.")
        if !leaves.isEmpty {
            lines.append("\(leaves.joined(separator: ", ")) cannot make every stop.")
        }
        if !splits.isEmpty {
            lines.append("Take apart \(splits.joined(separator: ", ")) before the first tight opening.")
        }
        if !turns.isEmpty {
            lines.append("Turn \(turns.joined(separator: ", ")) — they fit, just not in the way you are holding them.")
        }
        if call == .proceed {
            lines.append("Every piece clears every measured stop as carried.")
        }
        if !blocker.isEmpty && call != .proceed {
            lines.append("The stop that sets the call is \(blocker).")
        }
        return lines.joined(separator: " ")
    }
}
