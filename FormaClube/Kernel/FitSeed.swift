import Foundation

enum FitSeed {
    static let pieces: [FurniturePiece] = [
        FurniturePiece(
            id: "case",
            name: "Pine case",
            kind: "Cabinet",
            widthMM: 900,
            depthMM: 860,
            heightMM: 1900,
            parts: [RemovablePart(id: "case-side", name: "Side panel", axis: .width, reliefMM: 220)]
        ),
        FurniturePiece(
            id: "shelves",
            name: "Shelf boards",
            kind: "Boards",
            widthMM: 740,
            depthMM: 280,
            heightMM: 200,
            parts: []
        ),
        FurniturePiece(
            id: "back",
            name: "Back panel",
            kind: "Panel",
            widthMM: 860,
            depthMM: 16,
            heightMM: 1700,
            parts: []
        ),
        FurniturePiece(
            id: "plinth",
            name: "Plinth",
            kind: "Base",
            widthMM: 880,
            depthMM: 300,
            heightMM: 100,
            parts: []
        )
    ]

    static let routePlaces: [RouteStop] = [
        RouteStop(id: "seller-door", name: "Seller door", module: .door, primaryMM: 810, secondaryMM: 2030, tertiaryMM: 15, note: "Front door, measured inside the frame."),
        RouteStop(id: "seller-corner", name: "Hall corner", module: .turn, primaryMM: 1050, secondaryMM: 980, tertiaryMM: 2400, note: "Turn from the hall into the front room."),
        RouteStop(id: "seller-stair", name: "Front stair", module: .stair, primaryMM: 820, secondaryMM: 2000, tertiaryMM: 2800, note: "Straight flight down to the door."),
        RouteStop(id: "van-rear", name: "Van rear", module: .vehicle, primaryMM: 1220, secondaryMM: 1480, tertiaryMM: 15, note: "Rear doors, clear of the latch."),
        RouteStop(id: "van-side", name: "Van side", module: .vehicle, primaryMM: 980, secondaryMM: 1200, tertiaryMM: 15, note: "Sliding door on the kerb side."),
        RouteStop(id: "van-bay", name: "Van bay", module: .cargo, primaryMM: 2500, secondaryMM: 1650, tertiaryMM: 1450, note: "Floor to the roof lining, behind the seats."),
        RouteStop(id: "storage-floor", name: "Storage bay", module: .spot, primaryMM: 2100, secondaryMM: 1600, tertiaryMM: 450, note: "Bay 14. Leave an aisle to the door.")
    ]

    static let haulPlans: [HaulPlan] = [
        HaulPlan(id: "by-stair", name: "Out by the stair", stopIDs: ["seller-door", "seller-corner", "seller-stair", "van-rear", "van-bay", "storage-floor"]),
        HaulPlan(id: "skip-stair", name: "Skip the stair", stopIDs: ["seller-door", "seller-corner", "van-rear", "van-bay", "storage-floor"])
    ]

