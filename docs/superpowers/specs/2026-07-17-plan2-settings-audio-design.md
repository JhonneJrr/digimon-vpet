# Digimon V-Pet — Plan 2: Settings, Lockable HUD Color & Audio — Design Document

**Date:** 2026-07-17
**Status:** Approved design, ready for implementation planning
**Follows:** `2026-07-17-hud-glass-redesign-design.md` (Plan 1, shipped). This closes the
visual/UX arc before the next cycle (gameplay expansion — training/battles).

## 1. Overview

Plan 1 shipped the glass HUD + parallax biome world with the HUD accent **derived**
from the biome and audio/settings explicitly deferred. Plan 2 finishes that arc:

- A **settings screen** (new), reached from the top-bar gear.
- **Player-lockable HUD color** (biome-auto by default, or a locked preset swatch).
- **Audio** — event-based Digimon SFX (the classic V-Pet device sounds), with a mute toggle.
- Fix the top-bar **gear icon** (currently a hardcoded, wrong glyph) and wire it.

No gameplay changes. The care loop, evolution, death, persistence, and the Plan-1 HUD are untouched except where noted.

## 2. Goals & Non-Goals

**Goals**
- Give the player control over sound (mute) and HUD accent (auto vs a locked preset).
- Make the pet feel alive with the authentic per-event V-Pet sounds.
- A small, glass-styled settings screen with a couple of quality-of-life extras.

**Non-goals (deferred / backlog)**
- Background music / ambience (SFX only this cycle).
- A full RGB/HSV color picker (preset swatches only).
- Per-Digimon unique cries (the original Ver.1–6 devices used shared per-event beeps; per-monster voices are a modern-device/game feature — a possible future enhancement).
- Any gameplay mechanic (training, battles) — that is the **next** cycle, not this one.

## 3. Audio

### 3.1 Nature of the sounds (research finding)

