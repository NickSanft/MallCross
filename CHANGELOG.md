# Changelog

All notable changes to MallCross are documented here. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Pre-1.0 minor versions mark phase boundaries.

## [Unreleased]

## [0.2.0] - 2026-05-22 — Phase 2: Mall greybox

### Added
- `scripts/MallLayoutMath.gd` — pure static helpers (`store_z_positions`, `store_front_x`, `food_court_table_positions`, `player_spawn_position`, `is_inside_box`). Centering math for the store run lives here so layout tweaks (more stores, different spacing) don't require touching geometry code.
- `scripts/MallGreybox.gd` — programmatic greybox builder:
  - 8 m × 40 m corridor with 5 m ceiling and 4 corridor overhead lights.
  - 6 colored store-front facades (3 per side, 10 m wide, 1.5 m gaps) flush against the inside of the corridor walls, each labeled `STORE 1`…`STORE 6` via `Label3D`.
  - 20 m × 18 m food court extension at the +Z end with 3 tables at `MINI`, `MIDI`, `FULL` positions — Phase 4 will wire interaction prompts to these.
  - Closed entrance endcap at the −Z end (mall entrance comes later).
  - Player auto-positioned 3 m inside the entrance, facing into the mall.
- `scenes/MallGreybox.tscn` — Node3D with `MallGreybox.gd` + a `Player.tscn` instance.
- `scenes/Main.tscn` now instances `MallGreybox.tscn`.
- `tests/test_mall_layout_math.gd` — 21 GUT tests covering store centering, side symmetry, spacing math, food-court table layout, player spawn calculation, and AABB containment.

### Removed
- `scripts/TestRoom.gd`, `scripts/TestRoom.gd.uid`, `scenes/TestRoom.tscn` — Phase 1 scaffolding was always slated for deletion at Phase 2, per the CHANGELOG note on `v0.1.0`.

### Why it matters
With a navigable mall in place, the next four phases have concrete world coordinates to attach to: Phase 3's crossword logic ships independently, Phase 4 binds it to the three labeled food-court tables, Phase 6 fills in the store interiors behind the colored facades, and Phase 9 spawns NPCs along the corridor. The layout math is exhaustively tested so re-tuning corridor width or store count is a one-line change with no surprises.

### Architecture
- Same pattern as Phase 1: pure helpers (`MallLayoutMath`) separated from node-bound builders (`MallGreybox`). The builder is a thin orchestrator — it reads layout constants, asks `MallLayoutMath` where things go, and emits `StaticBody3D` boxes via a single `_make_box` helper.
- All geometry is generated in `_ready` rather than authored as a `.tscn`. Trade-off: scenes are easier to inspect in the editor, but code is faster to iterate on, easier to diff, and trivially reusable for variant malls (different floor plans, store counts, etc.) — the kind of variation Phase 7+ will want.
- Store-front facades are thinner (0.2 m) than the corridor walls (0.4 m) and sit flush against the corridor-facing side. This avoids Z-fighting while keeping the visual hierarchy clear (colored facades pop against a neutral corridor).

### UX details
- Mall is fully enclosed — no escape geometry; collision tested by walking into every wall on the smoke run.
- Difficulty labels above each food-court table are billboarded so they're readable from any angle.
- Player faces `+Z` on spawn so the first thing visible is the corridor stretching away to the food court.

### Tests
- `tests/test_mall_layout_math.gd` — 21 GUT tests across all five helpers. Total project test count: 41/41 across 3 scripts.
- CI 60-frame headless smoke-run boots the full mall scene without runtime errors.

### Pre-push checklist (Phase 2)
- [x] `godot --headless --import` clean.
- [x] `godot --headless --quit` exit 0.
- [x] `godot --headless --quit-after 60 res://scenes/Main.tscn` exit 0.
- [x] GUT: 41/41 tests passing across 3 scripts, exit 0.
- [x] TestRoom artifacts deleted (no orphan `.uid` files).

### Known limitations
- **No navmesh yet** — deferred from the original Phase 2 plan to keep this commit narrow. Navmesh baking will land just before Phase 9 (NPCs), or as its own sub-phase if anything else needs path-finding sooner.
- Store fronts are visually solid — no doors, no interiors. Phase 6 cuts doorways and adds shop interiors.
- Lighting is uniform omni-light placement, not styled. Phase 8's PS1/N64 art pass replaces this with a hand-tuned setup.
- No floor markings (mall directory tiles, store signage above doors). All store identification is via `Label3D` text.

[0.2.0]: https://github.com/NickSanft/MallCross/releases/tag/v0.2.0

## [0.1.0] - 2026-05-22 — Phase 1: First-person controller

### Added
- `scripts/MovementMath.gd` — pure static helpers (`compute_horizontal_velocity`, `speed_for_input`, `head_bob_offset`, `clamp_pitch`, `mouse_yaw_delta`, `mouse_pitch_delta`). Dependency-free so they're exhaustively unit-testable without instantiating `CharacterBody3D`.
- `scripts/Player.gd` + `scenes/Player.tscn` — `CharacterBody3D` first-person controller:
  - WASD movement, sprint on Shift (5.0 / 8.5 m/s).
  - Space to jump (4.8 m/s initial velocity), gravity from project settings.
  - Mouse-look with 90° pitch clamp.
  - Distance-based head-bob (cycles per meter, not per second — freezes when standing still).
  - Esc toggles mouse capture for ALT-tab and dev workflow.
  - Headless guard on `_ready` so `--quit-after` smoke-runs don't try to capture the mouse in CI.
