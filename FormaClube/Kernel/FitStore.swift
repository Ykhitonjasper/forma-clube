import Foundation
import Observation

@MainActor
@Observable
final class FitStore {
    var hasCompletedOnboarding = false
    var selectedTab: FitTab = .route
    var pieces: [FurniturePiece] = FitSeed.pieces
    var stops: [RouteStop] = FitSeed.routePlaces
    var readings: [FitReading] = FitSeed.pieceReadings
    var activePieceID = "case"
    var activePlanID = "by-stair"
    var skippedStopIDs: [String] = []
    var partsOffIDs: [String] = []
    var doorVisible = false
    var doorSaved = false
    var turnVisible = false
    var turnSaved = false
    var doorReport: GateReport?
    var turnReport: GateReport?
    private var nextID = 1

    init() {
        load()
    }

    static func preview() -> FitStore {
        let store = FitStore()
        store.hasCompletedOnboarding = true
        return store
    }

    var activePiece: FurniturePiece? {
        pieces.first { $0.id == activePieceID } ?? pieces.first
    }

    var activePlan: HaulPlan {
        let plan = FitSeed.haulPlans.first { $0.id == activePlanID } ?? FitSeed.haulPlans[0]
        return HaulPlan(id: plan.id, name: plan.name, stopIDs: plan.stopIDs.filter { !skippedStopIDs.contains($0) })
    }

    func measured(_ piece: FurniturePiece) -> FurniturePiece {
        guard partsOffIDs.contains(piece.id), !piece.parts.isEmpty else { return piece }
        let reduced = piece.box.reduced(by: piece.parts)
        var copy = piece
        copy.widthMM = reduced.width
        copy.depthMM = reduced.depth
        copy.heightMM = reduced.height
        copy.parts = []
        return copy
    }

    var activeMeasured: FurniturePiece? {
        activePiece.map(measured)
    }

    func stop(_ id: String) -> RouteStop? {
        stops.first { $0.id == id }
    }

    func piece(_ id: String) -> FurniturePiece? {
        pieces.first { $0.id == id }
    }

    func reading(_ id: String) -> FitReading? {
        readings.first { $0.id == id }
    }

    func stops(for module: FitModule) -> [RouteStop] {
        stops.filter { $0.module == module }
    }

    func readings(for pieceID: String) -> [FitReading] {
        readings.filter { $0.pieceID == pieceID }
    }

    func revealDoor() {
        guard let piece = activeMeasured, let stop = stops.first(where: { $0.id == "seller-door" }) ?? stops.first(where: { $0.module == .door }) else { return }
        var result = FitEngine.gate(module: .door, box: piece.box, stop: stop, parts: piece.parts)
        result.call = FitEngine.upgrade(call: result.call, piece: piece, stop: stop, stops: stops)
        result.headline = result.call.title
        doorReport = result
        doorVisible = true
        doorSaved = false
    }

    func revealTurn() {
        guard let piece = activeMeasured, let stop = stops.first(where: { $0.id == "seller-corner" }) ?? stops.first(where: { $0.module == .turn }) else { return }
        var result = FitEngine.gate(module: .turn, box: piece.box, stop: stop, parts: piece.parts)
        result.call = FitEngine.upgrade(call: result.call, piece: piece, stop: stop, stops: stops)
        result.headline = result.call.title
        turnReport = result
        turnVisible = true
        turnSaved = false
    }

    func saveDoor() {
        guard let piece = activeMeasured, let stop = stops.first(where: { $0.module == .door }), let report = doorReport else { return }
        append(piece: piece, stop: stop, report: report)
        doorSaved = true
    }

    func saveTurn() {
        guard let piece = activeMeasured, let stop = stops.first(where: { $0.module == .turn }), let report = turnReport else { return }
        append(piece: piece, stop: stop, report: report)
        turnSaved = true
    }

    func check(module: FitModule, stop: RouteStop, piece: FurniturePiece) -> GateReport {
        var result = FitEngine.gate(module: module, box: piece.box, stop: stop, parts: piece.parts)
        result.call = FitEngine.upgrade(call: result.call, piece: piece, stop: stop, stops: stops)
        result.headline = result.call.title
        return result
    }