The original Digimon V-Pet (Ver.1–6, the Botamon→Greymon line this game emulates) has
**no per-Digimon voice**. Its buzzer plays short melodies per **event** (eat, happy/affection,
refuse, evolve, call-for-attention, death), identical across Digimon. So audio is modeled
**per event**, not per monster. (Confirmed against a faithful emulator, `mabuchner/vpet-emu-zepp`
`utils/sound.js`, which reimplements the device's buzzer/frequency/envelope rather than playing samples.)

### 3.2 Asset sourcing (IP note)

The authentic recordings are **Bandai IP** — the same category as the existing character
sprites, which is already why this repo is **private**. Using them does not change or
resolve that; it is accepted for this personal, private project.

There is **no clean public archive** of these files — they live embedded in fan
emulators/simulators and in soundboards (e.g. the 101soundboards "Digivice" board). So the
audio system is designed **asset-agnostic**: it plays whatever WAV/MP3 files are present under
`assets/audio/` for each event. Actual clips are obtained during implementation from the best
accessible source (Digivice soundboard clips), and any event lacking a clean clip gets an
**authored placeholder beep** (public-domain, ours) in that slot — the same "placeholder,
refine later" stance used for the Fluent icons in Plan 1. Sources are swap-friendly.

### 3.3 Sound events

| Event | Trigger |
|---|---|
| `eat` | `feed()` |
| `care` | `play()` (affection) |
| `clean` | `clean()` |
| `medicine` | `giveMedicine()` (only when it actually cures) |
| `evolve` | stage advances in `checkEvolution` |
| `death` | pet transitions to `isDead` |
| `call` *(optional)* | pet enters a `needsAttention` state |

### 3.4 Design

- Add `flame_audio` (official Flame bridge, bundled-asset playback, offline — fits the
  offline-first constraint; no native beyond what it already needs). Pin a version compatible
  with the pinned `flame ^1.37.0`.
- **`AudioService`** depends on a small **`SoundPlayer` interface** (`play(String asset)`,
  `preload(List<String>)`) so tests inject a fake and assert behavior without real audio.
  The production impl wraps `flame_audio` (`FlameAudioSoundPlayer`).
- `AudioService.play(SfxEvent e)` maps the event → asset path and plays it **unless muted**.
  Rapid-repeat events (button mashing) use `flame_audio`'s pooled playback.
- Muted state comes from preferences (§4) and is honored live.
- Wiring: `VpetGame` calls `AudioService.play(...)` from its action handlers (`_act`) and from
  the evolution/death transitions in `update`. `AudioService` is injected into `VpetGame`
  (constructor), defaulting to a no-op player in tests that don't care about sound.

## 4. Preferences Store

Player preferences are **not pet state** — kept out of `Pet`/`PetRepository`.

- `AppPreferences` value object: `bool soundMuted`, `int? hudColorOverride` (ARGB; `null` = auto).
- `PreferencesRepository` interface: `Future<AppPreferences> load()`, `Future<void> save(AppPreferences)`.
- `SharedPrefsPreferencesRepository` — one JSON blob under a distinct key
  (`app_prefs`, separate from `pet_state`). No new persistence dependency (`shared_preferences`
  is already present).
- A `FakePreferencesRepository` for tests.

## 5. Settings Screen

New `lib/ui/settings_screen.dart`, glass-styled (reuses `GlassPanel`), pushed from the
top-bar gear. Sections:

1. **HUD color** — a toggle between "Follow biome (auto)" and "Locked color", plus a row of
   preset **swatches** (the 6 biome accents + a few neutrals). Picking a swatch sets
   `hudColorOverride`; choosing auto clears it (`null`).
2. **Sound** — a mute toggle bound to `soundMuted`.
3. **Restart / hatch new egg** — a button that opens a **confirmation dialog**; on confirm,
   calls `game.restart()` and pops back. (Confirmation required so it can't wipe progress by accident.)
4. **Credits** — static attributions: Fluent Emoji (MIT), the character sprite collection
   (community/Bandai IP), and the V-Pet sounds (Bandai, fan-preserved).
5. **Version** — footer showing `kAppVersion` (a plain string constant, no new dependency).

Changes persist immediately via `PreferencesRepository`. On returning to `HomeScreen`, the HUD
reflects the new override/mute (see §6).

### 5.1 Preset swatches

A constant list of ~8 accent colors: the six `BiomePalette` accents plus 1–2 neutrals
(e.g. white, a soft grey). All chosen to stay legible on the glass surfaces.

## 6. HUD Color Resolution

`hudAccentFor` gains the override: `Color hudAccentFor(Pet pet, {Color? override})` returns
`override ?? paletteForBiome(biomeForStage(pet.stage)).accent`. `HomeScreen` loads
`AppPreferences` on init, holds them in state, passes the override into `TopStatusBar` (and any
other accent consumer), and re-reads/`setState`s after the settings screen returns so a newly
locked/cleared color takes effect immediately.

## 7. Gear Icon Fix

The Plan-1 top bar used a hardcoded `IconData(0xe8b8, fontFamily: 'MaterialIcons')` that renders
as a wrong (trash-can-like) glyph. Replace it with the real `Icons.settings` (importing
`package:flutter/material.dart` where needed), and wire its `onTap` to push the settings screen.

## 8. Data / Wiring Summary

- `VpetGame({required repo, AudioService? audio, int Function()? clock})` — audio injected,
  defaults to a no-op player.
- `HomeScreen` owns: the `VpetGame`, an `AudioService` (real `FlameAudioSoundPlayer`), and the
  loaded `AppPreferences` (mute → AudioService, override → HUD). It pushes `SettingsScreen`,
  passing current prefs + `PreferencesRepository` + the `game` (for restart).
- Nothing in `lib/state/` gains a Flutter/Flame import. File placement (pinned to avoid
  ambiguity): the pure `AppPreferences` value object and the `PreferencesRepository` interface
  live in `lib/state/`; the `SharedPrefsPreferencesRepository` impl also in `lib/state/`
  (mirrors `PrefsPetRepository`). The `SoundPlayer` interface + `AudioService` + the
  `FlameAudioSoundPlayer` impl live in `lib/game/` (they touch `flame_audio`). `SfxEvent` is a
  plain enum in `lib/game/` alongside `AudioService`.

## 9. Testing

- **Unit:** `PreferencesRepository` round-trip (fake/mock prefs); `hudAccentFor` override
  precedence (override wins over biome; `null` falls back to biome); `AudioService` mute-gating
  (with a `FakeSoundPlayer` — asserts `play` is/ isn't called based on `muted`, and that each
  event maps to the right asset).
- **Behavioral widget tests:** mute toggle persists; picking a swatch sets the override and
  auto clears it; the restart button shows a confirmation and only restarts on confirm; tapping
  the gear opens the settings screen.
- **No pixel golden tests** for icon/asset-bearing widgets (Plan-1 lesson: headless
  `flutter test` can't render `Image.asset`; behavioral tests + on-device checks instead).
- **On-device (`/vpet-run`):** confirm SFX actually play on actions/evolution, mute silences
  them, the gear opens settings, a locked swatch changes the HUD accent, and restart works.
- Gate every task with `/vpet-verify` (analyze + full suite); final whole-branch review with the
  `flutter-flame-reviewer` agent.

## 10. Versioning / Docs

- Introduce `kAppVersion` (e.g. `"0.2.0-beta"`) shown in Settings; bump `pubspec.yaml` version
  to match the milestone.
- Update `PROGRESS.md` (currently stale — still says "PR #1 open", empty backlog) to reflect
  the shipped HUD redesign (Plan 1) and this Plan 2, and to record gameplay expansion
  (training/battles) as the next planned cycle.

## 11. Out of Scope (This Version)

- Background music / ambience; full color picker; per-Digimon unique cries.
- Gameplay mechanics (training, battles, more evolutions/roster) — the **next** cycle, to be
  brainstormed separately.
