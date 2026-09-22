# 2.1 Smoke

The automated walkthrough (scripts/run-smoke.py → OUTPUTS/smoke-result.yaml, OUTPUTS/smoke.log) proves the app
survives this route. This file is the human half: the route a reviewer should take and what
they should see.

App: FormaClube
Date: 2026-09-21
Simulator: iPhone 17 Pro Max
Build: OUTPUTS/build.log from the same edit

## Tap route (complete twice)

1. Onboarding page 1 → 2 → 3 → Next, Next, Get started
2. Tab Route → Start fit check → save doorway → Corner chip → save corner
3. Repeat doorway check once more if needed
4. Pieces, Stops, Settings — seeded furniture, openings, and the about block
5. Settings → Privacy (page loads)
6. Settings → Terms (page loads)
7. Settings → Delete All Data → introduction returns

## Result

- [x] Pass 1 — no crash, no dead tap
- [x] Pass 2 — same
- [x] Every tab seeded
- [x] Privacy + Terms open (not example.com)
- [x] Delete All works

Notes: Critical checks are the doorway readout and corner readout on Route, each saved before the next one.
