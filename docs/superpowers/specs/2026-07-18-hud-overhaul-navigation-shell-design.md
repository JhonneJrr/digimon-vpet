# HUD overhaul + navigation shell — design

_Design doc · 2026-07-18 · approved direction (see mockup in session)_

## Context

The app (v0.2) is a **single-screen** V-Pet: a Flame `VpetGame` (procedural biome parallax +
pet) behind a glass HUD (`top_status_bar`, `action_dock`, `status_badges`, `glass_panel`,
`hud_theme`). It works but (a) uses procedural art, not the real game's world, and (b) has no
screen structure — nowhere for the upcoming heavy mechanics (combat, training, shop, map) to live.

The sprite library is now organized (`DigitalTamers02_extracted/organized/`), which unlocked the
real game's art: **30 overworld maps** (`BG01`–`BG30`), **room screens** (`BG_TrainingRoom`,
`BG_EvoRoom`, `BG_JogressRoom`, `BG_Loja`, `BG_SelectMap`, `BG_Inventory`, `BG_PC`, `BG_Tamer_Info`,
`BG_challenge`, `BG_InfinityTower`…), **battle backdrops** (`bg_Btl_*`), and a full **HUD/button
set** (`spr_*_HUD`, `spr_*_Button`, icon sheets). Native art is landscape pixel-art, mostly
**538×300** (BG_TrainingRoom 536×192, BG01 196×120); the app is portrait mobile.

This overhaul makes the app **feel like the real game** and **opens the doors** for combat/training —
without building those mechanics yet.

## Goals

- Replace the procedural world with a **real map background** rendered pixel-perfect in a framed
  16:9 **scene**, pet composited inside it.
- Keep the tested glass HUD but blend in the **real game's UI art** (icons/frames) → the approved
  **hybrid** aesthetic.
- Add a **navigation shell**: home (pet care) + a menu opening **doors** to Training / Battle / Map /
  Shop / Evo-Bios, each a **stub room** using its real background + a "coming soon" state and back nav.
- Structure it so combat/training slot in later by filling a room's content slot — no refactor.
- Keep `lib/state/` pure/untouched; ship real art via the app's `assets/`.

## Non-goals