    func save(module: FitModule, stop: RouteStop, piece: FurniturePiece, report: GateReport) {
        append(piece: piece, stop: stop, report: report)
    }

    func updatePiece(_ piece: FurniturePiece) {
        guard let index = pieces.firstIndex(where: { $0.id == piece.id }) else { return }
        pieces[index] = piece
        persist()
    }

    func updateStop(_ stop: RouteStop) {
        guard let index = stops.firstIndex(where: { $0.id == stop.id }) else { return }
        stops[index] = stop
        persist()
    }

    func addPiece(name: String, width: Double, depth: Double, height: Double) {
        let id = "piece-\(nextID)"
        nextID += 1
        pieces.append(
            FurniturePiece(
                id: id,
                name: name,
                kind: "Piece",
                widthMM: width,
                depthMM: depth,
                heightMM: height,
                parts: []
            )
        )
        activePieceID = id
        persist()
    }

    func addStop(name: String, module: FitModule, primary: Double, secondary: Double, tertiary: Double) {
        let id = "stop-\(nextID)"
        nextID += 1
        stops.append(
            RouteStop(
                id: id,
                name: name,
                module: module,
                primaryMM: primary,
                secondaryMM: secondary,
                tertiaryMM: tertiary,
                note: "Measured on this phone."
            )
        )
        persist()
    }

    func toggleParts(for pieceID: String) {
        if let index = partsOffIDs.firstIndex(of: pieceID) {
            partsOffIDs.remove(at: index)
        } else {
            partsOffIDs.append(pieceID)
        }
        doorVisible = false
        doorSaved = false
        turnVisible = false
        turnSaved = false
        doorReport = nil
        turnReport = nil
        persist()
    }

    func toggleSkip(_ stopID: String) {
        if let index = skippedStopIDs.firstIndex(of: stopID) {
            skippedStopIDs.remove(at: index)
        } else {
            skippedStopIDs.append(stopID)
        }
        persist()
    }

    func removePiece(_ id: String) {
        pieces.removeAll { $0.id == id }
        readings.removeAll { $0.pieceID == id }
        partsOffIDs.removeAll { $0 == id }
        if activePieceID == id {
            activePieceID = pieces.first?.id ?? ""
        }
        persist()
    }

    func removeStop(_ id: String) {
        stops.removeAll { $0.id == id }
        readings.removeAll { $0.stopID == id }
        skippedStopIDs.removeAll { $0 == id }
        persist()
    }

    func removeReading(_ id: String) {
        readings.removeAll { $0.id == id }
        persist()
    }

    func duplicatePiece(_ id: String) {
        guard var piece = piece(id) else { return }
        piece.id = "piece-\(nextID)"
        nextID += 1
        piece.name = "\(piece.name) copy"
        pieces.append(piece)
        activePieceID = piece.id
        persist()
    }

    func rename(_ id: String, to name: String) {
        guard var piece = piece(id) else { return }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        piece.name = trimmed
        updatePiece(piece)
    }

    func saveActiveRoute() {
        guard let piece = activeMeasured else { return }
        for stopID in activePlan.stopIDs {
            guard let stop = stop(stopID) else { continue }
            let report = check(module: stop.module, stop: stop, piece: piece)
            append(piece: piece, stop: stop, report: report)
        }
    }

    func usePiece(_ id: String) {
        activePieceID = id
        doorVisible = false
        doorSaved = false
        turnVisible = false
        turnSaved = false
        doorReport = nil
        turnReport = nil
        persist()
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        persist()
    }

    func deleteAll() {
        hasCompletedOnboarding = false
        pieces = []
        stops = []
        readings = []
        activePieceID = ""
        skippedStopIDs = []
        partsOffIDs = []
        doorVisible = false
        doorSaved = false
        turnVisible = false
        turnSaved = false
        doorReport = nil
        turnReport = nil
        UserDefaults.standard.removeObject(forKey: Self.storageKey)
    }

