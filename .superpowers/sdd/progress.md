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

---

## Plan 2: Phase 0+1 — Data-driven creatures
Plan: docs/superpowers/plans/2026-07-17-phase1-data-driven-creatures.md
Spec: docs/superpowers/specs/2026-07-17-phase1-data-driven-creatures-design.md
Branch: feat/phase1-data-driven-creatures
BASE (branch start): 7ff4126 (plan commit)

### Status (Phase 0+1)
- Task 1 DigimonSpecies model: dispatched (BASE 7ff4126)
- Task 1 DigimonSpecies model: complete (commits 7ff4126..42a08d0, review clean)
    Minor (defer to final review): no test for evolvesTo absent-key default (const []); no ==/hashCode on model classes; report line-count off by 3.
- Task 2 species.json seed: dispatched (BASE 42a08d0)
- Task 2 species.json seed: complete (commits 42a08d0..9857571, review clean; afterMs/biomes verified vs game_config & biome.dart)
    Minor (defer): report line-count typo only.
- Task 3 Pet->speciesId + migration + bridge: dispatched (BASE 9857571)
- Task 3 Pet->speciesId + migration + bridge: complete (commits 9857571..f723717, review clean; 57/57 suite green)
    Minor (defer): copyWith(speciesId+stage) precedence undocumented; stage getter silent fallback for unknown id (both from brief reference code).
- Task 4 data-driven evolution: dispatched (BASE f723717)
- CORRECTION: Task 4 was NOT dispatched. Development PAUSED by user (2026-07-17) with Task 3 complete (HEAD f723717, 57/57 green, analyze clean). Resume = dispatch Task 4 implementer, BASE f723717 (brief ready: .superpowers/sdd/task-4-brief.md).

## RESUME (revised 2026-07-17 — real art + per-state animations)
- Art committed: 5ad599e (assets/creatures/<id>/{idle,eat,happy,sick}_*.png, padded uniform; botamon has no sick→fallback idle). pubspec updated.
- Plan REVISED for real art: SpriteRef(grid) -> per-state animation model; species.json -> real frame counts; PetComponent -> per-state care animation.
- Task order from here: (4) data-driven evolution [v1 brief, art-agnostic] -> (5-new) animation model + real-art seed -> (6-new) per-state rendering -> (biome, v1 T6) -> (remove bridge, v1 T7) -> (on-device, v1 T8, verify animations).
- Tasks 1-3 done (42a08d0, 9857571, f723717). Suite green 57/57.
- Task 4 data-driven evolution: dispatched (BASE 5ad599e).
- Task 4 data-driven evolution: complete (commits 5ad599e..8f9367d, review clean; 58/58 suite green)
    Minor (defer to final review): unknown-speciesId normalization in vpet_game.onLoad doesn't reset stageStartedAtMs (corrupt save could instant-cascade botamon); game_config.stageDurationMs now dead (removed in bridge-removal task).
- Task 5 animation model + real-art seed: running in ISOLATED WORKTREE (parallel to T4); will review its diff (5ad599e..<t5head>) then merge its branch into feat/phase1 (now at 8f9367d) and re-run full suite. Files disjoint from T4 (digimon_species.dart, species.json, 2 tests).
- Task 5 animation model + real-art seed: complete (FF-merged 8f9367d..6fa7200 into feat/phase1; review clean; combined suite 61/61 green, analyze clean). Worktree removed, feat/task5-anim-model deleted.
    Minor (defer): CreatureSprite.fromJson byName error doesn't name the species/file on a bad state key (cosmetic).
- Task 6 per-state care rendering: authoring brief (PetComponent per-state animation + care-state switching; delete sprite_map.dart). BASE 6fa7200.
- Task 6 per-state care rendering: complete (commits 6fa7200..439ca0a + fix 607ce39, review found 1 Important race bug -> fixed & verified; 61/61 green, analyze clean).
    Important FIXED: one-shot reaction fallback guarded against mid-reaction evolution (stale-species race). Minors fixed too (_isSick getter, empty-clip guard, stale sprite_map comment).
- Task 7 biome-as-species-field: dispatched (BASE 607ce39).
- Task 7 biome-as-species-field: complete (commits 607ce39..fdae30d, review clean; 60/60 green — count dropped 61->60 because obsolete biomeForStage-totality test removed with the function; analyze clean). Also adapted test/hud/top_status_bar_test.dart (unlisted) to the new constructor, kept meaningful.
    Minor (defer): hud_theme dropped the Plan-2 lockable-HUD-color doc note; no widget test covers home_screen._topBar() threading species.name/biome.
- Task 8 remove-LifeStage-bridge: dispatched (BASE fdae30d).
- Task 8 remove-LifeStage-bridge: complete (commits fdae30d..a516c0f, verified by controller; 60/60 green, analyze clean, grep LifeStage empty; _lineIds + fromJson migration intact).

## ALL CODE TASKS (1-8) COMPLETE — Phase 1 data-driven creatures done. HEAD a516c0f. 60/60 tests, analyze clean.
Remaining: whole-branch final review + on-device visual verification (real art animations) + finishing-a-development-branch.

## PHASE 1 SHIPPED (2026-07-17)
- Final review fix applied (e538482: reset stage clock on unknown-id normalize). 60/60 green, analyze clean.
- Docs reconciled (f83eb07: PROGRESS phase-complete + spec addendum for real-art/animation model).
- Pushed feat/phase1-data-driven-creatures. **PR #3**: https://github.com/JhonneJrr/digimon-vpet/pull/3 (base master; 18 commits incl. parked Plan-2 docs + gitignore). NOT merged — left for user's review gate.
- On-device verified: Botamon renders + idle-animates with real extracted art; HUD reads species; nursery biome. Emulator digimon_test left running.
- Deferred Minors for a future pass: add a _topBar widget test; wrap byName parse errors with species/file; re-add Plan-2 HUD-color doc note when Plan 2 runs.