- `scripts/TestRoom.gd` + `scenes/TestRoom.tscn` — 24x24 m programmatic greybox room with colored walls, floor, four pillars, and a stepping block for jump testing. Built in `_ready` so geometry tweaks are code changes, not scene fiddling. Replaced in Phase 2 by the actual mall.
- `scenes/Main.tscn` now instances `TestRoom.tscn` instead of being an empty `Node3D`.
- Input map in `project.godot`: `move_forward`, `move_back`, `move_left`, `move_right`, `jump`, `sprint`, `interact` — all bound to physical keycodes so layouts other than QWERTY still work positionally.
- `tests/test_movement_math.gd` — 18 GUT tests covering all `MovementMath` helpers (velocity composition, sprint switching, bob phase alignment, pitch clamping, mouse-axis inversion, linear sensitivity scaling).
- CI now runs a 60-frame headless smoke of the main scene between parse-check and GUT — catches `_ready`-time crashes that pure parse-check misses (would have caught the `const PackedColorArray` regression).

### Why it matters
The first-person controller is the substrate every later phase touches: Phase 4 (food court table interaction), Phase 6 (store browsing), and Phase 9 (NPC eavesdropping) all assume a working FP body that walks, looks, and interacts. Locking it in now with pure-helper unit coverage means we can refactor the controller later without losing confidence — the camera math and movement math are protected by 18 assertions that don't care about the surrounding scene.

### Architecture
- Pure logic (`MovementMath`) is separated from node-bound behavior (`Player`). Player is thin: it reads input, calls `MovementMath`, and applies the result. This is the pattern every future gameplay system should follow — pure helpers get exhaustive unit tests, node code gets smoke tests.
- Head-bob is parameterized by *distance* (`HEAD_BOB_CYCLES_PER_METER`), not time. Standing still freezes the bob. Sprinting accelerates it naturally because the accumulator advances faster.
- Test room geometry is built in code, not authored as a scene. Quicker to iterate, easier to delete in Phase 2, and `_make_box` is a reusable pattern for Phase 2's greybox.

### UX details
- Mouse captured on launch; Esc toggles visible/captured.
- Pitch clamped to ±90° — no upside-down view.
- Bob amplitude 0.06 m, half-frequency horizontal sway — gentle, not nauseating.

### Tests
- `tests/test_movement_math.gd` — 18 assertions across velocity, sprint, head-bob phase, pitch clamping, mouse inversion, sensitivity scaling.
- CI smoke-run boots `Main.tscn` for 60 frames headless — gates against `_ready`-time crashes.

### Pre-push checklist (Phase 1)
- [x] `godot --headless --import` clean.
- [x] `godot --headless --quit` (parse-check) exit 0.
- [x] `godot --headless --quit-after 60 res://scenes/Main.tscn` exit 0 (no runtime crashes).
- [x] GUT: 20/20 tests passing across 2 scripts, exit 0.
- [x] `.gitignore` still covers `.godot/`.

### Known limitations
- No coyote-time, no air-control reduction, no slope-clamp — basic controller only. Tunable constants live in `Player.gd`.
- No FOV change on sprint (Phase 8 polish).
- No footstep audio (Phase 8).
- TestRoom is throwaway — Phase 2 replaces with the mall greybox.

[0.1.0]: https://github.com/NickSanft/MallCross/releases/tag/v0.1.0

## [0.0.1] - 2026-05-22 — Phase 0: Project skeleton

### Added
- Godot 4.6 project file (`project.godot`) with Forward+ renderer and untyped-declaration warnings enabled.
- Empty `scenes/Main.tscn` placeholder as the main scene.
- Project `icon.svg` (placeholder mall storefront art).
- Standard Godot 4 `.gitignore`.
- README with pitch, planned controls, dev setup, test command.
- This CHANGELOG.
- [GUT](https://github.com/bitwes/Gut) 9.x test framework installed at `addons/gut/`.
- Smoke test (`tests/test_smoke.gd`) asserting GUT runs.
- GitHub Actions workflow (`.github/workflows/ci.yml`):
  - Pinned Godot 4.6.1-stable (standard Linux build) for headless runs.
  - Parse-check via `godot --headless --quit`.
  - GUT suite execution via `godot --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://tests/ -gexit`.
  - Workflow fails red on any parse error or test failure.

### Why it matters
Phase 0 establishes the safety net every later phase relies on. Green CI on a runnable empty Godot project means every subsequent phase has a baseline to compare against — and the per-phase ship workflow (`implement → tests → push → watch CI → tag`) has a real `gh run watch` target from day one. No gameplay code lands until this floor is in place.

### Architecture
None yet — placeholder scene only.

### UX details
No UI yet.

### Tests
- `tests/test_smoke.gd` — single passing assertion verifying the GUT pipeline works end-to-end.

### Pre-push checklist (Phase 0)
- [x] Parse-check passes locally (`godot --headless --quit`).
- [x] GUT smoke test passes locally.
- [x] `.gitignore` covers Godot generated dirs (`.godot/`, etc.).
- [x] No untracked files unintentionally left out.

### Known limitations
- No first-person controller yet (Phase 1).
- No mall geometry (Phase 2).
- No crossword logic (Phase 3).
- Default Godot icon is a placeholder — real cover art comes in Phase 8.

[Unreleased]: https://github.com/NickSanft/MallCross/compare/v0.2.0...HEAD
[0.0.1]: https://github.com/NickSanft/MallCross/releases/tag/v0.0.1
