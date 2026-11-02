# Ravenhill 3D — investigation prototype

This is a **separate experimental build** under `ravenhill-3d/`. It does **not** replace the original Case Files homepage.

## Run
Open `ravenhill-3d/index.html` through GitHub Pages or a local HTTP server. Internet is required for the Three.js module CDN.

## Controls
- Desktop: WASD to move, drag the scene to look, E to inspect.
- iPhone: on-screen arrows to move, turn buttons to look, Inspect to examine nearby evidence.
- End Turn: switches Detective / Forensic player and restores their own saved position and facing.

## Features
- First-person 3D hotel with lobby, kitchen, office, security, records.
- Seven inspectable evidence points, shared evidence notebook, 3 AP per turn.
- Separate player positions, mobile touch controls, basic collisions.
- Local save / reload in the same browser via localStorage.
- Preliminary accusation flow for Case 001.

## Limitations
- Primitive 3D meshes, **not photorealistic art**. No GLB/PBR asset pack yet.
- Single-device turn-taking, **not online multiplayer**.
- Case narrative and evidence are preliminary; the locked-room solution still needs full writing and proof.
- JavaScript was reviewed but mobile browser gameplay has not been fully tested.

## Next development milestones
1. Fix reported device-specific navigation issues.
2. Replace blockout meshes with original GLB assets and PBR materials; keep interaction positions independent of artwork.
3. Expand suspect interviews, full timeline and fair locked-room deduction.
4. Add Supabase-backed rooms and server-authoritative AP/turn handling.

Main branch and original `index.html` remain unchanged until review.