    static let pieceReadings: [FitReading] = [
        reading("case-door", "case", "seller-door", .door, .splitParts, 115, "height up, width across", "Side panel off. The door then clears by 115 mm."),
        reading("case-corner", "case", "seller-corner", .turn, .proceed, 80, "height up, width across", "Upright footprint clears the tighter hall by 80 mm."),
        reading("case-stair", "case", "seller-stair", .stair, .splitParts, 100, "height up, width across", "Side panel off. The stair is the second place that needs it."),
        reading("case-rear", "case", "van-rear", .vehicle, .turnIt, 345, "width up, depth across", "Lay it so the depth faces the rear opening. 345 mm spare."),
        reading("case-side", "case", "van-side", .vehicle, .turnIt, 105, "width up, depth across", "The side door also needs a turn, with only 105 mm spare."),
        reading("case-bay", "case", "van-bay", .cargo, .turnIt, 590, "depth up, width across", "One case fits once it is laid down. 590 mm left on the tight axis."),
        reading("case-spot", "case", "storage-floor", .spot, .proceed, 740, "height up, width across", "The bay takes it as measured, with the aisle left open."),
        reading("shelves-door", "shelves", "seller-door", .door, .proceed, 55, "height up, width across", "Boards face the door as stacked. 55 mm spare."),
        reading("shelves-corner", "shelves", "seller-corner", .turn, .proceed, 240, "height up, width across", "The stack walks the corner upright."),
        reading("shelves-stair", "shelves", "seller-stair", .stair, .proceed, 80, "height up, width across", "The stack goes up the stair as carried."),
        reading("shelves-rear", "shelves", "van-rear", .vehicle, .proceed, 465, "height up, width across", "Rear doors take the stack without turning it."),
        reading("shelves-side", "shelves", "van-side", .vehicle, .proceed, 225, "height up, width across", "The side door takes the stack as well."),
        reading("shelves-bay", "shelves", "van-bay", .cargo, .proceed, 50, "height up, width across", "112 stacks fit if you fill the bay. 50 mm left on the height."),
        reading("shelves-spot", "shelves", "storage-floor", .spot, .proceed, 910, "height up, width across", "The floor has room to spare."),
        reading("back-door", "back", "seller-door", .door, .turnIt, 779, "width up, depth across", "Go through edge first. The wide face does not fit the width."),
        reading("back-corner", "back", "seller-corner", .turn, .proceed, 120, "height up, width across", "The panel walks upright. 120 mm in the tighter hall."),
        reading("back-stair", "back", "seller-stair", .stair, .turnIt, 804, "width up, depth across", "Carry the thin edge across the stair."),
        reading("back-rear", "back", "van-rear", .vehicle, .turnIt, 605, "width up, depth across", "Rear opening needs the panel on edge."),
        reading("back-side", "back", "van-side", .vehicle, .turnIt, 325, "width up, depth across", "Side door needs the same edge-first carry."),
        reading("back-bay", "back", "van-bay", .cargo, .turnIt, 2, "width up, depth across", "103 panels fit on edge. Only 2 mm left, so do not add a blanket under the stack."),
        reading("back-spot", "back", "storage-floor", .spot, .proceed, 790, "height up, width across", "The panel stands on the floor as measured."),
        reading("plinth-door", "plinth", "seller-door", .door, .turnIt, 695, "width up, height across", "Turn the plinth. The 880 mm face is wider than the door."),
        reading("plinth-corner", "plinth", "seller-corner", .turn, .proceed, 100, "height up, width across", "The plinth walks the corner with 100 mm spare."),
        reading("plinth-stair", "plinth", "seller-stair", .stair, .turnIt, 720, "width up, height across", "The wide face has to lead along the stair, not across it."),
        reading("plinth-rear", "plinth", "van-rear", .vehicle, .proceed, 325, "height up, width across", "Rear doors take the plinth as measured."),
        reading("plinth-side", "plinth", "van-side", .vehicle, .proceed, 85, "height up, width across", "Side door takes it too, with 85 mm spare."),
        reading("plinth-bay", "plinth", "van-bay", .cargo, .proceed, 50, "height up, width across", "112 plinths would fit. This pickup is one."),
        reading("plinth-spot", "plinth", "storage-floor", .spot, .proceed, 770, "height up, width across", "The bay floor takes the plinth as measured.")
    ]

    static let comparePairs: [ComparePair] = [
        ComparePair(
            id: "door-case-shelves",
            title: "Case against the boards",
            leftID: "case-door",
            rightID: "shelves-door",
            reason: "Same seller door. The boards go through. The case does not, until the side panel is off."
        ),
        ComparePair(
            id: "rear-against-side",
            title: "Rear door against side door",
            leftID: "case-rear",
            rightID: "case-side",
            reason: "Both need the case turned. The rear door has more spare, so load there."
        ),
        ComparePair(
            id: "stair-against-corner",
            title: "Stair against the corner",
            leftID: "case-stair",
            rightID: "case-corner",
            reason: "The corner is fine upright. The stair still needs the side panel off."
        )
    ]

    static func piece(_ id: String) -> FurniturePiece? {
        pieces.first { $0.id == id }
    }

    static func stop(_ id: String) -> RouteStop? {
        routePlaces.first { $0.id == id }
    }

    static func reading(_ id: String) -> FitReading? {
        pieceReadings.first { $0.id == id }
    }

    private static func reading(
        _ id: String,
        _ pieceID: String,
        _ stopID: String,
        _ module: FitModule,
        _ call: MoveCall,
        _ clearance: Double,
        _ orientation: String,
        _ note: String
    ) -> FitReading {
        FitReading(
            id: id,
            pieceID: pieceID,
            stopID: stopID,
            module: module,
            call: call,
            clearanceMM: clearance,
            orientation: orientation,
            recorded: "Tue 22 Sep",
            note: note
        )
    }
}