## PLAN: radial-care-menu-and-real-hud-buttons (2026-07-18) — BASE 04293f8
Plan: docs/superpowers/plans/2026-07-18-radial-care-menu-and-real-hud-buttons.md (9 tasks)
- Task 1 assets (buttons+care icons+db bg): complete (commit 04293f8..7ada54a, review clean). BASE next 7ada54a.
- Task 2 pet-scale (species.json data): complete (commit 7ada54a..2002dfa, review clean). BASE next 2002dfa.
- Task 3 VpetGame anchor+wander gate: complete (commit 2002dfa..bcd8550, review clean). BASE next bcd8550.
    Minor (defer): WanderController uses unseeded Random; a seeded test RNG would make the wander-pause test airtight (probabilistically fine now).
- Task 4 CareRadial widget: complete (commit bcd8550..a6dd972, review clean; errorBuilder wildcards adapted to (_,_,_) for lint). BASE next a6dd972.
- Task 5 PetTapTarget widget: complete (commit a6dd972..925da0b, review clean; fixed brief bug: Positioned-under-LayoutBuilder -> Positioned.fill+inner Stack). BASE next 925da0b.
    Minor (defer): PetTapTarget test only asserts centre tap, not box geometry / outside-tap no-op (inherited from brief).
- Task 6 kRooms six-room set: complete (commit 925da0b..e430673, review clean). BASE next e430673.
- Task 7 HudOverlay menu buttons: complete (commit e430673..f21cf9f, review clean; home_screen intentionally broken until Task 8). BASE next f21cf9f.
- Task 8 HomeScreen wiring: complete (commit f21cf9f..9790ca9; analyze clean, full suite 80/80). BASE next 9790ca9.
    ADJUDICATED (controller): reviewer flagged _doCare closes-before-await (vs brief prose "action then close"). Kept close-first: snappier dismissal, no post-await setState/dispose risk, and feed/play stay frozen via the isReacting guard; wander-pause purpose (stable anchor while menu open) fully met. Flag for final review.
## CODE TASKS 1-8 COMPLETE. HEAD 9790ca9. Next: final whole-branch review, then on-device verify + PROGRESS (Task 9).

## FINAL WHOLE-BRANCH REVIEW (opus) — Ready to merge: YES (3 follow-ups, none blocking)
- Adjudications confirmed: _doCare close-first is correct (isReacting guard covers feed/play seamlessly, no dispose risk); tap-layer stacking correct (single opaque winner, no dead zone); RNG concern moot (careMenuOpen short-circuits wander block).
- IMPORTANT #1 (FIXING NOW): PetTapTarget hitbox refreshes only at 1Hz (onPetChanged) but pet walks ~42px/s -> tap zone lags a walking pet by up to ~40px. Fix: drive anchor via per-frame ValueNotifier + ValueListenableBuilder.
- Minor #2 (defer): menu_sheet.dart orphaned (no prod caller) but kept + tested -> delete in planned cleanup.
- Minor #3 (defer): pet_tap_target_test only asserts centre tap fires, no geometry/outside-miss.
- Minor #4 (defer): home-assembly (toggle/careMenuOpen sync/care callbacks) has no widget test; on-device only.
- FINAL-REVIEW FIX (Important #1): applied 9790ca9..4c26798 (per-frame petAnchorX ValueNotifier + ValueListenableBuilder; disposed in onRemove). Full suite 82/82, analyze clean. Controller-verified diff. HEAD 4c26798.
- Task 9 verify + on-device: DONE. On-device confirmed (landscape): 6 real menu buttons seat in sockets; tapping the pet opens the top-arc radial (meat/poop/bandage/ball) no HUD collision; pet reads small; Training socket -> Treino 'em breve' room. Full suite 82/82, analyze clean.
- MERGED + PUSHED: master 451bb51..95706f5 (merge commit 95706f5). Plan COMPLETE. feat/hud-overhaul-shell fully merged. 81/81 tests, analyze clean on merged master.

## POST-MERGE HUD FIXES (2026-07-18, on master) — in-flight
- MERGED radial-care plan to master (95706f5), pushed. Then on-device testing surfaced HUD issues.
- 6809c7b: buttons-in-sockets (v1) + Reborn-2 need pop-ups over pet (care_indicators.dart, assets/game/ui/needs/). Removed StatusBadges from HUD. 84/84 tests.
- 6cfec1a: recalibrated button seating to REAL game (measured reference screenshot; _socketX/_socketY/_btnWFrac/_btnHFrac in hud_overlay.dart). Pushed.
- HEAD 6cfec1a. Created .claude/agents/hud-visual-qa.md (image-only analysis; stalls if told to run emulator).
- OPEN (user reported on latest APK): (1) buttons "still errors" — re-measure #4 vs #3, nudge constants. (2) top-left name/status "completamente bugada" — real game has portrait+name+attributes+level; ours only name on plate + empty level gauge. Not yet diagnosed. See PROGRESS RESUME POINT for the two screenshot paths + scratchpad measure scripts.
- NEXT: diagnose both (image compare #4 vs #3, or dispatch hud-visual-qa image-only), fix hud_overlay.dart, analyze+test, rebuild APK.
