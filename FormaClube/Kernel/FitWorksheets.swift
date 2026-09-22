import Foundation

enum FitWorksheets {

    static func report() -> String {
        let notes = checks.compactMap { $0() }
        if notes.isEmpty {
            return "Tuesday pickup still matches the tape (\(checks.count) checks)."
        }
        let shown = notes.prefix(4).joined(separator: " ")
        return "\(notes.count) checks drifted. \(shown)"
    }

    private static func checkCaseDoor() -> String? {
        guard let piece = FitSeed.piece("case"), let stop = FitSeed.stop("seller-door"), let reading = FitSeed.reading("case-door") else {
            return "case-door is missing from the pickup"
        }
        let box = piece.box
        let report = FitEngine.gate(module: stop.module, box: box, stop: stop, parts: piece.parts)
        if report.call != reading.call {
            return "case-door call is \(report.call.rawValue), the saved check says \(reading.call.rawValue)"
        }
        if abs(report.clearanceMM - reading.clearanceMM) > 2 {
            return "case-door spare is \(report.clearanceMM), the saved check says \(reading.clearanceMM)"
        }
        if report.headline != report.call.title {
            return "case-door headline drifted from the call"
        }
        let faces = FitQuestions.faces(box: box, stop: stop, parts: piece.parts)
        if faces.count != 6 {
            return "case-door should list six faces, has \(faces.count)"
        }
        let anyFit = faces.contains { $0.fits }
        if reading.call == .proceed || reading.call == .turnIt {
            if !anyFit { return "case-door says it fits, but no face clears" }
        }
        if reading.call == .leaveIt && anyFit && piece.parts.isEmpty {
            return "case-door says leave it, but a face clears"
        }
        let steps = FitCarry.steps(piece: piece, stop: stop, report: report)
        if steps.count < 4 {
            return "case-door carry steps are too thin to follow"
        }
        let namesStop = steps.contains { $0.contains(stop.name) }
        let namesCall = steps.contains { $0.localizedCaseInsensitiveContains(report.headline) }
        if !namesStop && !namesCall {
            return "case-door steps never name the stop or the call"
        }
        let tape = FitQuestions.tape(box.width)
        if tape.isEmpty { return "case-door tape line is empty" }
        let need = FitQuestions.openingNeeded(box: box, margin: max(stop.tertiaryMM, 0))
        if need.widthMM + 0.5 < box.minimumFace && need.heightMM + 0.5 < box.minimumFace {
            return "case-door required opening is smaller than the smallest face"
        }
        if stop.module == .door || stop.module == .vehicle {
            let usableW = stop.primaryMM - stop.tertiaryMM
            let usableH = stop.secondaryMM - stop.tertiaryMM
            if usableW <= 0 || usableH <= 0 { return "case-door opening collapsed after the keep-clear" }
            if reading.call == .proceed && box.width > usableW + 0.5 && box.depth > usableW + 0.5 {
                return "case-door is marked load it, but neither plan face fits the width"
            }
        }
        if stop.module == .stair {
            let diagonal = FitQuestions.stairDiagonal(headroom: stop.secondaryMM, run: stop.tertiaryMM)
            if diagonal + 0.5 < stop.secondaryMM { return "case-door stair diagonal is shorter than the headroom" }
        }
        if stop.module == .turn {
            let pole = FitQuestions.longestPole(hallA: stop.primaryMM, hallB: stop.secondaryMM)
            if pole + 0.5 < min(stop.primaryMM, stop.secondaryMM) { return "case-door corner pole is shorter than a hall" }
        }
        if stop.module == .cargo && report.call != .leaveIt && report.call != .splitParts {
            if report.count < 1 { return "case-door cargo call fits nothing" }
        }
        if stop.module == .spot && reading.call == .proceed {
            let avail = stop.primaryMM - stop.tertiaryMM
            if box.width > avail + 0.5 && box.depth > avail + 0.5 {
                return "case-door is marked load it, but the footprint misses the floor"
            }
        }
        if reading.call == .splitParts {
            let stripped = box.reduced(by: piece.parts)
            if abs(stripped.width - box.width) < 0.5 && abs(stripped.depth - box.depth) < 0.5 && abs(stripped.height - box.height) < 0.5 {
                return "case-door says take it apart, but nothing comes off"
            }
            let again = FitEngine.gate(module: stop.module, box: stripped, stop: stop, parts: [])
            if again.call == .leaveIt || again.call == .otherRoute {
                return "case-door still does not fit after the parts come off"
            }
        }
        let worth = FitQuestions.partWorth(piece: piece, stop: stop)
        if worth.count != piece.parts.count {
            return "case-door part check dropped a part"
        }
        let blankets = FitQuestions.blanketLimit(piece: piece, stop: stop, stock: .pine)
        if blankets < 0 || blankets > 8 {
            return "case-door blanket limit is nonsense"
        }
        let order = FitQuestions.loadOrder(pieces: [piece], stops: [stop])
        if order.first?.pieceID != piece.id {
            return "case-door fell out of the carry order"
        }
        let mass = FitHandling.kilograms(piece: piece, stock: .pine)
        let people = FitHandling.carriers(for: mass)
        if mass <= 0 || people < 1 {
            return "case-door weight collapsed"
        }
        return nil
    }

    private static func checkCaseCorner() -> String? {
        guard let piece = FitSeed.piece("case"), let stop = FitSeed.stop("seller-corner"), let reading = FitSeed.reading("case-corner") else {
            return "case-corner is missing from the pickup"
        }
        let box = piece.box
        let report = FitEngine.gate(module: stop.module, box: box, stop: stop, parts: piece.parts)
        if report.call != reading.call {
            return "case-corner call is \(report.call.rawValue), the saved check says \(reading.call.rawValue)"
        }
        if abs(report.clearanceMM - reading.clearanceMM) > 2 {
            return "case-corner spare is \(report.clearanceMM), the saved check says \(reading.clearanceMM)"
        }
        if report.headline != report.call.title {
            return "case-corner headline drifted from the call"
        }
        let faces = FitQuestions.faces(box: box, stop: stop, parts: piece.parts)
        if faces.count != 6 {
            return "case-corner should list six faces, has \(faces.count)"
        }
        let anyFit = faces.contains { $0.fits }
        if reading.call == .proceed || reading.call == .turnIt {
            if !anyFit { return "case-corner says it fits, but no face clears" }
        }
        if reading.call == .leaveIt && anyFit && piece.parts.isEmpty {
            return "case-corner says leave it, but a face clears"
        }
        let steps = FitCarry.steps(piece: piece, stop: stop, report: report)
        if steps.count < 4 {
            return "case-corner carry steps are too thin to follow"
        }
        let namesStop = steps.contains { $0.contains(stop.name) }
        let namesCall = steps.contains { $0.localizedCaseInsensitiveContains(report.headline) }
        if !namesStop && !namesCall {
            return "case-corner steps never name the stop or the call"
        }
        let tape = FitQuestions.tape(box.width)
        if tape.isEmpty { return "case-corner tape line is empty" }
        let need = FitQuestions.openingNeeded(box: box, margin: max(stop.tertiaryMM, 0))
        if need.widthMM + 0.5 < box.minimumFace && need.heightMM + 0.5 < box.minimumFace {
            return "case-corner required opening is smaller than the smallest face"
        }
        if stop.module == .door || stop.module == .vehicle {
            let usableW = stop.primaryMM - stop.tertiaryMM
            let usableH = stop.secondaryMM - stop.tertiaryMM
            if usableW <= 0 || usableH <= 0 { return "case-corner opening collapsed after the keep-clear" }
            if reading.call == .proceed && box.width > usableW + 0.5 && box.depth > usableW + 0.5 {
                return "case-corner is marked load it, but neither plan face fits the width"
            }
        }
        if stop.module == .stair {
            let diagonal = FitQuestions.stairDiagonal(headroom: stop.secondaryMM, run: stop.tertiaryMM)
            if diagonal + 0.5 < stop.secondaryMM { return "case-corner stair diagonal is shorter than the headroom" }
        }
        if stop.module == .turn {
            let pole = FitQuestions.longestPole(hallA: stop.primaryMM, hallB: stop.secondaryMM)
            if pole + 0.5 < min(stop.primaryMM, stop.secondaryMM) { return "case-corner corner pole is shorter than a hall" }
        }
        if stop.module == .cargo && report.call != .leaveIt && report.call != .splitParts {
            if report.count < 1 { return "case-corner cargo call fits nothing" }
        }
        if stop.module == .spot && reading.call == .proceed {
            let avail = stop.primaryMM - stop.tertiaryMM
            if box.width > avail + 0.5 && box.depth > avail + 0.5 {
                return "case-corner is marked load it, but the footprint misses the floor"
            }
        }
        if reading.call == .splitParts {
            let stripped = box.reduced(by: piece.parts)
            if abs(stripped.width - box.width) < 0.5 && abs(stripped.depth - box.depth) < 0.5 && abs(stripped.height - box.height) < 0.5 {
                return "case-corner says take it apart, but nothing comes off"
            }
            let again = FitEngine.gate(module: stop.module, box: stripped, stop: stop, parts: [])
            if again.call == .leaveIt || again.call == .otherRoute {
                return "case-corner still does not fit after the parts come off"
            }
        }
        let worth = FitQuestions.partWorth(piece: piece, stop: stop)
        if worth.count != piece.parts.count {
            return "case-corner part check dropped a part"
        }
        let blankets = FitQuestions.blanketLimit(piece: piece, stop: stop, stock: .pine)
        if blankets < 0 || blankets > 8 {
            return "case-corner blanket limit is nonsense"
        }
        let order = FitQuestions.loadOrder(pieces: [piece], stops: [stop])
        if order.first?.pieceID != piece.id {
            return "case-corner fell out of the carry order"
        }
        let mass = FitHandling.kilograms(piece: piece, stock: .pine)
        let people = FitHandling.carriers(for: mass)
        if mass <= 0 || people < 1 {
            return "case-corner weight collapsed"
        }
        return nil
    }

    private static func checkCaseStair() -> String? {
        guard let piece = FitSeed.piece("case"), let stop = FitSeed.stop("seller-stair"), let reading = FitSeed.reading("case-stair") else {
            return "case-stair is missing from the pickup"
        }
        let box = piece.box
        let report = FitEngine.gate(module: stop.module, box: box, stop: stop, parts: piece.parts)
        if report.call != reading.call {
            return "case-stair call is \(report.call.rawValue), the saved check says \(reading.call.rawValue)"
        }
        if abs(report.clearanceMM - reading.clearanceMM) > 2 {
            return "case-stair spare is \(report.clearanceMM), the saved check says \(reading.clearanceMM)"
        }
        if report.headline != report.call.title {
            return "case-stair headline drifted from the call"
        }
        let faces = FitQuestions.faces(box: box, stop: stop, parts: piece.parts)
        if faces.count != 6 {
            return "case-stair should list six faces, has \(faces.count)"
        }
        let anyFit = faces.contains { $0.fits }
        if reading.call == .proceed || reading.call == .turnIt {
            if !anyFit { return "case-stair says it fits, but no face clears" }
        }
        if reading.call == .leaveIt && anyFit && piece.parts.isEmpty {
            return "case-stair says leave it, but a face clears"
        }
        let steps = FitCarry.steps(piece: piece, stop: stop, report: report)
        if steps.count < 4 {
            return "case-stair carry steps are too thin to follow"
        }
        let namesStop = steps.contains { $0.contains(stop.name) }
        let namesCall = steps.contains { $0.localizedCaseInsensitiveContains(report.headline) }
        if !namesStop && !namesCall {
            return "case-stair steps never name the stop or the call"
        }
        let tape = FitQuestions.tape(box.width)
        if tape.isEmpty { return "case-stair tape line is empty" }
        let need = FitQuestions.openingNeeded(box: box, margin: max(stop.tertiaryMM, 0))
        if need.widthMM + 0.5 < box.minimumFace && need.heightMM + 0.5 < box.minimumFace {
            return "case-stair required opening is smaller than the smallest face"
        }
        if stop.module == .door || stop.module == .vehicle {
            let usableW = stop.primaryMM - stop.tertiaryMM
            let usableH = stop.secondaryMM - stop.tertiaryMM
            if usableW <= 0 || usableH <= 0 { return "case-stair opening collapsed after the keep-clear" }
            if reading.call == .proceed && box.width > usableW + 0.5 && box.depth > usableW + 0.5 {
                return "case-stair is marked load it, but neither plan face fits the width"
            }
        }
        if stop.module == .stair {
            let diagonal = FitQuestions.stairDiagonal(headroom: stop.secondaryMM, run: stop.tertiaryMM)
            if diagonal + 0.5 < stop.secondaryMM { return "case-stair stair diagonal is shorter than the headroom" }
        }
        if stop.module == .turn {
            let pole = FitQuestions.longestPole(hallA: stop.primaryMM, hallB: stop.secondaryMM)
            if pole + 0.5 < min(stop.primaryMM, stop.secondaryMM) { return "case-stair corner pole is shorter than a hall" }
        }
        if stop.module == .cargo && report.call != .leaveIt && report.call != .splitParts {
            if report.count < 1 { return "case-stair cargo call fits nothing" }
        }
        if stop.module == .spot && reading.call == .proceed {
            let avail = stop.primaryMM - stop.tertiaryMM
            if box.width > avail + 0.5 && box.depth > avail + 0.5 {
                return "case-stair is marked load it, but the footprint misses the floor"
            }
        }
        if reading.call == .splitParts {
            let stripped = box.reduced(by: piece.parts)
            if abs(stripped.width - box.width) < 0.5 && abs(stripped.depth - box.depth) < 0.5 && abs(stripped.height - box.height) < 0.5 {
                return "case-stair says take it apart, but nothing comes off"
            }
            let again = FitEngine.gate(module: stop.module, box: stripped, stop: stop, parts: [])
            if again.call == .leaveIt || again.call == .otherRoute {
                return "case-stair still does not fit after the parts come off"
            }
        }
        let worth = FitQuestions.partWorth(piece: piece, stop: stop)
        if worth.count != piece.parts.count {
            return "case-stair part check dropped a part"
        }
        let blankets = FitQuestions.blanketLimit(piece: piece, stop: stop, stock: .pine)
        if blankets < 0 || blankets > 8 {
            return "case-stair blanket limit is nonsense"
        }
        let order = FitQuestions.loadOrder(pieces: [piece], stops: [stop])
        if order.first?.pieceID != piece.id {
            return "case-stair fell out of the carry order"
        }
        let mass = FitHandling.kilograms(piece: piece, stock: .pine)
        let people = FitHandling.carriers(for: mass)
        if mass <= 0 || people < 1 {
            return "case-stair weight collapsed"
        }
        return nil
    }

    private static func checkCaseRear() -> String? {
        guard let piece = FitSeed.piece("case"), let stop = FitSeed.stop("van-rear"), let reading = FitSeed.reading("case-rear") else {
            return "case-rear is missing from the pickup"
        }
        let box = piece.box
        let report = FitEngine.gate(module: stop.module, box: box, stop: stop, parts: piece.parts)
        if report.call != reading.call {
            return "case-rear call is \(report.call.rawValue), the saved check says \(reading.call.rawValue)"
        }
        if abs(report.clearanceMM - reading.clearanceMM) > 2 {
            return "case-rear spare is \(report.clearanceMM), the saved check says \(reading.clearanceMM)"
        }
        if report.headline != report.call.title {
            return "case-rear headline drifted from the call"
        }
        let faces = FitQuestions.faces(box: box, stop: stop, parts: piece.parts)
        if faces.count != 6 {
            return "case-rear should list six faces, has \(faces.count)"
        }
        let anyFit = faces.contains { $0.fits }
        if reading.call == .proceed || reading.call == .turnIt {
            if !anyFit { return "case-rear says it fits, but no face clears" }
        }
        if reading.call == .leaveIt && anyFit && piece.parts.isEmpty {
            return "case-rear says leave it, but a face clears"
        }
        let steps = FitCarry.steps(piece: piece, stop: stop, report: report)
        if steps.count < 4 {
            return "case-rear carry steps are too thin to follow"
        }
        let namesStop = steps.contains { $0.contains(stop.name) }
        let namesCall = steps.contains { $0.localizedCaseInsensitiveContains(report.headline) }
        if !namesStop && !namesCall {
            return "case-rear steps never name the stop or the call"
        }
        let tape = FitQuestions.tape(box.width)
        if tape.isEmpty { return "case-rear tape line is empty" }
        let need = FitQuestions.openingNeeded(box: box, margin: max(stop.tertiaryMM, 0))
        if need.widthMM + 0.5 < box.minimumFace && need.heightMM + 0.5 < box.minimumFace {
            return "case-rear required opening is smaller than the smallest face"
        }
        if stop.module == .door || stop.module == .vehicle {
            let usableW = stop.primaryMM - stop.tertiaryMM
            let usableH = stop.secondaryMM - stop.tertiaryMM
            if usableW <= 0 || usableH <= 0 { return "case-rear opening collapsed after the keep-clear" }
            if reading.call == .proceed && box.width > usableW + 0.5 && box.depth > usableW + 0.5 {
                return "case-rear is marked load it, but neither plan face fits the width"
            }
        }
        if stop.module == .stair {
            let diagonal = FitQuestions.stairDiagonal(headroom: stop.secondaryMM, run: stop.tertiaryMM)
            if diagonal + 0.5 < stop.secondaryMM { return "case-rear stair diagonal is shorter than the headroom" }
        }
        if stop.module == .turn {
            let pole = FitQuestions.longestPole(hallA: stop.primaryMM, hallB: stop.secondaryMM)
            if pole + 0.5 < min(stop.primaryMM, stop.secondaryMM) { return "case-rear corner pole is shorter than a hall" }
        }
        if stop.module == .cargo && report.call != .leaveIt && report.call != .splitParts {
            if report.count < 1 { return "case-rear cargo call fits nothing" }
        }
        if stop.module == .spot && reading.call == .proceed {
            let avail = stop.primaryMM - stop.tertiaryMM
            if box.width > avail + 0.5 && box.depth > avail + 0.5 {
                return "case-rear is marked load it, but the footprint misses the floor"
            }
        }
        if reading.call == .splitParts {
            let stripped = box.reduced(by: piece.parts)
            if abs(stripped.width - box.width) < 0.5 && abs(stripped.depth - box.depth) < 0.5 && abs(stripped.height - box.height) < 0.5 {
                return "case-rear says take it apart, but nothing comes off"
            }
            let again = FitEngine.gate(module: stop.module, box: stripped, stop: stop, parts: [])
            if again.call == .leaveIt || again.call == .otherRoute {
                return "case-rear still does not fit after the parts come off"
            }
        }
        let worth = FitQuestions.partWorth(piece: piece, stop: stop)
        if worth.count != piece.parts.count {
            return "case-rear part check dropped a part"
        }
        let blankets = FitQuestions.blanketLimit(piece: piece, stop: stop, stock: .pine)
        if blankets < 0 || blankets > 8 {
            return "case-rear blanket limit is nonsense"
        }
        let order = FitQuestions.loadOrder(pieces: [piece], stops: [stop])
        if order.first?.pieceID != piece.id {
            return "case-rear fell out of the carry order"
        }
        let mass = FitHandling.kilograms(piece: piece, stock: .pine)
        let people = FitHandling.carriers(for: mass)
        if mass <= 0 || people < 1 {
            return "case-rear weight collapsed"
        }
        return nil
    }

    private static func checkCaseSide() -> String? {
        guard let piece = FitSeed.piece("case"), let stop = FitSeed.stop("van-side"), let reading = FitSeed.reading("case-side") else {
            return "case-side is missing from the pickup"
        }
        let box = piece.box
        let report = FitEngine.gate(module: stop.module, box: box, stop: stop, parts: piece.parts)
        if report.call != reading.call {
            return "case-side call is \(report.call.rawValue), the saved check says \(reading.call.rawValue)"
        }
        if abs(report.clearanceMM - reading.clearanceMM) > 2 {
            return "case-side spare is \(report.clearanceMM), the saved check says \(reading.clearanceMM)"
        }
        if report.headline != report.call.title {
            return "case-side headline drifted from the call"
        }
        let faces = FitQuestions.faces(box: box, stop: stop, parts: piece.parts)
        if faces.count != 6 {
            return "case-side should list six faces, has \(faces.count)"
        }
        let anyFit = faces.contains { $0.fits }
        if reading.call == .proceed || reading.call == .turnIt {
            if !anyFit { return "case-side says it fits, but no face clears" }
        }
        if reading.call == .leaveIt && anyFit && piece.parts.isEmpty {
            return "case-side says leave it, but a face clears"
        }
        let steps = FitCarry.steps(piece: piece, stop: stop, report: report)
        if steps.count < 4 {
            return "case-side carry steps are too thin to follow"
        }
        let namesStop = steps.contains { $0.contains(stop.name) }
        let namesCall = steps.contains { $0.localizedCaseInsensitiveContains(report.headline) }
        if !namesStop && !namesCall {
            return "case-side steps never name the stop or the call"
        }
        let tape = FitQuestions.tape(box.width)
        if tape.isEmpty { return "case-side tape line is empty" }
        let need = FitQuestions.openingNeeded(box: box, margin: max(stop.tertiaryMM, 0))
        if need.widthMM + 0.5 < box.minimumFace && need.heightMM + 0.5 < box.minimumFace {
            return "case-side required opening is smaller than the smallest face"
        }
        if stop.module == .door || stop.module == .vehicle {
            let usableW = stop.primaryMM - stop.tertiaryMM
            let usableH = stop.secondaryMM - stop.tertiaryMM
            if usableW <= 0 || usableH <= 0 { return "case-side opening collapsed after the keep-clear" }
            if reading.call == .proceed && box.width > usableW + 0.5 && box.depth > usableW + 0.5 {
                return "case-side is marked load it, but neither plan face fits the width"
            }
        }
        if stop.module == .stair {
            let diagonal = FitQuestions.stairDiagonal(headroom: stop.secondaryMM, run: stop.tertiaryMM)
            if diagonal + 0.5 < stop.secondaryMM { return "case-side stair diagonal is shorter than the headroom" }
        }
        if stop.module == .turn {
            let pole = FitQuestions.longestPole(hallA: stop.primaryMM, hallB: stop.secondaryMM)
            if pole + 0.5 < min(stop.primaryMM, stop.secondaryMM) { return "case-side corner pole is shorter than a hall" }
        }
        if stop.module == .cargo && report.call != .leaveIt && report.call != .splitParts {
            if report.count < 1 { return "case-side cargo call fits nothing" }
        }
        if stop.module == .spot && reading.call == .proceed {
            let avail = stop.primaryMM - stop.tertiaryMM
            if box.width > avail + 0.5 && box.depth > avail + 0.5 {
                return "case-side is marked load it, but the footprint misses the floor"
            }
        }
        if reading.call == .splitParts {
            let stripped = box.reduced(by: piece.parts)
            if abs(stripped.width - box.width) < 0.5 && abs(stripped.depth - box.depth) < 0.5 && abs(stripped.height - box.height) < 0.5 {
                return "case-side says take it apart, but nothing comes off"
            }
            let again = FitEngine.gate(module: stop.module, box: stripped, stop: stop, parts: [])
            if again.call == .leaveIt || again.call == .otherRoute {
                return "case-side still does not fit after the parts come off"
            }
        }
        let worth = FitQuestions.partWorth(piece: piece, stop: stop)
        if worth.count != piece.parts.count {
            return "case-side part check dropped a part"
        }
        let blankets = FitQuestions.blanketLimit(piece: piece, stop: stop, stock: .pine)
        if blankets < 0 || blankets > 8 {
            return "case-side blanket limit is nonsense"
        }
        let order = FitQuestions.loadOrder(pieces: [piece], stops: [stop])
        if order.first?.pieceID != piece.id {
            return "case-side fell out of the carry order"
        }
        let mass = FitHandling.kilograms(piece: piece, stock: .pine)
        let people = FitHandling.carriers(for: mass)
        if mass <= 0 || people < 1 {
            return "case-side weight collapsed"
        }
        return nil
    }

    private static func checkCaseBay() -> String? {
        guard let piece = FitSeed.piece("case"), let stop = FitSeed.stop("van-bay"), let reading = FitSeed.reading("case-bay") else {
            return "case-bay is missing from the pickup"
        }
        let box = piece.box
        let report = FitEngine.gate(module: stop.module, box: box, stop: stop, parts: piece.parts)
        if report.call != reading.call {
            return "case-bay call is \(report.call.rawValue), the saved check says \(reading.call.rawValue)"
        }
        if abs(report.clearanceMM - reading.clearanceMM) > 2 {
            return "case-bay spare is \(report.clearanceMM), the saved check says \(reading.clearanceMM)"
        }
        if report.headline != report.call.title {
            return "case-bay headline drifted from the call"
        }
        let faces = FitQuestions.faces(box: box, stop: stop, parts: piece.parts)
        if faces.count != 6 {
            return "case-bay should list six faces, has \(faces.count)"
        }
        let anyFit = faces.contains { $0.fits }
        if reading.call == .proceed || reading.call == .turnIt {
            if !anyFit { return "case-bay says it fits, but no face clears" }
        }
        if reading.call == .leaveIt && anyFit && piece.parts.isEmpty {
            return "case-bay says leave it, but a face clears"
        }
        let steps = FitCarry.steps(piece: piece, stop: stop, report: report)
        if steps.count < 4 {
            return "case-bay carry steps are too thin to follow"
        }
        let namesStop = steps.contains { $0.contains(stop.name) }
        let namesCall = steps.contains { $0.localizedCaseInsensitiveContains(report.headline) }
        if !namesStop && !namesCall {
            return "case-bay steps never name the stop or the call"
        }
        let tape = FitQuestions.tape(box.width)
        if tape.isEmpty { return "case-bay tape line is empty" }
        let need = FitQuestions.openingNeeded(box: box, margin: max(stop.tertiaryMM, 0))
        if need.widthMM + 0.5 < box.minimumFace && need.heightMM + 0.5 < box.minimumFace {
            return "case-bay required opening is smaller than the smallest face"
        }
        if stop.module == .door || stop.module == .vehicle {
            let usableW = stop.primaryMM - stop.tertiaryMM
            let usableH = stop.secondaryMM - stop.tertiaryMM
            if usableW <= 0 || usableH <= 0 { return "case-bay opening collapsed after the keep-clear" }
            if reading.call == .proceed && box.width > usableW + 0.5 && box.depth > usableW + 0.5 {
                return "case-bay is marked load it, but neither plan face fits the width"
            }
        }
        if stop.module == .stair {
            let diagonal = FitQuestions.stairDiagonal(headroom: stop.secondaryMM, run: stop.tertiaryMM)
            if diagonal + 0.5 < stop.secondaryMM { return "case-bay stair diagonal is shorter than the headroom" }
        }
        if stop.module == .turn {
            let pole = FitQuestions.longestPole(hallA: stop.primaryMM, hallB: stop.secondaryMM)
            if pole + 0.5 < min(stop.primaryMM, stop.secondaryMM) { return "case-bay corner pole is shorter than a hall" }
        }
        if stop.module == .cargo && report.call != .leaveIt && report.call != .splitParts {
            if report.count < 1 { return "case-bay cargo call fits nothing" }
        }
        if stop.module == .spot && reading.call == .proceed {
            let avail = stop.primaryMM - stop.tertiaryMM
            if box.width > avail + 0.5 && box.depth > avail + 0.5 {
                return "case-bay is marked load it, but the footprint misses the floor"
            }
        }
        if reading.call == .splitParts {
            let stripped = box.reduced(by: piece.parts)
            if abs(stripped.width - box.width) < 0.5 && abs(stripped.depth - box.depth) < 0.5 && abs(stripped.height - box.height) < 0.5 {
                return "case-bay says take it apart, but nothing comes off"
            }
            let again = FitEngine.gate(module: stop.module, box: stripped, stop: stop, parts: [])
            if again.call == .leaveIt || again.call == .otherRoute {
                return "case-bay still does not fit after the parts come off"
            }
        }
        let worth = FitQuestions.partWorth(piece: piece, stop: stop)
        if worth.count != piece.parts.count {
            return "case-bay part check dropped a part"
        }
        let blankets = FitQuestions.blanketLimit(piece: piece, stop: stop, stock: .pine)
        if blankets < 0 || blankets > 8 {
            return "case-bay blanket limit is nonsense"
        }
        let order = FitQuestions.loadOrder(pieces: [piece], stops: [stop])
        if order.first?.pieceID != piece.id {
            return "case-bay fell out of the carry order"
        }
        let mass = FitHandling.kilograms(piece: piece, stock: .pine)
        let people = FitHandling.carriers(for: mass)
        if mass <= 0 || people < 1 {
            return "case-bay weight collapsed"
        }
        return nil
    }

