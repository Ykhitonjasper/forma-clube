# Product Spec — FormaClube

## Slot
- Niche ID: niche-039
- Audience: members of a shared community kiln who measure a wet pot before loading day
- Product lane: utility
- Chassis: fieldkit
- Visual pack: orchard
- Content axis: bench measures + clay cards + kiln shelves

## Core loop
Open the bench → check the wall of the pot in your hands against the clay card → save the reading on that piece → find it later under Pieces, next to the shelf it will sit on.

## Tab labels (niche vocabulary, not chassis mechanic)
- Tab 1 label: Bench
- Tab 2 label: Pieces
- Tab 3 label: Shelves
- Tab 4 label: Settings

## First screen contract (hero of Tab 1)
- The one question the user is asking the app: "Will this wall hold in the kiln?"
- The one action they take: "Check the wall"
- ≤4 niche chips visible: Shrink, Rim, Glaze, Foot
- Result vocabulary (single niche noun): "Wall"
- On-screen counters (metric tiles like "16 setups / 31 spins"): none

The other bench tools (shelf clearance, dry check, clay cards, cone chart) sit as rows under the question. They are not a grid of scores.

## Onboarding voice (3 pages)
- Page 1: The shared kiln, and the pot you are holding.
- Page 2: Type a wall, a wet size, or a glaze pint. The clay card does the arithmetic.
- Page 3: The numbers stay on this phone.
- Final CTA text: "Get started"
- Earlier pages: "Next"

## 2.1 smoke plan
Onboarding three pages, then Bench. Check the wall, save it, check shrink, save it. Open Pieces, Shelves, Settings. Privacy and Terms are on Settings. Delete All Data returns to the first page.

## Surfaces (min 8 excl. Settings/Onboarding)
1. Bench — the question, one check, four chips
2. Wall card
3. Shrink card
4. Rim card
5. Glaze pint
6. Shelf fit
7. Dry check
8. Foot ring
9. Pieces list
10. Piece detail
11. Shelves
12. Shelf detail
13. Compare two pieces
14. Text export
15. Clay cards
16. Clay detail
17. Glaze book
18. Glaze detail
19. Cone chart
20. Clay blends
21. Kiln loads
22. Load detail
23. Bench methods
24. Packing count
25. Reclaim yield
26. Firing faults

## Seed plan
- 7 bench tools
- 50+ clay cards with shrink, wall range, dry hours, and throwing notes
- 24+ glaze batches with a 1000 g recipe and a pint-weight band
- 28 saved piece readings
- 8 places (kiln shelves and drying boards)
- 6 compare pairs
- cone rows, blends, past loads, methods, and firing faults

## Density placement
- modules ≥6 → enum BenchModule, opened from Bench rows, not as hero tiles
- readings ≥20 → Pieces list and piece detail
- places ≥5 → Shelves
- comparePairs ≥3 → Compare

## Projects / save model
Seed readings stay in the bundle. A check saved from the bench is appended in memory for this launch. Delete All Data clears those extras and returns to onboarding. The clay cards stay.

## Export
Plain text of the selected pieces, shared from the phone.

## Differentiation vs last 3 stubs
A still-proof editor, a home food cupboard, and a banquet flash sheet. This is a wet-clay bench book for one shared kiln.

## ASO draft (same vocabulary as the UI)
- Subtitle: Kiln wall and shrink
- Keywords: pottery,clay,shrink,kiln,glaze,shelf,stoneware
