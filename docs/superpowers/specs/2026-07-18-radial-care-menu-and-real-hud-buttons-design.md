# Design — Radial care menu + real HUD menu buttons

_Date: 2026-07-18 · Branch: `feat/hud-overhaul-shell` · Status: approved design, pending plan_

## Problem & intent

The landscape home shows the real `spr_MainHUD` over the living map. Today the HUD's bottom
**hexagonal sockets** are repurposed as the four care actions (feed / clean / medicine / play) plus a
`☰` menu button. That was a first pass; two things are off:

1. The care icons are Fluent-Emoji PNGs, not the game's own art, and they sit a touch high in the
   sockets (the calibration TODO).
2. In the **real game** those hex sockets are **menu buttons** (DigiVice, Shop, Training, Evolution,
   Database, Battle…), not care actions — confirmed by decompiled GML (`obj_MainButtons`).

We want the home HUD to match the real device (sockets = menu buttons, real sprites) so it already
fits the future mechanics, and to relocate the care loop to a **radial menu that orbits the Digimon**,
opened by tapping the pet. All art comes from the recovered Reborn v2 dump.

This supersedes the "minor HUD calibration" item in `PROGRESS.md` (option A): the calibration is
absorbed here (the real button sprites carry their own hex art, so they seat correctly; the badge/level
overlap is fixed in passing).

## Triangulated facts (from decompiled GML — authoritative)

`gml_Object_obj_MainButtons_Mouse_7.gml` maps `spr_MainButtons_ENG` frames → rooms:

| frame | button (label) | opens | real-game gate (future, not v1) |
|---|---|---|---|
| 0 | DigiVice | `room_DigiVice` | — |
| 1 | Shop | `room_Loja` | — |
| 2 | Training | `room_SelectTraining` | Energy == 100 && evolved |
| 3 | Evolution | `room_Evo_Select` | evolved |
| 4 | Database | `room_Database` | — |
| 5 | Digitize / Battle | `room_Select_Battle_Mode` | EvoStage ≥ 2 |
| 6 | Battle Items | `room_Battle_Items` | evolved (battle-context only) |

The MainHUD art has **6 sockets**: five clustered bottom-left + one bottom-right. Frame 6
(Battle Items) is battle-context, so the six home sockets map cleanly to frames 0–5.

Care-item art (verified via the in-game item list `Small Meat → Big Meat → Bandage → Medicine …`,
which is sprite-frame order offset by +1):

| care action | sprite | reads as |
|---|---|---|
| Feed | `spr_Meat_0` (items) | steak |
| Clean | `spr_poop_0` (items) | poop |
| Medicine | `spr_Items_3` (items) — the **Bandage** item, "Heals injuries" | crossed band-aids |
| Play | `spr_Ball_0` (effects) | soccer ball |

## Design

### A. Hex sockets → real menu buttons

The six sockets render the six real `spr_MainButtons_ENG` frames (0–5), each a tappable region
wired to a `RoomScreen` in the existing shell. No shell refactor — we extend `kRooms` and drive
navigation directly from the sockets instead of the `☰` sheet.

Socket → button → room mapping (5 left sockets L1–L5, then right socket R):

| socket | frame | button | room (`RoomConfig`) |
|---|---|---|---|
| L1 | 0 | DigiVice | **DigiVice** (new stub — device/status hub) |
| L2 | 1 | Shop | **Loja** (existing stub) |
| L3 | 2 | Training | **Treino** (existing stub) |
| L4 | 3 | Evolution | **Evo / Bios** (existing stub) |
| L5 | 4 | Database | **Database** (new stub — Digidex/bios) |
| R  | 5 | Digitize / Battle | **Batalha** (existing stub) |

- `kRooms` is updated to this six-room set. The standalone **Mapa** stub is **dropped from the home
  sockets** — a MainHUD button doesn't exist for it, and exploration/world-map is its own future phase
  (already noted in `PROGRESS.md`). No Mapa asset is deleted; it simply isn't wired to a socket now.
- The real-game gates (Training needs full energy, Battle needs EvoStage ≥ 2, …) are **out of scope
  for v1** — every socket opens its stub room. Gates return with the mechanics that need them.
- The `☰` menu button and `showMenuSheet` bottom sheet are **retired from home** (the sockets are the
  menu now). `menu_sheet.dart` is kept in the tree for now but no longer reachable from home; we may
  delete it in a later cleanup.

Sockets are positioned by fraction of the 538×300 HUD box (as the current care slots already are).
Each button PNG carries its own hex art and seats in its socket; a disabled/coming-soon room still
shows its button at full opacity (the room screen shows "em breve").

### B. Care loop → radial menu around the Digimon

Tapping the Digimon on the stage opens a **"top-arc" radial menu** of the four care actions; tapping
the pet again, or tapping empty stage, closes it. This is a Flutter overlay on the same 538×300 stage
as the HUD — it reads the pet's live position from the game.

- **Anchor:** the pet wanders horizontally. Its stage position is `petComponent.position`
  (x = `wander.x`, base y = `groundFractionForBiome(biome) * height`, bottomCenter anchor). The overlay
  converts to fractions of the stage box: `fx = wander.x / game.size.x`, ground `fy = groundFraction`.
  The four bubbles are placed at fixed offsets **above** that anchor (the approved "arco superior"
  layout: two outer-low, two inner-high, forming a shallow arc over the pet's head).
- **Stable while open:** wandering already pauses during care reactions and while sick; we extend that
  so **wander also pauses while the care menu is open**, keeping the anchor still.
- **Hit target:** a transparent tap region tracks the pet's current bounding box (its screen rect from
  position + size). Tapping it toggles the menu. A full-stage tap layer (below the bubbles, above the
  game) catches outside-taps to close.
