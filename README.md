# THE LOST FRONTIER: CASE FILES — V0.3

## What's new
- Three selectable playable cases: THE LAST GUEST, THE MISSING HOUR, THE SILENT GALLERY.
- Separate case evidence, locations, NPC testimony, deductions, accusations, and solutions.
- Actual WebP illustration assets integrated into the UI, cropped from the previously generated original game concept. This is not a complete sprite/animation system.
- Two-player hot-seat roles, with default Detective + Forensic Specialist. Four available professions, unique once-per-round abilities.
- 3 AP per player per turn; inspect, travel, talk, analyze, deduction board, and accusation.
- Browser localStorage save/resume.

## Run
Extract ZIP, keep index.html and assets/ together. Open index.html in a modern browser, or upload all files to a GitHub Pages repository. For iPhone, GitHub Pages is the easiest way to serve the game. No build tools or backend needed.

## How to play
Choose one of the three cases. Player 1 Detective and Player 2 Forensic are preselected. Select a place on the illustrated city map, travel there (1 AP), investigate (1 AP), talk to witnesses (1 AP), and analyze evidence (1 AP). Forensic can analyze physical evidence once per round for free; Detective can prove a deduction once per round for free when its two required clues have been analyzed. End turn to pass control to the other player. Open the evidence board and accuse once enough clues have been analyzed.

## Scope and limitations
This is an offline local hot-seat prototype, NOT real-time online multiplayer. The illustrated images are integrated assets from a generated concept, not yet individual animated character sprites. The 2nd and 3rd cases are shorter demonstration cases; they are not yet 45–90 minute fully authored stories. There is one save slot (new cases overwrite previous progress). The game's answers are stored in JavaScript, so a technically savvy player could inspect source to find solutions. There is no server-side validation or anti-cheat.

## Code guide
- `CASES`: all case-specific locations, evidence, witness statements, deduction rules, and solution.
- `ROLES`: professions and their unique skill.
- `state`: active investigation progress, AP, turn, player locations, and findings.
- `inspect`, `talk`, `analyzeOptions`, `deduction`, `skill`: gameplay actions.
- `accuse`: verifies culprit, method, motive, minimum evidence, and deductions.
- `refresh`: redraws UI based on game state.
- `save`/`resume`: local browser storage.

## Next
Build scene-specific layered original illustrations, walkable characters, multi-slot case save system, and Supabase-backed online lobby/state with server-side action validation.