    private static func checkCaseSpot() -> String? {
        guard let piece = FitSeed.piece("case"), let stop = FitSeed.stop("storage-floor"), let reading = FitSeed.reading("case-spot") else {
            return "case-spot is missing from the pickup"
        }
        let box = piece.box
        let report = FitEngine.gate(module: stop.module, box: box, stop: stop, parts: piece.parts)
        if report.call != reading.call {
            return "case-spot call is \(report.call.rawValue), the saved check says \(reading.call.rawValue)"
        }
        if abs(report.clearanceMM - reading.clearanceMM) > 2 {
            return "case-spot spare is \(report.clearanceMM), the saved check says \(reading.clearanceMM)"
        }
        if report.headline != report.call.title {
            return "case-spot headline drifted from the call"
        }
        let faces = FitQuestions.faces(box: box, stop: stop, parts: piece.parts)
        if faces.count != 6 {
            return "case-spot should list six faces, has \(faces.count)"
        }
        let anyFit = faces.contains { $0.fits }
        if reading.call == .proceed || reading.call == .turnIt {
            if !anyFit { return "case-spot says it fits, but no face clears" }
        }
        if reading.call == .leaveIt && anyFit && piece.parts.isEmpty {
            return "case-spot says leave it, but a face clears"
        }
        let steps = FitCarry.steps(piece: piece, stop: stop, report: report)
        if steps.count < 4 {
            return "case-spot carry steps are too thin to follow"
        }
        let namesStop = steps.contains { $0.contains(stop.name) }
        let namesCall = steps.contains { $0.localizedCaseInsensitiveContains(report.headline) }
        if !namesStop && !namesCall {
            return "case-spot steps never name the stop or the call"
        }
        let tape = FitQuestions.tape(box.width)
        if tape.isEmpty { return "case-spot tape line is empty" }
        let need = FitQuestions.openingNeeded(box: box, margin: max(stop.tertiaryMM, 0))
        if need.widthMM + 0.5 < box.minimumFace && need.heightMM + 0.5 < box.minimumFace {
            return "case-spot required opening is smaller than the smallest face"
        }
        if stop.module == .door || stop.module == .vehicle {
            let usableW = stop.primaryMM - stop.tertiaryMM
            let usableH = stop.secondaryMM - stop.tertiaryMM
            if usableW <= 0 || usableH <= 0 { return "case-spot opening collapsed after the keep-clear" }
            if reading.call == .proceed && box.width > usableW + 0.5 && box.depth > usableW + 0.5 {
                return "case-spot is marked load it, but neither plan face fits the width"
            }
        }
        if stop.module == .stair {
            let diagonal = FitQuestions.stairDiagonal(headroom: stop.secondaryMM, run: stop.tertiaryMM)
            if diagonal + 0.5 < stop.secondaryMM { return "case-spot stair diagonal is shorter than the headroom" }
        }
        if stop.module == .turn {
            let pole = FitQuestions.longestPole(hallA: stop.primaryMM, hallB: stop.secondaryMM)
            if pole + 0.5 < min(stop.primaryMM, stop.secondaryMM) { return "case-spot corner pole is shorter than a hall" }
        }
        if stop.module == .cargo && report.call != .leaveIt && report.call != .splitParts {
            if report.count < 1 { return "case-spot cargo call fits nothing" }
        }
        if stop.module == .spot && reading.call == .proceed {
            let avail = stop.primaryMM - stop.tertiaryMM
            if box.width > avail + 0.5 && box.depth > avail + 0.5 {
                return "case-spot is marked load it, but the footprint misses the floor"
            }
        }
        if reading.call == .splitParts {
            let stripped = box.reduced(by: piece.parts)
            if abs(stripped.width - box.width) < 0.5 && abs(stripped.depth - box.depth) < 0.5 && abs(stripped.height - box.height) < 0.5 {
                return "case-spot says take it apart, but nothing comes off"
            }
            let again = FitEngine.gate(module: stop.module, box: stripped, stop: stop, parts: [])
            if again.call == .leaveIt || again.call == .otherRoute {
                return "case-spot still does not fit after the parts come off"
            }
        }
        let worth = FitQuestions.partWorth(piece: piece, stop: stop)
        if worth.count != piece.parts.count {
            return "case-spot part check dropped a part"
        }
        let blankets = FitQuestions.blanketLimit(piece: piece, stop: stop, stock: .pine)
        if blankets < 0 || blankets > 8 {
            return "case-spot blanket limit is nonsense"
        }
        let order = FitQuestions.loadOrder(pieces: [piece], stops: [stop])
        if order.first?.pieceID != piece.id {
            return "case-spot fell out of the carry order"
        }
        let mass = FitHandling.kilograms(piece: piece, stock: .pine)
        let people = FitHandling.carriers(for: mass)
        if mass <= 0 || people < 1 {
            return "case-spot weight collapsed"
        }
        return nil
    }

    private static func checkShelvesDoor() -> String? {
        guard let piece = FitSeed.piece("shelves"), let stop = FitSeed.stop("seller-door"), let reading = FitSeed.reading("shelves-door") else {
            return "shelves-door is missing from the pickup"
        }
        let box = piece.box
        let report = FitEngine.gate(module: stop.module, box: box, stop: stop, parts: piece.parts)
        if report.call != reading.call {
            return "shelves-door call is \(report.call.rawValue), the saved check says \(reading.call.rawValue)"
        }
        if abs(report.clearanceMM - reading.clearanceMM) > 2 {
            return "shelves-door spare is \(report.clearanceMM), the saved check says \(reading.clearanceMM)"
        }
        if report.headline != report.call.title {
            return "shelves-door headline drifted from the call"
        }
        let faces = FitQuestions.faces(box: box, stop: stop, parts: piece.parts)
        if faces.count != 6 {
            return "shelves-door should list six faces, has \(faces.count)"
        }
        let anyFit = faces.contains { $0.fits }
        if reading.call == .proceed || reading.call == .turnIt {
            if !anyFit { return "shelves-door says it fits, but no face clears" }
        }
        if reading.call == .leaveIt && anyFit && piece.parts.isEmpty {
            return "shelves-door says leave it, but a face clears"
        }
        let steps = FitCarry.steps(piece: piece, stop: stop, report: report)
        if steps.count < 4 {
            return "shelves-door carry steps are too thin to follow"
        }
        let namesStop = steps.contains { $0.contains(stop.name) }
        let namesCall = steps.contains { $0.localizedCaseInsensitiveContains(report.headline) }
        if !namesStop && !namesCall {
            return "shelves-door steps never name the stop or the call"
        }
        let tape = FitQuestions.tape(box.width)
        if tape.isEmpty { return "shelves-door tape line is empty" }
        let need = FitQuestions.openingNeeded(box: box, margin: max(stop.tertiaryMM, 0))
        if need.widthMM + 0.5 < box.minimumFace && need.heightMM + 0.5 < box.minimumFace {
            return "shelves-door required opening is smaller than the smallest face"
        }
        if stop.module == .door || stop.module == .vehicle {
            let usableW = stop.primaryMM - stop.tertiaryMM
            let usableH = stop.secondaryMM - stop.tertiaryMM
            if usableW <= 0 || usableH <= 0 { return "shelves-door opening collapsed after the keep-clear" }
            if reading.call == .proceed && box.width > usableW + 0.5 && box.depth > usableW + 0.5 {
                return "shelves-door is marked load it, but neither plan face fits the width"
            }
        }
        if stop.module == .stair {
            let diagonal = FitQuestions.stairDiagonal(headroom: stop.secondaryMM, run: stop.tertiaryMM)
            if diagonal + 0.5 < stop.secondaryMM { return "shelves-door stair diagonal is shorter than the headroom" }
        }
        if stop.module == .turn {
            let pole = FitQuestions.longestPole(hallA: stop.primaryMM, hallB: stop.secondaryMM)
            if pole + 0.5 < min(stop.primaryMM, stop.secondaryMM) { return "shelves-door corner pole is shorter than a hall" }
        }
        if stop.module == .cargo && report.call != .leaveIt && report.call != .splitParts {
            if report.count < 1 { return "shelves-door cargo call fits nothing" }
        }
        if stop.module == .spot && reading.call == .proceed {
            let avail = stop.primaryMM - stop.tertiaryMM
            if box.width > avail + 0.5 && box.depth > avail + 0.5 {
                return "shelves-door is marked load it, but the footprint misses the floor"
            }
        }
        if reading.call == .splitParts {
            let stripped = box.reduced(by: piece.parts)
            if abs(stripped.width - box.width) < 0.5 && abs(stripped.depth - box.depth) < 0.5 && abs(stripped.height - box.height) < 0.5 {
                return "shelves-door says take it apart, but nothing comes off"
            }
            let again = FitEngine.gate(module: stop.module, box: stripped, stop: stop, parts: [])
            if again.call == .leaveIt || again.call == .otherRoute {
                return "shelves-door still does not fit after the parts come off"
            }
        }
        let worth = FitQuestions.partWorth(piece: piece, stop: stop)
        if worth.count != piece.parts.count {
            return "shelves-door part check dropped a part"
        }
        let blankets = FitQuestions.blanketLimit(piece: piece, stop: stop, stock: .pine)
        if blankets < 0 || blankets > 8 {
            return "shelves-door blanket limit is nonsense"
        }
        let order = FitQuestions.loadOrder(pieces: [piece], stops: [stop])
        if order.first?.pieceID != piece.id {
            return "shelves-door fell out of the carry order"
        }
        let mass = FitHandling.kilograms(piece: piece, stock: .pine)
        let people = FitHandling.carriers(for: mass)
        if mass <= 0 || people < 1 {
            return "shelves-door weight collapsed"
        }
        return nil
    }

    private static func checkShelvesCorner() -> String? {
        guard let piece = FitSeed.piece("shelves"), let stop = FitSeed.stop("seller-corner"), let reading = FitSeed.reading("shelves-corner") else {
            return "shelves-corner is missing from the pickup"
        }
        let box = piece.box
        let report = FitEngine.gate(module: stop.module, box: box, stop: stop, parts: piece.parts)
        if report.call != reading.call {
            return "shelves-corner call is \(report.call.rawValue), the saved check says \(reading.call.rawValue)"
        }
        if abs(report.clearanceMM - reading.clearanceMM) > 2 {
            return "shelves-corner spare is \(report.clearanceMM), the saved check says \(reading.clearanceMM)"
        }
        if report.headline != report.call.title {
            return "shelves-corner headline drifted from the call"
        }
        let faces = FitQuestions.faces(box: box, stop: stop, parts: piece.parts)
        if faces.count != 6 {
            return "shelves-corner should list six faces, has \(faces.count)"
        }
        let anyFit = faces.contains { $0.fits }
        if reading.call == .proceed || reading.call == .turnIt {
            if !anyFit { return "shelves-corner says it fits, but no face clears" }
        }
        if reading.call == .leaveIt && anyFit && piece.parts.isEmpty {
            return "shelves-corner says leave it, but a face clears"
        }
        let steps = FitCarry.steps(piece: piece, stop: stop, report: report)
        if steps.count < 4 {
            return "shelves-corner carry steps are too thin to follow"
        }
        let namesStop = steps.contains { $0.contains(stop.name) }
        let namesCall = steps.contains { $0.localizedCaseInsensitiveContains(report.headline) }
        if !namesStop && !namesCall {
            return "shelves-corner steps never name the stop or the call"
        }
        let tape = FitQuestions.tape(box.width)
        if tape.isEmpty { return "shelves-corner tape line is empty" }
        let need = FitQuestions.openingNeeded(box: box, margin: max(stop.tertiaryMM, 0))
        if need.widthMM + 0.5 < box.minimumFace && need.heightMM + 0.5 < box.minimumFace {
            return "shelves-corner required opening is smaller than the smallest face"
        }
        if stop.module == .door || stop.module == .vehicle {
            let usableW = stop.primaryMM - stop.tertiaryMM
            let usableH = stop.secondaryMM - stop.tertiaryMM
            if usableW <= 0 || usableH <= 0 { return "shelves-corner opening collapsed after the keep-clear" }
            if reading.call == .proceed && box.width > usableW + 0.5 && box.depth > usableW + 0.5 {
                return "shelves-corner is marked load it, but neither plan face fits the width"
            }
        }
        if stop.module == .stair {
            let diagonal = FitQuestions.stairDiagonal(headroom: stop.secondaryMM, run: stop.tertiaryMM)
            if diagonal + 0.5 < stop.secondaryMM { return "shelves-corner stair diagonal is shorter than the headroom" }
        }
        if stop.module == .turn {
            let pole = FitQuestions.longestPole(hallA: stop.primaryMM, hallB: stop.secondaryMM)
            if pole + 0.5 < min(stop.primaryMM, stop.secondaryMM) { return "shelves-corner corner pole is shorter than a hall" }
        }
        if stop.module == .cargo && report.call != .leaveIt && report.call != .splitParts {
            if report.count < 1 { return "shelves-corner cargo call fits nothing" }
        }
        if stop.module == .spot && reading.call == .proceed {
            let avail = stop.primaryMM - stop.tertiaryMM
            if box.width > avail + 0.5 && box.depth > avail + 0.5 {
                return "shelves-corner is marked load it, but the footprint misses the floor"
            }
        }
        if reading.call == .splitParts {
            let stripped = box.reduced(by: piece.parts)
            if abs(stripped.width - box.width) < 0.5 && abs(stripped.depth - box.depth) < 0.5 && abs(stripped.height - box.height) < 0.5 {
                return "shelves-corner says take it apart, but nothing comes off"
            }
            let again = FitEngine.gate(module: stop.module, box: stripped, stop: stop, parts: [])
            if again.call == .leaveIt || again.call == .otherRoute {
                return "shelves-corner still does not fit after the parts come off"
            }
        }
        let worth = FitQuestions.partWorth(piece: piece, stop: stop)
        if worth.count != piece.parts.count {
            return "shelves-corner part check dropped a part"
        }
        let blankets = FitQuestions.blanketLimit(piece: piece, stop: stop, stock: .pine)
        if blankets < 0 || blankets > 8 {
            return "shelves-corner blanket limit is nonsense"
        }
        let order = FitQuestions.loadOrder(pieces: [piece], stops: [stop])
        if order.first?.pieceID != piece.id {
            return "shelves-corner fell out of the carry order"
        }
        let mass = FitHandling.kilograms(piece: piece, stock: .pine)
        let people = FitHandling.carriers(for: mass)
        if mass <= 0 || people < 1 {
            return "shelves-corner weight collapsed"
        }
        return nil
    }

    private static func checkShelvesStair() -> String? {
        guard let piece = FitSeed.piece("shelves"), let stop = FitSeed.stop("seller-stair"), let reading = FitSeed.reading("shelves-stair") else {
            return "shelves-stair is missing from the pickup"
        }
        let box = piece.box
        let report = FitEngine.gate(module: stop.module, box: box, stop: stop, parts: piece.parts)
        if report.call != reading.call {
            return "shelves-stair call is \(report.call.rawValue), the saved check says \(reading.call.rawValue)"
        }
        if abs(report.clearanceMM - reading.clearanceMM) > 2 {
            return "shelves-stair spare is \(report.clearanceMM), the saved check says \(reading.clearanceMM)"
        }
        if report.headline != report.call.title {
            return "shelves-stair headline drifted from the call"
        }
        let faces = FitQuestions.faces(box: box, stop: stop, parts: piece.parts)
        if faces.count != 6 {
            return "shelves-stair should list six faces, has \(faces.count)"
        }
        let anyFit = faces.contains { $0.fits }
        if reading.call == .proceed || reading.call == .turnIt {
            if !anyFit { return "shelves-stair says it fits, but no face clears" }
        }
        if reading.call == .leaveIt && anyFit && piece.parts.isEmpty {
            return "shelves-stair says leave it, but a face clears"
        }
        let steps = FitCarry.steps(piece: piece, stop: stop, report: report)
        if steps.count < 4 {
            return "shelves-stair carry steps are too thin to follow"
        }
        let namesStop = steps.contains { $0.contains(stop.name) }
        let namesCall = steps.contains { $0.localizedCaseInsensitiveContains(report.headline) }
        if !namesStop && !namesCall {
            return "shelves-stair steps never name the stop or the call"
        }
        let tape = FitQuestions.tape(box.width)
        if tape.isEmpty { return "shelves-stair tape line is empty" }
        let need = FitQuestions.openingNeeded(box: box, margin: max(stop.tertiaryMM, 0))
        if need.widthMM + 0.5 < box.minimumFace && need.heightMM + 0.5 < box.minimumFace {
            return "shelves-stair required opening is smaller than the smallest face"
        }
        if stop.module == .door || stop.module == .vehicle {
            let usableW = stop.primaryMM - stop.tertiaryMM
            let usableH = stop.secondaryMM - stop.tertiaryMM
            if usableW <= 0 || usableH <= 0 { return "shelves-stair opening collapsed after the keep-clear" }
            if reading.call == .proceed && box.width > usableW + 0.5 && box.depth > usableW + 0.5 {
                return "shelves-stair is marked load it, but neither plan face fits the width"
            }
        }
        if stop.module == .stair {
            let diagonal = FitQuestions.stairDiagonal(headroom: stop.secondaryMM, run: stop.tertiaryMM)
            if diagonal + 0.5 < stop.secondaryMM { return "shelves-stair stair diagonal is shorter than the headroom" }
        }
        if stop.module == .turn {
            let pole = FitQuestions.longestPole(hallA: stop.primaryMM, hallB: stop.secondaryMM)
            if pole + 0.5 < min(stop.primaryMM, stop.secondaryMM) { return "shelves-stair corner pole is shorter than a hall" }
        }
        if stop.module == .cargo && report.call != .leaveIt && report.call != .splitParts {
            if report.count < 1 { return "shelves-stair cargo call fits nothing" }
        }
        if stop.module == .spot && reading.call == .proceed {
            let avail = stop.primaryMM - stop.tertiaryMM
            if box.width > avail + 0.5 && box.depth > avail + 0.5 {
                return "shelves-stair is marked load it, but the footprint misses the floor"
            }
        }
        if reading.call == .splitParts {
            let stripped = box.reduced(by: piece.parts)
            if abs(stripped.width - box.width) < 0.5 && abs(stripped.depth - box.depth) < 0.5 && abs(stripped.height - box.height) < 0.5 {
                return "shelves-stair says take it apart, but nothing comes off"
            }
            let again = FitEngine.gate(module: stop.module, box: stripped, stop: stop, parts: [])
            if again.call == .leaveIt || again.call == .otherRoute {
                return "shelves-stair still does not fit after the parts come off"
            }
        }
        let worth = FitQuestions.partWorth(piece: piece, stop: stop)
        if worth.count != piece.parts.count {
            return "shelves-stair part check dropped a part"
        }
        let blankets = FitQuestions.blanketLimit(piece: piece, stop: stop, stock: .pine)
        if blankets < 0 || blankets > 8 {
            return "shelves-stair blanket limit is nonsense"
        }
        let order = FitQuestions.loadOrder(pieces: [piece], stops: [stop])
        if order.first?.pieceID != piece.id {
            return "shelves-stair fell out of the carry order"
        }
        let mass = FitHandling.kilograms(piece: piece, stock: .pine)
        let people = FitHandling.carriers(for: mass)
        if mass <= 0 || people < 1 {
            return "shelves-stair weight collapsed"
        }
        return nil
    }

    private static func checkShelvesRear() -> String? {
        guard let piece = FitSeed.piece("shelves"), let stop = FitSeed.stop("van-rear"), let reading = FitSeed.reading("shelves-rear") else {
            return "shelves-rear is missing from the pickup"
        }
        let box = piece.box
        let report = FitEngine.gate(module: stop.module, box: box, stop: stop, parts: piece.parts)
        if report.call != reading.call {
            return "shelves-rear call is \(report.call.rawValue), the saved check says \(reading.call.rawValue)"
        }
        if abs(report.clearanceMM - reading.clearanceMM) > 2 {
            return "shelves-rear spare is \(report.clearanceMM), the saved check says \(reading.clearanceMM)"
        }
        if report.headline != report.call.title {
            return "shelves-rear headline drifted from the call"
        }
        let faces = FitQuestions.faces(box: box, stop: stop, parts: piece.parts)
        if faces.count != 6 {
            return "shelves-rear should list six faces, has \(faces.count)"
        }
        let anyFit = faces.contains { $0.fits }
        if reading.call == .proceed || reading.call == .turnIt {
            if !anyFit { return "shelves-rear says it fits, but no face clears" }
        }
        if reading.call == .leaveIt && anyFit && piece.parts.isEmpty {
            return "shelves-rear says leave it, but a face clears"
        }
        let steps = FitCarry.steps(piece: piece, stop: stop, report: report)
        if steps.count < 4 {
            return "shelves-rear carry steps are too thin to follow"
        }
        let namesStop = steps.contains { $0.contains(stop.name) }
        let namesCall = steps.contains { $0.localizedCaseInsensitiveContains(report.headline) }
        if !namesStop && !namesCall {
            return "shelves-rear steps never name the stop or the call"
        }
        let tape = FitQuestions.tape(box.width)
        if tape.isEmpty { return "shelves-rear tape line is empty" }
        let need = FitQuestions.openingNeeded(box: box, margin: max(stop.tertiaryMM, 0))
        if need.widthMM + 0.5 < box.minimumFace && need.heightMM + 0.5 < box.minimumFace {
            return "shelves-rear required opening is smaller than the smallest face"
        }
        if stop.module == .door || stop.module == .vehicle {
            let usableW = stop.primaryMM - stop.tertiaryMM
            let usableH = stop.secondaryMM - stop.tertiaryMM
            if usableW <= 0 || usableH <= 0 { return "shelves-rear opening collapsed after the keep-clear" }
            if reading.call == .proceed && box.width > usableW + 0.5 && box.depth > usableW + 0.5 {
                return "shelves-rear is marked load it, but neither plan face fits the width"
            }
        }
        if stop.module == .stair {
            let diagonal = FitQuestions.stairDiagonal(headroom: stop.secondaryMM, run: stop.tertiaryMM)
            if diagonal + 0.5 < stop.secondaryMM { return "shelves-rear stair diagonal is shorter than the headroom" }
        }
        if stop.module == .turn {
            let pole = FitQuestions.longestPole(hallA: stop.primaryMM, hallB: stop.secondaryMM)
            if pole + 0.5 < min(stop.primaryMM, stop.secondaryMM) { return "shelves-rear corner pole is shorter than a hall" }
        }
        if stop.module == .cargo && report.call != .leaveIt && report.call != .splitParts {
            if report.count < 1 { return "shelves-rear cargo call fits nothing" }
        }
        if stop.module == .spot && reading.call == .proceed {
            let avail = stop.primaryMM - stop.tertiaryMM
            if box.width > avail + 0.5 && box.depth > avail + 0.5 {
                return "shelves-rear is marked load it, but the footprint misses the floor"
            }
        }
        if reading.call == .splitParts {
            let stripped = box.reduced(by: piece.parts)
            if abs(stripped.width - box.width) < 0.5 && abs(stripped.depth - box.depth) < 0.5 && abs(stripped.height - box.height) < 0.5 {
                return "shelves-rear says take it apart, but nothing comes off"
            }
            let again = FitEngine.gate(module: stop.module, box: stripped, stop: stop, parts: [])
            if again.call == .leaveIt || again.call == .otherRoute {
                return "shelves-rear still does not fit after the parts come off"
            }
        }
        let worth = FitQuestions.partWorth(piece: piece, stop: stop)
        if worth.count != piece.parts.count {
            return "shelves-rear part check dropped a part"
        }
        let blankets = FitQuestions.blanketLimit(piece: piece, stop: stop, stock: .pine)
        if blankets < 0 || blankets > 8 {
            return "shelves-rear blanket limit is nonsense"
        }
        let order = FitQuestions.loadOrder(pieces: [piece], stops: [stop])
        if order.first?.pieceID != piece.id {
            return "shelves-rear fell out of the carry order"
        }
        let mass = FitHandling.kilograms(piece: piece, stock: .pine)
        let people = FitHandling.carriers(for: mass)
        if mass <= 0 || people < 1 {
            return "shelves-rear weight collapsed"
        }
        return nil
    }

    private static func checkShelvesSide() -> String? {
        guard let piece = FitSeed.piece("shelves"), let stop = FitSeed.stop("van-side"), let reading = FitSeed.reading("shelves-side") else {
            return "shelves-side is missing from the pickup"
        }
        let box = piece.box
        let report = FitEngine.gate(module: stop.module, box: box, stop: stop, parts: piece.parts)
        if report.call != reading.call {
            return "shelves-side call is \(report.call.rawValue), the saved check says \(reading.call.rawValue)"
        }
        if abs(report.clearanceMM - reading.clearanceMM) > 2 {
            return "shelves-side spare is \(report.clearanceMM), the saved check says \(reading.clearanceMM)"
        }
        if report.headline != report.call.title {
            return "shelves-side headline drifted from the call"
        }
        let faces = FitQuestions.faces(box: box, stop: stop, parts: piece.parts)
        if faces.count != 6 {
            return "shelves-side should list six faces, has \(faces.count)"
        }
        let anyFit = faces.contains { $0.fits }
        if reading.call == .proceed || reading.call == .turnIt {
            if !anyFit { return "shelves-side says it fits, but no face clears" }
        }
        if reading.call == .leaveIt && anyFit && piece.parts.isEmpty {
            return "shelves-side says leave it, but a face clears"
        }
        let steps = FitCarry.steps(piece: piece, stop: stop, report: report)
        if steps.count < 4 {
            return "shelves-side carry steps are too thin to follow"
        }
        let namesStop = steps.contains { $0.contains(stop.name) }
        let namesCall = steps.contains { $0.localizedCaseInsensitiveContains(report.headline) }
        if !namesStop && !namesCall {
            return "shelves-side steps never name the stop or the call"
        }
        let tape = FitQuestions.tape(box.width)
        if tape.isEmpty { return "shelves-side tape line is empty" }
        let need = FitQuestions.openingNeeded(box: box, margin: max(stop.tertiaryMM, 0))
        if need.widthMM + 0.5 < box.minimumFace && need.heightMM + 0.5 < box.minimumFace {
            return "shelves-side required opening is smaller than the smallest face"
        }
        if stop.module == .door || stop.module == .vehicle {
            let usableW = stop.primaryMM - stop.tertiaryMM
            let usableH = stop.secondaryMM - stop.tertiaryMM
            if usableW <= 0 || usableH <= 0 { return "shelves-side opening collapsed after the keep-clear" }
            if reading.call == .proceed && box.width > usableW + 0.5 && box.depth > usableW + 0.5 {
                return "shelves-side is marked load it, but neither plan face fits the width"
            }
        }
        if stop.module == .stair {
            let diagonal = FitQuestions.stairDiagonal(headroom: stop.secondaryMM, run: stop.tertiaryMM)
            if diagonal + 0.5 < stop.secondaryMM { return "shelves-side stair diagonal is shorter than the headroom" }
        }
        if stop.module == .turn {
            let pole = FitQuestions.longestPole(hallA: stop.primaryMM, hallB: stop.secondaryMM)
            if pole + 0.5 < min(stop.primaryMM, stop.secondaryMM) { return "shelves-side corner pole is shorter than a hall" }
        }
        if stop.module == .cargo && report.call != .leaveIt && report.call != .splitParts {
            if report.count < 1 { return "shelves-side cargo call fits nothing" }
        }
        if stop.module == .spot && reading.call == .proceed {
            let avail = stop.primaryMM - stop.tertiaryMM
            if box.width > avail + 0.5 && box.depth > avail + 0.5 {
                return "shelves-side is marked load it, but the footprint misses the floor"
            }
        }
        if reading.call == .splitParts {
            let stripped = box.reduced(by: piece.parts)
            if abs(stripped.width - box.width) < 0.5 && abs(stripped.depth - box.depth) < 0.5 && abs(stripped.height - box.height) < 0.5 {
                return "shelves-side says take it apart, but nothing comes off"
            }
            let again = FitEngine.gate(module: stop.module, box: stripped, stop: stop, parts: [])
            if again.call == .leaveIt || again.call == .otherRoute {
                return "shelves-side still does not fit after the parts come off"
            }
        }
        let worth = FitQuestions.partWorth(piece: piece, stop: stop)
        if worth.count != piece.parts.count {
            return "shelves-side part check dropped a part"
        }
        let blankets = FitQuestions.blanketLimit(piece: piece, stop: stop, stock: .pine)
        if blankets < 0 || blankets > 8 {
            return "shelves-side blanket limit is nonsense"
        }
        let order = FitQuestions.loadOrder(pieces: [piece], stops: [stop])
        if order.first?.pieceID != piece.id {
            return "shelves-side fell out of the carry order"
        }
        let mass = FitHandling.kilograms(piece: piece, stock: .pine)
        let people = FitHandling.carriers(for: mass)
        if mass <= 0 || people < 1 {
            return "shelves-side weight collapsed"
        }
        return nil
    }

