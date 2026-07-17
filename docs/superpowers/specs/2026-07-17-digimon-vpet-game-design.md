# Digimon V-Pet Game — Design Document

**Date:** 2026-07-17
**Status:** Approved design, ready for implementation planning

## 1. Overview

A Tamagotchi/Digivice-style virtual pet game for **Android**. The player raises a
Digimon that grows hungry, makes messes, can get sick, evolves through life stages,
and can die from neglect. Modeled on the original Digital Monster V-Pet loop, at an
**accelerated** time pace.

## 2. Tech Stack

- **Engine/framework:** Flutter + Flame (2D game engine on top of Flutter).
- **Rationale:** Fully CLI-automatable pipeline (`flutter create` / `flutter test` /
  `flutter build apk`) with no GUI editor required; all logic in Dart; Flame has
  native spritesheet/animation support matching our assets; mature Dart-only plugins
  cover notifications, background work, and storage.
- **Language:** Dart.
- **Supporting packages:**
  - `flame` — game loop, sprite animation, components.
  - `hive` (or `shared_preferences`) — local persistence of pet state.
  - `flutter_local_notifications` — "your Digimon needs you" reminders.
  - `workmanager` — schedules the periodic notification nudge (does NOT mutate game
    state in background; see Section 5).

## 3. Project Structure

```
digimon/
  assets/
    sprites/            # character sprite sheets (already downloaded)
    ui/                 # our original pixel-art UI icons (created in-repo)
  lib/
    game/               # Flame components, sprite animation, on-screen layout
    state/              # pet data model + persistence + pure logic (the "brain")
    ui/                 # Flutter screens outside the canvas (death screen, etc.)
  test/                 # unit tests for state/logic (pure functions)
  docs/superpowers/specs/
```

## 4. Assets & Visual Direction

- **Character sprites:** community collection (permission granted for use). Each PNG
  is a 3×4 grid (12 frames). A mapping of grid-index → animation (idle, eating, sick,
  happy, etc.) must be established during implementation.
- **Evolution line (downloaded):** Botamon (Baby I) → Koromon (Baby II) →
  Agumon (Child) → Greymon (Adult) → **MetalGreymon / SkullGreymon** (Perfect, branch).
- **UI direction:** ORIGINAL pixel-art UI inspired by the V-Pet spirit — NOT a copy of
  Bandai's physical device (avoids trademark risk, fits a phone screen).
  - Status/menu icons (food, poop, heart, medicine, skull): created in-repo as small
    pixel-art PNGs (16×16 / 32×32), CC0/ours. May later be swapped for a free-licensed
    pack (e.g. Kenney.nl, public domain).
  - Frame and buttons: drawn in Flutter/Flame code, clean pixel-art style.
- **IP note:** character sprites carry usage permission, but the "Digimon" name/logo
  and device design are Bandai trademarks. Public (Play Store) release would require
  revisiting branding.

## 5. Time Model (Accelerated)

Android Doze/battery restrictions make reliable background ticking impossible, so we
follow the physical-toy pattern:

- Persist `lastTick` (timestamp). On app open/resume, compute elapsed time and apply
  accumulated changes at once (hunger rises, poop may appear, etc.).
- While the app is open, a Flame timer updates stats in real time every few seconds.
- A single central `GAME_SPEED` multiplier controls all rates (set to accelerated;
  trivially adjustable in one place).
- **Initial tuning (to be refined):** hunger 0→max in ~5 min; poop every ~3–4 min;
  each evolution stage ~15–20 min of active care.

## 6. Pet Data Model

Single state object, persisted locally:

- `stage`: Baby1 | Baby2 | Child | Adult | Perfect(Metal|Skull)
- `hunger`: 0–max
- `cleanliness` / poop count on screen
- `health`: healthy | sick
- `happiness` / affection
- `careScore`: accumulated average of how well cared-for (decides Metal vs Skull)
- `stageStartedAt`: timestamp entering current stage (drives evolution timing)
- `lastTick`: timestamp for elapsed-time computation
- `isDead`: bool

## 7. Player Actions (Main Screen)

Digivice-style single screen: animated pet centered, row of buttons below.

- 🍖 **Feed** — lowers hunger.
- 🧹 **Clean** — removes poop from screen.
- 💊 **Medicine** — cures sickness (button only reacts when the pet is sick).
- ❤️ **Play** — raises happiness/affection; feeds `careScore` toward the Metal/Skull branch.

Lightweight visual indicators: status icons appear on screen when attention is needed
(hunger, poop, skull when sick) — no percentage bars. Irrelevant buttons are dimmed.

## 8. Evolution

- Each stage has a target time (accelerated). On reaching it, the pet evolves to the
  next sprite.
- **Greymon → Perfect branch:** check accumulated `careScore`. Above threshold →
  **MetalGreymon**; below → **SkullGreymon**. Simple average rule, no complex
  discipline system.

## 9. Death (Faithful to Original)

- If hunger stays maxed too long OR sickness is left untreated, the pet dies.
- Simple "end" screen → restart from the egg (Botamon). Progress resets, giving weight
  to care decisions.

## 10. Notifications & Background

- `flutter_local_notifications` + `workmanager`: a periodic "your Digimon needs you"
  reminder when the app has been closed too long.
- The notification only nudges; state is recomputed on reopen (Section 5). No game-state
  mutation happens in the background.

## 11. Testing

- Core logic (stats, time computation, evolution, death conditions) lives in `lib/state`
  as **pure functions**, decoupled from rendering.
- Unit-tested with `flutter test` — no rendering required. This is the critical
  correctness surface.

## 12. Out of Scope (This Version)

- Battles / training.
- Discipline mechanic beyond the simple `careScore` average.
- Sleep/weight stats, multiple evolution branches beyond the single Metal/Skull fork.
- Home-screen widget (would require a small native Kotlin layer — deferred).
- Public store release / branding cleanup.

## 13. Tooling Note

`graphify` knowledge-graph CLI (`graphifyy`) is installed. Graph build + Claude Code
hook wiring is deferred until after the Flutter project is scaffolded (nothing to index
yet). Dart tree-sitter support to be verified at activation.
