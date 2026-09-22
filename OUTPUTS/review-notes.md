# Review notes — FormaClube

<!-- a2ui-stamp -->
- App: FormaClube
- Lane: utility
- Chassis: fieldkit
- Pack: orchard
<!-- /a2ui-stamp -->

## 2.1 Completeness
- Risk: reviewer opens Route and sees no piece or stops.
- Mitigation: seeded furniture pieces, door/stair/van stops, and saved checks ship in the binary. Onboarding is three pages. Settings can wipe all data and return to onboarding.

## 2.1.0 / 2.3.6 — no account (paste into ASC App Review Information → Notes)
This app has no login and no user accounts. A demo account is not applicable. All features work offline after install. Screenshots match the binary; there is no hidden sign-in.

## 4.2 Minimum functionality
- Risk: a thin calculator with one number.
- Mitigation: route fit checks (doorway, corner, stair, van), piece library, reusable stops, load plan, handling notes, form templates, compare, and export text — all usable without a network.

## 4.3 Spam
- Risk: another generic unit converter.
- Mitigation: the job is a furniture pickup route. The nouns are pieces, openings, and load-or-leave calls.

## 5.1.1 Privacy
- Permissions requested: none (no location, camera, tracking prompt)
- Pickup data: pieces, stops, checks — on device only; Delete All Data in Settings
- App Privacy (ASC): Usage Data + Advertising Data, **not linked to you**, used for third-party advertising; tracking false
- Legal: https://formaclube-legal.pages.dev/privacy and /terms (in-app Safari sheet)

## 5.6 Conduct
- Risk: the listing describes a different tool than the binary.
- Mitigation: subtitle and Route tab both describe measuring a piece against openings to the van. Identity for this app is only in this project.

## Waivers
None.

## Demo for reviewer
Offline. After three onboarding pages: Route → **Start fit check** → save doorway → open **Corner** → save corner. Open Pieces and Stops (seeded data). Settings → Privacy Policy and Terms of Use (in-app links). **Delete All Data** returns to onboarding.

---

## App Store Connect — 2.1 Information Needed (paste into Notes + reply)

**1. Screen recording**  
Attached in this message: physical iPhone, latest iOS, cold launch through onboarding → Route fit check (door + corner saved) → Pieces → Stops → Settings → Privacy → Terms → Delete All Data → onboarding again. No login, UGC, IAP, or paid content in this build.

**2. Purpose and audience**  
FormaClube helps people who pick up used or private-sale furniture decide whether a piece will fit through each opening on the way out (seller door, corner, stair, van bay) and whether to load it, turn it, disassemble it, or walk away. Audience: individuals and small crews doing in-person pickups—not a business-only or employee tool.

**3. How to access main features**  
No setup, credentials, or sample files required. Install, tap through onboarding (Next → Next → Get started). Sample pieces and stops are preloaded. Main flow: Route tab → choose a piece chip → **Start fit check** → **Save this doorway** → tap **Corner** → **Save this corner**. Explore Pieces, Stops, and rows under “Every stop” on Route. Settings holds Privacy/Terms links and **Delete All Data**.

**4. External services**  
Core fit checks work offline. Network: hosted Privacy/Terms on Cloudflare Pages (`formaclube-legal.pages.dev`); third-party advertising partners per App Privacy (usage/advertising data not linked to identity). No accounts or backend API for pickup data.

**5. Regional differences**  
The app is the same in all regions: offline utility, English UI, no geo-gated features or content.

**6. Regulated industry / third-party material**  
Not applicable. No gambling, medical, financial, or licensed third-party catalogs.

---

## Screen recording script (~3–4 min)

Record on a **physical iPhone** (latest iOS). Enable **Settings → Control Center → Screen Recording**. Delete the app first (or use **Delete All Data**) so reviewers see a fresh install. Speak optional; not required.

| Step | Action | Show on screen |
|------|--------|----------------|
| 0 | Kill app; tap icon | Launch / splash → onboarding page 1 “Will it fit the way out?” |
| 1 | Next, Next, **Get started** | Page 2 stops/van, page 3 “Stored on this phone” |
| 2 | **Route** tab (default) | Hero “Will this piece fit the whole route?”, piece chips |
| 3 | **Start fit check** | Doorway readout (clearance / call) |
| 4 | **Save this doorway** | “Doorway saved” |
| 5 | Tap **Corner** chip | Corner readout |
| 6 | **Save this corner** | “Corner saved”; scroll briefly to “Every opening on this way” if visible |
| 7 | **Pieces** tab | List of seeded pieces; open one detail |
| 8 | **Stops** tab | Saved openings (door, stair, van) |
| 9 | **Settings** | Counts, “Network: Not used” |
| 10 | **Privacy Policy** | Policy page loads |
| 11 | Back → **Terms of Use** | Terms page loads |
| 12 | **Delete All Data** | Returns to onboarding (proves local wipe) |

**Not in app (say in Notes, not on video):** account registration/login/deletion, UGC/report/block, in-app purchases.

Upload: App Store Connect → your version → **App Review** → reply to the message and attach the `.mov`. Duplicate the “paste” block above into **App Review Information → Notes**.
