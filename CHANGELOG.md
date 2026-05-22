# Changelog

All notable changes to MallCross are documented here. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Pre-1.0 minor versions mark phase boundaries.

## [Unreleased]

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

[Unreleased]: https://github.com/NickSanft/MallCross/compare/v0.0.1...HEAD
[0.0.1]: https://github.com/NickSanft/MallCross/releases/tag/v0.0.1
