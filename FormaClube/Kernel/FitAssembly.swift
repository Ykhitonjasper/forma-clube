import Foundation

struct AssemblyMember: Identifiable, Hashable {
    var id: String
    var name: String
    var width: Double
    var depth: Double
    var height: Double
    var x: Double
    var y: Double
    var z: Double
    var removable: Bool

    var maxX: Double { x + width }
    var maxY: Double { y + depth }
    var maxZ: Double { z + height }
}

struct Assembly: Identifiable, Hashable {
    var id: String
    var name: String
    var kind: String
    var members: [AssemblyMember]

    var removable: [AssemblyMember] { members.filter(\.removable) }

    func box(omitting ids: Set<String> = []) -> FitBox {
        let kept = members.filter { !ids.contains($0.id) }
        guard !kept.isEmpty else { return FitBox(width: 1, depth: 1, height: 1) }
        let minX = kept.map(\.x).min() ?? 0
        let minY = kept.map(\.y).min() ?? 0
        let minZ = kept.map(\.z).min() ?? 0
        let maxX = kept.map(\.maxX).max() ?? 0
        let maxY = kept.map(\.maxY).max() ?? 0
        let maxZ = kept.map(\.maxZ).max() ?? 0
        return FitBox(width: max(1, maxX - minX), depth: max(1, maxY - minY), height: max(1, maxZ - minZ))
    }
}

struct StripChoice: Identifiable, Hashable {
    var id: String { removed.joined(separator: "-") }
    var removed: [String]
    var box: FitBox
    var report: GateReport

    var keepsMore: Bool { removed.isEmpty }
}

enum FitAssembly {
    static let forms: [Assembly] = [pineCase, sofa, table, fridge, mattress, washer]

    static func choice(assembly: Assembly, stop: RouteStop) -> StripChoice {
        let removableIDs = assembly.removable.map(\.id)
        var best: StripChoice?
        for subset in subsets(removableIDs) {
            let box = assembly.box(omitting: Set(subset))
            let report = FitEngine.gate(module: stop.module, box: box, stop: stop, parts: [])
            let choice = StripChoice(removed: names(subset, in: assembly), box: box, report: report)
            if report.call == .leaveIt || report.call == .otherRoute { continue }
            if best == nil || better(choice, than: best!) {
                best = choice
            }
        }
        if let best { return best }
        let intact = assembly.box()
        let report = FitEngine.gate(module: stop.module, box: intact, stop: stop, parts: [])
        return StripChoice(removed: [], box: intact, report: report)
    }

    static func piece(from assembly: Assembly, omitting ids: Set<String>) -> FurniturePiece {
        let box = assembly.box(omitting: ids)
        let parts = assembly.removable.filter { !ids.contains($0.id) }.map { member in
            RemovablePart(id: member.id, name: member.name, axis: reliefAxis(member, in: assembly), reliefMM: relief(member, in: assembly))
        }
        return FurniturePiece(
            id: assembly.id,
            name: assembly.name,
            kind: assembly.kind,
            widthMM: box.width,
            depthMM: box.depth,
            heightMM: box.height,
            parts: parts.filter { $0.reliefMM > 1 }
        )
    }

    static let pineCase = Assembly(
        id: "form-case",
        name: "Pine case",
        kind: "Cabinet",
        members: [
            AssemblyMember(id: "carcass", name: "Carcass", width: 680, depth: 860, height: 1900, x: 0, y: 0, z: 0, removable: false),
            AssemblyMember(id: "side", name: "Side panel", width: 220, depth: 860, height: 1900, x: 680, y: 0, z: 0, removable: true),
            AssemblyMember(id: "crown", name: "Crown", width: 900, depth: 860, height: 40, x: 0, y: 0, z: 1860, removable: true)
        ]
    )

    static let sofa = Assembly(
        id: "form-sofa",
        name: "Three-seat sofa",
        kind: "Sofa",
        members: [
            AssemblyMember(id: "body", name: "Body", width: 2100, depth: 900, height: 700, x: 0, y: 80, z: 120, removable: false),
            AssemblyMember(id: "feet", name: "Feet", width: 2100, depth: 900, height: 120, x: 0, y: 80, z: 0, removable: true),
            AssemblyMember(id: "back", name: "Back cushions", width: 2000, depth: 180, height: 450, x: 50, y: 0, z: 350, removable: true)
        ]
    )

    static let table = Assembly(
        id: "form-table",
        name: "Dining table",
        kind: "Table",
        members: [
            AssemblyMember(id: "top", name: "Top", width: 1800, depth: 900, height: 40, x: 0, y: 0, z: 720, removable: false),
            AssemblyMember(id: "legs", name: "Legs", width: 1600, depth: 700, height: 720, x: 100, y: 100, z: 0, removable: true)
        ]
    )

    static let fridge = Assembly(
        id: "form-fridge",
        name: "Fridge",
        kind: "Fridge",
        members: [
            AssemblyMember(id: "cabinet", name: "Cabinet", width: 700, depth: 620, height: 1800, x: 0, y: 0, z: 0, removable: false),
            AssemblyMember(id: "doors", name: "Doors", width: 700, depth: 80, height: 1700, x: 0, y: 620, z: 50, removable: true)
        ]
    )

    static let mattress = Assembly(
        id: "form-mattress",
        name: "Double mattress",
        kind: "Mattress",
        members: [
            AssemblyMember(id: "pad", name: "Mattress", width: 1350, depth: 1900, height: 280, x: 0, y: 0, z: 0, removable: false)
        ]
    )

    static let washer = Assembly(
        id: "form-washer",
        name: "Washer",
        kind: "Washer",
        members: [
            AssemblyMember(id: "drum", name: "Washer", width: 600, depth: 640, height: 850, x: 0, y: 0, z: 0, removable: false),
            AssemblyMember(id: "hoses", name: "Hoses", width: 600, depth: 40, height: 80, x: 0, y: 640, z: 200, removable: true)
        ]
    )

    private static func subsets(_ ids: [String]) -> [[String]] {
        var result: [[String]] = [[]]
        for id in ids {
            let grown = result.map { $0 + [id] }
            result.append(contentsOf: grown)
        }
        return result.sorted { $0.count < $1.count }
    }

    private static func names(_ ids: [String], in assembly: Assembly) -> [String] {
        ids.compactMap { id in assembly.members.first { $0.id == id }?.name }
    }

    private static func better(_ next: StripChoice, than current: StripChoice) -> Bool {
        if next.removed.count != current.removed.count {
            return next.removed.count < current.removed.count
        }
        if next.report.call.rank != current.report.call.rank {
            return next.report.call.rank < current.report.call.rank
        }
        return next.report.clearanceMM > current.report.clearanceMM
    }

    private static func reliefAxis(_ member: AssemblyMember, in assembly: Assembly) -> BoxAxis {
        let full = assembly.box()
        let without = assembly.box(omitting: [member.id])
        let widthLost = full.width - without.width
        let depthLost = full.depth - without.depth
        let heightLost = full.height - without.height
        if heightLost >= widthLost && heightLost >= depthLost && heightLost > 1 { return .height }
        if widthLost >= depthLost && widthLost > 1 { return .width }
        return .depth
    }

    private static func relief(_ member: AssemblyMember, in assembly: Assembly) -> Double {
        let full = assembly.box()
        let without = assembly.box(omitting: [member.id])
        switch reliefAxis(member, in: assembly) {
        case .width: return full.width - without.width
        case .depth: return full.depth - without.depth
        case .height: return full.height - without.height
        }
    }
}
