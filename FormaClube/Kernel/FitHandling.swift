import Foundation

enum Stock: String, CaseIterable, Identifiable {
    case pine
    case oak
    case birchPly
    case mdf
    case chipboard
    case glass
    case steelTube
    case marble

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pine: "Pine"
        case .oak: "Oak"
        case .birchPly: "Birch ply"
        case .mdf: "MDF"
        case .chipboard: "Chipboard"
        case .glass: "Glass"
        case .steelTube: "Steel tube"
        case .marble: "Marble"
        }
    }

    var kilogramsPerCubicMetre: Double {
        switch self {
        case .pine: 450
        case .oak: 720
        case .birchPly: 680
        case .mdf: 750
        case .chipboard: 680
        case .glass: 2500
        case .steelTube: 1200
        case .marble: 2700
        }
    }
}

struct HandlingBrief: Hashable {
    var kilograms: Double
    var people: Int
    var tip: String
    var blanketMM: Double
    var wrapped: FitBox
    var note: String
    var call: String
}

enum FitHandling {
    static let blanketThickness = 8.0
    static let onePersonLimit = 23.0
    static let twoPersonLimit = 45.0

    static func brief(piece: FurniturePiece, stock: Stock, blankets: Int, stop: RouteStop?) -> HandlingBrief {
        let bare = kilograms(piece: piece, stock: stock)
        let wrapMM = Double(max(0, blankets)) * blanketThickness
        let wrapped = padded(piece.box, by: wrapMM)
        let wrapMass = blanketMass(blankets: blankets, box: piece.box)
        let total = bare + wrapMass
        let people = carriers(for: total)
        let tip = tipNote(box: piece.box)
        let fitNote = fitAfterWrap(wrapped: wrapped, piece: piece, stop: stop, blankets: blankets)
        let call = haulCall(people: people, fitNote: fitNote, tip: tip)
        let note = [
            "\(stock.title) at \(FitFormat.count(Int(stock.kilogramsPerCubicMetre))) kg per cubic metre comes out near \(mass(total)).",
            peopleLine(people, mass: total),
            tip,
            fitNote
        ].joined(separator: " ")
        return HandlingBrief(
            kilograms: total,
            people: people,
            tip: tip,
            blanketMM: wrapMM,
            wrapped: wrapped,
            note: note,
            call: call
        )
    }

    static func kilograms(piece: FurniturePiece, stock: Stock) -> Double {
        let metres = piece.box.reduced(by: piece.parts)
        let full = cubicMetres(piece.box)
        let stripped = cubicMetres(metres)
        let shell = max(full * 0.35, full - (full - stripped) * 0.5)
        return shell * stock.kilogramsPerCubicMetre
    }

    static func carriers(for kilograms: Double) -> Int {
        if kilograms <= onePersonLimit { return 1 }
        if kilograms <= twoPersonLimit { return 2 }
        return 3
    }

    static func tipNote(box: FitBox) -> String {
        let base = min(box.width, box.depth)
        guard base > 0 else { return "The base is missing, so the tip check cannot run." }
        let ratio = box.height / base
        if ratio >= 4 {
            return "It is \(FitFormat.mm(box.height)) on a \(FitFormat.mm(base)) base. Two people, and do not let it stand free in the van."
        }
        if ratio >= 2.5 {
            return "Tall for its base (\(trimmed(ratio)) times). Keep a hand on it while the doors are open."
        }
        return "The base is wide enough that it can stand while you open the next door."
    }

    static func padded(_ box: FitBox, by millimetres: Double) -> FitBox {
        guard millimetres > 0 else { return box }
        return FitBox(
            width: box.width + millimetres * 2,
            depth: box.depth + millimetres * 2,
            height: box.height + millimetres * 2
        )
    }

    static func mass(_ kilograms: Double) -> String {
        String(format: "%.1f kg", kilograms)
    }

    private static func cubicMetres(_ box: FitBox) -> Double {
        (box.width / 1000) * (box.depth / 1000) * (box.height / 1000)
    }

    private static func blanketMass(blankets: Int, box: FitBox) -> Double {
        let layers = Double(max(0, blankets))
        let area = 2 * (box.width * box.depth + box.width * box.height + box.depth * box.height) / 1_000_000
        return layers * area * 0.6
    }

    private static func peopleLine(_ people: Int, mass: Double) -> String {
        switch people {
        case 1:
            return "\(Self.mass(mass)) is a one-person carry on the flat."
        case 2:
            return "\(Self.mass(mass)) wants two people, especially on the stair."
        default:
            return "\(Self.mass(mass)) wants three people, or it stays where it is."
        }
    }

    private static func fitAfterWrap(wrapped: FitBox, piece: FurniturePiece, stop: RouteStop?, blankets: Int) -> String {
        guard let stop else {
            return blankets > 0
                ? "Blankets add \(FitFormat.mm(Double(blankets) * blanketThickness)) a side. Check the doorway again before you wrap it."
                : "No blanket on it yet."
        }
        let bare = FitEngine.gate(module: stop.module, box: piece.box, stop: stop, parts: piece.parts)
        let thick = FitEngine.gate(module: stop.module, box: wrapped, stop: stop, parts: [])
        if blankets == 0 {
            return "Without a blanket, \(stop.name) says \(bare.headline.lowercased())."
        }
        if bare.call == thick.call {
            return "\(blankets) blanket\(blankets == 1 ? "" : "s") do not change \(stop.name): still \(thick.headline.lowercased())."
        }
        return "Bare, \(stop.name) says \(bare.headline.lowercased()). With \(blankets) blanket\(blankets == 1 ? "" : "s") it says \(thick.headline.lowercased())."
    }

    private static func haulCall(people: Int, fitNote: String, tip: String) -> String {
        if people >= 3 { return "Leave it unless you have a third person" }
        if fitNote.contains("leave it") { return "Leave it" }
        if fitNote.contains("take it apart") { return "Take it apart" }
        if people == 2 { return "Two people" }
        if tip.contains("Two people") { return "Two people" }
        return "One person can move it"
    }

    private static func trimmed(_ value: Double) -> String {
        String(format: "%.1f", value)
    }
}
