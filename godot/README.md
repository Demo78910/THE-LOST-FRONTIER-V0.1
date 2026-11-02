# REALM OF FORTUNE — Godot edition

Native Godot 4.4+ prototype built for a mobile-first workflow.

## Structure
- `project.godot` — engine configuration
- `scenes/main.tscn` — entry scene
- `scripts/main.gd` — 2–6-player pass-and-play, turn handling, dice, routes, encounters, potions, save/load
- `.github/workflows/godot-preview.yml` — cloud validation and Web export

## Important
The old HTML game at the repository root remains intact. This is an **independent prototype**; it does not import the existing localStorage save. Visuals are currently procedural placeholders, not the final diorama art.

Godot web export can be tested on iPhone but may behave differently from native iOS. An iOS .ipa build requires Apple signing and a macOS build environment.

## iPhone-only development workflow
1. Ask ChatGPT to modify Godot files on GitHub.
2. GitHub Actions runs headless import and Web export.
3. Open the preview at `https://demo78910.github.io/THE-LOST-FRONTIER-V0.1/godot-preview/` after a successful workflow run.
4. Review gameplay on iPhone and request changes.
