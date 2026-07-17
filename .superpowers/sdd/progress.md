# Digimon V-Pet — Progress Ledger

Plan: docs/superpowers/plans/2026-07-17-digimon-vpet-game.md
Branch: feat/vpet-mvp
Flutter: C:\Users\felip\flutter\bin (NOT on default PATH); JAVA_HOME=C:\Program Files\Android\Android Studio\jbr

## Status
- Task 0.1 install Flutter: complete — 3.44.6, Android toolchain green
- Task 0.2 scaffold + git: complete (029251d), branch feat/vpet-mvp
- Task 0.3 deps + assets: complete (86d0465)
- Task 3.1 UI icons: complete early (1941256) — 7 pixel-art icons, visually verified
- Phase 1 core logic: complete + adversarially reviewed + fixed (54bffc6). 25/25 tests.
    Fixed: incremental-tick remainder loss (Critical), dead-freeze (Critical),
    starving/mess backdate, evolution cascade, clock-rewind, careScore decay.
- Phase 2 (Flame rendering): dispatched

## Verified facts for downstream
- Sprite sheets: 48x64 = 3x4 grid of 16px frames. idle = frames 0,1 (cross-stage reliable).
  Reaction frames differ per stage -> use Flame effects, NOT frame indices. See sprite-mapping-verified.md
- Pet model changed vs plan: no more lastTickMs; per-stat anchors hungerSinceMs/happinessSinceMs/
  poopSinceMs + starvingSinceMs/messySinceMs/sickSinceMs. PetLogic signatures unchanged: applyElapsed(Pet,int),
  feed/clean/giveMedicine/play(Pet), checkEvolution(Pet,int).

## Minor findings deferred to final review
- careScore >= threshold routes exactly-0.6 to Metal (accepted).
- poopCount unbounded in logic; Phase 2 should CAP displayed poop piles.
- careScore decay constants are first-pass tuning (careDecayPerHungerPoint=0.02, perPoop=0.03, onSick=0.15).

## BASE for Phase 2 review: 54bffc6

## Phase 2 update (on-device verified)
- APK builds (145MB). Fixed: malformed pre-existing NDK removed + ndkVersion dropped (no native code);
  flutter_local_notifications needed core library desugaring (added desugar_jdk_libs 2.1.4). Commit 0cd7873.
- Disk was 100% full mid-build (freed my ~2GB temp downloads; later reclaimed to ~63GB).
- Created AVD digimon_test (android-34 google_apis x86_64), booted via WHPX, installed APK.
- LIVE VERIFIED end-to-end: launch, sprite render, real-time cascade evolution Botamon->Koromon->Agumon,
  neglect status icons, death -> DeathScreen, restart -> fresh Botamon, custom icons, button taps.
- POLISH TODO: Flame canvas paints black; make game background match the green LCD theme.
- Phase 2 adversarial review: pending (agent a3d7d9708800c25ee).

## Phase 2 COMPLETE (reviewed + fixed + on-device verified)
- Adversarial review found: Critical (double-tap restart -> blank screen),
  2 Important (buttons before load, save race). All fixed (commit aea886a).
- Added green LCD background, dimmed-irrelevant buttons, resize recenter, showFor gen guard.
- 30/30 tests, analyze clean, APK builds + runs. Verified live: green bg, evolution
  Botamon->Koromon, dimmed medicine when healthy, status icons, death+restart.
- BASE for Phase 4 review: aea886a
- Phase 4 (notifications): starting

## Phase 4 COMPLETE (reworked + verified)
- Impl (737d3c7, 12f727b) then reworked (0495b91): dropped unreliable on-pause show()
  (Flutter defers plugin calls during 'paused'); workmanager periodic task is now the
  sole reminder and is SMART (loads persisted pet, read-only, notifies only if
  PetLogic.needsAttention). 33 tests. Verified on device: clean launch, no racy notifs.
- Phase 5 (Task 5.1 build): DONE (APK builds+runs repeatedly). Task 5.2 graphify: starting.

## Phase 5 COMPLETE
- Task 5.1 build: APK builds + runs (verified repeatedly on emulator).
- Task 5.2 graphify (ca61618): built graph (288 nodes, Dart parsed fine), wired project
  Claude Code hook + CLAUDE.md, added Python Scripts to PATH. My Grep still works cleanly.

## ALL PHASES COMPLETE — dispatching final whole-branch review

## Final whole-branch review COMPLETE
- Found 1 Important cross-layer bug: care actions didn't reset time anchors
  (feed bounced back ~1s later). Fixed (nowMs threaded into feed/clean/play/medicine).
- Cheap minors fixed: hungerWarnThreshold constant, ExistingPeriodicWorkPolicy.keep,
  removed dead sprite constants. 34 tests, analyze clean, APK builds.
- Left as noted (acknowledged tuning): careScore/SkullGreymon reachability, happiness
  is spec-listed but not yet consumed.
- ALL WORK COMPLETE. Ready to finish the branch.