    private static func checkShelvesBay() -> String? {
        guard let piece = FitSeed.piece("shelves"), let stop = FitSeed.stop("van-bay"), let reading = FitSeed.reading("shelves-bay") else {
            return "shelves-bay is missing from the pickup"
        }
        let box = piece.box
        let report = FitEngine.gate(module: stop.module, box: box, stop: stop, parts: piece.parts)
        if report.call != reading.call {
            return "shelves-bay call is \(report.call.rawValue), the saved check says \(reading.call.rawValue)"
        }
        if abs(report.clearanceMM - reading.clearanceMM) > 2 {
            return "shelves-bay spare is \(report.clearanceMM), the saved check says \(reading.clearanceMM)"
        }
        if report.headline != report.call.title {
            return "shelves-bay headline drifted from the call"
        }
        let faces = FitQuestions.faces(box: box, stop: stop, parts: piece.parts)
        if faces.count != 6 {
            return "shelves-bay should list six faces, has \(faces.count)"
        }
        let anyFit = faces.contains { $0.fits }
        if reading.call == .proceed || reading.call == .turnIt {
            if !anyFit { return "shelves-bay says it fits, but no face clears" }
        }
        if reading.call == .leaveIt && anyFit && piece.parts.isEmpty {
            return "shelves-bay says leave it, but a face clears"
        }
        let steps = FitCarry.steps(piece: piece, stop: stop, report: report)
        if steps.count < 4 {
            return "shelves-bay carry steps are too thin to follow"
        }
        let namesStop = steps.contains { $0.contains(stop.name) }
        let namesCall = steps.contains { $0.localizedCaseInsensitiveContains(report.headline) }
        if !namesStop && !namesCall {
            return "shelves-bay steps never name the stop or the call"
        }
        let tape = FitQuestions.tape(box.width)
        if tape.isEmpty { return "shelves-bay tape line is empty" }
        let need = FitQuestions.openingNeeded(box: box, margin: max(stop.tertiaryMM, 0))
        if need.widthMM + 0.5 < box.minimumFace && need.heightMM + 0.5 < box.minimumFace {
            return "shelves-bay required opening is smaller than the smallest face"
        }
        if stop.module == .door || stop.module == .vehicle {
            let usableW = stop.primaryMM - stop.tertiaryMM
            let usableH = stop.secondaryMM - stop.tertiaryMM
            if usableW <= 0 || usableH <= 0 { return "shelves-bay opening collapsed after the keep-clear" }
            if reading.call == .proceed && box.width > usableW + 0.5 && box.depth > usableW + 0.5 {
                return "shelves-bay is marked load it, but neither plan face fits the width"
            }
        }
        if stop.module == .stair {
            let diagonal = FitQuestions.stairDiagonal(headroom: stop.secondaryMM, run: stop.tertiaryMM)
            if diagonal + 0.5 < stop.secondaryMM { return "shelves-bay stair diagonal is shorter than the headroom" }
        }
        if stop.module == .turn {
            let pole = FitQuestions.longestPole(hallA: stop.primaryMM, hallB: stop.secondaryMM)
            if pole + 0.5 < min(stop.primaryMM, stop.secondaryMM) { return "shelves-bay corner pole is shorter than a hall" }
        }
        if stop.module == .cargo && report.call != .leaveIt && report.call != .splitParts {
            if report.count < 1 { return "shelves-bay cargo call fits nothing" }
        }
        if stop.module == .spot && reading.call == .proceed {
            let avail = stop.primaryMM - stop.tertiaryMM
            if box.width > avail + 0.5 && box.depth > avail + 0.5 {
                return "shelves-bay is marked load it, but the footprint misses the floor"
            }
        }
        if reading.call == .splitParts {
            let stripped = box.reduced(by: piece.parts)
            if abs(stripped.width - box.width) < 0.5 && abs(stripped.depth - box.depth) < 0.5 && abs(stripped.height - box.height) < 0.5 {
                return "shelves-bay says take it apart, but nothing comes off"
            }
            let again = FitEngine.gate(module: stop.module, box: stripped, stop: stop, parts: [])
            if again.call == .leaveIt || again.call == .otherRoute {
                return "shelves-bay still does not fit after the parts come off"
            }
        }
        let worth = FitQuestions.partWorth(piece: piece, stop: stop)
        if worth.count != piece.parts.count {
            return "shelves-bay part check dropped a part"
        }
        let blankets = FitQuestions.blanketLimit(piece: piece, stop: stop, stock: .pine)
        if blankets < 0 || blankets > 8 {
            return "shelves-bay blanket limit is nonsense"
        }
        let order = FitQuestions.loadOrder(pieces: [piece], stops: [stop])
        if order.first?.pieceID != piece.id {
            return "shelves-bay fell out of the carry order"
        }
        let mass = FitHandling.kilograms(piece: piece, stock: .pine)
        let people = FitHandling.carriers(for: mass)
        if mass <= 0 || people < 1 {
            return "shelves-bay weight collapsed"
        }
        return nil
    }

    private static func checkShelvesSpot() -> String? {
        guard let piece = FitSeed.piece("shelves"), let stop = FitSeed.stop("storage-floor"), let reading = FitSeed.reading("shelves-spot") else {
            return "shelves-spot is missing from the pickup"
        }
        let box = piece.box
        let report = FitEngine.gate(module: stop.module, box: box, stop: stop, parts: piece.parts)
        if report.call != reading.call {
            return "shelves-spot call is \(report.call.rawValue), the saved check says \(reading.call.rawValue)"
        }
        if abs(report.clearanceMM - reading.clearanceMM) > 2 {
            return "shelves-spot spare is \(report.clearanceMM), the saved check says \(reading.clearanceMM)"
        }
        if report.headline != report.call.title {
            return "shelves-spot headline drifted from the call"
        }
        let faces = FitQuestions.faces(box: box, stop: stop, parts: piece.parts)
        if faces.count != 6 {
            return "shelves-spot should list six faces, has \(faces.count)"
        }
        let anyFit = faces.contains { $0.fits }
        if reading.call == .proceed || reading.call == .turnIt {
            if !anyFit { return "shelves-spot says it fits, but no face clears" }
        }
        if reading.call == .leaveIt && anyFit && piece.parts.isEmpty {
            return "shelves-spot says leave it, but a face clears"
        }
        let steps = FitCarry.steps(piece: piece, stop: stop, report: report)
        if steps.count < 4 {
            return "shelves-spot carry steps are too thin to follow"
        }
        let namesStop = steps.contains { $0.contains(stop.name) }
        let namesCall = steps.contains { $0.localizedCaseInsensitiveContains(report.headline) }
        if !namesStop && !namesCall {
            return "shelves-spot steps never name the stop or the call"
        }
        let tape = FitQuestions.tape(box.width)
        if tape.isEmpty { return "shelves-spot tape line is empty" }
        let need = FitQuestions.openingNeeded(box: box, margin: max(stop.tertiaryMM, 0))
        if need.widthMM + 0.5 < box.minimumFace && need.heightMM + 0.5 < box.minimumFace {
            return "shelves-spot required opening is smaller than the smallest face"
        }
        if stop.module == .door || stop.module == .vehicle {
            let usableW = stop.primaryMM - stop.tertiaryMM
            let usableH = stop.secondaryMM - stop.tertiaryMM
            if usableW <= 0 || usableH <= 0 { return "shelves-spot opening collapsed after the keep-clear" }
            if reading.call == .proceed && box.width > usableW + 0.5 && box.depth > usableW + 0.5 {
                return "shelves-spot is marked load it, but neither plan face fits the width"
            }
        }
        if stop.module == .stair {
            let diagonal = FitQuestions.stairDiagonal(headroom: stop.secondaryMM, run: stop.tertiaryMM)
            if diagonal + 0.5 < stop.secondaryMM { return "shelves-spot stair diagonal is shorter than the headroom" }
        }
        if stop.module == .turn {
            let pole = FitQuestions.longestPole(hallA: stop.primaryMM, hallB: stop.secondaryMM)
            if pole + 0.5 < min(stop.primaryMM, stop.secondaryMM) { return "shelves-spot corner pole is shorter than a hall" }
        }
        if stop.module == .cargo && report.call != .leaveIt && report.call != .splitParts {
            if report.count < 1 { return "shelves-spot cargo call fits nothing" }
        }
        if stop.module == .spot && reading.call == .proceed {
            let avail = stop.primaryMM - stop.tertiaryMM
            if box.width > avail + 0.5 && box.depth > avail + 0.5 {
                return "shelves-spot is marked load it, but the footprint misses the floor"
            }
        }
        if reading.call == .splitParts {
            let stripped = box.reduced(by: piece.parts)
            if abs(stripped.width - box.width) < 0.5 && abs(stripped.depth - box.depth) < 0.5 && abs(stripped.height - box.height) < 0.5 {
                return "shelves-spot says take it apart, but nothing comes off"
            }
            let again = FitEngine.gate(module: stop.module, box: stripped, stop: stop, parts: [])
            if again.call == .leaveIt || again.call == .otherRoute {
                return "shelves-spot still does not fit after the parts come off"
            }
        }
        let worth = FitQuestions.partWorth(piece: piece, stop: stop)
        if worth.count != piece.parts.count {
            return "shelves-spot part check dropped a part"
        }
        let blankets = FitQuestions.blanketLimit(piece: piece, stop: stop, stock: .pine)
        if blankets < 0 || blankets > 8 {
            return "shelves-spot blanket limit is nonsense"
        }
        let order = FitQuestions.loadOrder(pieces: [piece], stops: [stop])
        if order.first?.pieceID != piece.id {
            return "shelves-spot fell out of the carry order"
        }
        let mass = FitHandling.kilograms(piece: piece, stock: .pine)
        let people = FitHandling.carriers(for: mass)
        if mass <= 0 || people < 1 {
            return "shelves-spot weight collapsed"
        }
        return nil
    }

    private static func checkBackDoor() -> String? {
        guard let piece = FitSeed.piece("back"), let stop = FitSeed.stop("seller-door"), let reading = FitSeed.reading("back-door") else {
            return "back-door is missing from the pickup"
        }
        let box = piece.box
        let report = FitEngine.gate(module: stop.module, box: box, stop: stop, parts: piece.parts)
        if report.call != reading.call {
            return "back-door call is \(report.call.rawValue), the saved check says \(reading.call.rawValue)"
        }
        if abs(report.clearanceMM - reading.clearanceMM) > 2 {
            return "back-door spare is \(report.clearanceMM), the saved check says \(reading.clearanceMM)"
        }
        if report.headline != report.call.title {
            return "back-door headline drifted from the call"
        }
        let faces = FitQuestions.faces(box: box, stop: stop, parts: piece.parts)
        if faces.count != 6 {
            return "back-door should list six faces, has \(faces.count)"
        }
        let anyFit = faces.contains { $0.fits }
        if reading.call == .proceed || reading.call == .turnIt {
            if !anyFit { return "back-door says it fits, but no face clears" }
        }
        if reading.call == .leaveIt && anyFit && piece.parts.isEmpty {
            return "back-door says leave it, but a face clears"
        }
        let steps = FitCarry.steps(piece: piece, stop: stop, report: report)
        if steps.count < 4 {
            return "back-door carry steps are too thin to follow"
        }
        let namesStop = steps.contains { $0.contains(stop.name) }
        let namesCall = steps.contains { $0.localizedCaseInsensitiveContains(report.headline) }
        if !namesStop && !namesCall {
            return "back-door steps never name the stop or the call"
        }
        let tape = FitQuestions.tape(box.width)
        if tape.isEmpty { return "back-door tape line is empty" }
        let need = FitQuestions.openingNeeded(box: box, margin: max(stop.tertiaryMM, 0))
        if need.widthMM + 0.5 < box.minimumFace && need.heightMM + 0.5 < box.minimumFace {
            return "back-door required opening is smaller than the smallest face"
        }
        if stop.module == .door || stop.module == .vehicle {
            let usableW = stop.primaryMM - stop.tertiaryMM
            let usableH = stop.secondaryMM - stop.tertiaryMM
            if usableW <= 0 || usableH <= 0 { return "back-door opening collapsed after the keep-clear" }
            if reading.call == .proceed && box.width > usableW + 0.5 && box.depth > usableW + 0.5 {
                return "back-door is marked load it, but neither plan face fits the width"
            }
        }
        if stop.module == .stair {
            let diagonal = FitQuestions.stairDiagonal(headroom: stop.secondaryMM, run: stop.tertiaryMM)
            if diagonal + 0.5 < stop.secondaryMM { return "back-door stair diagonal is shorter than the headroom" }
        }
        if stop.module == .turn {
            let pole = FitQuestions.longestPole(hallA: stop.primaryMM, hallB: stop.secondaryMM)
            if pole + 0.5 < min(stop.primaryMM, stop.secondaryMM) { return "back-door corner pole is shorter than a hall" }
        }
        if stop.module == .cargo && report.call != .leaveIt && report.call != .splitParts {
            if report.count < 1 { return "back-door cargo call fits nothing" }
        }
        if stop.module == .spot && reading.call == .proceed {
            let avail = stop.primaryMM - stop.tertiaryMM
            if box.width > avail + 0.5 && box.depth > avail + 0.5 {
                return "back-door is marked load it, but the footprint misses the floor"
            }
        }
        if reading.call == .splitParts {
            let stripped = box.reduced(by: piece.parts)
            if abs(stripped.width - box.width) < 0.5 && abs(stripped.depth - box.depth) < 0.5 && abs(stripped.height - box.height) < 0.5 {
                return "back-door says take it apart, but nothing comes off"
            }
            let again = FitEngine.gate(module: stop.module, box: stripped, stop: stop, parts: [])
            if again.call == .leaveIt || again.call == .otherRoute {
                return "back-door still does not fit after the parts come off"
            }
        }
        let worth = FitQuestions.partWorth(piece: piece, stop: stop)
        if worth.count != piece.parts.count {
            return "back-door part check dropped a part"
        }
        let blankets = FitQuestions.blanketLimit(piece: piece, stop: stop, stock: .pine)
        if blankets < 0 || blankets > 8 {
            return "back-door blanket limit is nonsense"
        }
        let order = FitQuestions.loadOrder(pieces: [piece], stops: [stop])
        if order.first?.pieceID != piece.id {
            return "back-door fell out of the carry order"
        }
        let mass = FitHandling.kilograms(piece: piece, stock: .pine)
        let people = FitHandling.carriers(for: mass)
        if mass <= 0 || people < 1 {
            return "back-door weight collapsed"
        }
        return nil
    }

    private static func checkBackCorner() -> String? {
        guard let piece = FitSeed.piece("back"), let stop = FitSeed.stop("seller-corner"), let reading = FitSeed.reading("back-corner") else {
            return "back-corner is missing from the pickup"
        }
        let box = piece.box
        let report = FitEngine.gate(module: stop.module, box: box, stop: stop, parts: piece.parts)
        if report.call != reading.call {
            return "back-corner call is \(report.call.rawValue), the saved check says \(reading.call.rawValue)"
        }
        if abs(report.clearanceMM - reading.clearanceMM) > 2 {
            return "back-corner spare is \(report.clearanceMM), the saved check says \(reading.clearanceMM)"
        }
        if report.headline != report.call.title {
            return "back-corner headline drifted from the call"
        }
        let faces = FitQuestions.faces(box: box, stop: stop, parts: piece.parts)
        if faces.count != 6 {
            return "back-corner should list six faces, has \(faces.count)"
        }
        let anyFit = faces.contains { $0.fits }
        if reading.call == .proceed || reading.call == .turnIt {
            if !anyFit { return "back-corner says it fits, but no face clears" }
        }
        if reading.call == .leaveIt && anyFit && piece.parts.isEmpty {
            return "back-corner says leave it, but a face clears"
        }
        let steps = FitCarry.steps(piece: piece, stop: stop, report: report)
        if steps.count < 4 {
            return "back-corner carry steps are too thin to follow"
        }
        let namesStop = steps.contains { $0.contains(stop.name) }
        let namesCall = steps.contains { $0.localizedCaseInsensitiveContains(report.headline) }
        if !namesStop && !namesCall {
            return "back-corner steps never name the stop or the call"
        }
        let tape = FitQuestions.tape(box.width)
        if tape.isEmpty { return "back-corner tape line is empty" }
        let need = FitQuestions.openingNeeded(box: box, margin: max(stop.tertiaryMM, 0))
        if need.widthMM + 0.5 < box.minimumFace && need.heightMM + 0.5 < box.minimumFace {
            return "back-corner required opening is smaller than the smallest face"
        }
        if stop.module == .door || stop.module == .vehicle {
            let usableW = stop.primaryMM - stop.tertiaryMM
            let usableH = stop.secondaryMM - stop.tertiaryMM
            if usableW <= 0 || usableH <= 0 { return "back-corner opening collapsed after the keep-clear" }
            if reading.call == .proceed && box.width > usableW + 0.5 && box.depth > usableW + 0.5 {
                return "back-corner is marked load it, but neither plan face fits the width"
            }
        }
        if stop.module == .stair {
            let diagonal = FitQuestions.stairDiagonal(headroom: stop.secondaryMM, run: stop.tertiaryMM)
            if diagonal + 0.5 < stop.secondaryMM { return "back-corner stair diagonal is shorter than the headroom" }
        }
        if stop.module == .turn {
            let pole = FitQuestions.longestPole(hallA: stop.primaryMM, hallB: stop.secondaryMM)
            if pole + 0.5 < min(stop.primaryMM, stop.secondaryMM) { return "back-corner corner pole is shorter than a hall" }
        }
        if stop.module == .cargo && report.call != .leaveIt && report.call != .splitParts {
            if report.count < 1 { return "back-corner cargo call fits nothing" }
        }
        if stop.module == .spot && reading.call == .proceed {
            let avail = stop.primaryMM - stop.tertiaryMM
            if box.width > avail + 0.5 && box.depth > avail + 0.5 {
                return "back-corner is marked load it, but the footprint misses the floor"
            }
        }
        if reading.call == .splitParts {
            let stripped = box.reduced(by: piece.parts)
            if abs(stripped.width - box.width) < 0.5 && abs(stripped.depth - box.depth) < 0.5 && abs(stripped.height - box.height) < 0.5 {
                return "back-corner says take it apart, but nothing comes off"
            }
            let again = FitEngine.gate(module: stop.module, box: stripped, stop: stop, parts: [])
            if again.call == .leaveIt || again.call == .otherRoute {
                return "back-corner still does not fit after the parts come off"
            }
        }
        let worth = FitQuestions.partWorth(piece: piece, stop: stop)
        if worth.count != piece.parts.count {
            return "back-corner part check dropped a part"
        }
        let blankets = FitQuestions.blanketLimit(piece: piece, stop: stop, stock: .pine)
        if blankets < 0 || blankets > 8 {
            return "back-corner blanket limit is nonsense"
        }
        let order = FitQuestions.loadOrder(pieces: [piece], stops: [stop])
        if order.first?.pieceID != piece.id {
            return "back-corner fell out of the carry order"
        }
        let mass = FitHandling.kilograms(piece: piece, stock: .pine)
        let people = FitHandling.carriers(for: mass)
        if mass <= 0 || people < 1 {
            return "back-corner weight collapsed"
        }
        return nil
    }

    private static func checkBackStair() -> String? {
        guard let piece = FitSeed.piece("back"), let stop = FitSeed.stop("seller-stair"), let reading = FitSeed.reading("back-stair") else {
            return "back-stair is missing from the pickup"
        }
        let box = piece.box
        let report = FitEngine.gate(module: stop.module, box: box, stop: stop, parts: piece.parts)
        if report.call != reading.call {
            return "back-stair call is \(report.call.rawValue), the saved check says \(reading.call.rawValue)"
        }
        if abs(report.clearanceMM - reading.clearanceMM) > 2 {
            return "back-stair spare is \(report.clearanceMM), the saved check says \(reading.clearanceMM)"
        }
        if report.headline != report.call.title {
            return "back-stair headline drifted from the call"
        }
        let faces = FitQuestions.faces(box: box, stop: stop, parts: piece.parts)
        if faces.count != 6 {
            return "back-stair should list six faces, has \(faces.count)"
        }
        let anyFit = faces.contains { $0.fits }
        if reading.call == .proceed || reading.call == .turnIt {
            if !anyFit { return "back-stair says it fits, but no face clears" }
        }
        if reading.call == .leaveIt && anyFit && piece.parts.isEmpty {
            return "back-stair says leave it, but a face clears"
        }
        let steps = FitCarry.steps(piece: piece, stop: stop, report: report)
        if steps.count < 4 {
            return "back-stair carry steps are too thin to follow"
        }
        let namesStop = steps.contains { $0.contains(stop.name) }
        let namesCall = steps.contains { $0.localizedCaseInsensitiveContains(report.headline) }
        if !namesStop && !namesCall {
            return "back-stair steps never name the stop or the call"
        }
        let tape = FitQuestions.tape(box.width)
        if tape.isEmpty { return "back-stair tape line is empty" }
        let need = FitQuestions.openingNeeded(box: box, margin: max(stop.tertiaryMM, 0))
        if need.widthMM + 0.5 < box.minimumFace && need.heightMM + 0.5 < box.minimumFace {
            return "back-stair required opening is smaller than the smallest face"
        }
        if stop.module == .door || stop.module == .vehicle {
            let usableW = stop.primaryMM - stop.tertiaryMM
            let usableH = stop.secondaryMM - stop.tertiaryMM
            if usableW <= 0 || usableH <= 0 { return "back-stair opening collapsed after the keep-clear" }
            if reading.call == .proceed && box.width > usableW + 0.5 && box.depth > usableW + 0.5 {
                return "back-stair is marked load it, but neither plan face fits the width"
            }
        }
        if stop.module == .stair {
            let diagonal = FitQuestions.stairDiagonal(headroom: stop.secondaryMM, run: stop.tertiaryMM)
            if diagonal + 0.5 < stop.secondaryMM { return "back-stair stair diagonal is shorter than the headroom" }
        }
        if stop.module == .turn {
            let pole = FitQuestions.longestPole(hallA: stop.primaryMM, hallB: stop.secondaryMM)
            if pole + 0.5 < min(stop.primaryMM, stop.secondaryMM) { return "back-stair corner pole is shorter than a hall" }
        }
        if stop.module == .cargo && report.call != .leaveIt && report.call != .splitParts {
            if report.count < 1 { return "back-stair cargo call fits nothing" }
        }
        if stop.module == .spot && reading.call == .proceed {
            let avail = stop.primaryMM - stop.tertiaryMM
            if box.width > avail + 0.5 && box.depth > avail + 0.5 {
                return "back-stair is marked load it, but the footprint misses the floor"
            }
        }
        if reading.call == .splitParts {
            let stripped = box.reduced(by: piece.parts)
            if abs(stripped.width - box.width) < 0.5 && abs(stripped.depth - box.depth) < 0.5 && abs(stripped.height - box.height) < 0.5 {
                return "back-stair says take it apart, but nothing comes off"
            }
            let again = FitEngine.gate(module: stop.module, box: stripped, stop: stop, parts: [])
            if again.call == .leaveIt || again.call == .otherRoute {
                return "back-stair still does not fit after the parts come off"
            }
        }
        let worth = FitQuestions.partWorth(piece: piece, stop: stop)
        if worth.count != piece.parts.count {
            return "back-stair part check dropped a part"
        }
        let blankets = FitQuestions.blanketLimit(piece: piece, stop: stop, stock: .pine)
        if blankets < 0 || blankets > 8 {
            return "back-stair blanket limit is nonsense"
        }
        let order = FitQuestions.loadOrder(pieces: [piece], stops: [stop])
        if order.first?.pieceID != piece.id {
            return "back-stair fell out of the carry order"
        }
        let mass = FitHandling.kilograms(piece: piece, stock: .pine)
        let people = FitHandling.carriers(for: mass)
        if mass <= 0 || people < 1 {
            return "back-stair weight collapsed"
        }
        return nil
    }

    private static func checkBackRear() -> String? {
        guard let piece = FitSeed.piece("back"), let stop = FitSeed.stop("van-rear"), let reading = FitSeed.reading("back-rear") else {
            return "back-rear is missing from the pickup"
        }
        let box = piece.box
        let report = FitEngine.gate(module: stop.module, box: box, stop: stop, parts: piece.parts)
        if report.call != reading.call {
            return "back-rear call is \(report.call.rawValue), the saved check says \(reading.call.rawValue)"
        }
        if abs(report.clearanceMM - reading.clearanceMM) > 2 {
            return "back-rear spare is \(report.clearanceMM), the saved check says \(reading.clearanceMM)"
        }
        if report.headline != report.call.title {
            return "back-rear headline drifted from the call"
        }
        let faces = FitQuestions.faces(box: box, stop: stop, parts: piece.parts)
        if faces.count != 6 {
            return "back-rear should list six faces, has \(faces.count)"
        }
        let anyFit = faces.contains { $0.fits }
        if reading.call == .proceed || reading.call == .turnIt {
            if !anyFit { return "back-rear says it fits, but no face clears" }
        }
        if reading.call == .leaveIt && anyFit && piece.parts.isEmpty {
            return "back-rear says leave it, but a face clears"
        }
        let steps = FitCarry.steps(piece: piece, stop: stop, report: report)
        if steps.count < 4 {
            return "back-rear carry steps are too thin to follow"
        }
        let namesStop = steps.contains { $0.contains(stop.name) }
        let namesCall = steps.contains { $0.localizedCaseInsensitiveContains(report.headline) }
        if !namesStop && !namesCall {
            return "back-rear steps never name the stop or the call"
        }
        let tape = FitQuestions.tape(box.width)
        if tape.isEmpty { return "back-rear tape line is empty" }
        let need = FitQuestions.openingNeeded(box: box, margin: max(stop.tertiaryMM, 0))
        if need.widthMM + 0.5 < box.minimumFace && need.heightMM + 0.5 < box.minimumFace {
            return "back-rear required opening is smaller than the smallest face"
        }
        if stop.module == .door || stop.module == .vehicle {
            let usableW = stop.primaryMM - stop.tertiaryMM
            let usableH = stop.secondaryMM - stop.tertiaryMM
            if usableW <= 0 || usableH <= 0 { return "back-rear opening collapsed after the keep-clear" }
            if reading.call == .proceed && box.width > usableW + 0.5 && box.depth > usableW + 0.5 {
                return "back-rear is marked load it, but neither plan face fits the width"
            }
        }
        if stop.module == .stair {
            let diagonal = FitQuestions.stairDiagonal(headroom: stop.secondaryMM, run: stop.tertiaryMM)
            if diagonal + 0.5 < stop.secondaryMM { return "back-rear stair diagonal is shorter than the headroom" }
        }
        if stop.module == .turn {
            let pole = FitQuestions.longestPole(hallA: stop.primaryMM, hallB: stop.secondaryMM)
            if pole + 0.5 < min(stop.primaryMM, stop.secondaryMM) { return "back-rear corner pole is shorter than a hall" }
        }
        if stop.module == .cargo && report.call != .leaveIt && report.call != .splitParts {
            if report.count < 1 { return "back-rear cargo call fits nothing" }
        }
        if stop.module == .spot && reading.call == .proceed {
            let avail = stop.primaryMM - stop.tertiaryMM
            if box.width > avail + 0.5 && box.depth > avail + 0.5 {
                return "back-rear is marked load it, but the footprint misses the floor"
            }
        }
        if reading.call == .splitParts {
            let stripped = box.reduced(by: piece.parts)
            if abs(stripped.width - box.width) < 0.5 && abs(stripped.depth - box.depth) < 0.5 && abs(stripped.height - box.height) < 0.5 {
                return "back-rear says take it apart, but nothing comes off"
            }
            let again = FitEngine.gate(module: stop.module, box: stripped, stop: stop, parts: [])
            if again.call == .leaveIt || again.call == .otherRoute {
                return "back-rear still does not fit after the parts come off"
            }
        }
        let worth = FitQuestions.partWorth(piece: piece, stop: stop)
        if worth.count != piece.parts.count {
            return "back-rear part check dropped a part"
        }
        let blankets = FitQuestions.blanketLimit(piece: piece, stop: stop, stock: .pine)
        if blankets < 0 || blankets > 8 {
            return "back-rear blanket limit is nonsense"
        }
        let order = FitQuestions.loadOrder(pieces: [piece], stops: [stop])
        if order.first?.pieceID != piece.id {
            return "back-rear fell out of the carry order"
        }
        let mass = FitHandling.kilograms(piece: piece, stock: .pine)
        let people = FitHandling.carriers(for: mass)
        if mass <= 0 || people < 1 {
            return "back-rear weight collapsed"
        }
        return nil
    }

    private static func checkBackSide() -> String? {
        guard let piece = FitSeed.piece("back"), let stop = FitSeed.stop("van-side"), let reading = FitSeed.reading("back-side") else {
            return "back-side is missing from the pickup"
        }
        let box = piece.box
        let report = FitEngine.gate(module: stop.module, box: box, stop: stop, parts: piece.parts)
        if report.call != reading.call {
            return "back-side call is \(report.call.rawValue), the saved check says \(reading.call.rawValue)"
        }
        if abs(report.clearanceMM - reading.clearanceMM) > 2 {
            return "back-side spare is \(report.clearanceMM), the saved check says \(reading.clearanceMM)"
        }
        if report.headline != report.call.title {
            return "back-side headline drifted from the call"
        }
        let faces = FitQuestions.faces(box: box, stop: stop, parts: piece.parts)
        if faces.count != 6 {
            return "back-side should list six faces, has \(faces.count)"
        }
        let anyFit = faces.contains { $0.fits }
        if reading.call == .proceed || reading.call == .turnIt {
            if !anyFit { return "back-side says it fits, but no face clears" }
        }
        if reading.call == .leaveIt && anyFit && piece.parts.isEmpty {
            return "back-side says leave it, but a face clears"
        }
        let steps = FitCarry.steps(piece: piece, stop: stop, report: report)
        if steps.count < 4 {
            return "back-side carry steps are too thin to follow"
        }
        let namesStop = steps.contains { $0.contains(stop.name) }
        let namesCall = steps.contains { $0.localizedCaseInsensitiveContains(report.headline) }
        if !namesStop && !namesCall {
            return "back-side steps never name the stop or the call"
        }
        let tape = FitQuestions.tape(box.width)
        if tape.isEmpty { return "back-side tape line is empty" }
        let need = FitQuestions.openingNeeded(box: box, margin: max(stop.tertiaryMM, 0))
        if need.widthMM + 0.5 < box.minimumFace && need.heightMM + 0.5 < box.minimumFace {
            return "back-side required opening is smaller than the smallest face"
        }
        if stop.module == .door || stop.module == .vehicle {
            let usableW = stop.primaryMM - stop.tertiaryMM
            let usableH = stop.secondaryMM - stop.tertiaryMM
            if usableW <= 0 || usableH <= 0 { return "back-side opening collapsed after the keep-clear" }
            if reading.call == .proceed && box.width > usableW + 0.5 && box.depth > usableW + 0.5 {
                return "back-side is marked load it, but neither plan face fits the width"
            }
        }
        if stop.module == .stair {
            let diagonal = FitQuestions.stairDiagonal(headroom: stop.secondaryMM, run: stop.tertiaryMM)
            if diagonal + 0.5 < stop.secondaryMM { return "back-side stair diagonal is shorter than the headroom" }
        }
        if stop.module == .turn {
            let pole = FitQuestions.longestPole(hallA: stop.primaryMM, hallB: stop.secondaryMM)
            if pole + 0.5 < min(stop.primaryMM, stop.secondaryMM) { return "back-side corner pole is shorter than a hall" }
        }
        if stop.module == .cargo && report.call != .leaveIt && report.call != .splitParts {
            if report.count < 1 { return "back-side cargo call fits nothing" }
        }
        if stop.module == .spot && reading.call == .proceed {
            let avail = stop.primaryMM - stop.tertiaryMM
            if box.width > avail + 0.5 && box.depth > avail + 0.5 {
                return "back-side is marked load it, but the footprint misses the floor"
            }
        }
        if reading.call == .splitParts {
            let stripped = box.reduced(by: piece.parts)
            if abs(stripped.width - box.width) < 0.5 && abs(stripped.depth - box.depth) < 0.5 && abs(stripped.height - box.height) < 0.5 {
                return "back-side says take it apart, but nothing comes off"
            }
            let again = FitEngine.gate(module: stop.module, box: stripped, stop: stop, parts: [])
            if again.call == .leaveIt || again.call == .otherRoute {
                return "back-side still does not fit after the parts come off"
            }
        }
        let worth = FitQuestions.partWorth(piece: piece, stop: stop)
        if worth.count != piece.parts.count {
            return "back-side part check dropped a part"
        }
        let blankets = FitQuestions.blanketLimit(piece: piece, stop: stop, stock: .pine)
        if blankets < 0 || blankets > 8 {
            return "back-side blanket limit is nonsense"
        }
        let order = FitQuestions.loadOrder(pieces: [piece], stops: [stop])
        if order.first?.pieceID != piece.id {
            return "back-side fell out of the carry order"
        }
        let mass = FitHandling.kilograms(piece: piece, stock: .pine)
        let people = FitHandling.carriers(for: mass)
        if mass <= 0 || people < 1 {
            return "back-side weight collapsed"
        }
        return nil
    }

