# Verified sprite-sheet frame mapping (Task 2.1)

Determined by visually inspecting upscaled grids of the actual sheets in `assets/sprites/`.

## Sheet geometry (CONFIRMED)
- Every sheet is **48×64 px = 3 columns × 4 rows = 12 frames of 16×16**.
- Frames are indexed left→right, top→bottom: row0 = 0,1,2 · row1 = 3,4,5 · row2 = 6,7,8 · row3 = 9,10,11.

## Cross-stage reliable mapping (USE THIS)
- **idle = frames 0 and 1** — the calm standing pose pair. VERIFIED identical semantics on both Botamon (baby) and Agumon (child). Alternate 0↔1 (~0.5s each) for the idle bob. This is the only animation the MVP must render continuously, and it is reliable across stages.

## NOT cross-stage reliable (do NOT assume a shared index)
The non-idle "reaction" frames occupy DIFFERENT indices per stage:
- Botamon: eat≈frame 3 (horizontal red mouth), angry/attack≈7, sleep≈9/10.
- Agumon: eat≈frame 4 (head down, mouth open), happy≈2, attack≈7/8, sleep≈9/10.
Because the semantic order shifts per sheet, a single `frameIndex` map for reactions would render the wrong pose on some stages.

## Decision for the MVP
- Render **idle only** from the sheet (frames 0/1), for ALL six stages.
- Implement button-press feedback (feed/clean/medicine/play) as a **Flame effect on the PetComponent** (e.g. a quick ScaleEffect "bounce" and/or a brief MoveEffect hop), NOT a frame-based reaction animation. This is robust, looks lively, and sidesteps the per-stage frame-semantics uncertainty.
- `sprite_map.dart` therefore only needs: `frameSize=16`, `sheetCols=3`, `sheetRows=4`, the idle indices (0,1), and `spriteSheetForStage(LifeStage)`.

## spriteSheetForStage mapping (unchanged from plan)
- baby1 → sprites/Botamon.png
- baby2 → sprites/Koromon.png
- child → sprites/Agumon.png
- adult → sprites/Greymon.png
- perfectMetal → sprites/MetalGreymon.png
- perfectSkull → sprites/SkullGreymon.png
