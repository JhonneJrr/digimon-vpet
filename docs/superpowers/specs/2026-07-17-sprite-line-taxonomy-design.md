# Sprite library reorganization — hybrid name + line taxonomy

_Design doc · 2026-07-17 · supersedes the earlier "per-digimon + line index (no duplication)" plan_

## Context

Phase 0/1 extracted the full art of the user's own game **Digital Tamers Reborn (v2)** from
`DigitalTamers02\data.win` via UndertaleModTool (read-only). The result lives at
`C:\Users\felip\Documents\DigitalTamers02_extracted\` (git-ignored — Bandai/Toei IP, private use):

- `sprites/` — **67,755** tightly-cropped RGBA PNGs, flat, named `<spriteName>_<frameIndex>.png`.
- `meta/sprite_index.tsv` — 10,318 rows: `sprite_name, frame_count, type, width, height`.
- `meta/digimon-id-map.md` — authoritative `d###`→name map (**658/665** named, high confidence),
  reverse-engineered from `obj_Bios_Step_0` (`bios_data(name, family, elem, attr, d<ID>_idle,…)`)
  cross-validated against the `Digi_HUNT_*` wild-spawn scripts.
- `meta/dump/CodeEntries/` — 5,863 GML files (evolution graph, battle timelines, bios).
- `line_padded/` — earlier partial padded re-export of our core line (d1,d2,d3,d5,d85,d87 — **no
  d151**); a separate padded set, left as-is.

The flat 67k dump is unusable for the coming phases (battle, full roster, world). We want a clean,
browsable, reusable **`organized/`** library where **saying a name resolves directly to a folder**,
and where an evolution **family can be browsed together**.

This doc reflects the user's revised decision (a deliberate change from the earlier plan): organize
**physically by evolution line, with duplication**, so `agumon/` is a real folder holding the family
— no index lookup. Confirmed choices: **hybrid (name + line)** structure, **full roster (658)** scope,
**hardlink** materialization.

## Goals

- Every named Digimon resolves to a canonical folder by name, once: `digimon/<name>/`.
- Every evolution family is browsable as a physical folder: `lines/<rookie>/…`, duplicating shared
  members so branches and Jogress results appear under each line that reaches them.
- One Digimon folder holds **everything** about it: overworld/vpet poses **and** battle poses.
- Non-Digimon art (ui, effects, backgrounds, items, npcs) is sorted into its own top-level folders.
- The raw `sprites/` dump stays byte-for-byte intact and re-doable.
- The evolution graph is captured as data + human-readable per-line docs.

## Non-goals

- No changes to the Flutter app / `assets/` this pass — this is asset-library curation only.
- No re-export from `data.win` (we use the existing cropped `sprites/`); padded frames stay in
  `line_padded/` for the current line's in-game use.
- Not wiring these assets into the game (that's a later phase's `species.json` work).

## Design

### Folder layout

```
organized/
  digimon/<name>/                       # CANONICAL — every named Digimon exactly once
      idle/ walk/ eat/ win/ dmg/ …      #   overworld/vpet poses (from d###_<pose>)
      battle/atk01/ atkSP/ block/ crest_born/ …   # battle poses (from b###_<pose>)
  lines/<rookie>/                       # LINES — family grouping, members hardlinked in
      _line.md                          #   the family tree + evolution conditions
      <member>/ …                       #   each member = same per-name pose/battle subtree
  ui/        # buttons, hud, icons, fonts        (from spr_)
  effects/   # attack/status/FX sprites          (from spr_)
  backgrounds/  # maps + battle backdrops        (from bg_/BG*)
  items/     # item/consumable icons             (from spr_)
  npcs/      # NPC-only digimon (vendors, bosses not in a rookie line)
  misc/      # residual / unclassified (logged, never silently dropped)
  LINES.md       # index of every line and its members
  README.md      # how the library is organized + how to navigate
  manifest.tsv   # source_frame_path <TAB> target_relative_path  (one row per materialized link)
  COVERAGE.md    # counts: sources represented, digimon with/without art, unclassified residue
```

Every materialized file is a **hardlink** to the corresponding `sprites/` frame (same NTFS volume,
`C:`), so duplicating a member across N lines costs **0 extra disk** and is instant. Editing a file
in `organized/` would mutate the shared source — this library is **read-only reference**; edits for
the game happen in the Flutter `assets/` tree, never here.

### Line-cutting rules (the core semantics)

Operate on the evolution graph extracted from GML (see below). Nodes = Digimon (by `d###` id + name
+ stage); directed edges = `from → into` evolutions; Jogress edges have ≥2 parents.

- **Anchor = Rookie.** Every Digimon whose stage is **Rookie** (enum `Value_3`, e.g. Agumon d3)
  anchors a line `lines/<rookie-slug>/`. Slug = lowercase, spaces→`-`, parens stripped:
  "Agumon (Black)" → `agumon-black`, "V-mon" → `v-mon`.