    private static func checkBackBay() -> String? {
        guard let piece = FitSeed.piece("back"), let stop = FitSeed.stop("van-bay"), let reading = FitSeed.reading("back-bay") else {
            return "back-bay is missing from the pickup"
        }
        let box = piece.box
        let report = FitEngine.gate(module: stop.module, box: box, stop: stop, parts: piece.parts)
        if report.call != reading.call {
            return "back-bay call is \(report.call.rawValue), the saved check says \(reading.call.rawValue)"
        }
        if abs(report.clearanceMM - reading.clearanceMM) > 2 {
            return "back-bay spare is \(report.clearanceMM), the saved check says \(reading.clearanceMM)"
        }
        if report.headline != report.call.title {
            return "back-bay headline drifted from the call"
        }
        let faces = FitQuestions.faces(box: box, stop: stop, parts: piece.parts)
        if faces.count != 6 {
            return "back-bay should list six faces, has \(faces.count)"
        }
        let anyFit = faces.contains { $0.fits }
        if reading.call == .proceed || reading.call == .turnIt {
            if !anyFit { return "back-bay says it fits, but no face clears" }
        }
        if reading.call == .leaveIt && anyFit && piece.parts.isEmpty {
            return "back-bay says leave it, but a face clears"
        }
        let steps = FitCarry.steps(piece: piece, stop: stop, report: report)
        if steps.count < 4 {
            return "back-bay carry steps are too thin to follow"
        }
        let namesStop = steps.contains { $0.contains(stop.name) }
        let namesCall = steps.contains { $0.localizedCaseInsensitiveContains(report.headline) }
        if !namesStop && !namesCall {
            return "back-bay steps never name the stop or the call"
        }
        let tape = FitQuestions.tape(box.width)
        if tape.isEmpty { return "back-bay tape line is empty" }
        let need = FitQuestions.openingNeeded(box: box, margin: max(stop.tertiaryMM, 0))
        if need.widthMM + 0.5 < box.minimumFace && need.heightMM + 0.5 < box.minimumFace {
            return "back-bay required opening is smaller than the smallest face"
        }
        if stop.module == .door || stop.module == .vehicle {
            let usableW = stop.primaryMM - stop.tertiaryMM
            let usableH = stop.secondaryMM - stop.tertiaryMM
            if usableW <= 0 || usableH <= 0 { return "back-bay opening collapsed after the keep-clear" }
            if reading.call == .proceed && box.width > usableW + 0.5 && box.depth > usableW + 0.5 {
                return "back-bay is marked load it, but neither plan face fits the width"
            }
        }
        if stop.module == .stair {
            let diagonal = FitQuestions.stairDiagonal(headroom: stop.secondaryMM, run: stop.tertiaryMM)
            if diagonal + 0.5 < stop.secondaryMM { return "back-bay stair diagonal is shorter than the headroom" }
        }
        if stop.module == .turn {
            let pole = FitQuestions.longestPole(hallA: stop.primaryMM, hallB: stop.secondaryMM)
            if pole + 0.5 < min(stop.primaryMM, stop.secondaryMM) { return "back-bay corner pole is shorter than a hall" }
        }
        if stop.module == .cargo && report.call != .leaveIt && report.call != .splitParts {
            if report.count < 1 { return "back-bay cargo call fits nothing" }
        }
        if stop.module == .spot && reading.call == .proceed {
            let avail = stop.primaryMM - stop.tertiaryMM
            if box.width > avail + 0.5 && box.depth > avail + 0.5 {
                return "back-bay is marked load it, but the footprint misses the floor"
            }
        }
        if reading.call == .splitParts {
            let stripped = box.reduced(by: piece.parts)
            if abs(stripped.width - box.width) < 0.5 && abs(stripped.depth - box.depth) < 0.5 && abs(stripped.height - box.height) < 0.5 {
                return "back-bay says take it apart, but nothing comes off"
            }
            let again = FitEngine.gate(module: stop.module, box: stripped, stop: stop, parts: [])
            if again.call == .leaveIt || again.call == .otherRoute {
                return "back-bay still does not fit after the parts come off"
            }
        }
        let worth = FitQuestions.partWorth(piece: piece, stop: stop)
        if worth.count != piece.parts.count {
            return "back-bay part check dropped a part"
        }
        let blankets = FitQuestions.blanketLimit(piece: piece, stop: stop, stock: .pine)
        if blankets < 0 || blankets > 8 {
            return "back-bay blanket limit is nonsense"
        }
        let order = FitQuestions.loadOrder(pieces: [piece], stops: [stop])
        if order.first?.pieceID != piece.id {
            return "back-bay fell out of the carry order"
        }
        let mass = FitHandling.kilograms(piece: piece, stock: .pine)
        let people = FitHandling.carriers(for: mass)
        if mass <= 0 || people < 1 {
            return "back-bay weight collapsed"
        }
        return nil
    }

    private static func checkBackSpot() -> String? {
        guard let piece = FitSeed.piece("back"), let stop = FitSeed.stop("storage-floor"), let reading = FitSeed.reading("back-spot") else {
            return "back-spot is missing from the pickup"
        }
        let box = piece.box
        let report = FitEngine.gate(module: stop.module, box: box, stop: stop, parts: piece.parts)
        if report.call != reading.call {
            return "back-spot call is \(report.call.rawValue), the saved check says \(reading.call.rawValue)"
        }
        if abs(report.clearanceMM - reading.clearanceMM) > 2 {
            return "back-spot spare is \(report.clearanceMM), the saved check says \(reading.clearanceMM)"
        }
        if report.headline != report.call.title {
            return "back-spot headline drifted from the call"
        }
        let faces = FitQuestions.faces(box: box, stop: stop, parts: piece.parts)
        if faces.count != 6 {
            return "back-spot should list six faces, has \(faces.count)"
        }
        let anyFit = faces.contains { $0.fits }
        if reading.call == .proceed || reading.call == .turnIt {
            if !anyFit { return "back-spot says it fits, but no face clears" }
        }
        if reading.call == .leaveIt && anyFit && piece.parts.isEmpty {
            return "back-spot says leave it, but a face clears"
        }
        let steps = FitCarry.steps(piece: piece, stop: stop, report: report)
        if steps.count < 4 {
            return "back-spot carry steps are too thin to follow"
        }
        let namesStop = steps.contains { $0.contains(stop.name) }
        let namesCall = steps.contains { $0.localizedCaseInsensitiveContains(report.headline) }
        if !namesStop && !namesCall {
            return "back-spot steps never name the stop or the call"
        }
        let tape = FitQuestions.tape(box.width)
        if tape.isEmpty { return "back-spot tape line is empty" }
        let need = FitQuestions.openingNeeded(box: box, margin: max(stop.tertiaryMM, 0))
        if need.widthMM + 0.5 < box.minimumFace && need.heightMM + 0.5 < box.minimumFace {
            return "back-spot required opening is smaller than the smallest face"
        }
        if stop.module == .door || stop.module == .vehicle {
            let usableW = stop.primaryMM - stop.tertiaryMM
            let usableH = stop.secondaryMM - stop.tertiaryMM
            if usableW <= 0 || usableH <= 0 { return "back-spot opening collapsed after the keep-clear" }
            if reading.call == .proceed && box.width > usableW + 0.5 && box.depth > usableW + 0.5 {
                return "back-spot is marked load it, but neither plan face fits the width"
            }
        }
        if stop.module == .stair {
            let diagonal = FitQuestions.stairDiagonal(headroom: stop.secondaryMM, run: stop.tertiaryMM)
            if diagonal + 0.5 < stop.secondaryMM { return "back-spot stair diagonal is shorter than the headroom" }
        }
        if stop.module == .turn {
            let pole = FitQuestions.longestPole(hallA: stop.primaryMM, hallB: stop.secondaryMM)
            if pole + 0.5 < min(stop.primaryMM, stop.secondaryMM) { return "back-spot corner pole is shorter than a hall" }
        }
        if stop.module == .cargo && report.call != .leaveIt && report.call != .splitParts {
            if report.count < 1 { return "back-spot cargo call fits nothing" }
        }
        if stop.module == .spot && reading.call == .proceed {
            let avail = stop.primaryMM - stop.tertiaryMM
            if box.width > avail + 0.5 && box.depth > avail + 0.5 {
                return "back-spot is marked load it, but the footprint misses the floor"
            }
        }
        if reading.call == .splitParts {
            let stripped = box.reduced(by: piece.parts)
            if abs(stripped.width - box.width) < 0.5 && abs(stripped.depth - box.depth) < 0.5 && abs(stripped.height - box.height) < 0.5 {
                return "back-spot says take it apart, but nothing comes off"
            }
            let again = FitEngine.gate(module: stop.module, box: stripped, stop: stop, parts: [])
            if again.call == .leaveIt || again.call == .otherRoute {
                return "back-spot still does not fit after the parts come off"
            }
        }
        let worth = FitQuestions.partWorth(piece: piece, stop: stop)
        if worth.count != piece.parts.count {
            return "back-spot part check dropped a part"
        }
        let blankets = FitQuestions.blanketLimit(piece: piece, stop: stop, stock: .pine)
        if blankets < 0 || blankets > 8 {
            return "back-spot blanket limit is nonsense"
        }
        let order = FitQuestions.loadOrder(pieces: [piece], stops: [stop])
        if order.first?.pieceID != piece.id {
            return "back-spot fell out of the carry order"
        }
        let mass = FitHandling.kilograms(piece: piece, stock: .pine)
        let people = FitHandling.carriers(for: mass)
        if mass <= 0 || people < 1 {
            return "back-spot weight collapsed"
        }
        return nil
    }

    private static func checkPlinthDoor() -> String? {
        guard let piece = FitSeed.piece("plinth"), let stop = FitSeed.stop("seller-door"), let reading = FitSeed.reading("plinth-door") else {
            return "plinth-door is missing from the pickup"
        }
        let box = piece.box
        let report = FitEngine.gate(module: stop.module, box: box, stop: stop, parts: piece.parts)
        if report.call != reading.call {
            return "plinth-door call is \(report.call.rawValue), the saved check says \(reading.call.rawValue)"
        }
        if abs(report.clearanceMM - reading.clearanceMM) > 2 {
            return "plinth-door spare is \(report.clearanceMM), the saved check says \(reading.clearanceMM)"
        }
        if report.headline != report.call.title {
            return "plinth-door headline drifted from the call"
        }
        let faces = FitQuestions.faces(box: box, stop: stop, parts: piece.parts)
        if faces.count != 6 {
            return "plinth-door should list six faces, has \(faces.count)"
        }
        let anyFit = faces.contains { $0.fits }
        if reading.call == .proceed || reading.call == .turnIt {
            if !anyFit { return "plinth-door says it fits, but no face clears" }
        }
        if reading.call == .leaveIt && anyFit && piece.parts.isEmpty {
            return "plinth-door says leave it, but a face clears"
        }
        let steps = FitCarry.steps(piece: piece, stop: stop, report: report)
        if steps.count < 4 {
            return "plinth-door carry steps are too thin to follow"
        }
        let namesStop = steps.contains { $0.contains(stop.name) }
        let namesCall = steps.contains { $0.localizedCaseInsensitiveContains(report.headline) }
        if !namesStop && !namesCall {
            return "plinth-door steps never name the stop or the call"
        }
        let tape = FitQuestions.tape(box.width)
        if tape.isEmpty { return "plinth-door tape line is empty" }
        let need = FitQuestions.openingNeeded(box: box, margin: max(stop.tertiaryMM, 0))
        if need.widthMM + 0.5 < box.minimumFace && need.heightMM + 0.5 < box.minimumFace {
            return "plinth-door required opening is smaller than the smallest face"
        }
        if stop.module == .door || stop.module == .vehicle {
            let usableW = stop.primaryMM - stop.tertiaryMM
            let usableH = stop.secondaryMM - stop.tertiaryMM
            if usableW <= 0 || usableH <= 0 { return "plinth-door opening collapsed after the keep-clear" }
            if reading.call == .proceed && box.width > usableW + 0.5 && box.depth > usableW + 0.5 {
                return "plinth-door is marked load it, but neither plan face fits the width"
            }
        }
        if stop.module == .stair {
            let diagonal = FitQuestions.stairDiagonal(headroom: stop.secondaryMM, run: stop.tertiaryMM)
            if diagonal + 0.5 < stop.secondaryMM { return "plinth-door stair diagonal is shorter than the headroom" }
        }
        if stop.module == .turn {
            let pole = FitQuestions.longestPole(hallA: stop.primaryMM, hallB: stop.secondaryMM)
            if pole + 0.5 < min(stop.primaryMM, stop.secondaryMM) { return "plinth-door corner pole is shorter than a hall" }
        }
        if stop.module == .cargo && report.call != .leaveIt && report.call != .splitParts {
            if report.count < 1 { return "plinth-door cargo call fits nothing" }
        }
        if stop.module == .spot && reading.call == .proceed {
            let avail = stop.primaryMM - stop.tertiaryMM
            if box.width > avail + 0.5 && box.depth > avail + 0.5 {
                return "plinth-door is marked load it, but the footprint misses the floor"
            }
        }
        if reading.call == .splitParts {
            let stripped = box.reduced(by: piece.parts)
            if abs(stripped.width - box.width) < 0.5 && abs(stripped.depth - box.depth) < 0.5 && abs(stripped.height - box.height) < 0.5 {
                return "plinth-door says take it apart, but nothing comes off"
            }
            let again = FitEngine.gate(module: stop.module, box: stripped, stop: stop, parts: [])
            if again.call == .leaveIt || again.call == .otherRoute {
                return "plinth-door still does not fit after the parts come off"
            }
        }
        let worth = FitQuestions.partWorth(piece: piece, stop: stop)
        if worth.count != piece.parts.count {
            return "plinth-door part check dropped a part"
        }
        let blankets = FitQuestions.blanketLimit(piece: piece, stop: stop, stock: .pine)
        if blankets < 0 || blankets > 8 {
            return "plinth-door blanket limit is nonsense"
        }
        let order = FitQuestions.loadOrder(pieces: [piece], stops: [stop])
        if order.first?.pieceID != piece.id {
            return "plinth-door fell out of the carry order"
        }
        let mass = FitHandling.kilograms(piece: piece, stock: .pine)
        let people = FitHandling.carriers(for: mass)
        if mass <= 0 || people < 1 {
            return "plinth-door weight collapsed"
        }
        return nil
    }

    private static func checkPlinthCorner() -> String? {
        guard let piece = FitSeed.piece("plinth"), let stop = FitSeed.stop("seller-corner"), let reading = FitSeed.reading("plinth-corner") else {
            return "plinth-corner is missing from the pickup"
        }
        let box = piece.box
        let report = FitEngine.gate(module: stop.module, box: box, stop: stop, parts: piece.parts)
        if report.call != reading.call {
            return "plinth-corner call is \(report.call.rawValue), the saved check says \(reading.call.rawValue)"
        }
        if abs(report.clearanceMM - reading.clearanceMM) > 2 {
            return "plinth-corner spare is \(report.clearanceMM), the saved check says \(reading.clearanceMM)"
        }
        if report.headline != report.call.title {
            return "plinth-corner headline drifted from the call"
        }
        let faces = FitQuestions.faces(box: box, stop: stop, parts: piece.parts)
        if faces.count != 6 {
            return "plinth-corner should list six faces, has \(faces.count)"
        }
        let anyFit = faces.contains { $0.fits }
        if reading.call == .proceed || reading.call == .turnIt {
            if !anyFit { return "plinth-corner says it fits, but no face clears" }
        }
        if reading.call == .leaveIt && anyFit && piece.parts.isEmpty {
            return "plinth-corner says leave it, but a face clears"
        }
        let steps = FitCarry.steps(piece: piece, stop: stop, report: report)
        if steps.count < 4 {
            return "plinth-corner carry steps are too thin to follow"
        }
        let namesStop = steps.contains { $0.contains(stop.name) }
        let namesCall = steps.contains { $0.localizedCaseInsensitiveContains(report.headline) }
        if !namesStop && !namesCall {
            return "plinth-corner steps never name the stop or the call"
        }
        let tape = FitQuestions.tape(box.width)
        if tape.isEmpty { return "plinth-corner tape line is empty" }
        let need = FitQuestions.openingNeeded(box: box, margin: max(stop.tertiaryMM, 0))
        if need.widthMM + 0.5 < box.minimumFace && need.heightMM + 0.5 < box.minimumFace {
            return "plinth-corner required opening is smaller than the smallest face"
        }
        if stop.module == .door || stop.module == .vehicle {
            let usableW = stop.primaryMM - stop.tertiaryMM
            let usableH = stop.secondaryMM - stop.tertiaryMM
            if usableW <= 0 || usableH <= 0 { return "plinth-corner opening collapsed after the keep-clear" }
            if reading.call == .proceed && box.width > usableW + 0.5 && box.depth > usableW + 0.5 {
                return "plinth-corner is marked load it, but neither plan face fits the width"
            }
        }
        if stop.module == .stair {
            let diagonal = FitQuestions.stairDiagonal(headroom: stop.secondaryMM, run: stop.tertiaryMM)
            if diagonal + 0.5 < stop.secondaryMM { return "plinth-corner stair diagonal is shorter than the headroom" }
        }
        if stop.module == .turn {
            let pole = FitQuestions.longestPole(hallA: stop.primaryMM, hallB: stop.secondaryMM)
            if pole + 0.5 < min(stop.primaryMM, stop.secondaryMM) { return "plinth-corner corner pole is shorter than a hall" }
        }
        if stop.module == .cargo && report.call != .leaveIt && report.call != .splitParts {
            if report.count < 1 { return "plinth-corner cargo call fits nothing" }
        }
        if stop.module == .spot && reading.call == .proceed {
            let avail = stop.primaryMM - stop.tertiaryMM
            if box.width > avail + 0.5 && box.depth > avail + 0.5 {
                return "plinth-corner is marked load it, but the footprint misses the floor"
            }
        }
        if reading.call == .splitParts {
            let stripped = box.reduced(by: piece.parts)
            if abs(stripped.width - box.width) < 0.5 && abs(stripped.depth - box.depth) < 0.5 && abs(stripped.height - box.height) < 0.5 {
                return "plinth-corner says take it apart, but nothing comes off"
            }
            let again = FitEngine.gate(module: stop.module, box: stripped, stop: stop, parts: [])
            if again.call == .leaveIt || again.call == .otherRoute {
                return "plinth-corner still does not fit after the parts come off"
            }
        }
        let worth = FitQuestions.partWorth(piece: piece, stop: stop)
        if worth.count != piece.parts.count {
            return "plinth-corner part check dropped a part"
        }
        let blankets = FitQuestions.blanketLimit(piece: piece, stop: stop, stock: .pine)
        if blankets < 0 || blankets > 8 {
            return "plinth-corner blanket limit is nonsense"
        }
        let order = FitQuestions.loadOrder(pieces: [piece], stops: [stop])
        if order.first?.pieceID != piece.id {
            return "plinth-corner fell out of the carry order"
        }
        let mass = FitHandling.kilograms(piece: piece, stock: .pine)
        let people = FitHandling.carriers(for: mass)
        if mass <= 0 || people < 1 {
            return "plinth-corner weight collapsed"
        }
        return nil
    }

    private static func checkPlinthStair() -> String? {
        guard let piece = FitSeed.piece("plinth"), let stop = FitSeed.stop("seller-stair"), let reading = FitSeed.reading("plinth-stair") else {
            return "plinth-stair is missing from the pickup"
        }
        let box = piece.box
        let report = FitEngine.gate(module: stop.module, box: box, stop: stop, parts: piece.parts)
        if report.call != reading.call {
            return "plinth-stair call is \(report.call.rawValue), the saved check says \(reading.call.rawValue)"
        }
        if abs(report.clearanceMM - reading.clearanceMM) > 2 {
            return "plinth-stair spare is \(report.clearanceMM), the saved check says \(reading.clearanceMM)"
        }
        if report.headline != report.call.title {
            return "plinth-stair headline drifted from the call"
        }
        let faces = FitQuestions.faces(box: box, stop: stop, parts: piece.parts)
        if faces.count != 6 {
            return "plinth-stair should list six faces, has \(faces.count)"
        }
        let anyFit = faces.contains { $0.fits }
        if reading.call == .proceed || reading.call == .turnIt {
            if !anyFit { return "plinth-stair says it fits, but no face clears" }
        }
        if reading.call == .leaveIt && anyFit && piece.parts.isEmpty {
            return "plinth-stair says leave it, but a face clears"
        }
        let steps = FitCarry.steps(piece: piece, stop: stop, report: report)
        if steps.count < 4 {
            return "plinth-stair carry steps are too thin to follow"
        }
        let namesStop = steps.contains { $0.contains(stop.name) }
        let namesCall = steps.contains { $0.localizedCaseInsensitiveContains(report.headline) }
        if !namesStop && !namesCall {
            return "plinth-stair steps never name the stop or the call"
        }
        let tape = FitQuestions.tape(box.width)
        if tape.isEmpty { return "plinth-stair tape line is empty" }
        let need = FitQuestions.openingNeeded(box: box, margin: max(stop.tertiaryMM, 0))
        if need.widthMM + 0.5 < box.minimumFace && need.heightMM + 0.5 < box.minimumFace {
            return "plinth-stair required opening is smaller than the smallest face"
        }
        if stop.module == .door || stop.module == .vehicle {
            let usableW = stop.primaryMM - stop.tertiaryMM
            let usableH = stop.secondaryMM - stop.tertiaryMM
            if usableW <= 0 || usableH <= 0 { return "plinth-stair opening collapsed after the keep-clear" }
            if reading.call == .proceed && box.width > usableW + 0.5 && box.depth > usableW + 0.5 {
                return "plinth-stair is marked load it, but neither plan face fits the width"
            }
        }
        if stop.module == .stair {
            let diagonal = FitQuestions.stairDiagonal(headroom: stop.secondaryMM, run: stop.tertiaryMM)
            if diagonal + 0.5 < stop.secondaryMM { return "plinth-stair stair diagonal is shorter than the headroom" }
        }
        if stop.module == .turn {
            let pole = FitQuestions.longestPole(hallA: stop.primaryMM, hallB: stop.secondaryMM)
            if pole + 0.5 < min(stop.primaryMM, stop.secondaryMM) { return "plinth-stair corner pole is shorter than a hall" }
        }
        if stop.module == .cargo && report.call != .leaveIt && report.call != .splitParts {
            if report.count < 1 { return "plinth-stair cargo call fits nothing" }
        }
        if stop.module == .spot && reading.call == .proceed {
            let avail = stop.primaryMM - stop.tertiaryMM
            if box.width > avail + 0.5 && box.depth > avail + 0.5 {
                return "plinth-stair is marked load it, but the footprint misses the floor"
            }
        }
        if reading.call == .splitParts {
            let stripped = box.reduced(by: piece.parts)
            if abs(stripped.width - box.width) < 0.5 && abs(stripped.depth - box.depth) < 0.5 && abs(stripped.height - box.height) < 0.5 {
                return "plinth-stair says take it apart, but nothing comes off"
            }
            let again = FitEngine.gate(module: stop.module, box: stripped, stop: stop, parts: [])
            if again.call == .leaveIt || again.call == .otherRoute {
                return "plinth-stair still does not fit after the parts come off"
            }
        }
        let worth = FitQuestions.partWorth(piece: piece, stop: stop)
        if worth.count != piece.parts.count {
            return "plinth-stair part check dropped a part"
        }
        let blankets = FitQuestions.blanketLimit(piece: piece, stop: stop, stock: .pine)
        if blankets < 0 || blankets > 8 {
            return "plinth-stair blanket limit is nonsense"
        }
        let order = FitQuestions.loadOrder(pieces: [piece], stops: [stop])
        if order.first?.pieceID != piece.id {
            return "plinth-stair fell out of the carry order"
        }
        let mass = FitHandling.kilograms(piece: piece, stock: .pine)
        let people = FitHandling.carriers(for: mass)
        if mass <= 0 || people < 1 {
            return "plinth-stair weight collapsed"
        }
        return nil
    }

    private static func checkPlinthRear() -> String? {
        guard let piece = FitSeed.piece("plinth"), let stop = FitSeed.stop("van-rear"), let reading = FitSeed.reading("plinth-rear") else {
            return "plinth-rear is missing from the pickup"
        }
        let box = piece.box
        let report = FitEngine.gate(module: stop.module, box: box, stop: stop, parts: piece.parts)
        if report.call != reading.call {
            return "plinth-rear call is \(report.call.rawValue), the saved check says \(reading.call.rawValue)"
        }
        if abs(report.clearanceMM - reading.clearanceMM) > 2 {
            return "plinth-rear spare is \(report.clearanceMM), the saved check says \(reading.clearanceMM)"
        }
        if report.headline != report.call.title {
            return "plinth-rear headline drifted from the call"
        }
        let faces = FitQuestions.faces(box: box, stop: stop, parts: piece.parts)
        if faces.count != 6 {
            return "plinth-rear should list six faces, has \(faces.count)"
        }
        let anyFit = faces.contains { $0.fits }
        if reading.call == .proceed || reading.call == .turnIt {
            if !anyFit { return "plinth-rear says it fits, but no face clears" }
        }
        if reading.call == .leaveIt && anyFit && piece.parts.isEmpty {
            return "plinth-rear says leave it, but a face clears"
        }
        let steps = FitCarry.steps(piece: piece, stop: stop, report: report)
        if steps.count < 4 {
            return "plinth-rear carry steps are too thin to follow"
        }
        let namesStop = steps.contains { $0.contains(stop.name) }
        let namesCall = steps.contains { $0.localizedCaseInsensitiveContains(report.headline) }
        if !namesStop && !namesCall {
            return "plinth-rear steps never name the stop or the call"
        }
        let tape = FitQuestions.tape(box.width)
        if tape.isEmpty { return "plinth-rear tape line is empty" }
        let need = FitQuestions.openingNeeded(box: box, margin: max(stop.tertiaryMM, 0))
        if need.widthMM + 0.5 < box.minimumFace && need.heightMM + 0.5 < box.minimumFace {
            return "plinth-rear required opening is smaller than the smallest face"
        }
        if stop.module == .door || stop.module == .vehicle {
            let usableW = stop.primaryMM - stop.tertiaryMM
            let usableH = stop.secondaryMM - stop.tertiaryMM
            if usableW <= 0 || usableH <= 0 { return "plinth-rear opening collapsed after the keep-clear" }
            if reading.call == .proceed && box.width > usableW + 0.5 && box.depth > usableW + 0.5 {
                return "plinth-rear is marked load it, but neither plan face fits the width"
            }
        }
        if stop.module == .stair {
            let diagonal = FitQuestions.stairDiagonal(headroom: stop.secondaryMM, run: stop.tertiaryMM)
            if diagonal + 0.5 < stop.secondaryMM { return "plinth-rear stair diagonal is shorter than the headroom" }
        }
        if stop.module == .turn {
            let pole = FitQuestions.longestPole(hallA: stop.primaryMM, hallB: stop.secondaryMM)
            if pole + 0.5 < min(stop.primaryMM, stop.secondaryMM) { return "plinth-rear corner pole is shorter than a hall" }
        }
        if stop.module == .cargo && report.call != .leaveIt && report.call != .splitParts {
            if report.count < 1 { return "plinth-rear cargo call fits nothing" }
        }
        if stop.module == .spot && reading.call == .proceed {
            let avail = stop.primaryMM - stop.tertiaryMM
            if box.width > avail + 0.5 && box.depth > avail + 0.5 {
                return "plinth-rear is marked load it, but the footprint misses the floor"
            }
        }
        if reading.call == .splitParts {
            let stripped = box.reduced(by: piece.parts)
            if abs(stripped.width - box.width) < 0.5 && abs(stripped.depth - box.depth) < 0.5 && abs(stripped.height - box.height) < 0.5 {
                return "plinth-rear says take it apart, but nothing comes off"
            }
            let again = FitEngine.gate(module: stop.module, box: stripped, stop: stop, parts: [])
            if again.call == .leaveIt || again.call == .otherRoute {
                return "plinth-rear still does not fit after the parts come off"
            }
        }
        let worth = FitQuestions.partWorth(piece: piece, stop: stop)
        if worth.count != piece.parts.count {
            return "plinth-rear part check dropped a part"
        }
        let blankets = FitQuestions.blanketLimit(piece: piece, stop: stop, stock: .pine)
        if blankets < 0 || blankets > 8 {
            return "plinth-rear blanket limit is nonsense"
        }
        let order = FitQuestions.loadOrder(pieces: [piece], stops: [stop])
        if order.first?.pieceID != piece.id {
            return "plinth-rear fell out of the carry order"
        }
        let mass = FitHandling.kilograms(piece: piece, stock: .pine)
        let people = FitHandling.carriers(for: mass)
        if mass <= 0 || people < 1 {
            return "plinth-rear weight collapsed"
        }
        return nil
    }

