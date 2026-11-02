# REALM OF FORTUNE — Art asset structure

This folder is reserved for **actual game-ready art assets**. The current board uses runtime vector drawing in `scripts/main.gd`; it is not a finished illustrated map.

## Folders
- `backgrounds/`: portrait or landscape scene backgrounds, preferably WebP or PNG
- `tiles/`: individual terrain and encounter tiles with transparent backgrounds
- `characters/`: player sprites and animation sheets
- `props/`: trees, rocks, chests, buildings, and decorative pieces
- `ui/`: button, icon, panel, and HUD art
- `fonts/`: licensed fonts (Sarabun is downloaded by GitHub Actions at build time)

## Asset rules
1. Keep gameplay objects separate from the background so they remain interactive.
2. Use transparent PNG/WebP for sprites and consistent pivot/anchor positions.
3. Prefer lowercase kebab-case filenames (e.g. `forest-tree-01.png`).
4. Document image license, creator, and intended use before adding external assets.
5. Do not add a single flat illustration as a substitute for interactive game objects.
6. Avoid unsupported emoji glyphs in Godot UI; use real texture icons or Thai text instead.