- **Bubbles:** four glass discs, one per action, each with the real icon and a per-action accent
  (feed = amber, clean = violet, medicine = red, play = blue). They animate out with a short staggered
  spring; disabled actions render dimmed and are non-tappable (same enable rules as today:
  feed if `hunger > 0`, clean if `poopCount > 0`, medicine if `health == sick`, play always).
- **Action:** tapping an enabled bubble calls the same `game.feed/clean/medicine/play`, plays the
  existing care reaction + haptic, then closes the menu.

### C. Assets

Add to `tools/sprite-library/copy_app_assets.sh` (the reproducible copy step) and commit into the
private repo:

- `assets/game/ui/menu_buttons/btn_0.png … btn_5.png` — the six `spr_MainButtons_ENG` frames.
- `assets/game/ui/care/feed.png` (`spr_Meat_0`), `clean.png` (`spr_poop_0`),
  `medicine.png` (`spr_Items_3`, the Bandage), `play.png` (`spr_Ball_0`).

The old `assets/ui/fe_*.png` care icons are left in place (still used by the pre-landscape widgets /
tests) but are no longer referenced by the home HUD.

### D. Pet scale rebalance (data-only)

At the current `displayHeight`s the pet dominates the scene — Agumon (96) fills ~53% of the ~180px
playfield between the HUD bars, and the Mega forms would be larger still. The pet should read as a
creature *in* the landscape. Shrink the whole line by a uniform factor **≈0.71** (Agumon 96 → 68),
preserving the relative sizing across evolutions:

| species | `displayHeight` old → new |
|---|---|
| Botamon | 64 → 45 |
| Koromon | 80 → 57 |
| Agumon | 96 → 68 |
| Greymon | 140 → 99 |
| MetalGreymon | 180 → 128 |
| SkullGreymon | 176 → 125 |

This is a **pure data edit** to `assets/data/species.json` (`sprite.displayHeight` per species) — no
code change; `PetComponent` already derives its scale from `displayHeight`. The radial menu's bubble
size (§B) is tuned against the new, smaller pet. Final values are confirmed on-device.

## Components & boundaries

- `lib/ui/hud/hud_overlay.dart` — **changed.** Sockets now render menu-button PNGs and take an
  `onOpenRoom(RoomConfig)` callback per socket instead of `onFeed/…`. Name plate + `StatusBadges`
  unchanged except the badge position nudge (fix the level-gauge overlap). No care icons here anymore.
- `lib/ui/hud/care_radial.dart` — **new.** Pure-widget radial menu: given the pet's anchor fraction,
  the four enable flags, and four `VoidCallback`s, lays out and animates the bubbles. No game imports;
  unit/widget-testable in isolation.
- `lib/ui/home_screen.dart` — **changed.** Owns `_careMenuOpen` state; builds the tap layers
  (pet-rect toggle + outside-close); passes the pet's live anchor + enable flags + care callbacks to
  `CareRadial`; passes `onOpenRoom` to `HudOverlay`; drives `game.setCareMenuOpen(bool)` to pause wander.
- `lib/game/vpet_game.dart` — **small change.** Expose the pet anchor (`double get petAnchorX` in [0,1],
  reuse `groundFractionForBiome`) and a `bool careMenuOpen` flag gating `wander.update` (alongside the
  existing sick / reacting guards). No logic-layer change.
- `lib/ui/shell/room_config.dart` — **changed.** `kRooms` becomes the six-room set (adds DigiVice,
  Database; drops Mapa from the list). Add `room_database.png` / `room_digivice.png` backgrounds (reuse
  an existing room bg as placeholder if a dedicated one isn't copied yet).
- `lib/state/` — **untouched** (pure logic layer stays Flutter/Flame-free; care rules unchanged).

## Testing

- **`care_radial` widget tests:** opens with N enabled bubbles; disabled bubbles are non-tappable and
  dimmed; tapping an enabled bubble fires its callback exactly once; layout places all four within the
  stage bounds for a given anchor.
- **HUD socket tests:** each socket, when tapped, invokes `onOpenRoom` with the expected `RoomConfig`.
- **Home wiring (widget test):** tapping the pet-rect toggles the radial; tapping outside closes it;
  the four care callbacks reach `game.*`; opening the menu sets `careMenuOpen`.
- **Pure/game test:** `wander` does not advance while `careMenuOpen` is true.
- **On-device (`/vpet-run`, landscape):** buttons seat in sockets pixel-perfect; tapping the pet opens
  the arc; icons (meat / poop / bandage / ball) read clearly; bubbles don't collide with the HUD; the
  pet reads as a small creature in the landscape at the new `displayHeight`s (§D).

## Out of scope

Real-game button gates (energy/evo/stage conditions); the actual room contents (Training, Battle, Shop,
Database, DigiVice interiors stay "em breve"); world-map/exploration and the position-driven map swap;
battle-context Battle-Items button; any change to the care rules or the `lib/state/` logic layer.