    private func append(piece: FurniturePiece, stop: RouteStop, report: GateReport) {
        let id = "saved-\(nextID)"
        nextID += 1
        readings.insert(
            FitReading(
                id: id,
                pieceID: piece.id,
                stopID: stop.id,
                module: stop.module,
                call: report.call,
                clearanceMM: report.clearanceMM,
                orientation: report.pose.spoken,
                recorded: "Today",
                note: report.note
            ),
            at: 0
        )
        persist()
    }

    private struct Snapshot: Codable {
        var hasCompletedOnboarding: Bool
        var pieces: [FurniturePiece]
        var stops: [RouteStop]
        var readings: [FitReading]
        var activePieceID: String
        var activePlanID: String
        var nextID: Int
        var skippedStopIDs: [String]
        var partsOffIDs: [String]

        enum CodingKeys: String, CodingKey {
            case hasCompletedOnboarding
            case pieces
            case stops
            case readings
            case activePieceID
            case activePlanID
            case nextID
            case skippedStopIDs
            case partsOffIDs
        }

        init(
            hasCompletedOnboarding: Bool,
            pieces: [FurniturePiece],
            stops: [RouteStop],
            readings: [FitReading],
            activePieceID: String,
            activePlanID: String,
            nextID: Int,
            skippedStopIDs: [String],
            partsOffIDs: [String]
        ) {
            self.hasCompletedOnboarding = hasCompletedOnboarding
            self.pieces = pieces
            self.stops = stops
            self.readings = readings
            self.activePieceID = activePieceID
            self.activePlanID = activePlanID
            self.nextID = nextID
            self.skippedStopIDs = skippedStopIDs
            self.partsOffIDs = partsOffIDs
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            hasCompletedOnboarding = try container.decode(Bool.self, forKey: .hasCompletedOnboarding)
            pieces = try container.decode([FurniturePiece].self, forKey: .pieces)
            stops = try container.decode([RouteStop].self, forKey: .stops)
            readings = try container.decode([FitReading].self, forKey: .readings)
            activePieceID = try container.decode(String.self, forKey: .activePieceID)
            activePlanID = try container.decode(String.self, forKey: .activePlanID)
            nextID = try container.decode(Int.self, forKey: .nextID)
            skippedStopIDs = try container.decodeIfPresent([String].self, forKey: .skippedStopIDs) ?? []
            partsOffIDs = try container.decodeIfPresent([String].self, forKey: .partsOffIDs) ?? []
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(hasCompletedOnboarding, forKey: .hasCompletedOnboarding)
            try container.encode(pieces, forKey: .pieces)
            try container.encode(stops, forKey: .stops)
            try container.encode(readings, forKey: .readings)
            try container.encode(activePieceID, forKey: .activePieceID)
            try container.encode(activePlanID, forKey: .activePlanID)
            try container.encode(nextID, forKey: .nextID)
            try container.encode(skippedStopIDs, forKey: .skippedStopIDs)
            try container.encode(partsOffIDs, forKey: .partsOffIDs)
        }
    }

    private static let storageKey = "formaclube.haul"

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
              let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data) else { return }
        hasCompletedOnboarding = snapshot.hasCompletedOnboarding
        pieces = snapshot.pieces
        stops = snapshot.stops
        readings = snapshot.readings
        activePieceID = snapshot.activePieceID
        activePlanID = snapshot.activePlanID
        nextID = snapshot.nextID
        skippedStopIDs = snapshot.skippedStopIDs
        partsOffIDs = snapshot.partsOffIDs
    }

    private func persist() {
        let snapshot = Snapshot(
            hasCompletedOnboarding: hasCompletedOnboarding,
            pieces: pieces,
            stops: stops,
            readings: readings,
            activePieceID: activePieceID,
            activePlanID: activePlanID,
            nextID: nextID,
            skippedStopIDs: skippedStopIDs,
            partsOffIDs: partsOffIDs
        )
        if let data = try? JSONEncoder().encode(snapshot) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }
}
