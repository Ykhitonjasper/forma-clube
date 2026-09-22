import Foundation

struct FreeSpace: Hashable {
    var x: Double
    var y: Double
    var z: Double
    var length: Double
    var width: Double
    var height: Double

    var volume: Double { max(0, length) * max(0, width) * max(0, height) }

    func fits(along: Double, across: Double, up: Double) -> Bool {
        along <= length + 0.01 && across <= width + 0.01 && up <= height + 0.01
    }
}

struct PackedItem: Hashable, Identifiable {
    var id: String { pieceID }
    var pieceID: String
    var name: String
    var x: Double
    var y: Double
    var z: Double
    var along: Double
    var across: Double
    var up: Double
    var spoken: String

    var endX: Double { x + along }
    var endY: Double { y + across }
    var endZ: Double { z + up }
}

struct BayPlan: Hashable {
    var method: String
    var placed: [PackedItem]
    var leftOut: [String]
    var leftoverMM: Double

    var fitsAll: Bool { leftOut.isEmpty }
    var headline: String {
        if fitsAll { return placed.count == 1 ? "The piece fits" : "All \(placed.count) fit" }
        if placed.isEmpty { return "Nothing fits" }
        return "\(leftOut.count) left out"
    }
}

enum FitPacker {
    static func pack(pieces: [FurniturePiece], bay: RouteStop) -> BayPlan {
        let tallFirst = pack(pieces: pieces, bay: bay, method: "Tall pieces first", rank: { volume($0) })
        let flatFirst = pack(pieces: pieces, bay: bay, method: "Flat pieces first", rank: { min($0.widthMM, $0.depthMM, $0.heightMM) })
        return better(tallFirst, flatFirst)
    }

    static func overlaps(_ plan: BayPlan) -> [String] {
        var hits: [String] = []
        for leftIndex in plan.placed.indices {
            for rightIndex in plan.placed.indices where rightIndex > leftIndex {
                let left = plan.placed[leftIndex]
                let right = plan.placed[rightIndex]
                if intersects(left, right) {
                    hits.append("\(left.name) crosses \(right.name)")
                }
            }
        }
        return hits
    }

    static func outsideBay(_ plan: BayPlan, bay: RouteStop) -> [String] {
        plan.placed.compactMap { item in
            if item.x < -0.01 || item.y < -0.01 || item.z < -0.01 { return "\(item.name) starts outside the bay" }
            if item.endX > bay.primaryMM + 0.01 { return "\(item.name) sticks out the back" }
            if item.endY > bay.secondaryMM + 0.01 { return "\(item.name) sticks out the side" }
            if item.endZ > bay.tertiaryMM + 0.01 { return "\(item.name) hits the roof" }
            return nil
        }
    }

    static func lines(for plan: BayPlan, bay: RouteStop) -> [String] {
        var rows = ["\(plan.method). \(plan.headline)."]
        rows.append("Bay \(FitFormat.mm(bay.primaryMM)) × \(FitFormat.mm(bay.secondaryMM)) × \(FitFormat.mm(bay.tertiaryMM)).")
        if plan.placed.isEmpty {
            rows.append("No orientation of these pieces sits inside that bay.")
            return rows
        }
        for item in plan.placed {
            rows.append(
                "\(item.name): \(item.spoken), from \(FitFormat.mm(item.x)), \(FitFormat.mm(item.y)), \(FitFormat.mm(item.z))."
            )
        }
        if !plan.leftOut.isEmpty {
            rows.append("Leave behind: \(plan.leftOut.joined(separator: ", ")).")
        }
        let clashes = overlaps(plan)
        if clashes.isEmpty {
            rows.append("Nothing in the plan occupies the same space.")
        } else {
            rows.append(contentsOf: clashes)
        }
        let proud = outsideBay(plan, bay: bay)
        if proud.isEmpty {
            rows.append("Nothing sticks out of the measured bay.")
        } else {
            rows.append(contentsOf: proud)
        }
        rows.append("Unused space on the tight axis is about \(FitFormat.mm(plan.leftoverMM)).")
        return rows
    }

