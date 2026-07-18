# Sprite library builder — Digital Tamers Reborn art

Reorganizes the raw extracted dump
`C:\Users\felip\Documents\DigitalTamers02_extracted\sprites\` (67,755 cropped RGBA frames,
flat) into a browsable `organized/` library. Design spec:
`docs/superpowers/specs/2026-07-17-sprite-line-taxonomy-design.md`.

**The extracted data is git-ignored (Bandai/Toei IP, private use). These scripts are the tooling;
the output `organized/` lives next to `sprites/`, not in this repo.**

## What it produces (`DigitalTamers02_extracted/organized/`)

- `digimon/<name>/` — every named Digimon, once. `<pose>/` = overworld/vpet frames (`d###`);
  `battle/<pose>/` = battle frames (`b###`, which map 1:1 to the same `d###` id). Say a name → open
  its folder. 666 folders.
- `lines/<rookie>/<member>/` — hand-curated evolution families as **directory junctions** into
  `digimon/`. Each carries its canonical predisposed baby chain (agumon = Botamon→Koromon→Agumon→
  Greymon→MetalGreymon/SkullGreymon→WarGreymon). 7 lines so far.
- `ui/ effects/ backgrounds/ items/ npcs/ misc/` — non-Digimon art, heuristic-sorted.
- `README.md`, `LINES.md`, `lines/<line>/_line.md` — generated docs.

Materialized with **hardlinks** (canonical files) + **junctions** (line members): ~0 extra disk,
`sprites/` stays byte-identical. Read-only reference — editing a file here edits the source.

## Why lines are curated, not automatic

The game's evolution data (`obj_EvoCards_Step_0.gml`, 1909 edges + Jogress) is one dense **522-node
mesh** — shared babies (Botamon→5 in-trainings) and shared megas connect nearly everything, so
"reachable from a rookie" averages ~120 members. Clean lines require editorial spines. `curated_lines.json`
holds them; each spine edge is verified **reachable** in the game graph by `validate_lines.py`.

## Regenerate

```bash
# 1. build the plan (deterministic; reads the id-map + evolution GML + real sprite files)
python tools/sprite-library/build_manifest.py <out-dir>      # e.g. a scratch 'plan' dir
# 2. (optional) validate curated lines against the game graph
python tools/sprite-library/validate_lines.py                # run from the plan's parent
# 3. materialize hardlinks + junctions + docs
pwsh tools/sprite-library/materialize.ps1                     # edit $plan/$root paths inside
```

`build_manifest.py` reads `curated_lines.json` from its own directory. To add a line, append
`"<rookie-slug>": {"members":[ids...], "spine":[[parent,child],...]}` and re-run (2)+(3). Member ids
are `d###` ids from `meta/digimon-id-map.md`.

## Files
- `build_manifest.py` — parse + classify + emit hardlink/junction plan + docs (deterministic).
- `curated_lines.json` — the hand-authored evolution lines (id-based).
- `validate_lines.py` — checks each line's members have art and each spine edge is reachable.
- `materialize.ps1` — creates the hardlinks (P/Invoke CreateHardLink), junctions, copies docs.
