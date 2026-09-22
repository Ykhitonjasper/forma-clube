import Foundation

enum BoxAxis: String, Codable, CaseIterable, Identifiable {
    case width
    case depth
    case height

    var id: String { rawValue }

    var title: String {
        switch self {
        case .width: "Width"
        case .depth: "Depth"
        case .height: "Height"
        }
    }
}

enum MoveCall: String, Codable, CaseIterable, Identifiable {
    case proceed
    case turnIt
    case splitParts
    case otherRoute
    case leaveIt

    var id: String { rawValue }

    var title: String {
        switch self {
        case .proceed: "Load it"
        case .turnIt: "Turn it"
        case .splitParts: "Take it apart"
        case .otherRoute: "Try another stop"
        case .leaveIt: "Leave it"
        }
    }

    var rank: Int {
        switch self {
        case .proceed: 0
        case .turnIt: 1
        case .splitParts: 2
        case .otherRoute: 3
        case .leaveIt: 4
        }
    }
}

enum FitModule: String, Codable, CaseIterable, Identifiable {
    case door
    case turn
    case stair
    case vehicle
    case cargo
    case spot

    var id: String { rawValue }

    var title: String {
        switch self {
        case .door: "Doorway"
        case .turn: "Corner"
        case .stair: "Stairs"
        case .vehicle: "Van opening"
        case .cargo: "Cargo bay"
        case .spot: "Floor spot"
        }
    }

    var symbol: String {
        switch self {
        case .door: "door.left.hand.open"
        case .turn: "arrow.turn.up.right"
        case .stair: "figure.stairs"
        case .vehicle: "truck.box"
        case .cargo: "square.stack.3d.up"
        case .spot: "square.dashed"
        }
    }

    var primaryLabel: String {
        switch self {
        case .door, .vehicle: "Clear width"
        case .turn: "First hall width"
        case .stair: "Stair width"
        case .cargo: "Bay length"
        case .spot: "Floor length"
        }
    }

    var secondaryLabel: String {
        switch self {
        case .door, .vehicle: "Clear height"
        case .turn: "Second hall width"
        case .stair: "Headroom"
        case .cargo: "Bay width"
        case .spot: "Floor depth"
        }
    }

    var tertiaryLabel: String {
        switch self {
        case .door, .vehicle: "Keep clear"
        case .turn: "Ceiling"
        case .stair: "Stair run"
        case .cargo: "Bay height"
        case .spot: "Aisle to leave"
        }
    }

    var prompt: String {
        switch self {
        case .door: "Which face actually goes through this opening?"
        case .turn: "Can you walk it around this corner upright?"
        case .stair: "Does it pass the stair on end, or only on its side?"
        case .vehicle: "Which face enters the van?"
        case .cargo: "How does it sit in the bay, and how many?"
        case .spot: "Does the footprint fit once an aisle is left open?"
        }
    }
}

enum FitTab: String, CaseIterable, Identifiable, Hashable {
    case route
    case pieces
    case stops
    case settings

    var id: String { rawValue }

    var label: String {
        switch self {
        case .route: "Route"
        case .pieces: "Pieces"
        case .stops: "Stops"
        case .settings: "Settings"
        }
    }

    var symbol: String {
        switch self {
        case .route: "arrow.triangle.turn.up.right.circle"
        case .pieces: "cube"
        case .stops: "door.left.hand.open"
        case .settings: "gearshape"
        }
    }
}

enum FitRoute: Hashable {
    case module(FitModule)
    case piece(String)
    case stop(String)
    case compare
    case export
    case loadPlan
    case forms
    case handling
}

struct RemovablePart: Identifiable, Hashable, Codable {
    var id: String
    var name: String
    var axis: BoxAxis
    var reliefMM: Double
}

struct FurniturePiece: Identifiable, Hashable, Codable {
    var id: String
    var name: String
    var kind: String
    var widthMM: Double
    var depthMM: Double
    var heightMM: Double
    var parts: [RemovablePart]

    var box: FitBox {
        FitBox(width: widthMM, depth: depthMM, height: heightMM)
    }

    var sizeLine: String {
        "\(FitFormat.mm(widthMM)) × \(FitFormat.mm(depthMM)) × \(FitFormat.mm(heightMM))"
    }
}

struct FitBox: Hashable {
    var width: Double
    var depth: Double
    var height: Double

    func reduced(by parts: [RemovablePart]) -> FitBox {
        var copy = self
        for part in parts where part.reliefMM > 0 {
            switch part.axis {
            case .width: copy.width = max(1, copy.width - part.reliefMM)
            case .depth: copy.depth = max(1, copy.depth - part.reliefMM)
            case .height: copy.height = max(1, copy.height - part.reliefMM)
            }
        }
        return copy
    }

    var minimumFace: Double { min(width, depth, height) }
}

struct Pose: Hashable {
    var up: BoxAxis
    var across: BoxAxis
    var travel: BoxAxis
    var upMM: Double
    var acrossMM: Double
    var travelMM: Double

    var isNatural: Bool { up == .height && across == .width }

    var spoken: String {
        "\(up.title.lowercased()) up, \(across.title.lowercased()) across"
    }
}

struct RouteStop: Identifiable, Hashable, Codable {
    var id: String
    var name: String
    var module: FitModule
    var primaryMM: Double
    var secondaryMM: Double
    var tertiaryMM: Double
    var note: String

    var sizeLine: String {
        "\(FitFormat.mm(primaryMM)) × \(FitFormat.mm(secondaryMM))"
    }
}

struct FitReading: Identifiable, Hashable, Codable {
    var id: String
    var pieceID: String
    var stopID: String
    var module: FitModule
    var call: MoveCall
    var clearanceMM: Double
    var orientation: String
    var recorded: String
    var note: String
}

struct ComparePair: Identifiable, Hashable, Codable {
    var id: String
    var title: String
    var leftID: String
    var rightID: String
    var reason: String
}

struct HaulPlan: Identifiable, Hashable, Codable {
    var id: String
    var name: String
    var stopIDs: [String]
}

struct GateReport: Hashable {
    var call: MoveCall
    var clearanceMM: Double
    var pose: Pose
    var headline: String
    var note: String
    var count: Int
    var usedParts: Bool

    var fits: Bool { call != .leaveIt && call != .otherRoute }
}

struct RouteReport {
    var planName: String
    var call: MoveCall
    var blockerName: String
    var gates: [(stop: RouteStop, report: GateReport)]

    var headline: String { call.title }
}

enum FitFormat {
    static func mm(_ value: Double) -> String {
        let rounded = value.rounded()
        if abs(rounded) >= 1000 {
            return String(format: "%.2f m", rounded / 1000)
        }
        return String(format: "%.0f mm", rounded)
    }

    static func signedMM(_ value: Double) -> String {
        let body = mm(abs(value))
        if value > 0.5 { return "+\(body)" }
        if value < -0.5 { return "−\(body)" }
        return body
    }

    static func count(_ value: Int) -> String {
        value == 1 ? "1" : "\(value)"
    }
}