    private static func checkPlinthSide() -> String? {
        guard let piece = FitSeed.piece("plinth"), let stop = FitSeed.stop("van-side"), let reading = FitSeed.reading("plinth-side") else {
            return "plinth-side is missing from the pickup"
        }
        let box = piece.box
        let report = FitEngine.gate(module: stop.module, box: box, stop: stop, parts: piece.parts)
        if report.call != reading.call {
            return "plinth-side call is \(report.call.rawValue), the saved check says \(reading.call.rawValue)"
        }
        if abs(report.clearanceMM - reading.clearanceMM) > 2 {
            return "plinth-side spare is \(report.clearanceMM), the saved check says \(reading.clearanceMM)"
        }
        if report.headline != report.call.title {
            return "plinth-side headline drifted from the call"
        }
        let faces = FitQuestions.faces(box: box, stop: stop, parts: piece.parts)
        if faces.count != 6 {
            return "plinth-side should list six faces, has \(faces.count)"
        }
        let anyFit = faces.contains { $0.fits }
        if reading.call == .proceed || reading.call == .turnIt {
            if !anyFit { return "plinth-side says it fits, but no face clears" }
        }
        if reading.call == .leaveIt && anyFit && piece.parts.isEmpty {
            return "plinth-side says leave it, but a face clears"
        }
        let steps = FitCarry.steps(piece: piece, stop: stop, report: report)
        if steps.count < 4 {
            return "plinth-side carry steps are too thin to follow"
        }
        let namesStop = steps.contains { $0.contains(stop.name) }
        let namesCall = steps.contains { $0.localizedCaseInsensitiveContains(report.headline) }
        if !namesStop && !namesCall {
            return "plinth-side steps never name the stop or the call"
        }
        let tape = FitQuestions.tape(box.width)
        if tape.isEmpty { return "plinth-side tape line is empty" }
        let need = FitQuestions.openingNeeded(box: box, margin: max(stop.tertiaryMM, 0))
        if need.widthMM + 0.5 < box.minimumFace && need.heightMM + 0.5 < box.minimumFace {
            return "plinth-side required opening is smaller than the smallest face"
        }
        if stop.module == .door || stop.module == .vehicle {
            let usableW = stop.primaryMM - stop.tertiaryMM
            let usableH = stop.secondaryMM - stop.tertiaryMM
            if usableW <= 0 || usableH <= 0 { return "plinth-side opening collapsed after the keep-clear" }
            if reading.call == .proceed && box.width > usableW + 0.5 && box.depth > usableW + 0.5 {
                return "plinth-side is marked load it, but neither plan face fits the width"
            }
        }
        if stop.module == .stair {
            let diagonal = FitQuestions.stairDiagonal(headroom: stop.secondaryMM, run: stop.tertiaryMM)
            if diagonal + 0.5 < stop.secondaryMM { return "plinth-side stair diagonal is shorter than the headroom" }
        }
        if stop.module == .turn {
            let pole = FitQuestions.longestPole(hallA: stop.primaryMM, hallB: stop.secondaryMM)
            if pole + 0.5 < min(stop.primaryMM, stop.secondaryMM) { return "plinth-side corner pole is shorter than a hall" }
        }
        if stop.module == .cargo && report.call != .leaveIt && report.call != .splitParts {
            if report.count < 1 { return "plinth-side cargo call fits nothing" }
        }
        if stop.module == .spot && reading.call == .proceed {
            let avail = stop.primaryMM - stop.tertiaryMM
            if box.width > avail + 0.5 && box.depth > avail + 0.5 {
                return "plinth-side is marked load it, but the footprint misses the floor"
            }
        }
        if reading.call == .splitParts {
            let stripped = box.reduced(by: piece.parts)
            if abs(stripped.width - box.width) < 0.5 && abs(stripped.depth - box.depth) < 0.5 && abs(stripped.height - box.height) < 0.5 {
                return "plinth-side says take it apart, but nothing comes off"
            }
            let again = FitEngine.gate(module: stop.module, box: stripped, stop: stop, parts: [])
            if again.call == .leaveIt || again.call == .otherRoute {
                return "plinth-side still does not fit after the parts come off"
            }
        }
        let worth = FitQuestions.partWorth(piece: piece, stop: stop)
        if worth.count != piece.parts.count {
            return "plinth-side part check dropped a part"
        }
        let blankets = FitQuestions.blanketLimit(piece: piece, stop: stop, stock: .pine)
        if blankets < 0 || blankets > 8 {
            return "plinth-side blanket limit is nonsense"
        }
        let order = FitQuestions.loadOrder(pieces: [piece], stops: [stop])
        if order.first?.pieceID != piece.id {
            return "plinth-side fell out of the carry order"
        }
        let mass = FitHandling.kilograms(piece: piece, stock: .pine)
        let people = FitHandling.carriers(for: mass)
        if mass <= 0 || people < 1 {
            return "plinth-side weight collapsed"
        }
        return nil
    }

    private static func checkPlinthBay() -> String? {
        guard let piece = FitSeed.piece("plinth"), let stop = FitSeed.stop("van-bay"), let reading = FitSeed.reading("plinth-bay") else {
            return "plinth-bay is missing from the pickup"
        }
        let box = piece.box
        let report = FitEngine.gate(module: stop.module, box: box, stop: stop, parts: piece.parts)
        if report.call != reading.call {
            return "plinth-bay call is \(report.call.rawValue), the saved check says \(reading.call.rawValue)"
        }
        if abs(report.clearanceMM - reading.clearanceMM) > 2 {
            return "plinth-bay spare is \(report.clearanceMM), the saved check says \(reading.clearanceMM)"
        }
        if report.headline != report.call.title {
            return "plinth-bay headline drifted from the call"
        }
        let faces = FitQuestions.faces(box: box, stop: stop, parts: piece.parts)
        if faces.count != 6 {
            return "plinth-bay should list six faces, has \(faces.count)"
        }
        let anyFit = faces.contains { $0.fits }
        if reading.call == .proceed || reading.call == .turnIt {
            if !anyFit { return "plinth-bay says it fits, but no face clears" }
        }
        if reading.call == .leaveIt && anyFit && piece.parts.isEmpty {
            return "plinth-bay says leave it, but a face clears"
        }
        let steps = FitCarry.steps(piece: piece, stop: stop, report: report)
        if steps.count < 4 {
            return "plinth-bay carry steps are too thin to follow"
        }
        let namesStop = steps.contains { $0.contains(stop.name) }
        let namesCall = steps.contains { $0.localizedCaseInsensitiveContains(report.headline) }
        if !namesStop && !namesCall {
            return "plinth-bay steps never name the stop or the call"
        }
        let tape = FitQuestions.tape(box.width)
        if tape.isEmpty { return "plinth-bay tape line is empty" }
        let need = FitQuestions.openingNeeded(box: box, margin: max(stop.tertiaryMM, 0))
        if need.widthMM + 0.5 < box.minimumFace && need.heightMM + 0.5 < box.minimumFace {
            return "plinth-bay required opening is smaller than the smallest face"
        }
        if stop.module == .door || stop.module == .vehicle {
            let usableW = stop.primaryMM - stop.tertiaryMM
            let usableH = stop.secondaryMM - stop.tertiaryMM
            if usableW <= 0 || usableH <= 0 { return "plinth-bay opening collapsed after the keep-clear" }
            if reading.call == .proceed && box.width > usableW + 0.5 && box.depth > usableW + 0.5 {
                return "plinth-bay is marked load it, but neither plan face fits the width"
            }
        }
        if stop.module == .stair {
            let diagonal = FitQuestions.stairDiagonal(headroom: stop.secondaryMM, run: stop.tertiaryMM)
            if diagonal + 0.5 < stop.secondaryMM { return "plinth-bay stair diagonal is shorter than the headroom" }
        }
        if stop.module == .turn {
            let pole = FitQuestions.longestPole(hallA: stop.primaryMM, hallB: stop.secondaryMM)
            if pole + 0.5 < min(stop.primaryMM, stop.secondaryMM) { return "plinth-bay corner pole is shorter than a hall" }
        }
        if stop.module == .cargo && report.call != .leaveIt && report.call != .splitParts {
            if report.count < 1 { return "plinth-bay cargo call fits nothing" }
        }
        if stop.module == .spot && reading.call == .proceed {
            let avail = stop.primaryMM - stop.tertiaryMM
            if box.width > avail + 0.5 && box.depth > avail + 0.5 {
                return "plinth-bay is marked load it, but the footprint misses the floor"
            }
        }
        if reading.call == .splitParts {
            let stripped = box.reduced(by: piece.parts)
            if abs(stripped.width - box.width) < 0.5 && abs(stripped.depth - box.depth) < 0.5 && abs(stripped.height - box.height) < 0.5 {
                return "plinth-bay says take it apart, but nothing comes off"
            }
            let again = FitEngine.gate(module: stop.module, box: stripped, stop: stop, parts: [])
            if again.call == .leaveIt || again.call == .otherRoute {
                return "plinth-bay still does not fit after the parts come off"
            }
        }
        let worth = FitQuestions.partWorth(piece: piece, stop: stop)
        if worth.count != piece.parts.count {
            return "plinth-bay part check dropped a part"
        }
        let blankets = FitQuestions.blanketLimit(piece: piece, stop: stop, stock: .pine)
        if blankets < 0 || blankets > 8 {
            return "plinth-bay blanket limit is nonsense"
        }
        let order = FitQuestions.loadOrder(pieces: [piece], stops: [stop])
        if order.first?.pieceID != piece.id {
            return "plinth-bay fell out of the carry order"
        }
        let mass = FitHandling.kilograms(piece: piece, stock: .pine)
        let people = FitHandling.carriers(for: mass)
        if mass <= 0 || people < 1 {
            return "plinth-bay weight collapsed"
        }
        return nil
    }

    private static func checkPlinthSpot() -> String? {
        guard let piece = FitSeed.piece("plinth"), let stop = FitSeed.stop("storage-floor"), let reading = FitSeed.reading("plinth-spot") else {
            return "plinth-spot is missing from the pickup"
        }
        let box = piece.box
        let report = FitEngine.gate(module: stop.module, box: box, stop: stop, parts: piece.parts)
        if report.call != reading.call {
            return "plinth-spot call is \(report.call.rawValue), the saved check says \(reading.call.rawValue)"
        }
        if abs(report.clearanceMM - reading.clearanceMM) > 2 {
            return "plinth-spot spare is \(report.clearanceMM), the saved check says \(reading.clearanceMM)"
        }
        if report.headline != report.call.title {
            return "plinth-spot headline drifted from the call"
        }
        let faces = FitQuestions.faces(box: box, stop: stop, parts: piece.parts)
        if faces.count != 6 {
            return "plinth-spot should list six faces, has \(faces.count)"
        }
        let anyFit = faces.contains { $0.fits }
        if reading.call == .proceed || reading.call == .turnIt {
            if !anyFit { return "plinth-spot says it fits, but no face clears" }
        }
        if reading.call == .leaveIt && anyFit && piece.parts.isEmpty {
            return "plinth-spot says leave it, but a face clears"
        }
        let steps = FitCarry.steps(piece: piece, stop: stop, report: report)
        if steps.count < 4 {
            return "plinth-spot carry steps are too thin to follow"
        }
        let namesStop = steps.contains { $0.contains(stop.name) }
        let namesCall = steps.contains { $0.localizedCaseInsensitiveContains(report.headline) }
        if !namesStop && !namesCall {
            return "plinth-spot steps never name the stop or the call"
        }
        let tape = FitQuestions.tape(box.width)
        if tape.isEmpty { return "plinth-spot tape line is empty" }
        let need = FitQuestions.openingNeeded(box: box, margin: max(stop.tertiaryMM, 0))
        if need.widthMM + 0.5 < box.minimumFace && need.heightMM + 0.5 < box.minimumFace {
            return "plinth-spot required opening is smaller than the smallest face"
        }
        if stop.module == .door || stop.module == .vehicle {
            let usableW = stop.primaryMM - stop.tertiaryMM
            let usableH = stop.secondaryMM - stop.tertiaryMM
            if usableW <= 0 || usableH <= 0 { return "plinth-spot opening collapsed after the keep-clear" }
            if reading.call == .proceed && box.width > usableW + 0.5 && box.depth > usableW + 0.5 {
                return "plinth-spot is marked load it, but neither plan face fits the width"
            }
        }
        if stop.module == .stair {
            let diagonal = FitQuestions.stairDiagonal(headroom: stop.secondaryMM, run: stop.tertiaryMM)
            if diagonal + 0.5 < stop.secondaryMM { return "plinth-spot stair diagonal is shorter than the headroom" }
        }
        if stop.module == .turn {
            let pole = FitQuestions.longestPole(hallA: stop.primaryMM, hallB: stop.secondaryMM)
            if pole + 0.5 < min(stop.primaryMM, stop.secondaryMM) { return "plinth-spot corner pole is shorter than a hall" }
        }
        if stop.module == .cargo && report.call != .leaveIt && report.call != .splitParts {
            if report.count < 1 { return "plinth-spot cargo call fits nothing" }
        }
        if stop.module == .spot && reading.call == .proceed {
            let avail = stop.primaryMM - stop.tertiaryMM
            if box.width > avail + 0.5 && box.depth > avail + 0.5 {
                return "plinth-spot is marked load it, but the footprint misses the floor"
            }
        }
        if reading.call == .splitParts {
            let stripped = box.reduced(by: piece.parts)
            if abs(stripped.width - box.width) < 0.5 && abs(stripped.depth - box.depth) < 0.5 && abs(stripped.height - box.height) < 0.5 {
                return "plinth-spot says take it apart, but nothing comes off"
            }
            let again = FitEngine.gate(module: stop.module, box: stripped, stop: stop, parts: [])
            if again.call == .leaveIt || again.call == .otherRoute {
                return "plinth-spot still does not fit after the parts come off"
            }
        }
        let worth = FitQuestions.partWorth(piece: piece, stop: stop)
        if worth.count != piece.parts.count {
            return "plinth-spot part check dropped a part"
        }
        let blankets = FitQuestions.blanketLimit(piece: piece, stop: stop, stock: .pine)
        if blankets < 0 || blankets > 8 {
            return "plinth-spot blanket limit is nonsense"
        }
        let order = FitQuestions.loadOrder(pieces: [piece], stops: [stop])
        if order.first?.pieceID != piece.id {
            return "plinth-spot fell out of the carry order"
        }
        let mass = FitHandling.kilograms(piece: piece, stock: .pine)
        let people = FitHandling.carriers(for: mass)
        if mass <= 0 || people < 1 {
            return "plinth-spot weight collapsed"
        }
        return nil
    }

    private static func checkPineCaseSellerDoor() -> String? {
        let form = FitAssembly.pineCase
        guard let stop = FitSeed.stop("seller-door") else { return "pineCase at seller-door has no stop" }
        let intact = form.box()
        if intact.width < 1 || intact.depth < 1 || intact.height < 1 {
            return "pineCase collapsed to an empty box"
        }
        let choice = FitAssembly.choice(assembly: form, stop: stop)
        if !choice.removed.isEmpty {
            let ids = Set(form.removable.filter { choice.removed.contains($0.name) }.map(\.id))
            let stripped = form.box(omitting: ids)
            if stripped.width > intact.width + 0.5 || stripped.height > intact.height + 0.5 || stripped.depth > intact.depth + 0.5 {
                return "pineCase grew when parts came off for seller-door"
            }
        }
        let made = FitAssembly.piece(from: form, omitting: [])
        if abs(made.widthMM - intact.width) > 1 || abs(made.depthMM - intact.depth) > 1 || abs(made.heightMM - intact.height) > 1 {
            return "pineCase piece size does not match the intact box"
        }
        let report = FitEngine.gate(module: stop.module, box: intact, stop: stop, parts: made.parts)
        let steps = FitCarry.steps(piece: made, stop: stop, report: report)
        if steps.count < 3 {
            return "pineCase at seller-door has no carry steps"
        }
        let faces = FitQuestions.faces(box: intact, stop: stop, parts: [])
        if faces.count != 6 {
            return "pineCase at seller-door did not list six faces"
        }
        let pole = FitQuestions.longestPole(hallA: max(stop.primaryMM, 1), hallB: max(stop.secondaryMM, 1))
        if pole <= 0 { return "pineCase pole collapsed at seller-door" }
        let tape = FitQuestions.tape(intact.width)
        if tape.isEmpty { return "pineCase tape line lost the measure" }
        if stop.module == .cargo {
            let bay = FitPacker.pack(pieces: [made], bay: stop)
            let allowedOut = report.call == .leaveIt || report.call == .splitParts || report.call == .otherRoute || report.call == .turnIt
            if bay.placed.isEmpty && !allowedOut {
                return "pineCase fits the check but the bay packer left it out"
            }
        }
        let people = FitHandling.carriers(for: FitHandling.kilograms(piece: made, stock: .pine))
        if people < 1 || people > 3 {
            return "pineCase people count is outside 1...3"
        }
        let brief = FitHandling.brief(piece: made, stock: .pine, blankets: 1, stop: stop)
        if brief.kilograms <= 0 { return "pineCase weighs nothing" }
        if brief.wrapped.width <= intact.width {
            return "pineCase blanket did not add width"
        }
        if choice.report.headline.isEmpty {
            return "pineCase at seller-door has an empty call"
        }
        let order = FitQuestions.loadOrder(pieces: [made], stops: [stop])
        if order.count != 1 { return "pineCase carry order lost the piece at seller-door" }
        return nil
    }

    private static func checkPineCaseSellerCorner() -> String? {
        let form = FitAssembly.pineCase
        guard let stop = FitSeed.stop("seller-corner") else { return "pineCase at seller-corner has no stop" }
        let intact = form.box()
        if intact.width < 1 || intact.depth < 1 || intact.height < 1 {
            return "pineCase collapsed to an empty box"
        }
        let choice = FitAssembly.choice(assembly: form, stop: stop)
        if !choice.removed.isEmpty {
            let ids = Set(form.removable.filter { choice.removed.contains($0.name) }.map(\.id))
            let stripped = form.box(omitting: ids)
            if stripped.width > intact.width + 0.5 || stripped.height > intact.height + 0.5 || stripped.depth > intact.depth + 0.5 {
                return "pineCase grew when parts came off for seller-corner"
            }
        }
        let made = FitAssembly.piece(from: form, omitting: [])
        if abs(made.widthMM - intact.width) > 1 || abs(made.depthMM - intact.depth) > 1 || abs(made.heightMM - intact.height) > 1 {
            return "pineCase piece size does not match the intact box"
        }
        let report = FitEngine.gate(module: stop.module, box: intact, stop: stop, parts: made.parts)
        let steps = FitCarry.steps(piece: made, stop: stop, report: report)
        if steps.count < 3 {
            return "pineCase at seller-corner has no carry steps"
        }
        let faces = FitQuestions.faces(box: intact, stop: stop, parts: [])
        if faces.count != 6 {
            return "pineCase at seller-corner did not list six faces"
        }
        let pole = FitQuestions.longestPole(hallA: max(stop.primaryMM, 1), hallB: max(stop.secondaryMM, 1))
        if pole <= 0 { return "pineCase pole collapsed at seller-corner" }
        let tape = FitQuestions.tape(intact.width)
        if tape.isEmpty { return "pineCase tape line lost the measure" }
        if stop.module == .cargo {
            let bay = FitPacker.pack(pieces: [made], bay: stop)
            let allowedOut = report.call == .leaveIt || report.call == .splitParts || report.call == .otherRoute || report.call == .turnIt
            if bay.placed.isEmpty && !allowedOut {
                return "pineCase fits the check but the bay packer left it out"
            }
        }
        let people = FitHandling.carriers(for: FitHandling.kilograms(piece: made, stock: .pine))
        if people < 1 || people > 3 {
            return "pineCase people count is outside 1...3"
        }
        let brief = FitHandling.brief(piece: made, stock: .pine, blankets: 1, stop: stop)
        if brief.kilograms <= 0 { return "pineCase weighs nothing" }
        if brief.wrapped.width <= intact.width {
            return "pineCase blanket did not add width"
        }
        if choice.report.headline.isEmpty {
            return "pineCase at seller-corner has an empty call"
        }
        let order = FitQuestions.loadOrder(pieces: [made], stops: [stop])
        if order.count != 1 { return "pineCase carry order lost the piece at seller-corner" }
        return nil
    }

    private static func checkPineCaseSellerStair() -> String? {
        let form = FitAssembly.pineCase
        guard let stop = FitSeed.stop("seller-stair") else { return "pineCase at seller-stair has no stop" }
        let intact = form.box()
        if intact.width < 1 || intact.depth < 1 || intact.height < 1 {
            return "pineCase collapsed to an empty box"
        }
        let choice = FitAssembly.choice(assembly: form, stop: stop)
        if !choice.removed.isEmpty {
            let ids = Set(form.removable.filter { choice.removed.contains($0.name) }.map(\.id))
            let stripped = form.box(omitting: ids)
            if stripped.width > intact.width + 0.5 || stripped.height > intact.height + 0.5 || stripped.depth > intact.depth + 0.5 {
                return "pineCase grew when parts came off for seller-stair"
            }
        }
        let made = FitAssembly.piece(from: form, omitting: [])
        if abs(made.widthMM - intact.width) > 1 || abs(made.depthMM - intact.depth) > 1 || abs(made.heightMM - intact.height) > 1 {
            return "pineCase piece size does not match the intact box"
        }
        let report = FitEngine.gate(module: stop.module, box: intact, stop: stop, parts: made.parts)
        let steps = FitCarry.steps(piece: made, stop: stop, report: report)
        if steps.count < 3 {
            return "pineCase at seller-stair has no carry steps"
        }
        let faces = FitQuestions.faces(box: intact, stop: stop, parts: [])
        if faces.count != 6 {
            return "pineCase at seller-stair did not list six faces"
        }
        let pole = FitQuestions.longestPole(hallA: max(stop.primaryMM, 1), hallB: max(stop.secondaryMM, 1))
        if pole <= 0 { return "pineCase pole collapsed at seller-stair" }
        let tape = FitQuestions.tape(intact.width)
        if tape.isEmpty { return "pineCase tape line lost the measure" }
        if stop.module == .cargo {
            let bay = FitPacker.pack(pieces: [made], bay: stop)
            let allowedOut = report.call == .leaveIt || report.call == .splitParts || report.call == .otherRoute || report.call == .turnIt
            if bay.placed.isEmpty && !allowedOut {
                return "pineCase fits the check but the bay packer left it out"
            }
        }
        let people = FitHandling.carriers(for: FitHandling.kilograms(piece: made, stock: .pine))
        if people < 1 || people > 3 {
            return "pineCase people count is outside 1...3"
        }
        let brief = FitHandling.brief(piece: made, stock: .pine, blankets: 1, stop: stop)
        if brief.kilograms <= 0 { return "pineCase weighs nothing" }
        if brief.wrapped.width <= intact.width {
            return "pineCase blanket did not add width"
        }
        if choice.report.headline.isEmpty {
            return "pineCase at seller-stair has an empty call"
        }
        let order = FitQuestions.loadOrder(pieces: [made], stops: [stop])
        if order.count != 1 { return "pineCase carry order lost the piece at seller-stair" }
        return nil
    }

    private static func checkPineCaseVanRear() -> String? {
        let form = FitAssembly.pineCase
        guard let stop = FitSeed.stop("van-rear") else { return "pineCase at van-rear has no stop" }
        let intact = form.box()
        if intact.width < 1 || intact.depth < 1 || intact.height < 1 {
            return "pineCase collapsed to an empty box"
        }
        let choice = FitAssembly.choice(assembly: form, stop: stop)
        if !choice.removed.isEmpty {
            let ids = Set(form.removable.filter { choice.removed.contains($0.name) }.map(\.id))
            let stripped = form.box(omitting: ids)
            if stripped.width > intact.width + 0.5 || stripped.height > intact.height + 0.5 || stripped.depth > intact.depth + 0.5 {
                return "pineCase grew when parts came off for van-rear"
            }
        }
        let made = FitAssembly.piece(from: form, omitting: [])
        if abs(made.widthMM - intact.width) > 1 || abs(made.depthMM - intact.depth) > 1 || abs(made.heightMM - intact.height) > 1 {
            return "pineCase piece size does not match the intact box"
        }
        let report = FitEngine.gate(module: stop.module, box: intact, stop: stop, parts: made.parts)
        let steps = FitCarry.steps(piece: made, stop: stop, report: report)
        if steps.count < 3 {
            return "pineCase at van-rear has no carry steps"
        }
        let faces = FitQuestions.faces(box: intact, stop: stop, parts: [])
        if faces.count != 6 {
            return "pineCase at van-rear did not list six faces"
        }
        let pole = FitQuestions.longestPole(hallA: max(stop.primaryMM, 1), hallB: max(stop.secondaryMM, 1))
        if pole <= 0 { return "pineCase pole collapsed at van-rear" }
        let tape = FitQuestions.tape(intact.width)
        if tape.isEmpty { return "pineCase tape line lost the measure" }
        if stop.module == .cargo {
            let bay = FitPacker.pack(pieces: [made], bay: stop)
            let allowedOut = report.call == .leaveIt || report.call == .splitParts || report.call == .otherRoute || report.call == .turnIt
            if bay.placed.isEmpty && !allowedOut {
                return "pineCase fits the check but the bay packer left it out"
            }
        }
        let people = FitHandling.carriers(for: FitHandling.kilograms(piece: made, stock: .pine))
        if people < 1 || people > 3 {
            return "pineCase people count is outside 1...3"
        }
        let brief = FitHandling.brief(piece: made, stock: .pine, blankets: 1, stop: stop)
        if brief.kilograms <= 0 { return "pineCase weighs nothing" }
        if brief.wrapped.width <= intact.width {
            return "pineCase blanket did not add width"
        }
        if choice.report.headline.isEmpty {
            return "pineCase at van-rear has an empty call"
        }
        let order = FitQuestions.loadOrder(pieces: [made], stops: [stop])
        if order.count != 1 { return "pineCase carry order lost the piece at van-rear" }
        return nil
    }

    private static func checkPineCaseVanBay() -> String? {
        let form = FitAssembly.pineCase
        guard let stop = FitSeed.stop("van-bay") else { return "pineCase at van-bay has no stop" }
        let intact = form.box()
        if intact.width < 1 || intact.depth < 1 || intact.height < 1 {
            return "pineCase collapsed to an empty box"
        }
        let choice = FitAssembly.choice(assembly: form, stop: stop)
        if !choice.removed.isEmpty {
            let ids = Set(form.removable.filter { choice.removed.contains($0.name) }.map(\.id))
            let stripped = form.box(omitting: ids)
            if stripped.width > intact.width + 0.5 || stripped.height > intact.height + 0.5 || stripped.depth > intact.depth + 0.5 {
                return "pineCase grew when parts came off for van-bay"
            }
        }
        let made = FitAssembly.piece(from: form, omitting: [])
        if abs(made.widthMM - intact.width) > 1 || abs(made.depthMM - intact.depth) > 1 || abs(made.heightMM - intact.height) > 1 {
            return "pineCase piece size does not match the intact box"
        }
        let report = FitEngine.gate(module: stop.module, box: intact, stop: stop, parts: made.parts)
        let steps = FitCarry.steps(piece: made, stop: stop, report: report)
        if steps.count < 3 {
            return "pineCase at van-bay has no carry steps"
        }
        let faces = FitQuestions.faces(box: intact, stop: stop, parts: [])
        if faces.count != 6 {
            return "pineCase at van-bay did not list six faces"
        }
        let pole = FitQuestions.longestPole(hallA: max(stop.primaryMM, 1), hallB: max(stop.secondaryMM, 1))
        if pole <= 0 { return "pineCase pole collapsed at van-bay" }
        let tape = FitQuestions.tape(intact.width)
        if tape.isEmpty { return "pineCase tape line lost the measure" }
        if stop.module == .cargo {
            let bay = FitPacker.pack(pieces: [made], bay: stop)
            let allowedOut = report.call == .leaveIt || report.call == .splitParts || report.call == .otherRoute || report.call == .turnIt
            if bay.placed.isEmpty && !allowedOut {
                return "pineCase fits the check but the bay packer left it out"
            }
        }
        let people = FitHandling.carriers(for: FitHandling.kilograms(piece: made, stock: .pine))
        if people < 1 || people > 3 {
            return "pineCase people count is outside 1...3"
        }
        let brief = FitHandling.brief(piece: made, stock: .pine, blankets: 1, stop: stop)
        if brief.kilograms <= 0 { return "pineCase weighs nothing" }
        if brief.wrapped.width <= intact.width {
            return "pineCase blanket did not add width"
        }
        if choice.report.headline.isEmpty {
            return "pineCase at van-bay has an empty call"
        }
        let order = FitQuestions.loadOrder(pieces: [made], stops: [stop])
        if order.count != 1 { return "pineCase carry order lost the piece at van-bay" }
        return nil
    }