- No combat/training/shop/map-exploration logic. Rooms are stubs.
- No new evolution UI — evolution stays in the existing care loop.
- Not a from-scratch visual system. A **deeper second visual overhaul is explicitly deferred**
  (user's call); this is the functional/first-pass hybrid that unblocks mechanics.

## Design

### Visual model — the framed scene

A portrait "device" layout: glass **top bar**, a **16:9 scene** window (the real map), glass **action
dock**. The scene is the app's centerpiece.

- **`MapBackgroundComponent`** (new, `lib/game/`) — a Flame `SpriteComponent` that draws the current
  map sprite with `BoxFit.cover` into the 16:9 region, **anti-aliasing off / `FilterQuality.none`**
  so the low-res pixel art stays crisp when upscaled. Replaces `world_background.dart`'s procedural
  `SkyComponent`/`GroundComponent`/parallax (removed).
- The **pet stays a Flame component** on top of the map (composited in-engine), keeping the existing
  idle/bounce animation.
- **Home map is biome-driven:** reuse `biomeForStage` → a real map asset (e.g. nursery →
  `bg_AgumonHouse`). A small `biome→mapAsset` table (in the game layer) makes it swappable.

### HUD — hybrid

- Keep `top_status_bar` (name, stage/biome, needs) + `action_dock` (Feed/Clean/Med/Play) + glass
  primitives. Add a **menu button** (`☰`) to the top bar.
- Blend in real-game UI art where it reads well (dock icon frames, accent chrome). `hud_theme`
  gains references to the real icon assets. Panels stay glass for legibility.

### Navigation shell

- **`AppShell`** (`lib/ui/shell/app_shell.dart`) — hosts a Flutter `Navigator` with lightweight,
  low-animation routes. Home route = the V-Pet care screen.
- **`MenuSheet`** (`menu_sheet.dart`) — a glass bottom sheet listing the doors; opened from `☰`.
- **`RoomScreen`** + **`RoomConfig`** (`room_screen.dart`, `room_config.dart`) — one reusable screen:
  `RoomConfig { String title; String backgroundAsset; bool comingSoon; Widget? content; }`.
  - `comingSoon:true` → renders the real room background (pixel-perfect) + title + a "em breve"
    badge + a back button. This is every stub today.
  - Later, a real mechanic passes `content:` (the training/battle UI) and `comingSoon:false` — **the
    door opens with no shell changes**. This is the extensibility hinge.
- **Initial doors (stubs):** Treino (`BG_TrainingRoom`), Batalha (`bg_Btl_Magma_Mountain` or a
  chosen default), Mapa (`BG_SelectMap`), Loja (`BG_Loja`), Evo/Bios (`BG_EvoRoom`).

### Asset pipeline

The extracted art is git-ignored/external; the app can only ship what's under `assets/`. So:

- Copy a **selected subset** of PNGs from `organized/` into **`assets/game/backgrounds/`** and
  **`assets/game/ui/`**, register the dirs in `pubspec.yaml`, and **commit** them (private repo,
  consistent with the existing community sprites already shipped in `assets/`).
- Initial set: the home map(s) + the ~5 room backgrounds + the action/menu icon frames. A small
  script/list documents which files were copied (so it's reproducible from the library).
- Rendering config: pixel art loaded with anti-alias off; `BoxFit.cover` inside the 16:9 frame.

### Architecture / files

```
lib/
  ui/shell/
    app_shell.dart      # Navigator + routes; hosts home + rooms
    menu_sheet.dart     # glass bottom sheet of doors
    room_screen.dart    # reusable room (bg + title + comingSoon | content + back)
    room_config.dart    # RoomConfig data class + the door registry
  ui/
    home_screen.dart    # + menu button; otherwise the care screen
    hud_theme.dart      # + real icon asset refs
  game/
    map_background.dart  # NEW MapBackgroundComponent (replaces world_background)
    vpet_game.dart       # swap procedural bg -> map bg; pet unchanged
    (world_background.dart, biome_palette parallax bits retired)
assets/game/{backgrounds,ui}/   # committed real art subset
```

`lib/state/` (pure logic) is **untouched** — navigation and rendering are UI-only. `biomeForStage`
is reused, not changed.

### Extensibility for combat/training

The `RoomScreen.content` slot + the door registry are the seams. A future phase adds, per mechanic:
its `content` widget (the UI) and its logic in `lib/state/` (pure, tested). The shell, HUD, asset
pipeline, and rendering are already in place — no re-architecture.

## Testing / verification

- **Widget tests:** menu opens/closes; each door pushes its `RoomScreen`; stub shows background +
  title + "em breve" + back returns home; top bar shows the menu button on home only.
- **Keep** existing HUD tests (top bar, dock, badges) green.
- **Rendering** (can't assert headless): on-device smoke via `/vpet-run` — pixel-perfect map, pet
  composited, HUD legible over the scene, navigation flows.
- `flutter analyze` clean; full `flutter test` green (`/vpet-verify`).

## Risks / mitigations

- **Landscape art in portrait** → framed 16:9 scene (cover-fit) instead of full-bleed; the "device"
  framing is intentional and reads like a V-Pet screen.
- **Blurry upscaled pixel art** → anti-alias off / `FilterQuality.none` everywhere pixel art scales.
- **Asset bloat / IP** → ship only the selected subset; private repo; documented copy list.
- **Scope creep into mechanics** → rooms are stubs; the `content` slot is the only door to real UIs.

## Future (out of scope here)

- A deeper **second visual overhaul** (richer HUD, transitions, full real-UI adoption) — deferred by
  the user; this hybrid is the functional first pass.
- Real room implementations (training, battle, shop, map exploration) — each its own phase, mounting
  into the existing `RoomScreen.content` slot.