- **Membership of line L(R):**
  - R itself.
  - **Upstream:** all Baby / In-Training ancestors that can evolve (transitively) into R.
    Shared babies (Botamon→Koromon feed many rookies) are **duplicated** into each such line.
  - **Downstream:** everything reachable from R by forward edges — Champion, Ultimate, Mega —
    **including every branch** (Greymon→MetalGreymon *and* →SkullGreymon→WarGreymon).
  - **Jogress / fusion:** a Jogress result (≥2 parents) is included in the line of **each** parent
    that can reach it. Duplicated, like any shared form.
- **Orphans:** a named Digimon reachable from no rookie line (pure NPC/boss/standalone) still gets
  its `digimon/<name>/` canonical folder; it simply does not appear under `lines/`. Clearly NPC-only
  sprites are additionally linked under `npcs/`.
- **Name collisions:** distinct ids that resolve to the same slug get the id appended, e.g.
  `greymon` vs `greymon-d373`. The `digimon/<name>/` folder name is unique per id.

### Pose & battle-sprite mapping

- `d###_<pose>` (overworld/vpet: idle/eat/walk/win/dmg/…) → `digimon/<name>/<pose>/`. Deterministic
  via the id-map; pose = the substring after `d<digits>_`.
- `b###_<pose>` (battle: atk01/atk02/atkSP/block/dmg/idle/jump/lose/walk/win/crest_born/masks…) →
  `digimon/<name>/battle/<pose>/`, after mapping the **22 distinct `b###` numbers** to species
  (an agent reads the battle GML/timelines; e.g. the extractor already spotted `b49_AtkGreymon`).
- Line folders receive the same per-member subtree (overworld + battle) by hardlink.
- Any `d###`/`b###` that cannot be mapped is linked into `misc/` and **logged** in `COVERAGE.md` —
  never silently dropped.

### Source of the evolution graph

- `obj_EvoCards_Step_0.gml` — **1,909** `evo_card_att(name, id, sprite, family, stage, attr, elem)`
  entries, grouped under the source-Digimon guard blocks; parsing the control-flow context yields
  `from → into` edges. `evo_card_att` defines the *target* card; the *source* is the enclosing block.
- `obj_JogressOptions_Step_0.gml` — the Jogress (fusion) options.
- Stage enum (observed): `Value_2`=In-Training, `Value_3`=Rookie, `Value_4`=Champion, and by
  extension `Value_5`=Ultimate, `Value_6`=Mega (to be confirmed during extraction).
- `digimon-id-map.md` already provides id→name + family/element/attribute.

## Execution pipeline

Ultracode is on; the independent investigation/classification steps fan out as a **Workflow**, then
deterministic manifest-building and hardlinking are scripted (not delegated to LLMs).

1. **Extract evolution graph** — agent(s) read `obj_EvoCards_Step_0` + `obj_JogressOptions_Step_0`
   → structured edges `{fromId, fromName, intoId, intoName, stage, jogressParents?}`.
2. **d### → name + pose** — script over `sprite_index.tsv` + id-map (deterministic).
3. **b### → species** — agent reads battle GML/timelines → `{bNum: name, evidence, confidence}`.
4. **Classify `spr_` (1,317) + `bg` (147)** — script heuristics first; agent classifies the fuzzy
   residual → `{name: category}` over {ui, effects, backgrounds, items, npcs, misc}.
5. **Build `manifest.tsv`** — script joins all of the above → for each source frame, 1+ target
   paths (canonical `digimon/`, each line copy, `battle/`, or a non-digimon folder). Compute line
   membership by graph traversal (rookie anchors → upstream + downstream + Jogress).
6. **Materialize** — script creates each target as a **hardlink** to its source frame.
7. **Index & docs** — generate `LINES.md`, per-line `_line.md` (tree + conditions), `README.md`,
   `COVERAGE.md`.
8. **Verify** — assert: every source frame represented ≥1×; every named Digimon has a folder; no
   dangling links; residue in `misc/` is logged, not hidden. Spot-check a known line (Agumon) and a
   Jogress case.

## Testing / verification

- **Determinism:** re-running steps 2 & 5 on unchanged inputs yields an identical manifest.
- **Coverage assertions** (fail loud): `sources_linked + sources_in_misc == 67,755`; every id in the
  id-map with sprites has a `digimon/<name>/`; every rookie has a `lines/<rookie>/`.
- **Link integrity:** each `organized/` file shares an inode with its `sprites/` source; deleting
  `organized/` leaves `sprites/` untouched (hardlink semantics).
- **Human spot-check:** open `lines/agumon/` — expect Botamon→Koromon→Agumon→Greymon→
  MetalGreymon/SkullGreymon→WarGreymon, each with idle/walk/eat/battle poses. Confirm a Jogress mega
  appears under each contributing line.

## Risks / mitigations

- **Wrong line cut** (mis-parsed guards) → agent extraction is verified against the known Agumon line
  and a Jogress example before the full manifest is trusted.
- **Ambiguous `b###`/`spr_`** → default to `misc/` + log; never guess silently.
- **Hardlink edit hazard** → documented in `README.md`; library is read-only reference.
- **Redo cost** → `sprites/` untouched; `organized/` is fully regenerable from the manifest.