    private static func checkPineCaseStorageFloor() -> String? {
        let form = FitAssembly.pineCase
        guard let stop = FitSeed.stop("storage-floor") else { return "pineCase at storage-floor has no stop" }
        let intact = form.box()
        if intact.width < 1 || intact.depth < 1 || intact.height < 1 {
            return "pineCase collapsed to an empty box"
        }
        let choice = FitAssembly.choice(assembly: form, stop: stop)
        if !choice.removed.isEmpty {
            let ids = Set(form.removable.filter { choice.removed.contains($0.name) }.map(\.id))
            let stripped = form.box(omitting: ids)
            if stripped.width > intact.width + 0.5 || stripped.height > intact.height + 0.5 || stripped.depth > intact.depth + 0.5 {
                return "pineCase grew when parts came off for storage-floor"
            }
        }
        let made = FitAssembly.piece(from: form, omitting: [])
        if abs(made.widthMM - intact.width) > 1 || abs(made.depthMM - intact.depth) > 1 || abs(made.heightMM - intact.height) > 1 {
            return "pineCase piece size does not match the intact box"
        }
        let report = FitEngine.gate(module: stop.module, box: intact, stop: stop, parts: made.parts)
        let steps = FitCarry.steps(piece: made, stop: stop, report: report)
        if steps.count < 3 {
            return "pineCase at storage-floor has no carry steps"
        }
        let faces = FitQuestions.faces(box: intact, stop: stop, parts: [])
        if faces.count != 6 {
            return "pineCase at storage-floor did not list six faces"
        }
        let pole = FitQuestions.longestPole(hallA: max(stop.primaryMM, 1), hallB: max(stop.secondaryMM, 1))
        if pole <= 0 { return "pineCase pole collapsed at storage-floor" }
        let tape = FitQuestions.tape(intact.width)
        if tape.isEmpty { return "pineCase tape line lost the measure" }
        if stop.module == .cargo {
            let bay = FitPacker.pack(pieces: [made], bay: stop)
            let allowedOut = report.call == .leaveIt || report.call == .splitParts || report.call == .otherRoute || report.call == .turnIt
            if bay.placed.isEmpty && !allowedOut {
                return "pineCase fits the check but the bay packer left it out"
            }
        }
        let people = FitHandling.carriers(for: FitHandling.kilograms(piece: made, stock: .pine))
        if people < 1 || people > 3 {
            return "pineCase people count is outside 1...3"
        }
        let brief = FitHandling.brief(piece: made, stock: .pine, blankets: 1, stop: stop)
        if brief.kilograms <= 0 { return "pineCase weighs nothing" }
        if brief.wrapped.width <= intact.width {
            return "pineCase blanket did not add width"
        }
        if choice.report.headline.isEmpty {
            return "pineCase at storage-floor has an empty call"
        }
        let order = FitQuestions.loadOrder(pieces: [made], stops: [stop])
        if order.count != 1 { return "pineCase carry order lost the piece at storage-floor" }
        return nil
    }

    private static func checkSofaSellerDoor() -> String? {
        let form = FitAssembly.sofa
        guard let stop = FitSeed.stop("seller-door") else { return "sofa at seller-door has no stop" }
        let intact = form.box()
        if intact.width < 1 || intact.depth < 1 || intact.height < 1 {
            return "sofa collapsed to an empty box"
        }
        let choice = FitAssembly.choice(assembly: form, stop: stop)
        if !choice.removed.isEmpty {
            let ids = Set(form.removable.filter { choice.removed.contains($0.name) }.map(\.id))
            let stripped = form.box(omitting: ids)
            if stripped.width > intact.width + 0.5 || stripped.height > intact.height + 0.5 || stripped.depth > intact.depth + 0.5 {
                return "sofa grew when parts came off for seller-door"
            }
        }
        let made = FitAssembly.piece(from: form, omitting: [])
        if abs(made.widthMM - intact.width) > 1 || abs(made.depthMM - intact.depth) > 1 || abs(made.heightMM - intact.height) > 1 {
            return "sofa piece size does not match the intact box"
        }
        let report = FitEngine.gate(module: stop.module, box: intact, stop: stop, parts: made.parts)
        let steps = FitCarry.steps(piece: made, stop: stop, report: report)
        if steps.count < 3 {
            return "sofa at seller-door has no carry steps"
        }
        let faces = FitQuestions.faces(box: intact, stop: stop, parts: [])
        if faces.count != 6 {
            return "sofa at seller-door did not list six faces"
        }
        let pole = FitQuestions.longestPole(hallA: max(stop.primaryMM, 1), hallB: max(stop.secondaryMM, 1))
        if pole <= 0 { return "sofa pole collapsed at seller-door" }
        let tape = FitQuestions.tape(intact.width)
        if tape.isEmpty { return "sofa tape line lost the measure" }
        if stop.module == .cargo {
            let bay = FitPacker.pack(pieces: [made], bay: stop)
            let allowedOut = report.call == .leaveIt || report.call == .splitParts || report.call == .otherRoute || report.call == .turnIt
            if bay.placed.isEmpty && !allowedOut {
                return "sofa fits the check but the bay packer left it out"
            }
        }
        let people = FitHandling.carriers(for: FitHandling.kilograms(piece: made, stock: .pine))
        if people < 1 || people > 3 {
            return "sofa people count is outside 1...3"
        }
        let brief = FitHandling.brief(piece: made, stock: .pine, blankets: 1, stop: stop)
        if brief.kilograms <= 0 { return "sofa weighs nothing" }
        if brief.wrapped.width <= intact.width {
            return "sofa blanket did not add width"
        }
        if choice.report.headline.isEmpty {
            return "sofa at seller-door has an empty call"
        }
        let order = FitQuestions.loadOrder(pieces: [made], stops: [stop])
        if order.count != 1 { return "sofa carry order lost the piece at seller-door" }
        return nil
    }

    private static func checkSofaSellerCorner() -> String? {
        let form = FitAssembly.sofa
        guard let stop = FitSeed.stop("seller-corner") else { return "sofa at seller-corner has no stop" }
        let intact = form.box()
        if intact.width < 1 || intact.depth < 1 || intact.height < 1 {
            return "sofa collapsed to an empty box"
        }
        let choice = FitAssembly.choice(assembly: form, stop: stop)
        if !choice.removed.isEmpty {
            let ids = Set(form.removable.filter { choice.removed.contains($0.name) }.map(\.id))
            let stripped = form.box(omitting: ids)
            if stripped.width > intact.width + 0.5 || stripped.height > intact.height + 0.5 || stripped.depth > intact.depth + 0.5 {
                return "sofa grew when parts came off for seller-corner"
            }
        }
        let made = FitAssembly.piece(from: form, omitting: [])
        if abs(made.widthMM - intact.width) > 1 || abs(made.depthMM - intact.depth) > 1 || abs(made.heightMM - intact.height) > 1 {
            return "sofa piece size does not match the intact box"
        }
        let report = FitEngine.gate(module: stop.module, box: intact, stop: stop, parts: made.parts)
        let steps = FitCarry.steps(piece: made, stop: stop, report: report)
        if steps.count < 3 {
            return "sofa at seller-corner has no carry steps"
        }
        let faces = FitQuestions.faces(box: intact, stop: stop, parts: [])
        if faces.count != 6 {
            return "sofa at seller-corner did not list six faces"
        }
        let pole = FitQuestions.longestPole(hallA: max(stop.primaryMM, 1), hallB: max(stop.secondaryMM, 1))
        if pole <= 0 { return "sofa pole collapsed at seller-corner" }
        let tape = FitQuestions.tape(intact.width)
        if tape.isEmpty { return "sofa tape line lost the measure" }
        if stop.module == .cargo {
            let bay = FitPacker.pack(pieces: [made], bay: stop)
            let allowedOut = report.call == .leaveIt || report.call == .splitParts || report.call == .otherRoute || report.call == .turnIt
            if bay.placed.isEmpty && !allowedOut {
                return "sofa fits the check but the bay packer left it out"
            }
        }
        let people = FitHandling.carriers(for: FitHandling.kilograms(piece: made, stock: .pine))
        if people < 1 || people > 3 {
            return "sofa people count is outside 1...3"
        }
        let brief = FitHandling.brief(piece: made, stock: .pine, blankets: 1, stop: stop)
        if brief.kilograms <= 0 { return "sofa weighs nothing" }
        if brief.wrapped.width <= intact.width {
            return "sofa blanket did not add width"
        }
        if choice.report.headline.isEmpty {
            return "sofa at seller-corner has an empty call"
        }
        let order = FitQuestions.loadOrder(pieces: [made], stops: [stop])
        if order.count != 1 { return "sofa carry order lost the piece at seller-corner" }
        return nil
    }

    private static func checkSofaSellerStair() -> String? {
        let form = FitAssembly.sofa
        guard let stop = FitSeed.stop("seller-stair") else { return "sofa at seller-stair has no stop" }
        let intact = form.box()
        if intact.width < 1 || intact.depth < 1 || intact.height < 1 {
            return "sofa collapsed to an empty box"
        }
        let choice = FitAssembly.choice(assembly: form, stop: stop)
        if !choice.removed.isEmpty {
            let ids = Set(form.removable.filter { choice.removed.contains($0.name) }.map(\.id))
            let stripped = form.box(omitting: ids)
            if stripped.width > intact.width + 0.5 || stripped.height > intact.height + 0.5 || stripped.depth > intact.depth + 0.5 {
                return "sofa grew when parts came off for seller-stair"
            }
        }
        let made = FitAssembly.piece(from: form, omitting: [])
        if abs(made.widthMM - intact.width) > 1 || abs(made.depthMM - intact.depth) > 1 || abs(made.heightMM - intact.height) > 1 {
            return "sofa piece size does not match the intact box"
        }
        let report = FitEngine.gate(module: stop.module, box: intact, stop: stop, parts: made.parts)
        let steps = FitCarry.steps(piece: made, stop: stop, report: report)
        if steps.count < 3 {
            return "sofa at seller-stair has no carry steps"
        }
        let faces = FitQuestions.faces(box: intact, stop: stop, parts: [])
        if faces.count != 6 {
            return "sofa at seller-stair did not list six faces"
        }
        let pole = FitQuestions.longestPole(hallA: max(stop.primaryMM, 1), hallB: max(stop.secondaryMM, 1))
        if pole <= 0 { return "sofa pole collapsed at seller-stair" }
        let tape = FitQuestions.tape(intact.width)
        if tape.isEmpty { return "sofa tape line lost the measure" }
        if stop.module == .cargo {
            let bay = FitPacker.pack(pieces: [made], bay: stop)
            let allowedOut = report.call == .leaveIt || report.call == .splitParts || report.call == .otherRoute || report.call == .turnIt
            if bay.placed.isEmpty && !allowedOut {
                return "sofa fits the check but the bay packer left it out"
            }
        }
        let people = FitHandling.carriers(for: FitHandling.kilograms(piece: made, stock: .pine))
        if people < 1 || people > 3 {
            return "sofa people count is outside 1...3"
        }
        let brief = FitHandling.brief(piece: made, stock: .pine, blankets: 1, stop: stop)
        if brief.kilograms <= 0 { return "sofa weighs nothing" }
        if brief.wrapped.width <= intact.width {
            return "sofa blanket did not add width"
        }
        if choice.report.headline.isEmpty {
            return "sofa at seller-stair has an empty call"
        }
        let order = FitQuestions.loadOrder(pieces: [made], stops: [stop])
        if order.count != 1 { return "sofa carry order lost the piece at seller-stair" }
        return nil
    }

    private static func checkSofaVanRear() -> String? {
        let form = FitAssembly.sofa
        guard let stop = FitSeed.stop("van-rear") else { return "sofa at van-rear has no stop" }
        let intact = form.box()
        if intact.width < 1 || intact.depth < 1 || intact.height < 1 {
            return "sofa collapsed to an empty box"
        }
        let choice = FitAssembly.choice(assembly: form, stop: stop)
        if !choice.removed.isEmpty {
            let ids = Set(form.removable.filter { choice.removed.contains($0.name) }.map(\.id))
            let stripped = form.box(omitting: ids)
            if stripped.width > intact.width + 0.5 || stripped.height > intact.height + 0.5 || stripped.depth > intact.depth + 0.5 {
                return "sofa grew when parts came off for van-rear"
            }
        }
        let made = FitAssembly.piece(from: form, omitting: [])
        if abs(made.widthMM - intact.width) > 1 || abs(made.depthMM - intact.depth) > 1 || abs(made.heightMM - intact.height) > 1 {
            return "sofa piece size does not match the intact box"
        }
        let report = FitEngine.gate(module: stop.module, box: intact, stop: stop, parts: made.parts)
        let steps = FitCarry.steps(piece: made, stop: stop, report: report)
        if steps.count < 3 {
            return "sofa at van-rear has no carry steps"
        }
        let faces = FitQuestions.faces(box: intact, stop: stop, parts: [])
        if faces.count != 6 {
            return "sofa at van-rear did not list six faces"
        }
        let pole = FitQuestions.longestPole(hallA: max(stop.primaryMM, 1), hallB: max(stop.secondaryMM, 1))
        if pole <= 0 { return "sofa pole collapsed at van-rear" }
        let tape = FitQuestions.tape(intact.width)
        if tape.isEmpty { return "sofa tape line lost the measure" }
        if stop.module == .cargo {
            let bay = FitPacker.pack(pieces: [made], bay: stop)
            let allowedOut = report.call == .leaveIt || report.call == .splitParts || report.call == .otherRoute || report.call == .turnIt
            if bay.placed.isEmpty && !allowedOut {
                return "sofa fits the check but the bay packer left it out"
            }
        }
        let people = FitHandling.carriers(for: FitHandling.kilograms(piece: made, stock: .pine))
        if people < 1 || people > 3 {
            return "sofa people count is outside 1...3"
        }
        let brief = FitHandling.brief(piece: made, stock: .pine, blankets: 1, stop: stop)
        if brief.kilograms <= 0 { return "sofa weighs nothing" }
        if brief.wrapped.width <= intact.width {
            return "sofa blanket did not add width"
        }
        if choice.report.headline.isEmpty {
            return "sofa at van-rear has an empty call"
        }
        let order = FitQuestions.loadOrder(pieces: [made], stops: [stop])
        if order.count != 1 { return "sofa carry order lost the piece at van-rear" }
        return nil
    }

    private static func checkSofaVanBay() -> String? {
        let form = FitAssembly.sofa
        guard let stop = FitSeed.stop("van-bay") else { return "sofa at van-bay has no stop" }
        let intact = form.box()
        if intact.width < 1 || intact.depth < 1 || intact.height < 1 {
            return "sofa collapsed to an empty box"
        }
        let choice = FitAssembly.choice(assembly: form, stop: stop)
        if !choice.removed.isEmpty {
            let ids = Set(form.removable.filter { choice.removed.contains($0.name) }.map(\.id))
            let stripped = form.box(omitting: ids)
            if stripped.width > intact.width + 0.5 || stripped.height > intact.height + 0.5 || stripped.depth > intact.depth + 0.5 {
                return "sofa grew when parts came off for van-bay"
            }
        }
        let made = FitAssembly.piece(from: form, omitting: [])
        if abs(made.widthMM - intact.width) > 1 || abs(made.depthMM - intact.depth) > 1 || abs(made.heightMM - intact.height) > 1 {
            return "sofa piece size does not match the intact box"
        }
        let report = FitEngine.gate(module: stop.module, box: intact, stop: stop, parts: made.parts)
        let steps = FitCarry.steps(piece: made, stop: stop, report: report)
        if steps.count < 3 {
            return "sofa at van-bay has no carry steps"
        }
        let faces = FitQuestions.faces(box: intact, stop: stop, parts: [])
        if faces.count != 6 {
            return "sofa at van-bay did not list six faces"
        }
        let pole = FitQuestions.longestPole(hallA: max(stop.primaryMM, 1), hallB: max(stop.secondaryMM, 1))
        if pole <= 0 { return "sofa pole collapsed at van-bay" }
        let tape = FitQuestions.tape(intact.width)
        if tape.isEmpty { return "sofa tape line lost the measure" }
        if stop.module == .cargo {
            let bay = FitPacker.pack(pieces: [made], bay: stop)
            let allowedOut = report.call == .leaveIt || report.call == .splitParts || report.call == .otherRoute || report.call == .turnIt
            if bay.placed.isEmpty && !allowedOut {
                return "sofa fits the check but the bay packer left it out"
            }
        }
        let people = FitHandling.carriers(for: FitHandling.kilograms(piece: made, stock: .pine))
        if people < 1 || people > 3 {
            return "sofa people count is outside 1...3"
        }
        let brief = FitHandling.brief(piece: made, stock: .pine, blankets: 1, stop: stop)
        if brief.kilograms <= 0 { return "sofa weighs nothing" }
        if brief.wrapped.width <= intact.width {
            return "sofa blanket did not add width"
        }
        if choice.report.headline.isEmpty {
            return "sofa at van-bay has an empty call"
        }
        let order = FitQuestions.loadOrder(pieces: [made], stops: [stop])
        if order.count != 1 { return "sofa carry order lost the piece at van-bay" }
        return nil
    }

    private static func checkSofaStorageFloor() -> String? {
        let form = FitAssembly.sofa
        guard let stop = FitSeed.stop("storage-floor") else { return "sofa at storage-floor has no stop" }
        let intact = form.box()
        if intact.width < 1 || intact.depth < 1 || intact.height < 1 {
            return "sofa collapsed to an empty box"
        }
        let choice = FitAssembly.choice(assembly: form, stop: stop)
        if !choice.removed.isEmpty {
            let ids = Set(form.removable.filter { choice.removed.contains($0.name) }.map(\.id))
            let stripped = form.box(omitting: ids)
            if stripped.width > intact.width + 0.5 || stripped.height > intact.height + 0.5 || stripped.depth > intact.depth + 0.5 {
                return "sofa grew when parts came off for storage-floor"
            }
        }
        let made = FitAssembly.piece(from: form, omitting: [])
        if abs(made.widthMM - intact.width) > 1 || abs(made.depthMM - intact.depth) > 1 || abs(made.heightMM - intact.height) > 1 {
            return "sofa piece size does not match the intact box"
        }
        let report = FitEngine.gate(module: stop.module, box: intact, stop: stop, parts: made.parts)
        let steps = FitCarry.steps(piece: made, stop: stop, report: report)
        if steps.count < 3 {
            return "sofa at storage-floor has no carry steps"
        }
        let faces = FitQuestions.faces(box: intact, stop: stop, parts: [])
        if faces.count != 6 {
            return "sofa at storage-floor did not list six faces"
        }
        let pole = FitQuestions.longestPole(hallA: max(stop.primaryMM, 1), hallB: max(stop.secondaryMM, 1))
        if pole <= 0 { return "sofa pole collapsed at storage-floor" }
        let tape = FitQuestions.tape(intact.width)
        if tape.isEmpty { return "sofa tape line lost the measure" }
        if stop.module == .cargo {
            let bay = FitPacker.pack(pieces: [made], bay: stop)
            let allowedOut = report.call == .leaveIt || report.call == .splitParts || report.call == .otherRoute || report.call == .turnIt
            if bay.placed.isEmpty && !allowedOut {
                return "sofa fits the check but the bay packer left it out"
            }
        }
        let people = FitHandling.carriers(for: FitHandling.kilograms(piece: made, stock: .pine))
        if people < 1 || people > 3 {
            return "sofa people count is outside 1...3"
        }
        let brief = FitHandling.brief(piece: made, stock: .pine, blankets: 1, stop: stop)
        if brief.kilograms <= 0 { return "sofa weighs nothing" }
        if brief.wrapped.width <= intact.width {
            return "sofa blanket did not add width"
        }
        if choice.report.headline.isEmpty {
            return "sofa at storage-floor has an empty call"
        }
        let order = FitQuestions.loadOrder(pieces: [made], stops: [stop])
        if order.count != 1 { return "sofa carry order lost the piece at storage-floor" }
        return nil
    }

    private static func checkTableSellerDoor() -> String? {
        let form = FitAssembly.table
        guard let stop = FitSeed.stop("seller-door") else { return "table at seller-door has no stop" }
        let intact = form.box()
        if intact.width < 1 || intact.depth < 1 || intact.height < 1 {
            return "table collapsed to an empty box"
        }
        let choice = FitAssembly.choice(assembly: form, stop: stop)
        if !choice.removed.isEmpty {
            let ids = Set(form.removable.filter { choice.removed.contains($0.name) }.map(\.id))
            let stripped = form.box(omitting: ids)
            if stripped.width > intact.width + 0.5 || stripped.height > intact.height + 0.5 || stripped.depth > intact.depth + 0.5 {
                return "table grew when parts came off for seller-door"
            }
        }
        let made = FitAssembly.piece(from: form, omitting: [])
        if abs(made.widthMM - intact.width) > 1 || abs(made.depthMM - intact.depth) > 1 || abs(made.heightMM - intact.height) > 1 {
            return "table piece size does not match the intact box"
        }
        let report = FitEngine.gate(module: stop.module, box: intact, stop: stop, parts: made.parts)
        let steps = FitCarry.steps(piece: made, stop: stop, report: report)
        if steps.count < 3 {
            return "table at seller-door has no carry steps"
        }
        let faces = FitQuestions.faces(box: intact, stop: stop, parts: [])
        if faces.count != 6 {
            return "table at seller-door did not list six faces"
        }
        let pole = FitQuestions.longestPole(hallA: max(stop.primaryMM, 1), hallB: max(stop.secondaryMM, 1))
        if pole <= 0 { return "table pole collapsed at seller-door" }
        let tape = FitQuestions.tape(intact.width)
        if tape.isEmpty { return "table tape line lost the measure" }
        if stop.module == .cargo {
            let bay = FitPacker.pack(pieces: [made], bay: stop)
            let allowedOut = report.call == .leaveIt || report.call == .splitParts || report.call == .otherRoute || report.call == .turnIt
            if bay.placed.isEmpty && !allowedOut {
                return "table fits the check but the bay packer left it out"
            }
        }
        let people = FitHandling.carriers(for: FitHandling.kilograms(piece: made, stock: .pine))
        if people < 1 || people > 3 {
            return "table people count is outside 1...3"
        }
        let brief = FitHandling.brief(piece: made, stock: .pine, blankets: 1, stop: stop)
        if brief.kilograms <= 0 { return "table weighs nothing" }
        if brief.wrapped.width <= intact.width {
            return "table blanket did not add width"
        }
        if choice.report.headline.isEmpty {
            return "table at seller-door has an empty call"
        }
        let order = FitQuestions.loadOrder(pieces: [made], stops: [stop])
        if order.count != 1 { return "table carry order lost the piece at seller-door" }
        return nil
    }

    private static func checkTableSellerCorner() -> String? {
        let form = FitAssembly.table
        guard let stop = FitSeed.stop("seller-corner") else { return "table at seller-corner has no stop" }
        let intact = form.box()
        if intact.width < 1 || intact.depth < 1 || intact.height < 1 {
            return "table collapsed to an empty box"
        }
        let choice = FitAssembly.choice(assembly: form, stop: stop)
        if !choice.removed.isEmpty {
            let ids = Set(form.removable.filter { choice.removed.contains($0.name) }.map(\.id))
            let stripped = form.box(omitting: ids)
            if stripped.width > intact.width + 0.5 || stripped.height > intact.height + 0.5 || stripped.depth > intact.depth + 0.5 {
                return "table grew when parts came off for seller-corner"
            }
        }
        let made = FitAssembly.piece(from: form, omitting: [])
        if abs(made.widthMM - intact.width) > 1 || abs(made.depthMM - intact.depth) > 1 || abs(made.heightMM - intact.height) > 1 {
            return "table piece size does not match the intact box"
        }
        let report = FitEngine.gate(module: stop.module, box: intact, stop: stop, parts: made.parts)
        let steps = FitCarry.steps(piece: made, stop: stop, report: report)
        if steps.count < 3 {
            return "table at seller-corner has no carry steps"
        }
        let faces = FitQuestions.faces(box: intact, stop: stop, parts: [])
        if faces.count != 6 {
            return "table at seller-corner did not list six faces"
        }
        let pole = FitQuestions.longestPole(hallA: max(stop.primaryMM, 1), hallB: max(stop.secondaryMM, 1))
        if pole <= 0 { return "table pole collapsed at seller-corner" }
        let tape = FitQuestions.tape(intact.width)
        if tape.isEmpty { return "table tape line lost the measure" }
        if stop.module == .cargo {
            let bay = FitPacker.pack(pieces: [made], bay: stop)
            let allowedOut = report.call == .leaveIt || report.call == .splitParts || report.call == .otherRoute || report.call == .turnIt
            if bay.placed.isEmpty && !allowedOut {
                return "table fits the check but the bay packer left it out"
            }
        }
        let people = FitHandling.carriers(for: FitHandling.kilograms(piece: made, stock: .pine))
        if people < 1 || people > 3 {
            return "table people count is outside 1...3"
        }
        let brief = FitHandling.brief(piece: made, stock: .pine, blankets: 1, stop: stop)
        if brief.kilograms <= 0 { return "table weighs nothing" }
        if brief.wrapped.width <= intact.width {
            return "table blanket did not add width"
        }
        if choice.report.headline.isEmpty {
            return "table at seller-corner has an empty call"
        }
        let order = FitQuestions.loadOrder(pieces: [made], stops: [stop])
        if order.count != 1 { return "table carry order lost the piece at seller-corner" }
        return nil
    }

    private static func checkTableSellerStair() -> String? {
        let form = FitAssembly.table
        guard let stop = FitSeed.stop("seller-stair") else { return "table at seller-stair has no stop" }
        let intact = form.box()
        if intact.width < 1 || intact.depth < 1 || intact.height < 1 {
            return "table collapsed to an empty box"
        }
        let choice = FitAssembly.choice(assembly: form, stop: stop)
        if !choice.removed.isEmpty {
            let ids = Set(form.removable.filter { choice.removed.contains($0.name) }.map(\.id))
            let stripped = form.box(omitting: ids)
            if stripped.width > intact.width + 0.5 || stripped.height > intact.height + 0.5 || stripped.depth > intact.depth + 0.5 {
                return "table grew when parts came off for seller-stair"
            }
        }
        let made = FitAssembly.piece(from: form, omitting: [])
        if abs(made.widthMM - intact.width) > 1 || abs(made.depthMM - intact.depth) > 1 || abs(made.heightMM - intact.height) > 1 {
            return "table piece size does not match the intact box"
        }
        let report = FitEngine.gate(module: stop.module, box: intact, stop: stop, parts: made.parts)
        let steps = FitCarry.steps(piece: made, stop: stop, report: report)
        if steps.count < 3 {
            return "table at seller-stair has no carry steps"
        }
        let faces = FitQuestions.faces(box: intact, stop: stop, parts: [])
        if faces.count != 6 {
            return "table at seller-stair did not list six faces"
        }
        let pole = FitQuestions.longestPole(hallA: max(stop.primaryMM, 1), hallB: max(stop.secondaryMM, 1))
        if pole <= 0 { return "table pole collapsed at seller-stair" }
        let tape = FitQuestions.tape(intact.width)
        if tape.isEmpty { return "table tape line lost the measure" }
        if stop.module == .cargo {
            let bay = FitPacker.pack(pieces: [made], bay: stop)
            let allowedOut = report.call == .leaveIt || report.call == .splitParts || report.call == .otherRoute || report.call == .turnIt
            if bay.placed.isEmpty && !allowedOut {
                return "table fits the check but the bay packer left it out"
            }
        }
        let people = FitHandling.carriers(for: FitHandling.kilograms(piece: made, stock: .pine))
        if people < 1 || people > 3 {
            return "table people count is outside 1...3"
        }
        let brief = FitHandling.brief(piece: made, stock: .pine, blankets: 1, stop: stop)
        if brief.kilograms <= 0 { return "table weighs nothing" }
        if brief.wrapped.width <= intact.width {
            return "table blanket did not add width"
        }
        if choice.report.headline.isEmpty {
            return "table at seller-stair has an empty call"
        }
        let order = FitQuestions.loadOrder(pieces: [made], stops: [stop])
        if order.count != 1 { return "table carry order lost the piece at seller-stair" }
        return nil
    }

    private static func checkTableVanRear() -> String? {
        let form = FitAssembly.table
        guard let stop = FitSeed.stop("van-rear") else { return "table at van-rear has no stop" }
        let intact = form.box()
        if intact.width < 1 || intact.depth < 1 || intact.height < 1 {
            return "table collapsed to an empty box"
        }
        let choice = FitAssembly.choice(assembly: form, stop: stop)
        if !choice.removed.isEmpty {
            let ids = Set(form.removable.filter { choice.removed.contains($0.name) }.map(\.id))
            let stripped = form.box(omitting: ids)
            if stripped.width > intact.width + 0.5 || stripped.height > intact.height + 0.5 || stripped.depth > intact.depth + 0.5 {
                return "table grew when parts came off for van-rear"
            }
        }
        let made = FitAssembly.piece(from: form, omitting: [])
        if abs(made.widthMM - intact.width) > 1 || abs(made.depthMM - intact.depth) > 1 || abs(made.heightMM - intact.height) > 1 {
            return "table piece size does not match the intact box"
        }
        let report = FitEngine.gate(module: stop.module, box: intact, stop: stop, parts: made.parts)
        let steps = FitCarry.steps(piece: made, stop: stop, report: report)
        if steps.count < 3 {
            return "table at van-rear has no carry steps"
        }
        let faces = FitQuestions.faces(box: intact, stop: stop, parts: [])
        if faces.count != 6 {
            return "table at van-rear did not list six faces"
        }
        let pole = FitQuestions.longestPole(hallA: max(stop.primaryMM, 1), hallB: max(stop.secondaryMM, 1))
        if pole <= 0 { return "table pole collapsed at van-rear" }
        let tape = FitQuestions.tape(intact.width)
        if tape.isEmpty { return "table tape line lost the measure" }
        if stop.module == .cargo {
            let bay = FitPacker.pack(pieces: [made], bay: stop)
            let allowedOut = report.call == .leaveIt || report.call == .splitParts || report.call == .otherRoute || report.call == .turnIt
            if bay.placed.isEmpty && !allowedOut {
                return "table fits the check but the bay packer left it out"
            }
        }
        let people = FitHandling.carriers(for: FitHandling.kilograms(piece: made, stock: .pine))
        if people < 1 || people > 3 {
            return "table people count is outside 1...3"
        }
        let brief = FitHandling.brief(piece: made, stock: .pine, blankets: 1, stop: stop)
        if brief.kilograms <= 0 { return "table weighs nothing" }
        if brief.wrapped.width <= intact.width {
            return "table blanket did not add width"
        }
        if choice.report.headline.isEmpty {
            return "table at van-rear has an empty call"
        }
        let order = FitQuestions.loadOrder(pieces: [made], stops: [stop])
        if order.count != 1 { return "table carry order lost the piece at van-rear" }
        return nil
    }

