# Changelog

All notable changes to MallCross are documented here. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Pre-1.0 minor versions mark phase boundaries.

## [Unreleased]

## [0.7.4] - 2026-05-22 — Phase 7.3: Full week of puzzles

### Added
- **`data/puzzles/mall_day_three.json`** — ALONG / AGAIN / KNIFE across; ABACK / GENRE down. Theme: "Midweek mall regulars."
- **`data/puzzles/mall_day_four.json`** — STORM / ABOUT / DECAL across; SCALD / METAL down. Theme: "Stormy Thursday."
- **`data/puzzles/mall_day_five.json`** — BRASS / AROMA / ELITE across; BRACE / SNARE down. Theme: "Friday flair."
- **`data/puzzles/mall_day_six.json`** — FLOOD / ARENA / EXTRA across; FLAME / DRAMA down. Theme: "Saturday spectacle."
- **`data/puzzles/mall_day_seven.json`** — DARTS / ULTRA / TRIBE across; DOUBT / SPADE down. Theme: "Sunday wrap."
- **End-of-week prompt**: on day 8+ the MINI table now reads `"Week 1 complete — more puzzles in a future update"` instead of the generic "no puzzle today" message. Player gets a clean stopping point.
- 2 new GUT tests in `tests/test_puzzle_schedule.gd`:
  - `test_full_week_each_day_has_puzzle` — iterates days 1–7 and asserts each has a scheduled puzzle.
  - `test_full_week_puzzle_ids_are_distinct` — ensures no day points at the same puzzle as another.

### Changed
- **`PuzzleSchedule._SCHEDULE`** extends to all seven days. The CI's puzzle-validate step ran clean on all seven `data/puzzles/*.json` files.