    private static func pack(pieces: [FurniturePiece], bay: RouteStop, method: String, rank: (FurniturePiece) -> Double) -> BayPlan {
        let ordered = pieces.sorted { rank($0) > rank($1) }
        var free = [FreeSpace(x: 0, y: 0, z: 0, length: bay.primaryMM, width: bay.secondaryMM, height: bay.tertiaryMM)]
        var placed: [PackedItem] = []
        var left: [String] = []
        for piece in ordered {
            if let hit = firstFit(piece: piece, free: free) {
                placed.append(hit.item)
                free.remove(at: hit.index)
                free.append(contentsOf: split(hit.space, along: hit.item.along, across: hit.item.across, up: hit.item.up))
                free = prune(free)
            } else {
                left.append(piece.name)
            }
        }
        let leftover = free.map(\.volume).max() ?? 0
        let edge = leftover > 0 ? leftover.squareRoot().squareRoot() : 0
        return BayPlan(method: method, placed: placed, leftOut: left, leftoverMM: edge)
    }

    private struct FitHit {
        var index: Int
        var space: FreeSpace
        var item: PackedItem
    }

    private static func firstFit(piece: FurniturePiece, free: [FreeSpace]) -> FitHit? {
        var best: FitHit?
        for pose in FitEngine.poses(of: piece.box) {
            for (index, space) in free.enumerated() where space.fits(along: pose.travelMM, across: pose.acrossMM, up: pose.upMM) {
                let item = PackedItem(
                    pieceID: piece.id,
                    name: piece.name,
                    x: space.x,
                    y: space.y,
                    z: space.z,
                    along: pose.travelMM,
                    across: pose.acrossMM,
                    up: pose.upMM,
                    spoken: pose.spoken
                )
                let waste = space.volume - pose.travelMM * pose.acrossMM * pose.upMM
                let candidate = FitHit(index: index, space: space, item: item)
                if best == nil || waste < wasteOf(best!, free: free) {
                    best = candidate
                }
            }
        }
        return best
    }

    private static func wasteOf(_ hit: FitHit, free: [FreeSpace]) -> Double {
        let space = free[hit.index]
        return space.volume - hit.item.along * hit.item.across * hit.item.up
    }

    private static func split(_ space: FreeSpace, along: Double, across: Double, up: Double) -> [FreeSpace] {
        var remainders: [FreeSpace] = []
        let restLength = space.length - along
        if restLength > 1 {
            remainders.append(
                FreeSpace(x: space.x + along, y: space.y, z: space.z, length: restLength, width: space.width, height: space.height)
            )
        }
        let restWidth = space.width - across
        if restWidth > 1 {
            remainders.append(
                FreeSpace(x: space.x, y: space.y + across, z: space.z, length: along, width: restWidth, height: space.height)
            )
        }
        let restHeight = space.height - up
        if restHeight > 1 {
            remainders.append(
                FreeSpace(x: space.x, y: space.y, z: space.z + up, length: along, width: across, height: restHeight)
            )
        }
        return remainders
    }

    private static func prune(_ spaces: [FreeSpace]) -> [FreeSpace] {
        var kept: [FreeSpace] = []
        for space in spaces where space.length > 1 && space.width > 1 && space.height > 1 {
            let contained = kept.contains { other in
                space.x >= other.x - 0.01 && space.y >= other.y - 0.01 && space.z >= other.z - 0.01
                    && space.x + space.length <= other.x + other.length + 0.01
                    && space.y + space.width <= other.y + other.width + 0.01
                    && space.z + space.height <= other.z + other.height + 0.01
            }
            if !contained {
                kept.removeAll { other in
                    other.x >= space.x - 0.01 && other.y >= space.y - 0.01 && other.z >= space.z - 0.01
                        && other.x + other.length <= space.x + space.length + 0.01
                        && other.y + other.width <= space.y + space.width + 0.01
                        && other.z + other.height <= space.z + space.height + 0.01
                }
                kept.append(space)
            }
        }
        return kept
    }

    private static func intersects(_ left: PackedItem, _ right: PackedItem) -> Bool {
        left.x < right.endX - 0.01 && right.x < left.endX - 0.01
            && left.y < right.endY - 0.01 && right.y < left.endY - 0.01
            && left.z < right.endZ - 0.01 && right.z < left.endZ - 0.01
    }

    private static func better(_ left: BayPlan, _ right: BayPlan) -> BayPlan {
        if left.leftOut.count != right.leftOut.count {
            return left.leftOut.count < right.leftOut.count ? left : right
        }
        if left.leftoverMM != right.leftoverMM {
            return left.leftoverMM > right.leftoverMM ? left : right
        }
        return left
    }

    private static func volume(_ piece: FurniturePiece) -> Double {
        piece.widthMM * piece.depthMM * piece.heightMM
    }
}