    private static func checkTableVanBay() -> String? {
        let form = FitAssembly.table
        guard let stop = FitSeed.stop("van-bay") else { return "table at van-bay has no stop" }
        let intact = form.box()
        if intact.width < 1 || intact.depth < 1 || intact.height < 1 {
            return "table collapsed to an empty box"
        }
        let choice = FitAssembly.choice(assembly: form, stop: stop)
        if !choice.removed.isEmpty {
            let ids = Set(form.removable.filter { choice.removed.contains($0.name) }.map(\.id))
            let stripped = form.box(omitting: ids)
            if stripped.width > intact.width + 0.5 || stripped.height > intact.height + 0.5 || stripped.depth > intact.depth + 0.5 {
                return "table grew when parts came off for van-bay"
            }
        }
        let made = FitAssembly.piece(from: form, omitting: [])
        if abs(made.widthMM - intact.width) > 1 || abs(made.depthMM - intact.depth) > 1 || abs(made.heightMM - intact.height) > 1 {
            return "table piece size does not match the intact box"
        }
        let report = FitEngine.gate(module: stop.module, box: intact, stop: stop, parts: made.parts)
        let steps = FitCarry.steps(piece: made, stop: stop, report: report)
        if steps.count < 3 {
            return "table at van-bay has no carry steps"
        }
        let faces = FitQuestions.faces(box: intact, stop: stop, parts: [])
        if faces.count != 6 {
            return "table at van-bay did not list six faces"
        }
        let pole = FitQuestions.longestPole(hallA: max(stop.primaryMM, 1), hallB: max(stop.secondaryMM, 1))
        if pole <= 0 { return "table pole collapsed at van-bay" }
        let tape = FitQuestions.tape(intact.width)
        if tape.isEmpty { return "table tape line lost the measure" }
        if stop.module == .cargo {
            let bay = FitPacker.pack(pieces: [made], bay: stop)
            let allowedOut = report.call == .leaveIt || report.call == .splitParts || report.call == .otherRoute || report.call == .turnIt
            if bay.placed.isEmpty && !allowedOut {
                return "table fits the check but the bay packer left it out"
            }
        }
        let people = FitHandling.carriers(for: FitHandling.kilograms(piece: made, stock: .pine))
        if people < 1 || people > 3 {
            return "table people count is outside 1...3"
        }
        let brief = FitHandling.brief(piece: made, stock: .pine, blankets: 1, stop: stop)
        if brief.kilograms <= 0 { return "table weighs nothing" }
        if brief.wrapped.width <= intact.width {
            return "table blanket did not add width"
        }
        if choice.report.headline.isEmpty {
            return "table at van-bay has an empty call"
        }
        let order = FitQuestions.loadOrder(pieces: [made], stops: [stop])
        if order.count != 1 { return "table carry order lost the piece at van-bay" }
        return nil
    }

    private static func checkTableStorageFloor() -> String? {
        let form = FitAssembly.table
        guard let stop = FitSeed.stop("storage-floor") else { return "table at storage-floor has no stop" }
        let intact = form.box()
        if intact.width < 1 || intact.depth < 1 || intact.height < 1 {
            return "table collapsed to an empty box"
        }
        let choice = FitAssembly.choice(assembly: form, stop: stop)
        if !choice.removed.isEmpty {
            let ids = Set(form.removable.filter { choice.removed.contains($0.name) }.map(\.id))
            let stripped = form.box(omitting: ids)
            if stripped.width > intact.width + 0.5 || stripped.height > intact.height + 0.5 || stripped.depth > intact.depth + 0.5 {
                return "table grew when parts came off for storage-floor"
            }
        }
        let made = FitAssembly.piece(from: form, omitting: [])
        if abs(made.widthMM - intact.width) > 1 || abs(made.depthMM - intact.depth) > 1 || abs(made.heightMM - intact.height) > 1 {
            return "table piece size does not match the intact box"
        }
        let report = FitEngine.gate(module: stop.module, box: intact, stop: stop, parts: made.parts)
        let steps = FitCarry.steps(piece: made, stop: stop, report: report)
        if steps.count < 3 {
            return "table at storage-floor has no carry steps"
        }
        let faces = FitQuestions.faces(box: intact, stop: stop, parts: [])
        if faces.count != 6 {
            return "table at storage-floor did not list six faces"
        }
        let pole = FitQuestions.longestPole(hallA: max(stop.primaryMM, 1), hallB: max(stop.secondaryMM, 1))
        if pole <= 0 { return "table pole collapsed at storage-floor" }
        let tape = FitQuestions.tape(intact.width)
        if tape.isEmpty { return "table tape line lost the measure" }
        if stop.module == .cargo {
            let bay = FitPacker.pack(pieces: [made], bay: stop)
            let allowedOut = report.call == .leaveIt || report.call == .splitParts || report.call == .otherRoute || report.call == .turnIt
            if bay.placed.isEmpty && !allowedOut {
                return "table fits the check but the bay packer left it out"
            }
        }
        let people = FitHandling.carriers(for: FitHandling.kilograms(piece: made, stock: .pine))
        if people < 1 || people > 3 {
            return "table people count is outside 1...3"
        }
        let brief = FitHandling.brief(piece: made, stock: .pine, blankets: 1, stop: stop)
        if brief.kilograms <= 0 { return "table weighs nothing" }
        if brief.wrapped.width <= intact.width {
            return "table blanket did not add width"
        }
        if choice.report.headline.isEmpty {
            return "table at storage-floor has an empty call"
        }
        let order = FitQuestions.loadOrder(pieces: [made], stops: [stop])
        if order.count != 1 { return "table carry order lost the piece at storage-floor" }
        return nil
    }

    private static func checkFridgeSellerDoor() -> String? {
        let form = FitAssembly.fridge
        guard let stop = FitSeed.stop("seller-door") else { return "fridge at seller-door has no stop" }
        let intact = form.box()
        if intact.width < 1 || intact.depth < 1 || intact.height < 1 {
            return "fridge collapsed to an empty box"
        }
        let choice = FitAssembly.choice(assembly: form, stop: stop)
        if !choice.removed.isEmpty {
            let ids = Set(form.removable.filter { choice.removed.contains($0.name) }.map(\.id))
            let stripped = form.box(omitting: ids)
            if stripped.width > intact.width + 0.5 || stripped.height > intact.height + 0.5 || stripped.depth > intact.depth + 0.5 {
                return "fridge grew when parts came off for seller-door"
            }
        }
        let made = FitAssembly.piece(from: form, omitting: [])
        if abs(made.widthMM - intact.width) > 1 || abs(made.depthMM - intact.depth) > 1 || abs(made.heightMM - intact.height) > 1 {
            return "fridge piece size does not match the intact box"
        }
        let report = FitEngine.gate(module: stop.module, box: intact, stop: stop, parts: made.parts)
        let steps = FitCarry.steps(piece: made, stop: stop, report: report)
        if steps.count < 3 {
            return "fridge at seller-door has no carry steps"
        }
        let faces = FitQuestions.faces(box: intact, stop: stop, parts: [])
        if faces.count != 6 {
            return "fridge at seller-door did not list six faces"
        }
        let pole = FitQuestions.longestPole(hallA: max(stop.primaryMM, 1), hallB: max(stop.secondaryMM, 1))
        if pole <= 0 { return "fridge pole collapsed at seller-door" }
        let tape = FitQuestions.tape(intact.width)
        if tape.isEmpty { return "fridge tape line lost the measure" }
        if stop.module == .cargo {
            let bay = FitPacker.pack(pieces: [made], bay: stop)
            let allowedOut = report.call == .leaveIt || report.call == .splitParts || report.call == .otherRoute || report.call == .turnIt
            if bay.placed.isEmpty && !allowedOut {
                return "fridge fits the check but the bay packer left it out"
            }
        }
        let people = FitHandling.carriers(for: FitHandling.kilograms(piece: made, stock: .pine))
        if people < 1 || people > 3 {
            return "fridge people count is outside 1...3"
        }
        let brief = FitHandling.brief(piece: made, stock: .pine, blankets: 1, stop: stop)
        if brief.kilograms <= 0 { return "fridge weighs nothing" }
        if brief.wrapped.width <= intact.width {
            return "fridge blanket did not add width"
        }
        if choice.report.headline.isEmpty {
            return "fridge at seller-door has an empty call"
        }
        let order = FitQuestions.loadOrder(pieces: [made], stops: [stop])
        if order.count != 1 { return "fridge carry order lost the piece at seller-door" }
        return nil
    }

    private static func checkFridgeSellerCorner() -> String? {
        let form = FitAssembly.fridge
        guard let stop = FitSeed.stop("seller-corner") else { return "fridge at seller-corner has no stop" }
        let intact = form.box()
        if intact.width < 1 || intact.depth < 1 || intact.height < 1 {
            return "fridge collapsed to an empty box"
        }
        let choice = FitAssembly.choice(assembly: form, stop: stop)
        if !choice.removed.isEmpty {
            let ids = Set(form.removable.filter { choice.removed.contains($0.name) }.map(\.id))
            let stripped = form.box(omitting: ids)
            if stripped.width > intact.width + 0.5 || stripped.height > intact.height + 0.5 || stripped.depth > intact.depth + 0.5 {
                return "fridge grew when parts came off for seller-corner"
            }
        }
        let made = FitAssembly.piece(from: form, omitting: [])
        if abs(made.widthMM - intact.width) > 1 || abs(made.depthMM - intact.depth) > 1 || abs(made.heightMM - intact.height) > 1 {
            return "fridge piece size does not match the intact box"
        }
        let report = FitEngine.gate(module: stop.module, box: intact, stop: stop, parts: made.parts)
        let steps = FitCarry.steps(piece: made, stop: stop, report: report)
        if steps.count < 3 {
            return "fridge at seller-corner has no carry steps"
        }
        let faces = FitQuestions.faces(box: intact, stop: stop, parts: [])
        if faces.count != 6 {
            return "fridge at seller-corner did not list six faces"
        }
        let pole = FitQuestions.longestPole(hallA: max(stop.primaryMM, 1), hallB: max(stop.secondaryMM, 1))
        if pole <= 0 { return "fridge pole collapsed at seller-corner" }
        let tape = FitQuestions.tape(intact.width)
        if tape.isEmpty { return "fridge tape line lost the measure" }
        if stop.module == .cargo {
            let bay = FitPacker.pack(pieces: [made], bay: stop)
            let allowedOut = report.call == .leaveIt || report.call == .splitParts || report.call == .otherRoute || report.call == .turnIt
            if bay.placed.isEmpty && !allowedOut {
                return "fridge fits the check but the bay packer left it out"
            }
        }
        let people = FitHandling.carriers(for: FitHandling.kilograms(piece: made, stock: .pine))
        if people < 1 || people > 3 {
            return "fridge people count is outside 1...3"
        }
        let brief = FitHandling.brief(piece: made, stock: .pine, blankets: 1, stop: stop)
        if brief.kilograms <= 0 { return "fridge weighs nothing" }
        if brief.wrapped.width <= intact.width {
            return "fridge blanket did not add width"
        }
        if choice.report.headline.isEmpty {
            return "fridge at seller-corner has an empty call"
        }
        let order = FitQuestions.loadOrder(pieces: [made], stops: [stop])
        if order.count != 1 { return "fridge carry order lost the piece at seller-corner" }
        return nil
    }

    private static func checkFridgeSellerStair() -> String? {
        let form = FitAssembly.fridge
        guard let stop = FitSeed.stop("seller-stair") else { return "fridge at seller-stair has no stop" }
        let intact = form.box()
        if intact.width < 1 || intact.depth < 1 || intact.height < 1 {
            return "fridge collapsed to an empty box"
        }
        let choice = FitAssembly.choice(assembly: form, stop: stop)
        if !choice.removed.isEmpty {
            let ids = Set(form.removable.filter { choice.removed.contains($0.name) }.map(\.id))
            let stripped = form.box(omitting: ids)
            if stripped.width > intact.width + 0.5 || stripped.height > intact.height + 0.5 || stripped.depth > intact.depth + 0.5 {
                return "fridge grew when parts came off for seller-stair"
            }
        }
        let made = FitAssembly.piece(from: form, omitting: [])
        if abs(made.widthMM - intact.width) > 1 || abs(made.depthMM - intact.depth) > 1 || abs(made.heightMM - intact.height) > 1 {
            return "fridge piece size does not match the intact box"
        }
        let report = FitEngine.gate(module: stop.module, box: intact, stop: stop, parts: made.parts)
        let steps = FitCarry.steps(piece: made, stop: stop, report: report)
        if steps.count < 3 {
            return "fridge at seller-stair has no carry steps"
        }
        let faces = FitQuestions.faces(box: intact, stop: stop, parts: [])
        if faces.count != 6 {
            return "fridge at seller-stair did not list six faces"
        }
        let pole = FitQuestions.longestPole(hallA: max(stop.primaryMM, 1), hallB: max(stop.secondaryMM, 1))
        if pole <= 0 { return "fridge pole collapsed at seller-stair" }
        let tape = FitQuestions.tape(intact.width)
        if tape.isEmpty { return "fridge tape line lost the measure" }
        if stop.module == .cargo {
            let bay = FitPacker.pack(pieces: [made], bay: stop)
            let allowedOut = report.call == .leaveIt || report.call == .splitParts || report.call == .otherRoute || report.call == .turnIt
            if bay.placed.isEmpty && !allowedOut {
                return "fridge fits the check but the bay packer left it out"
            }
        }
        let people = FitHandling.carriers(for: FitHandling.kilograms(piece: made, stock: .pine))
        if people < 1 || people > 3 {
            return "fridge people count is outside 1...3"
        }
        let brief = FitHandling.brief(piece: made, stock: .pine, blankets: 1, stop: stop)
        if brief.kilograms <= 0 { return "fridge weighs nothing" }
        if brief.wrapped.width <= intact.width {
            return "fridge blanket did not add width"
        }
        if choice.report.headline.isEmpty {
            return "fridge at seller-stair has an empty call"
        }
        let order = FitQuestions.loadOrder(pieces: [made], stops: [stop])
        if order.count != 1 { return "fridge carry order lost the piece at seller-stair" }
        return nil
    }

    private static func checkFridgeVanRear() -> String? {
        let form = FitAssembly.fridge
        guard let stop = FitSeed.stop("van-rear") else { return "fridge at van-rear has no stop" }
        let intact = form.box()
        if intact.width < 1 || intact.depth < 1 || intact.height < 1 {
            return "fridge collapsed to an empty box"
        }
        let choice = FitAssembly.choice(assembly: form, stop: stop)
        if !choice.removed.isEmpty {
            let ids = Set(form.removable.filter { choice.removed.contains($0.name) }.map(\.id))
            let stripped = form.box(omitting: ids)
            if stripped.width > intact.width + 0.5 || stripped.height > intact.height + 0.5 || stripped.depth > intact.depth + 0.5 {
                return "fridge grew when parts came off for van-rear"
            }
        }
        let made = FitAssembly.piece(from: form, omitting: [])
        if abs(made.widthMM - intact.width) > 1 || abs(made.depthMM - intact.depth) > 1 || abs(made.heightMM - intact.height) > 1 {
            return "fridge piece size does not match the intact box"
        }
        let report = FitEngine.gate(module: stop.module, box: intact, stop: stop, parts: made.parts)
        let steps = FitCarry.steps(piece: made, stop: stop, report: report)
        if steps.count < 3 {
            return "fridge at van-rear has no carry steps"
        }
        let faces = FitQuestions.faces(box: intact, stop: stop, parts: [])
        if faces.count != 6 {
            return "fridge at van-rear did not list six faces"
        }
        let pole = FitQuestions.longestPole(hallA: max(stop.primaryMM, 1), hallB: max(stop.secondaryMM, 1))
        if pole <= 0 { return "fridge pole collapsed at van-rear" }
        let tape = FitQuestions.tape(intact.width)
        if tape.isEmpty { return "fridge tape line lost the measure" }
        if stop.module == .cargo {
            let bay = FitPacker.pack(pieces: [made], bay: stop)
            let allowedOut = report.call == .leaveIt || report.call == .splitParts || report.call == .otherRoute || report.call == .turnIt
            if bay.placed.isEmpty && !allowedOut {
                return "fridge fits the check but the bay packer left it out"
            }
        }
        let people = FitHandling.carriers(for: FitHandling.kilograms(piece: made, stock: .pine))
        if people < 1 || people > 3 {
            return "fridge people count is outside 1...3"
        }
        let brief = FitHandling.brief(piece: made, stock: .pine, blankets: 1, stop: stop)
        if brief.kilograms <= 0 { return "fridge weighs nothing" }
        if brief.wrapped.width <= intact.width {
            return "fridge blanket did not add width"
        }
        if choice.report.headline.isEmpty {
            return "fridge at van-rear has an empty call"
        }
        let order = FitQuestions.loadOrder(pieces: [made], stops: [stop])
        if order.count != 1 { return "fridge carry order lost the piece at van-rear" }
        return nil
    }

    private static func checkFridgeVanBay() -> String? {
        let form = FitAssembly.fridge
        guard let stop = FitSeed.stop("van-bay") else { return "fridge at van-bay has no stop" }
        let intact = form.box()
        if intact.width < 1 || intact.depth < 1 || intact.height < 1 {
            return "fridge collapsed to an empty box"
        }
        let choice = FitAssembly.choice(assembly: form, stop: stop)
        if !choice.removed.isEmpty {
            let ids = Set(form.removable.filter { choice.removed.contains($0.name) }.map(\.id))
            let stripped = form.box(omitting: ids)
            if stripped.width > intact.width + 0.5 || stripped.height > intact.height + 0.5 || stripped.depth > intact.depth + 0.5 {
                return "fridge grew when parts came off for van-bay"
            }
        }
        let made = FitAssembly.piece(from: form, omitting: [])
        if abs(made.widthMM - intact.width) > 1 || abs(made.depthMM - intact.depth) > 1 || abs(made.heightMM - intact.height) > 1 {
            return "fridge piece size does not match the intact box"
        }
        let report = FitEngine.gate(module: stop.module, box: intact, stop: stop, parts: made.parts)
        let steps = FitCarry.steps(piece: made, stop: stop, report: report)
        if steps.count < 3 {
            return "fridge at van-bay has no carry steps"
        }
        let faces = FitQuestions.faces(box: intact, stop: stop, parts: [])
        if faces.count != 6 {
            return "fridge at van-bay did not list six faces"
        }
        let pole = FitQuestions.longestPole(hallA: max(stop.primaryMM, 1), hallB: max(stop.secondaryMM, 1))
        if pole <= 0 { return "fridge pole collapsed at van-bay" }
        let tape = FitQuestions.tape(intact.width)
        if tape.isEmpty { return "fridge tape line lost the measure" }
        if stop.module == .cargo {
            let bay = FitPacker.pack(pieces: [made], bay: stop)
            let allowedOut = report.call == .leaveIt || report.call == .splitParts || report.call == .otherRoute || report.call == .turnIt
            if bay.placed.isEmpty && !allowedOut {
                return "fridge fits the check but the bay packer left it out"
            }
        }
        let people = FitHandling.carriers(for: FitHandling.kilograms(piece: made, stock: .pine))
        if people < 1 || people > 3 {
            return "fridge people count is outside 1...3"
        }
        let brief = FitHandling.brief(piece: made, stock: .pine, blankets: 1, stop: stop)
        if brief.kilograms <= 0 { return "fridge weighs nothing" }
        if brief.wrapped.width <= intact.width {
            return "fridge blanket did not add width"
        }
        if choice.report.headline.isEmpty {
            return "fridge at van-bay has an empty call"
        }
        let order = FitQuestions.loadOrder(pieces: [made], stops: [stop])
        if order.count != 1 { return "fridge carry order lost the piece at van-bay" }
        return nil
    }

    private static func checkFridgeStorageFloor() -> String? {
        let form = FitAssembly.fridge
        guard let stop = FitSeed.stop("storage-floor") else { return "fridge at storage-floor has no stop" }
        let intact = form.box()
        if intact.width < 1 || intact.depth < 1 || intact.height < 1 {
            return "fridge collapsed to an empty box"
        }
        let choice = FitAssembly.choice(assembly: form, stop: stop)
        if !choice.removed.isEmpty {
            let ids = Set(form.removable.filter { choice.removed.contains($0.name) }.map(\.id))
            let stripped = form.box(omitting: ids)
            if stripped.width > intact.width + 0.5 || stripped.height > intact.height + 0.5 || stripped.depth > intact.depth + 0.5 {
                return "fridge grew when parts came off for storage-floor"
            }
        }
        let made = FitAssembly.piece(from: form, omitting: [])
        if abs(made.widthMM - intact.width) > 1 || abs(made.depthMM - intact.depth) > 1 || abs(made.heightMM - intact.height) > 1 {
            return "fridge piece size does not match the intact box"
        }
        let report = FitEngine.gate(module: stop.module, box: intact, stop: stop, parts: made.parts)
        let steps = FitCarry.steps(piece: made, stop: stop, report: report)
        if steps.count < 3 {
            return "fridge at storage-floor has no carry steps"
        }
        let faces = FitQuestions.faces(box: intact, stop: stop, parts: [])
        if faces.count != 6 {
            return "fridge at storage-floor did not list six faces"
        }
        let pole = FitQuestions.longestPole(hallA: max(stop.primaryMM, 1), hallB: max(stop.secondaryMM, 1))
        if pole <= 0 { return "fridge pole collapsed at storage-floor" }
        let tape = FitQuestions.tape(intact.width)
        if tape.isEmpty { return "fridge tape line lost the measure" }
        if stop.module == .cargo {
            let bay = FitPacker.pack(pieces: [made], bay: stop)
            let allowedOut = report.call == .leaveIt || report.call == .splitParts || report.call == .otherRoute || report.call == .turnIt
            if bay.placed.isEmpty && !allowedOut {
                return "fridge fits the check but the bay packer left it out"
            }
        }
        let people = FitHandling.carriers(for: FitHandling.kilograms(piece: made, stock: .pine))
        if people < 1 || people > 3 {
            return "fridge people count is outside 1...3"
        }
        let brief = FitHandling.brief(piece: made, stock: .pine, blankets: 1, stop: stop)
        if brief.kilograms <= 0 { return "fridge weighs nothing" }
        if brief.wrapped.width <= intact.width {
            return "fridge blanket did not add width"
        }
        if choice.report.headline.isEmpty {
            return "fridge at storage-floor has an empty call"
        }
        let order = FitQuestions.loadOrder(pieces: [made], stops: [stop])
        if order.count != 1 { return "fridge carry order lost the piece at storage-floor" }
        return nil
    }

    private static func checkMattressSellerDoor() -> String? {
        let form = FitAssembly.mattress
        guard let stop = FitSeed.stop("seller-door") else { return "mattress at seller-door has no stop" }
        let intact = form.box()
        if intact.width < 1 || intact.depth < 1 || intact.height < 1 {
            return "mattress collapsed to an empty box"
        }
        let choice = FitAssembly.choice(assembly: form, stop: stop)
        if !choice.removed.isEmpty {
            let ids = Set(form.removable.filter { choice.removed.contains($0.name) }.map(\.id))
            let stripped = form.box(omitting: ids)
            if stripped.width > intact.width + 0.5 || stripped.height > intact.height + 0.5 || stripped.depth > intact.depth + 0.5 {
                return "mattress grew when parts came off for seller-door"
            }
        }
        let made = FitAssembly.piece(from: form, omitting: [])
        if abs(made.widthMM - intact.width) > 1 || abs(made.depthMM - intact.depth) > 1 || abs(made.heightMM - intact.height) > 1 {
            return "mattress piece size does not match the intact box"
        }
        let report = FitEngine.gate(module: stop.module, box: intact, stop: stop, parts: made.parts)
        let steps = FitCarry.steps(piece: made, stop: stop, report: report)
        if steps.count < 3 {
            return "mattress at seller-door has no carry steps"
        }
        let faces = FitQuestions.faces(box: intact, stop: stop, parts: [])
        if faces.count != 6 {
            return "mattress at seller-door did not list six faces"
        }
        let pole = FitQuestions.longestPole(hallA: max(stop.primaryMM, 1), hallB: max(stop.secondaryMM, 1))
        if pole <= 0 { return "mattress pole collapsed at seller-door" }
        let tape = FitQuestions.tape(intact.width)
        if tape.isEmpty { return "mattress tape line lost the measure" }
        if stop.module == .cargo {
            let bay = FitPacker.pack(pieces: [made], bay: stop)
            let allowedOut = report.call == .leaveIt || report.call == .splitParts || report.call == .otherRoute || report.call == .turnIt
            if bay.placed.isEmpty && !allowedOut {
                return "mattress fits the check but the bay packer left it out"
            }
        }
        let people = FitHandling.carriers(for: FitHandling.kilograms(piece: made, stock: .pine))
        if people < 1 || people > 3 {
            return "mattress people count is outside 1...3"
        }
        let brief = FitHandling.brief(piece: made, stock: .pine, blankets: 1, stop: stop)
        if brief.kilograms <= 0 { return "mattress weighs nothing" }
        if brief.wrapped.width <= intact.width {
            return "mattress blanket did not add width"
        }
        if choice.report.headline.isEmpty {
            return "mattress at seller-door has an empty call"
        }
        let order = FitQuestions.loadOrder(pieces: [made], stops: [stop])
        if order.count != 1 { return "mattress carry order lost the piece at seller-door" }
        return nil
    }

    private static func checkMattressSellerCorner() -> String? {
        let form = FitAssembly.mattress
        guard let stop = FitSeed.stop("seller-corner") else { return "mattress at seller-corner has no stop" }
        let intact = form.box()
        if intact.width < 1 || intact.depth < 1 || intact.height < 1 {
            return "mattress collapsed to an empty box"
        }
        let choice = FitAssembly.choice(assembly: form, stop: stop)
        if !choice.removed.isEmpty {
            let ids = Set(form.removable.filter { choice.removed.contains($0.name) }.map(\.id))
            let stripped = form.box(omitting: ids)
            if stripped.width > intact.width + 0.5 || stripped.height > intact.height + 0.5 || stripped.depth > intact.depth + 0.5 {
                return "mattress grew when parts came off for seller-corner"
            }
        }
        let made = FitAssembly.piece(from: form, omitting: [])
        if abs(made.widthMM - intact.width) > 1 || abs(made.depthMM - intact.depth) > 1 || abs(made.heightMM - intact.height) > 1 {
            return "mattress piece size does not match the intact box"
        }
        let report = FitEngine.gate(module: stop.module, box: intact, stop: stop, parts: made.parts)
        let steps = FitCarry.steps(piece: made, stop: stop, report: report)
        if steps.count < 3 {
            return "mattress at seller-corner has no carry steps"
        }
        let faces = FitQuestions.faces(box: intact, stop: stop, parts: [])
        if faces.count != 6 {
            return "mattress at seller-corner did not list six faces"
        }
        let pole = FitQuestions.longestPole(hallA: max(stop.primaryMM, 1), hallB: max(stop.secondaryMM, 1))
        if pole <= 0 { return "mattress pole collapsed at seller-corner" }
        let tape = FitQuestions.tape(intact.width)
        if tape.isEmpty { return "mattress tape line lost the measure" }
        if stop.module == .cargo {
            let bay = FitPacker.pack(pieces: [made], bay: stop)
            let allowedOut = report.call == .leaveIt || report.call == .splitParts || report.call == .otherRoute || report.call == .turnIt
            if bay.placed.isEmpty && !allowedOut {
                return "mattress fits the check but the bay packer left it out"
            }
        }
        let people = FitHandling.carriers(for: FitHandling.kilograms(piece: made, stock: .pine))
        if people < 1 || people > 3 {
            return "mattress people count is outside 1...3"
        }
        let brief = FitHandling.brief(piece: made, stock: .pine, blankets: 1, stop: stop)
        if brief.kilograms <= 0 { return "mattress weighs nothing" }
        if brief.wrapped.width <= intact.width {
            return "mattress blanket did not add width"
        }
        if choice.report.headline.isEmpty {
            return "mattress at seller-corner has an empty call"
        }
        let order = FitQuestions.loadOrder(pieces: [made], stops: [stop])
        if order.count != 1 { return "mattress carry order lost the piece at seller-corner" }
        return nil
    }

