# Digimon V-Pet — project guide

A Tamagotchi-style Digimon virtual-pet game for **Android**, built with **Flutter + Flame**.
Current status, decisions, and roadmap live in [`PROGRESS.md`](PROGRESS.md) — read it first when picking the project back up.

Environment (this machine): Flutter is at `C:\Users\felip\flutter\bin` (NOT on the default PATH — prepend it), `JAVA_HOME=C:\Program Files\Android\Android Studio\jbr`, Android SDK at `%LOCALAPPDATA%\Android\Sdk`. Use `flutter test` / `flutter analyze` / `flutter build apk`. The app has no native code (NDK removed) and disables R8 for release (see PROGRESS.md).

## How to work here — always use Superpowers

This project is built with the **Superpowers** workflow. Keep using it every session:

- **New feature or behavior change** → invoke `superpowers:brainstorming` FIRST (explore intent + design), then `superpowers:writing-plans`, then execute with `superpowers:subagent-driven-development`. Do not jump straight to code.
- **Any bug, crash, or unexpected behavior** → invoke `superpowers:systematic-debugging` FIRST — find the root cause with evidence before proposing a fix.
- **Before claiming anything is done/fixed** → `superpowers:verification-before-completion` (actually run it and show the output).
- Adversarially review substantial changes (dispatch a reviewer subagent) before merging.

## Navigating the code — use graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

Rules:
- For codebase questions, first run `graphify query "<question>"` when graphify-out/graph.json exists. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).
