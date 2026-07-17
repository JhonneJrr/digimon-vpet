---
name: vpet-verify
description: "Use when verifying the Digimon V-Pet Flutter project is healthy — before claiming any change is done/fixed, before committing, before merging, or whenever the user asks to run tests / analyze / check the build. Handles this machine's Flutter environment quirks (Flutter is NOT on PATH; JAVA_HOME must be set) so `flutter` commands don't fail with 'command not found' or a JDK error."
---

# /vpet-verify

Run the project's health gate — `flutter analyze` + `flutter test` — with this
machine's environment set up correctly, and report the real output.

**Core principle:** evidence before assertions. Never claim "done", "fixed", or
"passing" for a code change without running this and showing the output.

## When to use

- Before saying any change is done / fixed / working.
- Before `git commit` or merging a branch.
- When the user asks to run tests, analyze, or check the build.
- After a subagent reports a task complete, to confirm independently.

**When NOT to use:** pure docs/spec/markdown changes with no `.dart` touched —
there's nothing to compile or test.

## The environment (why this skill exists)

On this machine Flutter is **not on PATH** and Android's JDK must be pointed at
explicitly. Every raw `flutter ...` call fails without this preamble:

- Flutter SDK: `C:\Users\felip\flutter\bin`
- `JAVA_HOME`: `C:\Program Files\Android\Android Studio\jbr`

## Run it

Primary (PowerShell — matches the project's documented flow):

```powershell
$env:Path = "C:\Users\felip\flutter\bin;" + $env:Path
$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
Set-Location "C:\Users\felip\Documents\digimon"
flutter analyze
flutter test
```

Bash-tool equivalent (POSIX shell):

```bash
export PATH="/c/Users/felip/flutter/bin:$PATH"
export JAVA_HOME="C:/Program Files/Android/Android Studio/jbr"
cd "C:/Users/felip/Documents/digimon"
flutter analyze && flutter test
```

## Reading the result

| Signal | Meaning |
|---|---|
| `No issues found!` (analyze) | Lint/static analysis clean. |
| `All tests passed!` (test) | Full suite green. |
| `analyzer` warnings/errors | Fix before claiming done — this project keeps analyze clean. |
| any `-N: ... [E]` / failing test | Not done. Report the failure verbatim; do not proceed to commit. |

Report both outputs. A green analyze with a failing test (or vice-versa) is a
FAIL — both must pass.

## Notes

- First run after a dependency change auto-runs `flutter pub get`; that's normal.
- Widget/golden HUD tests run headless here. Anything needing a real screen
  (blur/`BackdropFilter` perf, actual rendering) is out of scope for this gate —
  use `/vpet-run` on a device for that.