    private static func checkMattressSellerStair() -> String? {
        let form = FitAssembly.mattress
        guard let stop = FitSeed.stop("seller-stair") else { return "mattress at seller-stair has no stop" }
        let intact = form.box()
        if intact.width < 1 || intact.depth < 1 || intact.height < 1 {
            return "mattress collapsed to an empty box"
        }
        let choice = FitAssembly.choice(assembly: form, stop: stop)
        if !choice.removed.isEmpty {
            let ids = Set(form.removable.filter { choice.removed.contains($0.name) }.map(\.id))
            let stripped = form.box(omitting: ids)
            if stripped.width > intact.width + 0.5 || stripped.height > intact.height + 0.5 || stripped.depth > intact.depth + 0.5 {
                return "mattress grew when parts came off for seller-stair"
            }
        }
        let made = FitAssembly.piece(from: form, omitting: [])
        if abs(made.widthMM - intact.width) > 1 || abs(made.depthMM - intact.depth) > 1 || abs(made.heightMM - intact.height) > 1 {
            return "mattress piece size does not match the intact box"
        }
        let report = FitEngine.gate(module: stop.module, box: intact, stop: stop, parts: made.parts)
        let steps = FitCarry.steps(piece: made, stop: stop, report: report)
        if steps.count < 3 {
            return "mattress at seller-stair has no carry steps"
        }
        let faces = FitQuestions.faces(box: intact, stop: stop, parts: [])
        if faces.count != 6 {
            return "mattress at seller-stair did not list six faces"
        }
        let pole = FitQuestions.longestPole(hallA: max(stop.primaryMM, 1), hallB: max(stop.secondaryMM, 1))
        if pole <= 0 { return "mattress pole collapsed at seller-stair" }
        let tape = FitQuestions.tape(intact.width)
        if tape.isEmpty { return "mattress tape line lost the measure" }
        if stop.module == .cargo {
            let bay = FitPacker.pack(pieces: [made], bay: stop)
            let allowedOut = report.call == .leaveIt || report.call == .splitParts || report.call == .otherRoute || report.call == .turnIt
            if bay.placed.isEmpty && !allowedOut {
                return "mattress fits the check but the bay packer left it out"
            }
        }
        let people = FitHandling.carriers(for: FitHandling.kilograms(piece: made, stock: .pine))
        if people < 1 || people > 3 {
            return "mattress people count is outside 1...3"
        }
        let brief = FitHandling.brief(piece: made, stock: .pine, blankets: 1, stop: stop)
        if brief.kilograms <= 0 { return "mattress weighs nothing" }
        if brief.wrapped.width <= intact.width {
            return "mattress blanket did not add width"
        }
        if choice.report.headline.isEmpty {
            return "mattress at seller-stair has an empty call"
        }
        let order = FitQuestions.loadOrder(pieces: [made], stops: [stop])
        if order.count != 1 { return "mattress carry order lost the piece at seller-stair" }
        return nil
    }

    private static func checkMattressVanRear() -> String? {
        let form = FitAssembly.mattress
        guard let stop = FitSeed.stop("van-rear") else { return "mattress at van-rear has no stop" }
        let intact = form.box()
        if intact.width < 1 || intact.depth < 1 || intact.height < 1 {
            return "mattress collapsed to an empty box"
        }
        let choice = FitAssembly.choice(assembly: form, stop: stop)
        if !choice.removed.isEmpty {
            let ids = Set(form.removable.filter { choice.removed.contains($0.name) }.map(\.id))
            let stripped = form.box(omitting: ids)
            if stripped.width > intact.width + 0.5 || stripped.height > intact.height + 0.5 || stripped.depth > intact.depth + 0.5 {
                return "mattress grew when parts came off for van-rear"
            }
        }
        let made = FitAssembly.piece(from: form, omitting: [])
        if abs(made.widthMM - intact.width) > 1 || abs(made.depthMM - intact.depth) > 1 || abs(made.heightMM - intact.height) > 1 {
            return "mattress piece size does not match the intact box"
        }
        let report = FitEngine.gate(module: stop.module, box: intact, stop: stop, parts: made.parts)
        let steps = FitCarry.steps(piece: made, stop: stop, report: report)
        if steps.count < 3 {
            return "mattress at van-rear has no carry steps"
        }
        let faces = FitQuestions.faces(box: intact, stop: stop, parts: [])
        if faces.count != 6 {
            return "mattress at van-rear did not list six faces"
        }
        let pole = FitQuestions.longestPole(hallA: max(stop.primaryMM, 1), hallB: max(stop.secondaryMM, 1))
        if pole <= 0 { return "mattress pole collapsed at van-rear" }
        let tape = FitQuestions.tape(intact.width)
        if tape.isEmpty { return "mattress tape line lost the measure" }
        if stop.module == .cargo {
            let bay = FitPacker.pack(pieces: [made], bay: stop)
            let allowedOut = report.call == .leaveIt || report.call == .splitParts || report.call == .otherRoute || report.call == .turnIt
            if bay.placed.isEmpty && !allowedOut {
                return "mattress fits the check but the bay packer left it out"
            }
        }
        let people = FitHandling.carriers(for: FitHandling.kilograms(piece: made, stock: .pine))
        if people < 1 || people > 3 {
            return "mattress people count is outside 1...3"
        }
        let brief = FitHandling.brief(piece: made, stock: .pine, blankets: 1, stop: stop)
        if brief.kilograms <= 0 { return "mattress weighs nothing" }
        if brief.wrapped.width <= intact.width {
            return "mattress blanket did not add width"
        }
        if choice.report.headline.isEmpty {
            return "mattress at van-rear has an empty call"
        }
        let order = FitQuestions.loadOrder(pieces: [made], stops: [stop])
        if order.count != 1 { return "mattress carry order lost the piece at van-rear" }
        return nil
    }

    private static func checkMattressVanBay() -> String? {
        let form = FitAssembly.mattress
        guard let stop = FitSeed.stop("van-bay") else { return "mattress at van-bay has no stop" }
        let intact = form.box()
        if intact.width < 1 || intact.depth < 1 || intact.height < 1 {
            return "mattress collapsed to an empty box"
        }
        let choice = FitAssembly.choice(assembly: form, stop: stop)
        if !choice.removed.isEmpty {
            let ids = Set(form.removable.filter { choice.removed.contains($0.name) }.map(\.id))
            let stripped = form.box(omitting: ids)
            if stripped.width > intact.width + 0.5 || stripped.height > intact.height + 0.5 || stripped.depth > intact.depth + 0.5 {
                return "mattress grew when parts came off for van-bay"
            }
        }
        let made = FitAssembly.piece(from: form, omitting: [])
        if abs(made.widthMM - intact.width) > 1 || abs(made.depthMM - intact.depth) > 1 || abs(made.heightMM - intact.height) > 1 {
            return "mattress piece size does not match the intact box"
        }
        let report = FitEngine.gate(module: stop.module, box: intact, stop: stop, parts: made.parts)
        let steps = FitCarry.steps(piece: made, stop: stop, report: report)
        if steps.count < 3 {
            return "mattress at van-bay has no carry steps"
        }
        let faces = FitQuestions.faces(box: intact, stop: stop, parts: [])
        if faces.count != 6 {
            return "mattress at van-bay did not list six faces"
        }
        let pole = FitQuestions.longestPole(hallA: max(stop.primaryMM, 1), hallB: max(stop.secondaryMM, 1))
        if pole <= 0 { return "mattress pole collapsed at van-bay" }
        let tape = FitQuestions.tape(intact.width)
        if tape.isEmpty { return "mattress tape line lost the measure" }
        if stop.module == .cargo {
            let bay = FitPacker.pack(pieces: [made], bay: stop)
            let allowedOut = report.call == .leaveIt || report.call == .splitParts || report.call == .otherRoute || report.call == .turnIt
            if bay.placed.isEmpty && !allowedOut {
                return "mattress fits the check but the bay packer left it out"
            }
        }
        let people = FitHandling.carriers(for: FitHandling.kilograms(piece: made, stock: .pine))
        if people < 1 || people > 3 {
            return "mattress people count is outside 1...3"
        }
        let brief = FitHandling.brief(piece: made, stock: .pine, blankets: 1, stop: stop)
        if brief.kilograms <= 0 { return "mattress weighs nothing" }
        if brief.wrapped.width <= intact.width {
            return "mattress blanket did not add width"
        }
        if choice.report.headline.isEmpty {
            return "mattress at van-bay has an empty call"
        }
        let order = FitQuestions.loadOrder(pieces: [made], stops: [stop])
        if order.count != 1 { return "mattress carry order lost the piece at van-bay" }
        return nil
    }

    private static func checkMattressStorageFloor() -> String? {
        let form = FitAssembly.mattress
        guard let stop = FitSeed.stop("storage-floor") else { return "mattress at storage-floor has no stop" }
        let intact = form.box()
        if intact.width < 1 || intact.depth < 1 || intact.height < 1 {
            return "mattress collapsed to an empty box"
        }
        let choice = FitAssembly.choice(assembly: form, stop: stop)
        if !choice.removed.isEmpty {
            let ids = Set(form.removable.filter { choice.removed.contains($0.name) }.map(\.id))
            let stripped = form.box(omitting: ids)
            if stripped.width > intact.width + 0.5 || stripped.height > intact.height + 0.5 || stripped.depth > intact.depth + 0.5 {
                return "mattress grew when parts came off for storage-floor"
            }
        }
        let made = FitAssembly.piece(from: form, omitting: [])
        if abs(made.widthMM - intact.width) > 1 || abs(made.depthMM - intact.depth) > 1 || abs(made.heightMM - intact.height) > 1 {
            return "mattress piece size does not match the intact box"
        }
        let report = FitEngine.gate(module: stop.module, box: intact, stop: stop, parts: made.parts)
        let steps = FitCarry.steps(piece: made, stop: stop, report: report)
        if steps.count < 3 {
            return "mattress at storage-floor has no carry steps"
        }
        let faces = FitQuestions.faces(box: intact, stop: stop, parts: [])
        if faces.count != 6 {
            return "mattress at storage-floor did not list six faces"
        }
        let pole = FitQuestions.longestPole(hallA: max(stop.primaryMM, 1), hallB: max(stop.secondaryMM, 1))
        if pole <= 0 { return "mattress pole collapsed at storage-floor" }
        let tape = FitQuestions.tape(intact.width)
        if tape.isEmpty { return "mattress tape line lost the measure" }
        if stop.module == .cargo {
            let bay = FitPacker.pack(pieces: [made], bay: stop)
            let allowedOut = report.call == .leaveIt || report.call == .splitParts || report.call == .otherRoute || report.call == .turnIt
            if bay.placed.isEmpty && !allowedOut {
                return "mattress fits the check but the bay packer left it out"
            }
        }
        let people = FitHandling.carriers(for: FitHandling.kilograms(piece: made, stock: .pine))
        if people < 1 || people > 3 {
            return "mattress people count is outside 1...3"
        }
        let brief = FitHandling.brief(piece: made, stock: .pine, blankets: 1, stop: stop)
        if brief.kilograms <= 0 { return "mattress weighs nothing" }
        if brief.wrapped.width <= intact.width {
            return "mattress blanket did not add width"
        }
        if choice.report.headline.isEmpty {
            return "mattress at storage-floor has an empty call"
        }
        let order = FitQuestions.loadOrder(pieces: [made], stops: [stop])
        if order.count != 1 { return "mattress carry order lost the piece at storage-floor" }
        return nil
    }

    private static func checkWasherSellerDoor() -> String? {
        let form = FitAssembly.washer
        guard let stop = FitSeed.stop("seller-door") else { return "washer at seller-door has no stop" }
        let intact = form.box()
        if intact.width < 1 || intact.depth < 1 || intact.height < 1 {
            return "washer collapsed to an empty box"
        }
        let choice = FitAssembly.choice(assembly: form, stop: stop)
        if !choice.removed.isEmpty {
            let ids = Set(form.removable.filter { choice.removed.contains($0.name) }.map(\.id))
            let stripped = form.box(omitting: ids)
            if stripped.width > intact.width + 0.5 || stripped.height > intact.height + 0.5 || stripped.depth > intact.depth + 0.5 {
                return "washer grew when parts came off for seller-door"
            }
        }
        let made = FitAssembly.piece(from: form, omitting: [])
        if abs(made.widthMM - intact.width) > 1 || abs(made.depthMM - intact.depth) > 1 || abs(made.heightMM - intact.height) > 1 {
            return "washer piece size does not match the intact box"
        }
        let report = FitEngine.gate(module: stop.module, box: intact, stop: stop, parts: made.parts)
        let steps = FitCarry.steps(piece: made, stop: stop, report: report)
        if steps.count < 3 {
            return "washer at seller-door has no carry steps"
        }
        let faces = FitQuestions.faces(box: intact, stop: stop, parts: [])
        if faces.count != 6 {
            return "washer at seller-door did not list six faces"
        }
        let pole = FitQuestions.longestPole(hallA: max(stop.primaryMM, 1), hallB: max(stop.secondaryMM, 1))
        if pole <= 0 { return "washer pole collapsed at seller-door" }
        let tape = FitQuestions.tape(intact.width)
        if tape.isEmpty { return "washer tape line lost the measure" }
        if stop.module == .cargo {
            let bay = FitPacker.pack(pieces: [made], bay: stop)
            let allowedOut = report.call == .leaveIt || report.call == .splitParts || report.call == .otherRoute || report.call == .turnIt
            if bay.placed.isEmpty && !allowedOut {
                return "washer fits the check but the bay packer left it out"
            }
        }
        let people = FitHandling.carriers(for: FitHandling.kilograms(piece: made, stock: .pine))
        if people < 1 || people > 3 {
            return "washer people count is outside 1...3"
        }
        let brief = FitHandling.brief(piece: made, stock: .pine, blankets: 1, stop: stop)
        if brief.kilograms <= 0 { return "washer weighs nothing" }
        if brief.wrapped.width <= intact.width {
            return "washer blanket did not add width"
        }
        if choice.report.headline.isEmpty {
            return "washer at seller-door has an empty call"
        }
        let order = FitQuestions.loadOrder(pieces: [made], stops: [stop])
        if order.count != 1 { return "washer carry order lost the piece at seller-door" }
        return nil
    }

    private static func checkWasherSellerCorner() -> String? {
        let form = FitAssembly.washer
        guard let stop = FitSeed.stop("seller-corner") else { return "washer at seller-corner has no stop" }
        let intact = form.box()
        if intact.width < 1 || intact.depth < 1 || intact.height < 1 {
            return "washer collapsed to an empty box"
        }
        let choice = FitAssembly.choice(assembly: form, stop: stop)
        if !choice.removed.isEmpty {
            let ids = Set(form.removable.filter { choice.removed.contains($0.name) }.map(\.id))
            let stripped = form.box(omitting: ids)
            if stripped.width > intact.width + 0.5 || stripped.height > intact.height + 0.5 || stripped.depth > intact.depth + 0.5 {
                return "washer grew when parts came off for seller-corner"
            }
        }
        let made = FitAssembly.piece(from: form, omitting: [])
        if abs(made.widthMM - intact.width) > 1 || abs(made.depthMM - intact.depth) > 1 || abs(made.heightMM - intact.height) > 1 {
            return "washer piece size does not match the intact box"
        }
        let report = FitEngine.gate(module: stop.module, box: intact, stop: stop, parts: made.parts)
        let steps = FitCarry.steps(piece: made, stop: stop, report: report)
        if steps.count < 3 {
            return "washer at seller-corner has no carry steps"
        }
        let faces = FitQuestions.faces(box: intact, stop: stop, parts: [])
        if faces.count != 6 {
            return "washer at seller-corner did not list six faces"
        }
        let pole = FitQuestions.longestPole(hallA: max(stop.primaryMM, 1), hallB: max(stop.secondaryMM, 1))
        if pole <= 0 { return "washer pole collapsed at seller-corner" }
        let tape = FitQuestions.tape(intact.width)
        if tape.isEmpty { return "washer tape line lost the measure" }
        if stop.module == .cargo {
            let bay = FitPacker.pack(pieces: [made], bay: stop)
            let allowedOut = report.call == .leaveIt || report.call == .splitParts || report.call == .otherRoute || report.call == .turnIt
            if bay.placed.isEmpty && !allowedOut {
                return "washer fits the check but the bay packer left it out"
            }
        }
        let people = FitHandling.carriers(for: FitHandling.kilograms(piece: made, stock: .pine))
        if people < 1 || people > 3 {
            return "washer people count is outside 1...3"
        }
        let brief = FitHandling.brief(piece: made, stock: .pine, blankets: 1, stop: stop)
        if brief.kilograms <= 0 { return "washer weighs nothing" }
        if brief.wrapped.width <= intact.width {
            return "washer blanket did not add width"
        }
        if choice.report.headline.isEmpty {
            return "washer at seller-corner has an empty call"
        }
        let order = FitQuestions.loadOrder(pieces: [made], stops: [stop])
        if order.count != 1 { return "washer carry order lost the piece at seller-corner" }
        return nil
    }

    private static func checkWasherSellerStair() -> String? {
        let form = FitAssembly.washer
        guard let stop = FitSeed.stop("seller-stair") else { return "washer at seller-stair has no stop" }
        let intact = form.box()
        if intact.width < 1 || intact.depth < 1 || intact.height < 1 {
            return "washer collapsed to an empty box"
        }
        let choice = FitAssembly.choice(assembly: form, stop: stop)
        if !choice.removed.isEmpty {
            let ids = Set(form.removable.filter { choice.removed.contains($0.name) }.map(\.id))
            let stripped = form.box(omitting: ids)
            if stripped.width > intact.width + 0.5 || stripped.height > intact.height + 0.5 || stripped.depth > intact.depth + 0.5 {
                return "washer grew when parts came off for seller-stair"
            }
        }
        let made = FitAssembly.piece(from: form, omitting: [])
        if abs(made.widthMM - intact.width) > 1 || abs(made.depthMM - intact.depth) > 1 || abs(made.heightMM - intact.height) > 1 {
            return "washer piece size does not match the intact box"
        }
        let report = FitEngine.gate(module: stop.module, box: intact, stop: stop, parts: made.parts)
        let steps = FitCarry.steps(piece: made, stop: stop, report: report)
        if steps.count < 3 {
            return "washer at seller-stair has no carry steps"
        }
        let faces = FitQuestions.faces(box: intact, stop: stop, parts: [])
        if faces.count != 6 {
            return "washer at seller-stair did not list six faces"
        }
        let pole = FitQuestions.longestPole(hallA: max(stop.primaryMM, 1), hallB: max(stop.secondaryMM, 1))
        if pole <= 0 { return "washer pole collapsed at seller-stair" }
        let tape = FitQuestions.tape(intact.width)
        if tape.isEmpty { return "washer tape line lost the measure" }
        if stop.module == .cargo {
            let bay = FitPacker.pack(pieces: [made], bay: stop)
            let allowedOut = report.call == .leaveIt || report.call == .splitParts || report.call == .otherRoute || report.call == .turnIt
            if bay.placed.isEmpty && !allowedOut {
                return "washer fits the check but the bay packer left it out"
            }
        }
        let people = FitHandling.carriers(for: FitHandling.kilograms(piece: made, stock: .pine))
        if people < 1 || people > 3 {
            return "washer people count is outside 1...3"
        }
        let brief = FitHandling.brief(piece: made, stock: .pine, blankets: 1, stop: stop)
        if brief.kilograms <= 0 { return "washer weighs nothing" }
        if brief.wrapped.width <= intact.width {
            return "washer blanket did not add width"
        }
        if choice.report.headline.isEmpty {
            return "washer at seller-stair has an empty call"
        }
        let order = FitQuestions.loadOrder(pieces: [made], stops: [stop])
        if order.count != 1 { return "washer carry order lost the piece at seller-stair" }
        return nil
    }

    private static func checkWasherVanRear() -> String? {
        let form = FitAssembly.washer
        guard let stop = FitSeed.stop("van-rear") else { return "washer at van-rear has no stop" }
        let intact = form.box()
        if intact.width < 1 || intact.depth < 1 || intact.height < 1 {
            return "washer collapsed to an empty box"
        }
        let choice = FitAssembly.choice(assembly: form, stop: stop)
        if !choice.removed.isEmpty {
            let ids = Set(form.removable.filter { choice.removed.contains($0.name) }.map(\.id))
            let stripped = form.box(omitting: ids)
            if stripped.width > intact.width + 0.5 || stripped.height > intact.height + 0.5 || stripped.depth > intact.depth + 0.5 {
                return "washer grew when parts came off for van-rear"
            }
        }
        let made = FitAssembly.piece(from: form, omitting: [])
        if abs(made.widthMM - intact.width) > 1 || abs(made.depthMM - intact.depth) > 1 || abs(made.heightMM - intact.height) > 1 {
            return "washer piece size does not match the intact box"
        }
        let report = FitEngine.gate(module: stop.module, box: intact, stop: stop, parts: made.parts)
        let steps = FitCarry.steps(piece: made, stop: stop, report: report)
        if steps.count < 3 {
            return "washer at van-rear has no carry steps"
        }
        let faces = FitQuestions.faces(box: intact, stop: stop, parts: [])
        if faces.count != 6 {
            return "washer at van-rear did not list six faces"
        }
        let pole = FitQuestions.longestPole(hallA: max(stop.primaryMM, 1), hallB: max(stop.secondaryMM, 1))
        if pole <= 0 { return "washer pole collapsed at van-rear" }
        let tape = FitQuestions.tape(intact.width)
        if tape.isEmpty { return "washer tape line lost the measure" }
        if stop.module == .cargo {
            let bay = FitPacker.pack(pieces: [made], bay: stop)
            let allowedOut = report.call == .leaveIt || report.call == .splitParts || report.call == .otherRoute || report.call == .turnIt
            if bay.placed.isEmpty && !allowedOut {
                return "washer fits the check but the bay packer left it out"
            }
        }
        let people = FitHandling.carriers(for: FitHandling.kilograms(piece: made, stock: .pine))
        if people < 1 || people > 3 {
            return "washer people count is outside 1...3"
        }
        let brief = FitHandling.brief(piece: made, stock: .pine, blankets: 1, stop: stop)
        if brief.kilograms <= 0 { return "washer weighs nothing" }
        if brief.wrapped.width <= intact.width {
            return "washer blanket did not add width"
        }
        if choice.report.headline.isEmpty {
            return "washer at van-rear has an empty call"
        }
        let order = FitQuestions.loadOrder(pieces: [made], stops: [stop])
        if order.count != 1 { return "washer carry order lost the piece at van-rear" }
        return nil
    }

    private static func checkWasherVanBay() -> String? {
        let form = FitAssembly.washer
        guard let stop = FitSeed.stop("van-bay") else { return "washer at van-bay has no stop" }
        let intact = form.box()
        if intact.width < 1 || intact.depth < 1 || intact.height < 1 {
            return "washer collapsed to an empty box"
        }
        let choice = FitAssembly.choice(assembly: form, stop: stop)
        if !choice.removed.isEmpty {
            let ids = Set(form.removable.filter { choice.removed.contains($0.name) }.map(\.id))
            let stripped = form.box(omitting: ids)
            if stripped.width > intact.width + 0.5 || stripped.height > intact.height + 0.5 || stripped.depth > intact.depth + 0.5 {
                return "washer grew when parts came off for van-bay"
            }
        }
        let made = FitAssembly.piece(from: form, omitting: [])
        if abs(made.widthMM - intact.width) > 1 || abs(made.depthMM - intact.depth) > 1 || abs(made.heightMM - intact.height) > 1 {
            return "washer piece size does not match the intact box"
        }
        let report = FitEngine.gate(module: stop.module, box: intact, stop: stop, parts: made.parts)
        let steps = FitCarry.steps(piece: made, stop: stop, report: report)
        if steps.count < 3 {
            return "washer at van-bay has no carry steps"
        }
        let faces = FitQuestions.faces(box: intact, stop: stop, parts: [])
        if faces.count != 6 {
            return "washer at van-bay did not list six faces"
        }
        let pole = FitQuestions.longestPole(hallA: max(stop.primaryMM, 1), hallB: max(stop.secondaryMM, 1))
        if pole <= 0 { return "washer pole collapsed at van-bay" }
        let tape = FitQuestions.tape(intact.width)
        if tape.isEmpty { return "washer tape line lost the measure" }
        if stop.module == .cargo {
            let bay = FitPacker.pack(pieces: [made], bay: stop)
            let allowedOut = report.call == .leaveIt || report.call == .splitParts || report.call == .otherRoute || report.call == .turnIt
            if bay.placed.isEmpty && !allowedOut {
                return "washer fits the check but the bay packer left it out"
            }
        }
        let people = FitHandling.carriers(for: FitHandling.kilograms(piece: made, stock: .pine))
        if people < 1 || people > 3 {
            return "washer people count is outside 1...3"
        }
        let brief = FitHandling.brief(piece: made, stock: .pine, blankets: 1, stop: stop)
        if brief.kilograms <= 0 { return "washer weighs nothing" }
        if brief.wrapped.width <= intact.width {
            return "washer blanket did not add width"
        }
        if choice.report.headline.isEmpty {
            return "washer at van-bay has an empty call"
        }
        let order = FitQuestions.loadOrder(pieces: [made], stops: [stop])
        if order.count != 1 { return "washer carry order lost the piece at van-bay" }
        return nil
    }

    private static func checkWasherStorageFloor() -> String? {
        let form = FitAssembly.washer
        guard let stop = FitSeed.stop("storage-floor") else { return "washer at storage-floor has no stop" }
        let intact = form.box()
        if intact.width < 1 || intact.depth < 1 || intact.height < 1 {
            return "washer collapsed to an empty box"
        }
        let choice = FitAssembly.choice(assembly: form, stop: stop)
        if !choice.removed.isEmpty {
            let ids = Set(form.removable.filter { choice.removed.contains($0.name) }.map(\.id))
            let stripped = form.box(omitting: ids)
            if stripped.width > intact.width + 0.5 || stripped.height > intact.height + 0.5 || stripped.depth > intact.depth + 0.5 {
                return "washer grew when parts came off for storage-floor"
            }
        }
        let made = FitAssembly.piece(from: form, omitting: [])
        if abs(made.widthMM - intact.width) > 1 || abs(made.depthMM - intact.depth) > 1 || abs(made.heightMM - intact.height) > 1 {
            return "washer piece size does not match the intact box"
        }
        let report = FitEngine.gate(module: stop.module, box: intact, stop: stop, parts: made.parts)
        let steps = FitCarry.steps(piece: made, stop: stop, report: report)
        if steps.count < 3 {
            return "washer at storage-floor has no carry steps"
        }
        let faces = FitQuestions.faces(box: intact, stop: stop, parts: [])
        if faces.count != 6 {
            return "washer at storage-floor did not list six faces"
        }
        let pole = FitQuestions.longestPole(hallA: max(stop.primaryMM, 1), hallB: max(stop.secondaryMM, 1))
        if pole <= 0 { return "washer pole collapsed at storage-floor" }
        let tape = FitQuestions.tape(intact.width)
        if tape.isEmpty { return "washer tape line lost the measure" }
        if stop.module == .cargo {
            let bay = FitPacker.pack(pieces: [made], bay: stop)
            let allowedOut = report.call == .leaveIt || report.call == .splitParts || report.call == .otherRoute || report.call == .turnIt
            if bay.placed.isEmpty && !allowedOut {
                return "washer fits the check but the bay packer left it out"
            }
        }
        let people = FitHandling.carriers(for: FitHandling.kilograms(piece: made, stock: .pine))
        if people < 1 || people > 3 {
            return "washer people count is outside 1...3"
        }
        let brief = FitHandling.brief(piece: made, stock: .pine, blankets: 1, stop: stop)
        if brief.kilograms <= 0 { return "washer weighs nothing" }
        if brief.wrapped.width <= intact.width {
            return "washer blanket did not add width"
        }
        if choice.report.headline.isEmpty {
            return "washer at storage-floor has an empty call"
        }
        let order = FitQuestions.loadOrder(pieces: [made], stops: [stop])
        if order.count != 1 { return "washer carry order lost the piece at storage-floor" }
        return nil
    }
    private static let checks: [() -> String?] = [
        checkCaseDoor,
        checkCaseCorner,
        checkCaseStair,
        checkCaseRear,
        checkCaseSide,
        checkCaseBay,
        checkCaseSpot,
        checkShelvesDoor,
        checkShelvesCorner,
        checkShelvesStair,
        checkShelvesRear,
        checkShelvesSide,
        checkShelvesBay,
        checkShelvesSpot,
        checkBackDoor,
        checkBackCorner,
        checkBackStair,
        checkBackRear,
        checkBackSide,
        checkBackBay,
        checkBackSpot,
        checkPlinthDoor,
        checkPlinthCorner,
        checkPlinthStair,
        checkPlinthRear,
        checkPlinthSide,
        checkPlinthBay,
        checkPlinthSpot,
        checkPineCaseSellerDoor,
        checkPineCaseSellerCorner,
        checkPineCaseSellerStair,
        checkPineCaseVanRear,
        checkPineCaseVanBay,
        checkPineCaseStorageFloor,
        checkSofaSellerDoor,
        checkSofaSellerCorner,
        checkSofaSellerStair,
        checkSofaVanRear,
        checkSofaVanBay,
        checkSofaStorageFloor,
        checkTableSellerDoor,
        checkTableSellerCorner,
        checkTableSellerStair,
        checkTableVanRear,
        checkTableVanBay,
        checkTableStorageFloor,
        checkFridgeSellerDoor,
        checkFridgeSellerCorner,
        checkFridgeSellerStair,
        checkFridgeVanRear,
        checkFridgeVanBay,
        checkFridgeStorageFloor,
        checkMattressSellerDoor,
        checkMattressSellerCorner,
        checkMattressSellerStair,
        checkMattressVanRear,
        checkMattressVanBay,
        checkMattressStorageFloor,
        checkWasherSellerDoor,
        checkWasherSellerCorner,
        checkWasherSellerStair,
        checkWasherVanRear,
        checkWasherVanBay,
        checkWasherStorageFloor,
    ]
}