### Why it matters
A full week of distinct, validated puzzles. The streak counter can climb to 7 by solving every day in a row (with the bonus reaching `+30 Woints` on day 7's solve). Hitting day 8 gracefully tells the player they've finished the bundled content. The schedule data structure is unchanged — Phase 7.4+ adds more weeks the same way.

### Architecture
- All seven puzzles use the **same block pattern** as `mall_day_one` (blocks at `(1,1)(1,2)(1,3)(3,1)(3,2)(3,3)`). UI muscle memory stays consistent — players don't have to re-learn the grid shape each day.
- **Themes are descriptive, not enforced.** The validator doesn't try to interpret theme; it's metadata for the player + future puzzle-archive UI.
- **Numbering is identical across all seven puzzles** (1A / 3A / 4A / 1D / 2D) — Phase 8's polish pass could add per-puzzle quirks (longer answers, different shapes) once the painted-into-a-corner risk of 15x15 hand-authoring is solved.

### UX details
- Clue text varies in personality across the week (definition, slang, pop-culture) so puzzles don't feel mechanical.
- Day labels in clue text would clash with the game's "Day N" UI; each puzzle's `title` is "Mall Day N" instead.
- End-of-week prompt is intentionally promissory ("more puzzles in a future update") so the player knows the game is incomplete rather than broken.

### Tests
- All 7 puzzles validate clean via `tools/puzzle_validate.gd`.
- 246/246 tests passing across 17 scripts (419 assertions). +12 assertions in `test_puzzle_schedule.gd` cover the expanded mapping.

### Pre-push checklist (Phase 7.3)
- [x] `godot --headless --import` clean.
- [x] `godot --headless --quit` exit 0.
- [x] `godot --headless --quit-after 60 res://scenes/Main.tscn` exit 0.
- [x] All 7 puzzles `OK` via `tools/puzzle_validate.gd`.
- [x] GUT: 246/246 tests passing, exit 0.

### Known limitations
- **Still 5x5.** Hand-authoring 9x9 or 15x15 by hand is non-trivial; deferred to Phase 7.4+ if needed.
- **No archive of past puzzles.** Once you've solved Day 3, you can't re-attempt it via a menu. Phase 10 polish could add a "puzzle archive" room or kiosk.
- **No "Week 2" exists.** Player who burns through all 7 days will hit the end-of-week message permanently until more content ships.
- **MIDI / FULL tables still decorative.** They could become a parallel difficulty track in a later phase.

[0.7.4]: https://github.com/NickSanft/MallCross/releases/tag/v0.7.4

## [0.7.3] - 2026-05-22 — Phase 7.2: Daily puzzle rotation + 2nd puzzle

### Added
- **`data/puzzles/mall_day_two.json`** — second 5x5 puzzle (SLOSH / ALDER / KOOKY across; STARK / HARDY down). Same block pattern as `mall_day_one`, all real English words, validates clean.
- **`scripts/PuzzleSchedule.gd`** — pure static helper mapping in-game day → puzzle ID. Phase 7.2 hardcodes day 1 → `mall_day_one`, day 2 → `mall_day_two`. Methods: `puzzle_id_for_day`, `has_puzzle_for_day`, `scheduled_days` (sorted), `last_scheduled_day`. Phase 7.x+ may move this to `data/schedule.json` so puzzle packs ship without code.
- **`daily_puzzle` interactable metadata** as a fourth dispatch branch in `GameController` (alongside `puzzle_id`, `shop_id`, `sleep_action`). When the player interacts, `GameController` looks up the day's puzzle via `PuzzleSchedule` and opens it. If no puzzle is scheduled for today, the prompt reads `"No puzzle today — sleep to advance the day"` and pressing E is a no-op.
- **Dynamic HUD prompt** for the MINI table:
  - `[E] Solve Day N Crossword` when today's puzzle is unsolved
  - `[E] Day N Crossword (already solved)` when already done
  - `"No puzzle today — sleep to advance the day"` when the schedule has nothing for this day
- **`Player.refresh_interaction_target()`** — re-emits `interactable_changed` with the current target. Called by `GameController` after sleep finishes and after each modal closes, so the HUD prompt updates without making the player walk off and back. Fixes a latent UX issue where buying an item or solving a puzzle left the prompt frozen on the pre-action text.
- `tests/test_puzzle_schedule.gd` — 10 GUT tests covering the schedule's lookups, edge cases (day 0, negative, beyond-schedule), and a **meta-test that loads every scheduled puzzle and asserts the JSON file exists and parses**. Catches schedule/data drift the moment it happens.

### Changed
- **MINI table is now a daily-puzzle table.** `MallGreybox._build_table` takes a `daily_puzzle` bool instead of a fixed `puzzle_id`. Set true for MINI, false for MIDI / FULL (still decorative). The table tags itself `daily_puzzle: true` and stores `woints_reward` — `GameController` resolves the actual puzzle ID at interact time via `PuzzleSchedule`.
- **`GameController._open_puzzle` now takes an explicit `puzzle_id` argument** instead of reading from interactable metadata. The dispatcher passes either the static metadata's `puzzle_id` (for legacy fixed tables) or the schedule's lookup (for daily tables). One open path, two ways to resolve the ID.

### Why it matters
Resolves the "sleeping doesn't change anything" feedback: on day 1 the MINI table plays `mall_day_one`; sleep to day 2 and it plays `mall_day_two` (full 50 Woints + streak bonus on first solve). The streak indicator activates on the second consecutive-day solve. Days 3+ show the "no puzzle today" prompt until the schedule grows — exactly the "come back tomorrow" feel of a real daily-puzzle app.

### Architecture
- **Schedule is data, dispatcher is code.** The mapping lives in `PuzzleSchedule._SCHEDULE`; nothing else in the codebase encodes "which puzzle is today's." Adding a Phase 7.3 puzzle is a one-line edit there plus the JSON file.
- **The same `_open_puzzle` flow handles both fixed and daily tables** — the only difference is where the puzzle ID comes from. Same cache hookup, same reward calculation, same UI path.
- **`refresh_interaction_target` is a pure broadcast** — it doesn't re-poll the ray or change `_current_interactable`; it just re-emits the signal. Cheap, side-effect-free, and the `GameController` decides what to do with the new prompt content.

### UX details
- Walking to the MINI table on a day with no scheduled puzzle no longer leaves the player wondering — the prompt explicitly says to sleep.
- After solving today's puzzle and pressing Continue, the prompt instantly flips to `(already solved)` without requiring a step back.
- After buying coffee, walking back to the same shop button doesn't show "Buy" anymore — the prompt updates immediately.

### Tests
- `tests/test_puzzle_schedule.gd` — direct lookups, boundary cases, meta-test loading every scheduled JSON. Total: **244/244 tests across 17 scripts** (397 assertions).

### Pre-push checklist (Phase 7.2)
- [x] `godot --headless --import` clean.
- [x] `godot --headless --quit` exit 0.
- [x] `godot --headless --quit-after 60 res://scenes/Main.tscn` exit 0 (Main loads with both puzzles in schedule).
- [x] `tools/puzzle_validate.gd` reports `OK` on both `mall_day_one.json` and `mall_day_two.json`.
- [x] GUT: 244/244 tests passing across 17 scripts (397 asserts), exit 0.

### Known limitations
- **Schedule ends at day 2.** Days 3+ show "no puzzle today" — by design until more puzzles are authored.
- **MIDI / FULL tables still decorative.** They could become parallel daily-puzzle schedules (a MINI puzzle + MIDI puzzle + FULL puzzle each day), but that's a content question, not infra.
- **Smoke-run exit code is permissive.** The current `--quit-after 60` check exits 0 even on `SCRIPT ERROR` output. CI normally runs after a fresh `--import` so it'd catch missing scripts via the GUT run anyway, but a stricter smoke-run that greps stderr for `SCRIPT ERROR` would be a nice CI improvement.

[0.7.3]: https://github.com/NickSanft/MallCross/releases/tag/v0.7.3

## [0.7.2] - 2026-05-22 — Phase 7.1: Day advancement + streak bonus

### Added
- **Sleep cushion** in the food court back wall (purple box with a billboarded "SLEEP" label). Walking up to it shows `[E] Sleep — advance to next day`. Pressing E triggers a half-second fade to black, advances `Profile.current_day`, saves the profile, and fades back in.
- **Streak tracking on `Profile`**:
  - `streak: int` (consecutive-day solve count, starts at 0).
  - `last_solved_day: int` (in-game day of the most recent first-solve, starts at 0).
  - `mark_puzzle_solved` now updates streak math: first-ever solve = 1; same-day repeat first-solve doesn't change it; solving on day N+1 right after day N increments by 1; gap > 1 day resets to 1; already-solved attempts have no effect.
  - Both fields round-trip through `to_dict` / `from_dict` with defensive clamping (negatives → 0).
- **Streak bonus** via `WointsConfig.streak_bonus(streak)`. Formula: `max(0, streak - 1) * STREAK_BONUS_PER_DAY` (5). Day 1 of a streak = no bonus; day 2 = +5; day 5 = +20. Applied on top of the base difficulty reward at puzzle-solved time. `GameController._on_puzzle_solved` now awards `base + bonus` and saves.
- **HUD streak indicator**: a small orange label below the Day counter showing "Streak: N days" when `N > 1`. Hidden at streak 0/1 so it doesn't clutter the early game.
- **HUD fade overlay** (`HUD.fade_to_black_and_back`): a full-screen `ColorRect` driven by a `Tween` (0.5s fade in → callback → 0.5s fade out). Exposes a `fade_to_black_done` signal so `GameController` can advance the day at the darkest point.
- **`sleep_action` interactable metadata** as a third dispatch branch alongside `puzzle_id` and `shop_id`. `GameController._on_interaction_triggered` routes to `_start_sleep`. While sleeping, further interactions are ignored.
- **GUT tests**:
  - `tests/test_profile.gd` (+10 streak tests): default 0, first solve → 1, consecutive +1, 4-day streak, same-day no change, skipped day resets, repeat-solve no change, dict round-trip, defensive clamping.
  - `tests/test_woints_config.gd` (+4 streak_bonus tests): zero at streak 1, +5 at streak 2, linear scaling, zero/negative inputs.
- Total project test count: **234/234 across 16 scripts** (387 assertions).

### Why it matters
The daily-puzzle game loop has a turn now. Solve → sleep → next day → (eventually) next puzzle. Until Phase 7.2 lands more authored content, the player can re-solve `mall_day_one` only once for Woints, but advancing the day works visibly via the fade-to-black transition and the HUD day counter. The streak machinery is fully wired and tested; the moment a second puzzle exists (Phase 7.2 9x9, or 7.3 15x15), solving across consecutive days starts paying bonus Woints automatically.

### Architecture
- **Streak math lives on `Profile`**, not `GameController`. The streak update is part of `mark_puzzle_solved` so it's atomic with the solved-set mutation — there's no way to fire one without the other.
- **Sleep is a dispatch destination, not a top-level system**. The interaction system already routes by metadata key; sleep just adds a third metadata namespace. Future interactables (read-a-book, eat-at-counter, talk-to-NPC) plug in the same way.
- **Fade transition is HUD's responsibility, not GameController's**. The HUD owns the screen-space `ColorRect` already; adding the tween to it keeps the controller free of UI nodes. `GameController` just calls `fade_to_black_and_back()` and listens for `fade_to_black_done`.
- **Sleeping is gated by a single `_sleeping` flag** rather than the existing `set_paused_for_ui` because UI-pause flips the mouse mode and we don't want the mouse to become visible during a sleep — the player isn't interacting with anything visible. Sleep still calls `set_paused_for_ui(true)` for consistency, but the gate prevents re-entry.

### UX details
- Sleep cushion is purple so it visually pops against the neutral food court walls — discoverable without a tutorial.
- Fade is 0.5s each direction; total 1.0s feels like an in-game time skip without dragging.
- Streak label uses orange so it's distinct from the yellow Woints counter and blue Day counter.
- Streak hidden at 0/1 — first-time players don't see noise; the indicator appears as a reward.
- Sleeping during an open modal (puzzle / shop) isn't possible since interaction is gated. Closing the modal first is the natural flow.

### Tests
- Profile streak: all transition cases (zero / first / same-day / consecutive / gap / repeat-no-op) plus serialization round-trip and defensive parsing.
- Streak bonus: edge cases (streak 0, 1, 2, large), monotonic with day count.

### Pre-push checklist (Phase 7.1)
- [x] `godot --headless --import` clean.
- [x] `godot --headless --quit` exit 0.
- [x] `godot --headless --quit-after 60 res://scenes/Main.tscn` exit 0 (sleep cushion + Tween initialize without error in headless).
- [x] GUT: 234/234 tests passing across 16 scripts (387 asserts), exit 0.

### Known limitations
- **Only one puzzle in the game** (`mall_day_one`). You can solve once on day 1 (streak 1), sleep to day 2, sleep to day 3, etc., but there's nothing else to solve. Phase 7.2 fixes this by hand-authoring the MIDI 9x9.
- **No "puzzle-of-the-day" gating yet.** Puzzles aren't tied to specific days — `mall_day_one` is available regardless of `current_day`. Phase 7.3 may add daily rotation if it improves the game-feel.
- **Sleep is instant.** No time-of-day cycle, no morning music, no animation beyond the fade. Phase 8 polish.
- **No "Cancel Sleep" option.** Pressing E on the cushion commits to the day-advance. Fine for now (it's a small action) but could be a confirmation prompt later.
- **Streak displayed but not celebrated.** Hitting a 7-day streak doesn't trigger any special VFX. Phase 8 polish.

[0.7.2]: https://github.com/NickSanft/MallCross/releases/tag/v0.7.2

## [0.7.1] - 2026-05-22 — Fix pencil + check-letter keybinds (don't shadow letter input)

### Fixed
- **Pencil toggle and check-letter were unreachable.** The Phase 4/6 keybinds (P for pencil, C for check-letter) sat in the `match` block after the A-Z letter handler, so pressing either key entered a letter into the current cell instead of triggering the action.

### Changed
- **Pencil**: now bound to **`** (backtick / KEY_QUOTELEFT) instead of P.
- **Check letter** (Coffee): now bound to **/** (slash / KEY_SLASH) instead of C.
- Footer hint updated: `TAB toggle direction · \` pencil · Arrows move · BACKSPACE clear · ESC exit` (plus `· / check letter (Coffee)` when Coffee is owned).

### Why these keys
P and C are both valid puzzle letters in the shipped `mall_day_one` (PUTTS, PEACH, AMIGO… `C` appears in PEACH and SCORE). Binding an action to a letter the player will frequently type creates an unfixable conflict — the action either consumes the keystroke (no letter typed) or it doesn't (no action). Backtick and slash never appear in crossword answers, exist on virtually every keyboard, and don't require modifiers.

### Pre-push checklist
- [x] `godot --headless --quit` exit 0.
- [x] `godot --headless --quit-after 60 res://scenes/Main.tscn` exit 0.
- [x] GUT: 220/220, exit 0 (no test changes — fix is UI-only).

[0.7.1]: https://github.com/NickSanft/MallCross/releases/tag/v0.7.1

## [0.7.0] - 2026-05-22 — Phase 7: Real puzzles + authoring validator

### Added
- **`data/puzzles/mall_day_one.json`** — first real bundled puzzle, replacing the `demo_5x5` placeholder. 5x5 with 180° rotational symmetry, all five slots are real English words (PUTTS, AMIGO, HALVE across; PEACH, SCORE down) with corresponding clues. Same block pattern as the old demo, so the player feels the same UI/structure — only the content changed.
- **`scripts/PuzzleValidator.gd`** — pure static helper that audits a parsed puzzle against construction rules:
  - Grid present, non-empty, square
  - 180° rotational symmetry
  - No stranded short words (configurable min length, default 3)
  - Every slot has a clue with non-empty text
  - No duplicate `(number, direction)` pairs in the clue list
  - No orphan clues (warning, not error)
  - Returns an array of `{severity, code, message}` issue dicts. `has_errors` + `count_by_severity` helpers for callers.
- **`tools/puzzle_validate.gd`** — CLI wrapper. Run:
  ```
  godot --headless -s res://tools/puzzle_validate.gd -- res://data/puzzles/<id>.json [<id>.json ...]
  ```
  Exits 0 on clean (warnings allowed), 1 on any error, 2 on usage error. Prints one `OK`/`WARN`/`ERR` line per file plus indented issue details.
- **CI step: `Validate bundled puzzles`** — globs every JSON under `data/puzzles/`, runs the CLI validator over them in one Godot invocation, fails the build on any error. New puzzles ship through the workflow's safety net automatically.
- `tests/test_puzzle_validator.gd` — 12 GUT tests covering: clean puzzle, missing grid, empty grid, asymmetric grid, short word, missing clue, empty clue text, duplicate clue, orphan-as-warning, severity counts, and a meta-test that loads the shipped `mall_day_one.json` and asserts zero issues.
- Total project test count: **220/220 across 16 scripts** (367 assertions).

### Changed
- `MallGreybox` MINI table now wires to `mall_day_one` instead of `demo_5x5`. MIDI / FULL tables still unwired pending more authored puzzles in Phase 7.1.

### Removed
- `data/puzzles/demo_5x5.json` — replaced by `mall_day_one.json`. Old profiles that solved `demo_5x5` will see an orphan entry in `user://profile.json`'s `puzzles_solved` dict; harmless, will get pruned by a future "Reset Save" menu in Phase 10.

### Why it matters
The full check-letter feature shipped in Phase 6 wasn't really verifiable against the old placeholder puzzle (which had a column of gibberish — flashing red on every wrong letter looked the same as flashing red on a typo). With real interlocking words, **C** in the puzzle UI flashes only the cells the player got actually wrong — the intended behavior. The CI validator means any future puzzle author (including the eventual Phase 7.1 9x9 and 15x15) gets immediate feedback on symmetry or clue-coverage mistakes before pushing.

### Architecture
- **Validator is pure**, the CLI is a thin wrapper. The same `PuzzleValidator.validate(...)` runs in the in-process test suite and in the standalone CI tool. Both share the same issue-dict format.
- **Issue dicts**, not custom classes. Trivially JSON-serializable, easy to feed into Phase 8's "Reload puzzle" dev tool if that lands.
- **Severity ordering**: errors fail CI; warnings ride along. Orphan clues are marked warning because they don't break the game — the UI just doesn't display them. The CLI exit code is 0 when only warnings appear, matching shellcheck/eslint conventions.
- **`mall_day_one` keeps the demo's block pattern.** This minimizes UI test churn (cursor still lands at the same start cell, same number of slots, same focus order). Only the letters changed.

### UX details
- Player solving the MINI table now hits a real puzzle: golf, Spanish slang, fractions, fruit, basketball.
- The CLI validator's output is grep-friendly: status code in the first three chars (`OK `, `WARN`, `ERR`), file path next, then indented issues. Easy to wire into a future watch-mode editor.

### Tests
- `tests/test_puzzle_validator.gd` — 12 tests across the issue codes plus a happy-path validation of the shipped `mall_day_one.json`. The meta-test catches any future regression where someone edits the bundled puzzle and forgets to keep it valid.
- The CI `Validate bundled puzzles` step is itself a test: a malformed puzzle file will fail the build before tests run.

### Pre-push checklist (Phase 7)
- [x] `godot --headless --import` clean.
- [x] `godot --headless --quit` exit 0.
- [x] `godot --headless --quit-after 60 res://scenes/Main.tscn` exit 0.
- [x] CLI: `tools/puzzle_validate.gd` reports `OK` on `mall_day_one.json`, exit 0.
- [x] GUT: 220/220 tests passing across 16 scripts (367 asserts), exit 0.

### Known limitations
- **MIDI and FULL still unwired.** Hand-authoring a valid 9x9 and 15x15 is substantial work; Phase 7.1 will land them with the validator catching mistakes during authoring.
- **No day-advancement mechanic yet.** `Profile.current_day` still only goes up via direct API calls (no Sleep action, no clock). Phase 7.1 wires daily puzzle rotation.
- **No streak bonus.** `puzzles_solved[id].first_solved_day` is recorded but the bonus math itself is Phase 7.1+.
- **CLI tool has no `--strict` flag for warnings-as-errors.** Trivial to add when there's a need.
- **`mall_day_one.json` orphans old profile entries.** A `Reset Save` menu (Phase 10) or manually deleting `user://profile.json` is the workaround.

[0.7.0]: https://github.com/NickSanft/MallCross/releases/tag/v0.7.0

## [0.6.0] - 2026-05-22 — Phase 6: Stores + Woints spending + functional items

### Added
- `scripts/Item.gd` — pure data class with two slot constants (`SLOT_COSMETIC`, `SLOT_FUNCTIONAL`). `from_dict` clamps negative costs to 0 and falls back to functional on unknown slot strings; `to_dict` round-trips cleanly.
- `scripts/ItemCatalog.gd` — static registry. Phase 6 ships two items:
  - **Coffee** (functional, 40 Woints) — enables the in-puzzle "Check Letter" action.
  - **Mall Cap** (cosmetic, 100 Woints) — owned-state only for now; visible-on-player polish comes with the Phase 8 art pass.
- `scripts/shop/ShopUI.gd` + `scenes/ShopUI.tscn` — modal shop browser, layout built in code (same pattern as `CrosswordUI`). Each item row shows name + slot marker + description + cost, and a per-row button whose state reflects ownership and affordability ("Buy" / "Need N more" / "Owned"). Esc or the "Leave shop" footer button closes the modal.
- **Inventory on `Profile`**:
  - `owned_items: Array[String]` persisted to disk.
  - `own_item(id)` — idempotent append, returns `true` only on first acquisition.
  - `owns(id)`, `can_afford(cost)`, `try_purchase(id, cost)` — atomic purchase that refuses unaffordable or already-owned items and never partially mutates.
  - Defensive `from_dict` dedupes duplicate IDs and ignores non-string entries — corrupt saves can't double-own anything.
- **Store 1 wired as a shop**. `MallGreybox._build_store_fronts` now stamps `shop_id="mall_general"` + `shop_label` metadata on Store 1's facade. Stores 2–6 remain decorative facades.
- **`GameController` dispatch**: a single interactable can carry either `puzzle_id` *or* `shop_id` metadata. `_on_interaction_triggered` routes to `_open_puzzle` or `_open_shop` accordingly. Closing the shop saves the profile and refreshes the HUD Woints counter.
- **Check Letter** in `CrosswordUI`:
  - Footer hint updates to include `· C check letter (Coffee)` when the player owns Coffee.
  - Pressing **C** in the crossword flashes a red border around any incorrect letter in the current word for 2 seconds.
  - Uses a `SceneTreeTimer` so the flash auto-clears; the timer is null-checked at open time so re-opening a puzzle never carries stale wrong-cell highlights.
- `CrosswordGridView.set_wrong_cells(cells)` — public API for the UI to push wrong-cell positions; renders a 3 px inset red border on top of each affected cell during `_draw`.
- 33 new GUT tests across 3 files:
  - `tests/test_item.gd` (7 tests) — dict round-trip, clamping, slot fallback.
  - `tests/test_item_catalog.gd` (10 tests) — registry membership, lookups, monotonic-cost sanity, slot assignments.
  - `tests/test_profile.gd` extended (+16 tests) — own/owns, can_afford, try_purchase (success, broke, already-owned, empty/negative inputs), inventory disk round-trip, dedup, type filtering.
- Total project test count: **208/208 across 15 scripts** (352 assertions).

### Why it matters
First time Woints actually mean something. Earn 50 from solving the MINI puzzle, walk over to Store 1, buy a coffee for 40, return to the table, press C to see which letters you got wrong. Hat purchase wires the cosmetic slot end-to-end (Profile → ShopUI → persistence) so Phase 8 only has to add the visible-on-player rendering.

### Architecture
- **Single dispatch dimension** for interactables: the metadata key (`puzzle_id` vs `shop_id`) is what `GameController` switches on. Future interactables (NPCs in Phase 9, vending machines, etc.) plug in the same way without modifying `Player.gd` or the raycast logic.
- **Profile owns purchase atomicity**, not the UI. `ShopUI._on_buy_pressed` just calls `_profile.try_purchase(id, cost)` and refreshes. If you ever want a quick-buy from a debug menu or a cheat command, it's the same one-liner.
- **Coffee gating is profile-driven, not UI-driven.** `CrosswordUI` checks `_profile.owns("coffee")` at open time and on each C press. The UI itself owns no inventory state, so a future "borrow Coffee for one puzzle" mechanic would only need to lie to the UI about ownership.
- **Wrong-cell highlighting is a one-shot overlay**, not a persistent UI mode. The grid view holds a `_wrong_cell_set` dict, the UI clears it after 2s, and re-opening the puzzle blanks it explicitly. No leaking state between puzzles.
- Items live in code (`ItemCatalog.all_items()`) rather than JSON for Phase 6 — only two of them, balance is volatile, the JSON loader would be more code than the items it'd load. Phase 7 may move them to JSON if the puzzle pack ships themed shop items.

### UX details
- Shop modal greeting shows the current Woints balance in the header next to the shop name.
- Per-row "Need N more" text on unaffordable items tells the player exactly how many Woints to earn, no mental subtraction.
- Cosmetic vs functional slot is surfaced in the item row as `(cosmetic)` / `(functional)` so the player can see which slot a purchase fills.
- Check-letter flash is *only* over incorrect entries — blank cells are not flagged. Lets the player distinguish "wrong letter" from "haven't filled yet".
- Leave-shop button is focused on open so Enter closes the modal as a mouse-free shortcut.

### Tests
- `tests/test_item.gd` — round-trip, defensive parsing, slot constant distinctness.
- `tests/test_item_catalog.gd` — registry membership (`coffee` and `mall_cap` both present), `get_item` for valid + invalid IDs, `has_item`, slot assignments, monotonic-cost sanity.
- `tests/test_profile.gd` (extended) — purchase happy path, broke path, repeat-purchase guard, dict round-trip including `owned_items`, defensive parsing dedupes and filters non-strings.

### Pre-push checklist (Phase 6)
- [x] `godot --headless --import` clean.
- [x] `godot --headless --quit` exit 0.
- [x] `godot --headless --quit-after 60 res://scenes/Main.tscn` exit 0 (Main + ShopUI load without runtime errors in headless).
- [x] GUT: 208/208 tests passing across 15 scripts (352 asserts), exit 0.

### Known limitations
- **Only Store 1 is wired.** Stores 2–6 still walk into a solid facade. Phase 7 themed packs will probably populate the others.
- **Cosmetics aren't visible.** Mall Cap goes into your inventory but doesn't appear on the player model. Phase 8 art pass adds player hands + shadow + cosmetic rendering.
- **No "equip" mechanic.** Cosmetics auto-take effect on purchase (currently no-op since rendering is deferred). Functional items are always-on while owned. Phase 8 may add slot-equip if multiple cosmetics ship.
- **No "Reset Inventory" debug action.** `ProfileStore.delete_at_path` wipes the entire profile if you really need to start over.
- **Check Letter is unlimited.** No per-day or per-puzzle quota — Phase 7 may add charges if balance demands it.
- **Mall Cap doesn't do anything yet.** Bought, persisted, owned — visible-on-player is Phase 8.

[0.6.0]: https://github.com/NickSanft/MallCross/releases/tag/v0.6.0

## [0.5.0] - 2026-05-22 — Phase 5: Persistent profile + Woints economy

### Added
- `scripts/Profile.gd` — persistent player model. Holds `woints`, `current_day`, `puzzles_solved` (`puzzle_id` → `{first_solved_day}`), and an in-memory cache of `CrosswordState` per puzzle. Pure model — no disk I/O. Defensive `from_dict` clamps negative Woints and zero/missing day to 1. `mark_puzzle_solved` returns `true` only on first call per puzzle so the caller can award Woints idempotently.
- `scripts/ProfileStore.gd` — disk I/O at `user://profile.json`. Defaults to `Profile.new()` on missing file, empty file, or garbage JSON — the game always boots into a playable state. `save_to_path` returns a bool so callers can log failures; `delete_at_path` exists for tests and a future "Reset Save" menu option.
- `scripts/WointsConfig.gd` — per-difficulty reward table. MINI = 50, MIDI = 120, FULL = 300, DEFAULT = 25. Case-insensitive lookup; difficulties scale strictly. Phase 7's puzzle pack inherits these values unchanged.
- 40 new GUT tests across three files:
  - `tests/test_profile.gd` (24 tests) — defaults, Woints add/clamp, mark/repeat-solve, day advance + clamp, state cache round-trip, dict round-trip with all fields, defensive parsing.
  - `tests/test_profile_store.gd` (10 tests) — disk round-trip on temp `user://` paths (cleaned up per-test), missing/empty/garbage file recovery, valid-JSON shape verification, null-profile handling, delete-and-check.
  - `tests/test_woints_config.gd` (6 tests) — per-tier lookup, case insensitivity, unknown-label fallback, monotonic tier ordering.
- Total project test count: **175/175 across 13 scripts** (300 assertions).
- `HUD` now shows two persistent labels:
  - **Woints** (top-right) — yellow with black outline. Updated by `GameController` on load and after each award.
  - **Day** (top-left) — pale blue. Reads `Profile.current_day` on load.
- `CrosswordUI.open_puzzle` takes two new params:
  - `reward_amount: int` — Woints earned on first solve. Shown in the solve banner as "+N Woints".
  - `reward_already_taken: bool` — if true, banner reads "Already solved — no new Woints" instead.
- `GameController` rewritten around `Profile`:
  - Loads at `_ready` and pushes initial Woints/Day to HUD.
  - On interact: looks up the table's `woints_reward` metadata, passes the remaining reward to the UI (0 if puzzle already solved).
  - On `puzzle_solved`: calls `Profile.mark_puzzle_solved` (idempotent), awards Woints if first solve, saves profile.
  - On UI close: caches the live state on the profile, saves profile.
- `MallGreybox._build_table` now stores `woints_reward` metadata on each wired table (via `WointsConfig.reward_for_difficulty(label_text)`).

### Why it matters
The game now remembers you between runs. Walk into the MINI table, solve the puzzle, see "+50 Woints" on the banner, see your HUD balance jump from 0 to 50, quit the game, re-launch, and you're back at Day 1 with 50 Woints and the puzzle marked solved. Re-entering the table shows the "(Already solved — no new Woints)" footer when you re-fill it. Phase 6 plugs into `Profile.add_woints(-N)` for shop purchases; Phase 7's day advancement increments `current_day` ahead of each new themed puzzle.

### Architecture
- `Profile` is a pure data model. `ProfileStore` is the only I/O surface. The two are split deliberately so unit tests on `Profile` don't touch the disk and tests on `ProfileStore` don't have to set up complex model state.
- Save is idempotent. The same dict-serialization path runs whether the player closes a puzzle, solves it, or never opens it — there's exactly one shape of save file.
- `puzzles_solved` records the *day* of first solve, not just a bool. Phase 7's streak bonus calculation will read this directly without needing a second data structure.
- The `_cached_states` dict on `Profile` holds live `CrosswordState` references — same trick as `v0.4.1`'s `GameController` cache. `to_dict` serializes them through `CrosswordSerializer` on demand, so disk format and code format are decoupled.
- Reward amount travels through the system as metadata on the interactable. `GameController` looks it up once at open time, passes it to the UI. The UI never reads the profile directly — it's display-only.

### UX details
- HUD updates the moment the puzzle is solved, before the banner's Continue button is even clicked.
- Solve banner now has three lines: "PUZZLE SOLVED" / "Nice work!" / reward text. Reward text is yellow when there's a Woints award, gray when already-solved.
- Day counter is visible immediately on game launch — even before solving anything — so the day system's existence is discoverable.
- Quitting the game saves on `_on_ui_closed`; we don't currently save on `_notification(NOTIFICATION_WM_CLOSE_REQUEST)` (Phase 10 polish).

### Tests
- `tests/test_profile.gd` — model behavior in isolation: defaults, mutations, round-trips, defensive parsing of bad input.
- `tests/test_profile_store.gd` — disk round-trips per-test on unique `user://test_profile_<usec>.json` paths, cleaned up in `after_each`. Garbage-file recovery confirms the game can't be bricked by a corrupted save.
- `tests/test_woints_config.gd` — reward lookup and tier monotonicity.

### Pre-push checklist (Phase 5)
- [x] `godot --headless --import` clean.
- [x] `godot --headless --quit` exit 0.
- [x] `godot --headless --quit-after 60 res://scenes/Main.tscn` exit 0 (HUD labels render, profile loads in headless).
- [x] GUT: 175/175 tests passing across 13 scripts (300 asserts), exit 0.

### Known limitations
- **No day advancement mechanic yet.** `Profile.advance_day` works in code but nothing in the game calls it. Phase 7 wires it to the themed puzzle pack (one puzzle per day, advancing on solve).
- **No save on game-quit.** Closing the window via the title bar X doesn't save. Currently saves happen on puzzle close + puzzle solve, which covers the practical cases but not "left the game open then quit while looking around the mall."
- **No streak bonus yet.** `first_solved_day` is recorded for future bonus math; the bonus logic itself is Phase 7.
- **No "Reset Save" menu option.** `ProfileStore.delete_at_path` exists for tests; Phase 10 wires a settings-menu option to it.
- Solve banner reward text is plain — no animation, no celebration sound. Phase 8 polish.

[0.5.0]: https://github.com/NickSanft/MallCross/releases/tag/v0.5.0

## [0.4.1] - 2026-05-22 — Phase 4 polish: solve banner + in-memory state cache

### Added
- **Solve banner** in `CrosswordUI`: a centered green/yellow panel with "PUZZLE SOLVED" + "Continue" button appears the moment every white cell matches the solution. Continue button is focused automatically so Enter/Space/Esc all close the modal without needing the mouse. Banner re-hides if the player erases a letter (and re-appears on re-solve).
- **Input lockout while banner is up**: letter input and direction-toggle keys are ignored once the puzzle is solved — only Esc/Enter/Space close. Stops accidental key mashes from corrupting the win state.
- **In-memory solve-state cache** in `GameController` keyed by `puzzle_id`. Closing the modal stashes the current `CrosswordState`; re-opening the same puzzle restores it. Survives walking around the mall and re-interacting with the same table; **does not** survive a game restart yet — that's Phase 5.
- **Repeat-solve suppression**: `GameController._on_puzzle_solved` only logs once per puzzle per session. Phase 5's Woints award will hang off the same gate.
- `CrosswordUI.open_puzzle` now accepts an optional `existing_state` param (validated by size match); falls back to a fresh empty state on mismatch or null.
- `CrosswordUI.get_current_state()` getter so `GameController` can stash state without poking internals.

### Why it matters
Closes the two glaring UX cliffs reported on `v0.4.0`: no feedback when you finish a puzzle, and progress vanishing the moment you walk away from the table. The cache + banner together make the loop feel like a real game instead of a tech demo. Disk persistence is still pending (Phase 5) — quitting the game wipes everything — but within a single session you can now solve, walk away, come back, and continue exactly where you left off.

### Architecture
- `_solved_emitted` flag preserves "fire `puzzle_solved` exactly once per false→true transition". Erasing a letter resets it so a re-solve fires again. Re-opening a puzzle already in solved state suppresses the emit (signal is for *transition*, not *status*).
- `CrosswordUI` doesn't know about the cache. `GameController` owns the dict; the UI is stateless across opens.
- The state passed into `open_puzzle` is a *reference*, not a copy — the UI mutates it in place. Closing simply re-caches the same reference. Cheaper, simpler, and the reference identity doesn't matter because nothing else holds it.

### Pre-push checklist
- [x] `godot --headless --quit` exit 0.
- [x] `godot --headless --quit-after 60 res://scenes/Main.tscn` exit 0.
- [x] GUT: 135/135 tests passing, exit 0 (no test changes — patch is UI-only).

### Known limitations
- Disk persistence still missing — quitting/restarting the game loses all in-memory state. Phase 5 lands `user://profile.json` save/load.
- Banner is plain Godot defaults; Phase 8 art pass restyles it.

[0.4.1]: https://github.com/NickSanft/MallCross/releases/tag/v0.4.1

## [0.4.0] - 2026-05-22 — Phase 4: In-world table interaction + crossword UI

### Added
- `scripts/crossword/CrosswordCursor.gd` — pure cursor model. `at_start` lands at the first non-block cell; `toggle_direction`, `move_to`, `move`, `advance`, `retreat`, `direction_vector`, `current_word_cells`, `current_word_start`. No node refs — fully GUT-testable.
- `scripts/crossword/CrosswordGridView.gd` — custom-drawn grid (`Control` with a single `_draw` call). Renders cursor cell in cyan, current-word cells in pale blue, numbers in the top-left of each cell, letters centered (pencil entries in gray). Avoids spawning 225 child nodes for a 15x15 puzzle.
- `scripts/crossword/CrosswordUI.gd` + `scenes/CrosswordUI.tscn` — modal panel: title + progress (`N / N`) + direction + pencil indicator in the header, grid + scrollable clue list (across + down with the current clue highlighted yellow) in the body, current-clue caption below the grid, control hints in the footer. Layout built programmatically in `_ready` (avoids a fragile 20-node `.tscn`). Keyboard: A–Z to enter letters, Backspace to delete (and retreat if cell already blank), arrows to move (auto-switching direction), Tab/Space to toggle direction, P toggles pencil, Esc closes the modal. Emits `puzzle_solved` the moment every cell matches; `closed` on Esc.
- `scripts/PuzzleLoader.gd` — loads puzzles from `res://data/puzzles/<id>.json`. Returns the same dict shape as `CrosswordSerializer.puzzle_from_dict` so callers can't tell whether the puzzle came from disk or memory.
- `data/puzzles/demo_5x5.json` — first bundled fixture (`demo_5x5`). 5x5 with 180° symmetric blocks, 3 across + 2 down entries, full clue text. Two answers are placeholder strings (real puzzles arrive in Phase 7); the format and pipeline are exercised end-to-end either way.
- `scripts/HUD.gd` + `scenes/HUD.tscn` — minimal world-space HUD with one centered interaction prompt label ("[E] Solve MINI Crossword"). Phase 5 will add a Woints counter.
- `scripts/GameController.gd` + Main.tscn now uses it as the root. Wires `Player.interaction_triggered` → `PuzzleLoader.load_by_id` → `CrosswordUI.open_puzzle`, and `CrosswordUI.closed` → `Player.set_paused_for_ui(false)`. Logs on `puzzle_solved` (Woints award lands in Phase 5).
- `Player.gd` interaction layer: `RayCast3D` child of `Camera3D` looking 3 m forward. `_update_interaction_target` polls the ray each physics frame; emits `interactable_changed(node)` whenever the hit object in the `interactable` group transitions in/out of view. `interaction_triggered(node)` fires when the player presses E with something in sight. New `set_paused_for_ui(bool)` flips mouse capture and bails on both `_physics_process` and `_unhandled_input` while a modal is up.
- `MallGreybox._build_table` now takes an optional `puzzle_id` — when set, the tabletop joins the `interactable` group with `puzzle_id` + `puzzle_label` metadata. Phase 4 wires the MINI table to `demo_5x5`; MIDI/FULL get filled in Phase 7.
- `tests/test_crossword_cursor.gd` — **19 GUT tests** covering at-start, toggle, move bounds, block-skipping, advance/retreat, direction vectors, current-word enumeration across/down, block-stop, on-block returns empty. Total project test count: **135/135 across 10 scripts** (230 assertions).

### Why it matters
Phase 4 is the first phase where MallCross actually plays. The Phase 1 controller, Phase 2 mall, and Phase 3 crossword core all click together when the player walks to the MINI table, presses E, and is dropped into a modal where every keystroke maps to a puzzle action. Phase 5 just adds the persistent profile + Woints economy; Phase 6 adds shops; Phase 7 backfills real puzzles — but the core loop (walk → solve → solved!) exists as of `v0.4.0`.

### Architecture
- The interaction system is opinionated about responsibilities: `Player` owns the raycast and emits signals; `GameController` owns the policy decision of "what does interaction X open"; `CrosswordUI` owns puzzle state while open. Nothing else knows about the others' internals. Phase 6's shop browsing will plug into the same signals.
- `CrosswordUI` builds its layout in code rather than in `.tscn`. Trade-off: less inspectable in the editor, much easier to diff / refactor / theme later. Phase 8's PS1/N64 style pass can override a single `StyleBoxFlat` and font choice and re-skin the whole modal.
- `CrosswordGridView` draws all NxN cells in one pass via `_draw`. At 15x15 that's 225 quads; spawning 225 `Control` nodes would have been ~10x slower and 100x more memory. The `_word_cell_set` dict cache means current-word highlighting is O(1) per cell during draw.
- `PuzzleLoader` exists so Phase 7's authoring tool can write JSON files directly into `res://data/puzzles/` and the game picks them up without code changes.

### UX details
- HUD prompt appears the moment the interaction ray hits a wired table; disappears the moment you look away.
- Opening the modal hides the mouse-capture lock so the player can move the cursor on screen if needed; closing it re-captures.
- Direction toggles automatically when arrow keys are pressed in the orthogonal axis (e.g. pressing Up while in Across switches to Down and moves).
- Backspace on a filled cell clears it; Backspace on an already-blank cell retreats first (matches NYT app behavior).
- Pencil mode persists across letter entries until toggled off; pencil entries render in light gray to distinguish from confident pen entries.

### Tests
- `tests/test_crossword_cursor.gd` — 19 tests: position initialization, block-skipping at start, full-row-block wrap, toggle, valid/invalid move targets, blocked advance, retreat, direction vectors, across/down current-word enumeration, full-column/full-row walk through letter-only cells, on-block returns empty.
- UI integration is exercised by the 60-frame headless smoke-run of `Main.tscn` (catches any `_ready`-time crash in `GameController`, `CrosswordUI`, or `HUD`). Interactive flows (Esc closes, letters fill, puzzle-solved signal fires) are not GUT-testable headless and will require either a dedicated test scene or Godot's editor-test runner — deferred until needed.

### Pre-push checklist (Phase 4)
- [x] `godot --headless --import` clean.
- [x] `godot --headless --quit` exit 0.
- [x] `godot --headless --quit-after 60 res://scenes/Main.tscn` exit 0 (Main + HUD + CrosswordUI load without error in headless).
- [x] GUT: 135/135 tests passing across 10 scripts (230 asserts), exit 0.

### Known limitations
- **Only the MINI table is wired.** MIDI and FULL show their labels but pressing E does nothing — by design until Phase 7's authoring tool produces a 9x9 and a 15x15.
- **No persistence of solve state.** Closing the modal discards your entries. Phase 5 adds the persistent profile and resumes mid-puzzle on re-open.
- **No rebus entry yet** (originally listed for Phase 4 — pushed to Phase 7+ since real puzzles drive the need).
- **No mouse-click cell selection on the grid** — keyboard only for now. Easy to add in a later polish phase.
- **`demo_5x5` has two placeholder answers.** The crossword grid still validates correctly; the clues just say so.
- **No clue text on slots returned by `find_word_slots`** — `CrosswordUI._clue_text_for` does the join against the loaded puzzle's `clues` array. Phase 7 may merge them at load time if it simplifies the authoring tool.

[0.4.0]: https://github.com/NickSanft/MallCross/releases/tag/v0.4.0

## [0.3.0] - 2026-05-22 — Phase 3: Crossword core (data + logic)

### Added
- `scripts/crossword/CrosswordGrid.gd` — immutable solution grid. Square only; `size` configurable so synthetic 3x3/5x5 fixtures drive tests while the production game uses 15x15. Loads from an array of row strings (uppercased automatically), exposes `is_block`, `cell`, `in_bounds`, `to_strings`, `block_count`, `white_count`.
- `scripts/crossword/CrosswordSymmetry.gd` — 180° rotational symmetry checker (the American crossword standard). `is_symmetric` plus `find_asymmetries` which returns one entry per violating pair (dedup'd to avoid double-reporting the mirror) and `mirror_position` for editor tooling later.
- `scripts/crossword/CrosswordNumbering.gd` — standard NYT numbering. A cell starts an across word iff its left neighbor is a block or out-of-bounds AND its right neighbor is non-block (so the run is length >= 2). Length-1 stranded white cells are correctly skipped. Numbers proceed left-to-right, top-to-bottom. `find_word_slots` returns `{number, direction, row, col, length, answer}` dicts for every across/down entry.
- `scripts/crossword/CrosswordState.gd` — mutable player state: per-cell letter + pencil/pen flag. `set_letter` uppercases and clamps to one character; clearing a cell clears the pencil flag too. Pencil flag is auto-reset when the cell is blanked.
- `scripts/crossword/CrosswordValidator.gd` — `is_cell_correct`, `is_word_complete`, `is_puzzle_solved`, `cells_in_word`, `correct_cell_count`. Blocks always count as correct (they don't need entries), so a fully-solved puzzle ignores block cells.
- `scripts/crossword/CrosswordSerializer.gd` — JSON in/out with explicit format versions (`PUZZLE_FORMAT_VERSION = 1`, `STATE_FORMAT_VERSION = 1`). Defensive parsing: missing fields default to safe empties so malformed save files don't crash the loader.
- 6 GUT test files covering all 6 modules — **75 new tests**, total project test count: **116/116** across 9 scripts (195 assertions).

### Why it matters
Phase 4 wires this into the food court tables, but every UI decision there (cursor movement, current-clue highlight, rebus entry, pencil mode toggle, "check letter" button, "reveal word" button, save-on-exit) is just rendering and event-handling on top of these modules. Doing the data layer first — with 75 tests behind it — means Phase 4 ships UI without worrying about the underlying correctness of word-finding, numbering, or solve-state. Same pattern as Phase 1: thin scene code over heavily-tested pure helpers.

### Architecture
- Six small modules, each `RefCounted` with mostly static methods. No singletons, no autoloads, no node dependencies. The whole crossword stack can be exercised from a unit test in milliseconds.
- Grid is immutable after construction; State is the only mutable surface. This makes solve-state save/restore trivially safe — round-tripping a puzzle never affects its solution.
- Serializer format is dict-first, JSON-second. The dict form is the canonical shape; `puzzle_to_json` / `puzzle_from_json` are thin wrappers over `JSON.stringify` / `JSON.parse_string`. This lets Phase 7's authoring tool emit dicts directly without round-tripping through string parsing.
- All slot/clue data is plain `Dictionary` (vs. a custom class) so it's directly JSON-serializable without a marshaller. Trade-off: less type safety inside the dict, but the cost of marshalling outweighs that for a value-type the player never mutates.

### UX details
N/A — no UI in this phase.

### Tests
- `tests/test_crossword_grid.gd` — 15 tests: parsing, uppercasing, square-ness, block detection, out-of-bounds, round-trip, block/white counts.
- `tests/test_crossword_symmetry.gd` — 9 tests: open grids, center block, symmetric/asymmetric 5x5, multi-pair asymmetries, mirror math.
- `tests/test_crossword_numbering.gd` — 10 tests: 3x3 numbering, 5x5 with blocks (verifies stranded length-1 cells get no number), slot enumeration, across/down filtering, answer-string extraction.
- `tests/test_crossword_state.gd` — 13 tests: empty init, set_letter normalization, pencil flag lifecycle, clear_cell, out-of-bounds noop, filled_count.
- `tests/test_crossword_validator.gd` — 15 tests: cell correctness, block-always-correct, word completion, puzzle solved, blank vs wrong cell, cells_in_word for both directions, correct_cell_count progression.
- `tests/test_crossword_serializer.gd` — 13 tests: dict shape, format version recorded, metadata, round-trip via JSON, garbage-input tolerance, state round-trip preserves entries AND pencil flags, JSON validity.

### Pre-push checklist (Phase 3)
- [x] `godot --headless --import` clean.
- [x] `godot --headless --quit` exit 0.
- [x] `godot --headless --quit-after 60 res://scenes/Main.tscn` exit 0.
- [x] GUT: 116/116 tests passing across 9 scripts (195 asserts), exit 0.

### Known limitations
- **No bundled 15x15 puzzle yet** — the logic supports it, but writing a real puzzle requires the authoring tool from Phase 7. Phase 4 will use a small fixture for the demo interaction; Phase 7 backfills the week-1 themed pack.
- No clue text on the slots returned by `find_word_slots` — slots carry the answer, but clue text comes from the loaded puzzle file (Phase 4 will bind them).
- No support for rebus (multi-letter cells), circled cells, or shaded cells — Phase 7+ if the design calls for them.
- Defensive parsing tolerates malformed save files but doesn't surface diagnostic info — fine for v1, will improve once we have a real failure mode to debug.

[0.3.0]: https://github.com/NickSanft/MallCross/releases/tag/v0.3.0

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

[Unreleased]: https://github.com/NickSanft/MallCross/compare/v0.7.4...HEAD
[0.0.1]: https://github.com/NickSanft/MallCross/releases/tag/v0.0.1
