# MallCross

[![CI](https://github.com/NickSanft/MallCross/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/NickSanft/MallCross/actions/workflows/ci.yml)
[![Release](https://github.com/NickSanft/MallCross/actions/workflows/release.yml/badge.svg)](https://github.com/NickSanft/MallCross/actions/workflows/release.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

First-person 3D mall exploration. Each in-game day you walk to a food court table and solve a real NYT-style crossword — your choice of **5x5 MINI**, **9x9 MIDI**, or **15x15 FULL**. Solving earns **Woints**, the in-game currency you spend at mall stores on cosmetic items (visible on hands/shadow) and functional items that modify puzzle UX (pencil mode, check-letter, hint dialogue with NPCs).

Lo-fi PS1/N64 vibe: vertex-snap, point-filtered low-res textures, distance fog, procedural footsteps.

## Download

Pre-built binaries are attached to the [latest release](https://github.com/NickSanft/MallCross/releases/latest):

- **Windows x86_64** — single `MallCross.exe` (~100 MB, self-contained).
- **Linux x86_64** — single `MallCross.x86_64` ELF (~70 MB, self-contained). Mark executable (`chmod +x`) and run.

No installer, no dependencies — Godot's runtime is statically linked and all game data is embedded in the binary.

## Gameplay loop

1. Wake up in your apartment, walk to the mall.
2. Pick a food court table by difficulty (MINI / MIDI / FULL).
3. Solve the daily crossword. Each day the puzzle rotates from a hand-curated bank; streak bonuses stack.
4. Cash out Woints — currently spend them at Coffee Shop (check-letter ability), Bookstore (pencil mode), or chat to friendly NPCs for puzzle hints.
5. Return to your apartment, sleep, advance to the next day.

## Controls

| Input | Action |
|---|---|
| WASD | Move |
| Mouse | Look |
| Space | Jump |
| Shift | Sprint |
| E | Interact (tables, shops, NPCs, bed) |
| Esc | Settings / pause |
| **In crossword:** | |
| A-Z | Type letter |
| Backspace | Delete |
| Arrows | Move cursor |
| Tab | Toggle across/down |
| Backtick (\`) | Pencil mode |
| Slash (/) | Check letter (if you've bought the perk) |

## Tech

- **Engine:** Godot 4.6.1-stable (GDScript)
- **Tests:** [GUT](https://github.com/bitwes/Gut) 9.4 — 320 unit tests run headlessly on every push
- **CI:** GitHub Actions — parse-check, smoke-run, puzzle validator, full GUT suite
- **Release pipeline:** matrix-builds Linux + Windows binaries on tag push and attaches them to a GitHub Release
- **Puzzle generator:** in-house backtracking constraint solver (MRV + cross-slot validation + no-duplicate-word) against a curated ~5,100-word list. Used to bootstrap MIDI/FULL grids before hand-cluing.

## Local development

1. Install [Godot 4.6.1-stable](https://godotengine.org/download/archive/4.6.1-stable/) (mono or non-mono — the project is pure GDScript).
2. Open the project: `godot --path .`
3. Press F5 to run, or `godot --headless --quit-after 60 res://scenes/Main.tscn` to smoke-test.

### Running tests

GUT lives at `addons/gut/`. From the project root:

```bash
godot --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://tests/ -gexit
```

CI runs this same command on every push.

### Generating a new puzzle grid

```bash
godot --headless -s res://tools/puzzle_generate.gd -- <mini|midi|full> <output.json> [seed]
```

Generator fills the grid with real words from the bundled wordlist, writes `"TODO: <ANSWER>"` placeholders in each clue, and the author then edits the clue text and runs `tools/puzzle_validate.gd` before committing.

### Validating puzzles

```bash
godot --headless -s res://tools/puzzle_validate.gd -- res://data/puzzles/<file>.json
```

The validator checks block-pattern symmetry, clue numbering, word slot lengths, and grid/clue consistency.

## Roadmap

Full history and per-phase notes live in [CHANGELOG.md](CHANGELOG.md). Highlights:

- **Phase 0–3:** Project skeleton, first-person controller, mall geometry, PS1 shader.
- **Phase 4–6:** Crossword data model, interactive grid UI, daily rotation, profile + settings persistence.
- **Phase 7–8:** Shops, Woints economy, perks, NPC dialog with per-puzzle hints, footstep audio.
- **Phase 9:** Hint roster + dialog polish.
- **Phase 10:** Settings menu, reset-save, real 9x9 MIDI + 15x15 FULL puzzles, constraint-solver generator.
- **Phase 11 (v1.0.0):** Build pipeline (Linux + Windows binaries via GitHub Actions), MIT license, README polish.

## License

[MIT](LICENSE) © 2026 Nick Sanft.
