# Changelog

All notable changes to MallCross are documented here. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Pre-1.0 minor versions mark phase boundaries.

## [Unreleased]

## [0.10.4] - 2026-05-24 — Phase 10.4: Real 15x15 FULL puzzle

### Changed
- **`data/puzzles/mall_full_day_one.json` upgraded from 5x5 → 15x15.** Generated via `tools/puzzle_generate.gd -- full ... 1` against the new symmetric heavy-block pattern, then clue-authored by hand. The 15x15 has **78 slots: 39 across + 39 down**. Three horizontal bands separated by full-row block divides, each band containing three vertical pillars (4 + 5 + 4 letter slots per row). All 15 across rows and 13 of 15 columns are real English vocabulary.
- Theme metadata updated to `"Full-difficulty opening puzzle — 15x15"`.

### Added
- **CLI budget scaling** in `tools/puzzle_generate.gd`. The default 50 000-step backtrack budget is enough for 5x5 mini puzzles but fails on sparse 15x15 grids — bumped to **100 000 for MIDI** and **500 000 for FULL** so the solver has room to escape dead branches. MINI still uses the default.
- **Symmetric FULL block pattern.** The previous `full` pattern in `_pattern_for` was asymmetric (left over from a 5x5 prototype). Rewrote it as three 4-row bands (rows 0–3, 5–9, 11–14) split by full-row dividers (rows 4 and 10), each band cut by block columns at 4 and 10. 180° rotational symmetry verified by validator.

### Why it matters
This is the big one. The FULL tier is now a true Saturday-NYT-shaped puzzle: 15x15, dense, 78 slots, 15-letter rows broken into 4-5-4 columns. Players who clear MINI + MIDI on opening day can now reach for the real challenge — and the **180 Woints + 5-day streak bonus** payout finally lines up with the difficulty.

### Architecture
- **Same generator-then-hand-author workflow** as Phases 10.2 and 10.3. The 5,137-word bundled list filled the 15x15 grid with seed 1 in ~30 seconds at the new 500k budget. Author then wrote 78 clue strings; validator confirmed structural correctness.
- **Same `puzzle_id`** (`mall_full_day_one`) — keeps existing profile state working. Players who solved the 5x5 FULL placeholder see the new 15x15 as "already solved." Net-positive (they earned the Woints once already) and avoids profile migration.
- **Pillar grid layout.** Three bands × three pillars = nine 4x4 / 5x5 sub-blocks plus 2 horizontal dividers. Down clues span only within their band (4 or 5 cells), which is a forgiving structure for a curated 5 100-word list — bigger spanning downs would force vocab the bundled list can't cover yet.
- **Hand-curated answers.** Every word was checked against the bundled wordlist + a sanity pass. Highlights: spine anchors **ADVOCATES** (MIDI carry-over flavor), **OVERT**, **VERGE**, **DOZEN**, **ESTER**, **ENEMY**; vertical fill includes **SLAT**, **HAIR**, **UNDO**, **TEST**, **WILD**, **IDEA**, **NEAT**, **GAVE**, **SLED**, **SPOT**, **LIME**, **OPEN**, **BENT**.

### UX details
- 15 cells per side requires the bigger crossword UI panel; `CrosswordGridView` scales transparently. Cell pixel size is constant; the panel grows to ~600 px wide.
- All FULL-tier interactions (Tab to toggle direction, arrows, autoskip over block cells, pencil mode on backtick, check letter on slash) work identically — the input layer is geometry-agnostic.
- Solve banner triggers at all-78 correct, Continue returns to mall.

### Tests
- The existing `test_puzzle_schedule.gd::test_every_scheduled_id_across_all_difficulties_loads` meta-test now loads the new 15x15 file and verifies `grid.size > 0`. No code changes needed.
- `tools/puzzle_validate.gd` reports `OK` on the new puzzle.

### Pre-push checklist (Phase 10.4)
- [x] `godot --headless --quit` exit 0.
- [x] `godot --headless --quit-after 60 res://scenes/Main.tscn` exit 0.
- [x] `tools/puzzle_validate.gd` `OK` on all 9 puzzle files (7 MINI + 1 MIDI + 1 FULL).
- [x] GUT: 320/320 tests passing, exit 0 (no test changes — content + CLI tweak only).

### Known limitations
- **FULL schedule still has only day 1.** Days 2+ show "more FULL in a future update."
- **Generator budget tuning is per-pattern, not adaptive.** A pathological 15x15 with extreme constraint density might still need a manual seed sweep. Future enhancement: dynamic budget scaling based on slot count.
- **Wordlist density is uneven at length 6+.** Most 15x15 generations land on 4-5-letter slots because that's where the wordlist is dense. Bigger spanning words (7+) would require curating ~2× more vocabulary.

[0.10.4]: https://github.com/NickSanft/MallCross/releases/tag/v0.10.4

## [0.10.3] - 2026-05-24 — Phase 10.3: Real 9x9 MIDI puzzle

### Changed
- **`data/puzzles/mall_midi_day_one.json` upgraded from 5x5 → 9x9.** Generated via `tools/puzzle_generate.gd -- midi ... 7`, then clue-authored by hand. The 9x9 has 30 slots: 13 across + 17 down. Anchored by the 9-letter spine **ADVOCATES** running through the middle row, with **ACT** running vertically through the center. Surrounding it: USER / ICED / RELY / TARO / NAME / SNAG up top, OPAL / GAME / AUTO / OPEN / KNEW / TEND below, plus 16 three-letter downs flanking each side.
- Theme metadata updated to `"Mid-difficulty opening puzzle — 9x9"`.

### Why it matters
The MIDI tier is now a meaningfully different experience from MINI — 4× the cells, 6× the slots, two whole new vocabularies of 3- and 4-letter crossings. Solving MIDI Day 1 still pays the same 120 Woints + streak bonus; just feels earned now.

### Architecture
- **Generator → hand-author → ship.** Exactly the workflow Phase 10.2 set up: 5,100-word bundled list filled the grid in seconds; the human edits 30 clue strings; the validator catches any structural mistake on push.
- **Same `puzzle_id`** (`mall_midi_day_one`) — keeps existing profile state working. Players who solved the 5x5 see the new 9x9 as "already solved" because the ID didn't change. Mild net-positive (they earned the Woints once already) and avoids profile migration headaches.
- **Symmetric block pattern** — blocks at columns 4 on rows 0–2, 6–8 + center cross at row 3/5 col 4 + middle row clear. 180° rotational symmetry verified by validator.

### UX details
- 9 cells per side requires a bigger crossword UI panel; the existing `CrosswordGridView` scales to any N×N transparently (cell pixel size is constant; panel grows).
- Cursor navigation works identically — Tab to toggle direction, arrows to move through letter cells, autoskip over the 12 block cells.
- Coffee's check-letter highlight works on 9x9 the same way it did on 5x5 — flashes only the wrong cells in the current word.

### Tests
- The existing `test_puzzle_schedule.gd::test_every_scheduled_id_across_all_difficulties_loads` meta-test loaded the new 9x9 file and verified `grid.size > 0`. No code changes needed.
- `tools/puzzle_validate.gd` reports `OK` on the new puzzle.

### Pre-push checklist (Phase 10.3)
- [x] `godot --headless --import` clean.
- [x] `godot --headless --quit` exit 0.
- [x] `godot --headless --quit-after 60 res://scenes/Main.tscn` exit 0.
- [x] `tools/puzzle_validate.gd` `OK` on the new 9x9.
- [x] GUT: 320/320 tests passing, exit 0 (no test changes — content-only update).

### Known limitations
- **MIDI schedule still has only day 1.** Days 2+ show "more MIDI in a future update."
- **FULL is still 5x5.** Phase 10.4 will tackle the 15x15. Generator's `full` block pattern has a symmetry bug + the 50k backtrack budget isn't enough for sparse 7+ letter coverage — both will be addressed there.
- **All MIDI down clues are 3 letters.** A more sophisticated block pattern would mix in some 5- and 6-letter downs.

[0.10.3]: https://github.com/NickSanft/MallCross/releases/tag/v0.10.3

## [0.10.2] - 2026-05-24 — Phase 10.2: Constraint-solver puzzle generator

### Added
- **`data/wordlists/common_words.json`** — curated English wordlist organized by length. ~5,100 words spanning 3 to 15 letters. Heavy at 3-5 (where most slots in our patterns land); sparser at 11+. All entries are uppercase ASCII A-Z.
- **`scripts/Wordlist.gd`** — JSON loader with:
  - `words_of_length(n)` — length-indexed array access (the hot path for slot candidate enumeration).
  - `matches_pattern(p)` — filters by pattern like `"S.A.E"` (`.` = unknown).
  - `contains(word)` — O(1) word-membership check via a parallel set built at load time.
  - Defensive parsing: missing file / malformed JSON / wrong-length entries / non-alpha entries all get silently dropped.
- **`scripts/PuzzleGenerator.gd`** — backtracking constraint solver:
  - `PuzzleGenerator.fill(block_grid, wordlist, seed = 0, budget = 50000)` returns a filled `CrosswordGrid` or `null` if no fill exists within the backtrack budget.
  - **MRV** (most-constrained variable first) — picks the slot with the fewest candidate words each step. Fails fast on dead branches.
  - **Cross-slot validation** — every fully-filled slot is verified against `Wordlist.contains` each recursion. Catches the "row fills determine columns but columns aren't real words" pitfall.
  - **No-duplicate-word rule** — a fill that would repeat a word elsewhere in the grid is rejected.
  - **Deterministic with a seed** — internal Fisher-Yates shuffle uses the supplied `RandomNumberGenerator` instead of `Array.shuffle()` (which uses Godot's global RNG and ignores per-instance seeds).
- **`tools/puzzle_generate.gd`** — CLI front-end. Usage:
  ```
  godot --headless -s res://tools/puzzle_generate.gd -- <mini|midi|full> <output.json> [seed]
  ```
  Loads the bundled wordlist, picks a block pattern (5x5 / 9x9 / 15x15), fills it, writes a `CrosswordSerializer.puzzle_to_dict` JSON with placeholder clue text (`"TODO: <answer>"`). Author fills in real clues before shipping.
- **23 new GUT tests** across two files:
  - `tests/test_wordlist.gd` (12 tests) — bundled wordlist load shape, length filtering, pattern matching with wildcards, defensive parsing, all-uppercase invariant, total count.
  - `tests/test_puzzle_generator.gd` (11 tests) — 3x3 fill against the bundled list, every answer comes from the wordlist, null on impossible patterns, null inputs, block preservation, deterministic with seed, fills the mini pattern, validator passes the generated puzzle, no duplicate words.
- Total project test count: **320/320 across 23 scripts** (2,955 assertions — the wordlist meta-tests bulk this up significantly).

### Why it matters
Phase 10.3 (real 9x9) and Phase 10.4 (real 15x15) can now generate quality fills from a real wordlist instead of being blocked on hand-authoring. The CLI tool produces a JSON the author can drop into `data/puzzles/` after writing clue text.

### Architecture
- **Generator is wordlist-agnostic.** Pass in any `Wordlist` instance. Phase 10.3+ could swap in a themed mini-wordlist for a specific puzzle.
- **`Wordlist._word_set`** is a Dictionary used as a hash-set for O(1) membership. Worth the small load-time cost to avoid O(n) linear scans on the hot path inside `_solve`.
- **Validation happens inside the recursion**, not just at the leaf. Cross-slot constraints fail fast — usually in <100 backtracks for a 5x5, scaling roughly with grid size + density.
- **No external dependencies** — wordlist is a single JSON file, generator is one GDScript file, CLI is one more. Drop-in for anyone who wants to ship MallCross-style puzzles with different content.
- **Same `_make_box` pattern as MallGreybox** — generator is split into `_solve` (algorithm), `_slot_pattern` / `_snapshot_slot` / `_write_word` / `_restore_slot` (grid mutation helpers), and `_shuffle_with_rng` (deterministic randomization). Easy to extend with arc consistency or a domain store in a future pass.

### UX details
- CLI output reports the dictionary size: `"Generating mini (5x5) with 5137 words in the dictionary..."`. If the wordlist failed to load you'd see `0` and a clear error instead.
- On failure: `"Could not generate a valid puzzle within the backtrack budget. Try a different seed, a simpler pattern, or expanding the wordlist."` — actionable.
- Generated puzzle's clue text uses the `TODO:` prefix so an author searching the file can find every clue that still needs writing.

### Tests
- 23 new GUT tests covering load/lookup, pattern matching, full happy-path generation, all the dead-end branches (null inputs, empty wordlist, impossible block pattern), determinism, block preservation, validator round-trip, no-duplicate-word rule.

### Pre-push checklist (Phase 10.2)
- [x] `godot --headless --import` clean.
- [x] `godot --headless --quit` exit 0.
- [x] `godot --headless --quit-after 60 res://scenes/Main.tscn` exit 0.
- [x] CLI test: `puzzle_generate.gd -- mini /tmp/test_mini.json 42` → wrote a valid puzzle file.
- [x] GUT: 320/320 tests passing across 23 scripts (2,955 asserts), exit 0.

### Known limitations
- **Wordlist quality is starter-grade.** Common words only; few proper nouns or jargon. Longer-length buckets (11+) are sparse, so fills tend toward shorter words.
- **No theme constraint.** Generator doesn't know what's "interesting" — it picks whatever satisfies constraints. Real crossword authors hand-pick anchor entries first.
- **Block patterns are hardcoded in the CLI**. Three presets (mini/midi/full); no parameterization yet.
- **Backtrack budget is fixed at 50,000**. Most fills finish well under that, but very tight patterns or sparse wordlists could hit it. CLI exit code 1 signals "try a different seed or simpler pattern."
- **No clue generation.** Author still writes clue text by hand. Auto-cluing is well outside this phase.
- **Tested for solvability, not aesthetics.** A generated puzzle could have words like "EBB" / "EWE" / "URN" in a row — valid but boring. A future "puzzle quality scorer" could prefer fills with more interesting vocabulary.

[0.10.2]: https://github.com/NickSanft/MallCross/releases/tag/v0.10.2

## [0.10.1] - 2026-05-22 — Phase 10.1: MIDI + FULL puzzle tables (still 5x5 content)

### Added
- **`data/puzzles/mall_midi_day_one.json`** — 5x5 with SHARP / AROMA / FORGE across; SCARF / PLATE down. Real interlocking words, validator-clean.
- **`data/puzzles/mall_full_day_one.json`** — 5x5 with TAKEN / UNDER / EARTH across; TRUCE / NORTH down. Real interlocking words, validator-clean.
- **Multi-difficulty `PuzzleSchedule`**:
  - Three separate schedules (`_MINI_SCHEDULE`, `_MIDI_SCHEDULE`, `_FULL_SCHEDULE`) so each tier solves independently. Solving MIDI day 1 doesn't mark MINI day 1 solved (different `puzzle_id`).
  - `puzzle_id_for_day(day, difficulty = "mini")`, `has_puzzle_for_day`, `scheduled_days`, `last_scheduled_day` all take an optional `difficulty` arg.
  - Difficulty constants: `DIFFICULTY_MINI`, `DIFFICULTY_MIDI`, `DIFFICULTY_FULL`. Case-insensitive lookup; unknown difficulties fall back to MINI.
  - `all_difficulties()` for tests / future UI.
- **`MallGreybox`**: MIDI and FULL tables are now `daily_puzzle` interactables (joining MINI). Each table stores its tier in a `difficulty` meta key (`"mini"` / `"midi"` / `"full"`) and gets the per-tier Woints reward (50 / 120 / 300) from `WointsConfig`.
- **`GameController` dispatch**: reads `difficulty` from interactable metadata, passes it to `PuzzleSchedule.puzzle_id_for_day`. Prompt text now says `[E] Solve MINI Day N` / `[E] Solve MIDI Day N` / `[E] Solve FULL Day N` and reports tier-specific completion messages.
- **`_last_seen_interactable` cache** on `GameController` so `_show_daily_puzzle_prompt` can re-render after out-of-band state changes (sleep transition, modal close) without re-routing through the Player.
- **8 new `PuzzleSchedule` tests** in `tests/test_puzzle_schedule.gd`: MIDI / FULL day-1 lookups, day-2 returns empty for both, `last_scheduled_day` per difficulty, case-insensitive difficulty lookup, unknown-difficulty fallback, `all_difficulties` count, **meta-test that loads every scheduled puzzle across all three difficulties** (so adding a future schedule entry without a JSON file fails CI).
- Total project test count: **298/298 across 21 scripts** (574 assertions).

### Why it matters
First time MIDI and FULL tables actually do anything. Player now has three distinct puzzles to solve on day 1 — MINI / MIDI / FULL — each paying its own reward (50 / 120 / 300 Woints, plus the streak bonus on first solves). A perfect day 1 across all three tiers earns **470 Woints** in a single in-game day (almost enough for a Mall Cap on its own).

### Architecture
- **Same dispatcher, new dimension.** The `daily_puzzle` interactable model gained a `difficulty` axis without changing the core flow — `GameController._open_puzzle` still takes a single `puzzle_id`, the schedule just resolves it per-tier now.
- **Per-tier solve tracking.** Each tier's puzzle has a unique `puzzle_id` in the bundled JSON, so the Profile's `puzzles_solved` set distinguishes them. Solving MINI day 1 and MIDI day 1 are two separate entries.
- **Sparse schedules are first-class.** MIDI and FULL ship with only day 1 entries; days 2-7 just return `""` and the prompt reads "more in a future update." No special-casing in the controller — same flow as MINI's "Week 1 complete" message.
- **MINI hints stay MINI-only.** `HintRoster` still defaults to mini and only data/hints/mall_day_one..seven exist. MIDI and FULL puzzles deliberately ship without NPC hints — bigger puzzles ask for more independent solving. Phase 10.x could add per-difficulty hints if desired.

### UX details
- Walking up to the MIDI or FULL table now shows `[E] Solve MIDI Day 1` (or FULL). Solving it shows `+120 Woints` (or 300) plus the standard streak bonus.
- Each tier's "no puzzle today" message says the tier name explicitly so a player whose schedule has gaps knows which tier they're missing.
- All tables look identical visually (same `MINI` / `MIDI` / `FULL` labels from Phase 2). Phase 8.x art pass could re-color them to signal difficulty.

### Honest caveat
**All three puzzles are still 5x5.** The project's design memory calls for 15x15 NYT-style puzzles at the FULL tier, and ideally 9x9 at MIDI. Hand-authoring quality 9x9 / 15x15 puzzles takes hours per puzzle — significantly out of scope for a single commit cycle. Phase 10.1 ships the **architecture** (per-difficulty schedules, per-tier rewards, table-tier dispatch) so future content phases (Phase 10.2+) can drop real bigger-size puzzles into MIDI/FULL by editing one JSON file and one schedule line each.

A **constraint-solver puzzle generator** (Phase 10.x candidate) would unlock proper 9x9 / 15x15 fill quality from a bundled wordlist. Tracked as a known limitation; ping if you want me to prioritize.

### Tests
- `tests/test_puzzle_schedule.gd` — extended from 11 to 19 tests covering all three difficulties + cross-difficulty meta-test.

### Pre-push checklist (Phase 10.1)
- [x] `godot --headless --import` clean.
- [x] `godot --headless --quit` exit 0.
- [x] `godot --headless --quit-after 60 res://scenes/Main.tscn` exit 0.
- [x] `tools/puzzle_validate.gd` `OK` on both new puzzles + all existing.
- [x] GUT: 298/298 tests passing across 21 scripts (574 asserts), exit 0.

### Known limitations
- **All three tier puzzles are 5x5.** True 9x9 / 15x15 deferred (see "Honest caveat").
- **MIDI and FULL have only day 1 puzzles.** Day 2+ shows "more in a future update."
- **No hints for MIDI / FULL.** Hints currently MINI-only.
- **Table appearance is identical** across tiers. Phase 8.x could color-code by difficulty.
- **No "earn one of each per day" achievement / signal.** Just three separate solves with three separate rewards.

[0.10.1]: https://github.com/NickSanft/MallCross/releases/tag/v0.10.1

## [0.10.0] - 2026-05-22 — Phase 10: Settings menu + reset save

### Added
- **`scripts/SettingsManager.gd`** — disk I/O + value clamping for player-tunable settings. JSON at `user://settings.json`. Three settings ship in Phase 10:
  - `mouse_sensitivity` (default 0.002, range 0.0005 – 0.01)
  - `master_volume_db` (default 0 dB, range -60 to +6 dB)
  - `footstep_volume_db` (default -8 dB, range -40 to 0 dB)
  - Defensive: missing file / malformed JSON / out-of-range values all fall through to clamped defaults. The game can never boot into a state where the mouse is unmovable or the volume is broken.
  - `normalize(settings)` exposes the clamping helper so callers can sanitize raw input.
- **`scripts/SettingsMenu.gd` + `scenes/SettingsMenu.tscn`** — modal pause menu. Title, three sliders with live numeric readouts, a destructive "Reset Save" button (red text), and a "Close (Esc)" button. Slider changes fire `settings_changed` for live application (drag the mouse-sensitivity slider, feel the camera response change in real-time). Layout built programmatically in `_ready` — same pattern as `CrosswordUI` / `ShopUI`.
- **`ConfirmationDialog`** in `SettingsMenu` for the reset flow — explicit "Reset all save data? This deletes your Woints, day, solved puzzles, and inventory. Cannot be undone." with Cancel / OK. Confirming emits `reset_save_requested`; `GameController` deletes the profile file and reloads a fresh default.
- **`Player.set_mouse_sensitivity(float)`** + **`Player.set_footstep_volume_db(float)`** — settings drive these at runtime. `MOUSE_SENSITIVITY` was promoted from a const to `_mouse_sensitivity: float` with a `DEFAULT_MOUSE_SENSITIVITY` constant for the initial value.
- **`GameController` settings glue**: loads via `SettingsManager.load_from_path()` on `_ready`, calls `_apply_settings` to push values into the Player + master AudioServer bus; opens the settings menu on Esc (when no other modal is up); applies live changes via the `settings_changed` signal; saves on close.
- **Esc handling moved from `Player` to `GameController`.** Player used to toggle mouse capture on Esc — that's gone. `GameController._unhandled_input` now owns Esc and routes it to the settings menu (or lets the active modal catch it first). Mouse capture / release is now a side effect of `Player.set_paused_for_ui()`, driven by modal state.
- **14 new GUT tests** in `tests/test_settings_manager.gd`: default-settings shape + key set, load-missing-file fallback, save+load round-trip preserves all 3 values, garbage/empty-file fallback, clamping for each setting (too high, too low, missing keys), delete-and-check, save persists clamped (not raw) values to disk.
- Total project test count: **290/290 across 21 scripts** (560 assertions).

### Why it matters
First time the player can change anything. Mouse sensitivity was a one-line edit in `Player.gd` before; now it's a slider. Master volume affects every audio output (footsteps, plus future music / shop chimes). "Reset Save" gives a clean recovery path for testing or for sharing the game with another player on the same install.

### Architecture
- **`SettingsManager` mirrors `ProfileStore`**: same load / save / delete API, same defensive parsing, same temp-path-per-test cleanup pattern in the test file. One mental model for "things persisted to user://".
- **Settings are a plain `Dictionary`**, not a custom class. Trivially JSON-serializable, easy to pass through signals, easy to clamp uniformly. Same trade-off as Profile's solve-state representation.
- **Live application via signal, not poll.** `SettingsMenu` emits `settings_changed` on every slider tick; `GameController` re-applies. No per-frame setting-comparison logic in Player or audio bus management.
- **`Reset Save` is per-file, not per-key.** Deletes the entire profile and reloads a fresh default. Settings (which live in a separate file) are untouched — so you can reset progress without losing your tuned mouse sensitivity.
- **`Esc` is a controller concern, not a Player concern.** Player owns first-person motion; the controller owns the UI state machine. Phase 11's quit/menu flow plugs into the same handler.

### UX details
- Sliders show live value next to each (4-decimal float for sensitivity, integer dB for the two volumes).
- "Reset Save" button is red-tinted so accidental clicks register as a *destructive* action visually.
- "Close (Esc)" button label matches the keybind so players don't have to discover it.
- Settings dialog is the only modal you can open from "nothing else is up" — there's exactly one Esc behavior to remember from gameplay.
- Mouse mode flips visible the instant the menu opens (via `set_paused_for_ui(true)`); flips back to captured the instant it closes.

### Tests
- `tests/test_settings_manager.gd` — 14 tests across defaults, load/save round-trip, defensive parsing, clamping for all 3 values, delete behavior, save-persists-clamped.

### Pre-push checklist (Phase 10)
- [x] `godot --headless --import` clean.
- [x] `godot --headless --quit` exit 0.
- [x] `godot --headless --quit-after 60 res://scenes/Main.tscn` exit 0 (SettingsMenu instantiates cleanly in headless).
- [x] GUT: 290/290 tests passing across 21 scripts (560 asserts), exit 0.

### Known limitations
- **No save slots** — original Phase 10 plan called for them; deferred to Phase 10.1+. Single profile per machine for now.
- **No FOV slider.** The first-person camera uses Godot's default 75° FOV; would be a one-line addition to the menu + a new setting key.
- **No keybinding remap.** Hardcoded `move_forward` = W, etc. Phase 10.x could add a keybind UI.
- **No accessibility features** beyond the volume sliders. Colorblind modes, larger fonts, high-contrast UI, subtitles for NPC speech — all deferrable.
- **Audio buses are flat** — only "Master" exists. SFX / music / dialog buses with separate sliders would scale better once there's more sound.
- **No "Save settings as defaults" or import/export.** Each install has its own settings file; no profile-sharing flow.
- **Resetting save while standing on the sleep cushion** still keeps the prompt visible until next interaction-target update. Minor UX nit.

[0.10.0]: https://github.com/NickSanft/MallCross/releases/tag/v0.10.0

## [0.9.1] - 2026-05-22 — Phase 9.1: Per-day puzzle hints in NPC dialog

### Added
- **`scripts/HintRoster.gd`** — loads NPC hint dialog from `data/hints/<puzzle_id>.json`. Resolves today's puzzle via `PuzzleSchedule`, returns a `{npc_id → hint_text}` dict. Defensive: missing file, malformed JSON, wrong shape, empty puzzle ID — all return `{}` and callers fall back to flavor dialog.
- **7 hint files** under `data/hints/`, one per scheduled day:
  - `mall_day_one.json` — hints toward PUTTS / SCORE / PEACH
  - `mall_day_two.json` — SLOSH / HARDY / ALDER
  - `mall_day_three.json` — ALONG / GENRE / ABACK
  - `mall_day_four.json` — STORM / METAL / SCALD
  - `mall_day_five.json` — BRASS / SNARE / ELITE
  - `mall_day_six.json` — FLOOD / DRAMA / FLAME
  - `mall_day_seven.json` — DARTS / SPADE / DOUBT
  - Each NPC's line nudges toward one specific answer without spelling it out (e.g., `"I sank three short golf shots in a row at the course this morning."` → PUTTS).
- **`MallGreybox._spawned_npcs`** — `{npc_id → NPC instance}` dict populated by `_spawn_npcs`. Lets `GameController` reach into the mall to update NPC dialog without re-spawning.
- **`MallGreybox.apply_npc_hints_for_day(day)`** — iterates the roster, looks up today's hints, calls `npc.set_dialog(hint)` per NPC. NPCs with no hint for the day get the flavor default re-applied (idempotent — safe to call multiple times).
- **`GameController._ready` calls `_mall.apply_npc_hints_for_day(_profile.current_day)`** after loading the profile, so the first time the player walks past an NPC they hear today's hint.
- **`GameController._on_fade_to_black_done` re-applies hints** for the new day at the darkest point of the sleep transition — by the time the fade-back finishes, NPCs are saying tomorrow's lines.
- **11 GUT tests** in `tests/test_hint_roster.gd`: 3-entry day-1 hint count, keys match NPC IDs, defensive returns on bad days (0, negative, beyond schedule), `hint_for(npc_id, day)` happy + sad paths, **meta-test ensuring every scheduled day has a hints file with at least one entry**, and a second meta-test ensuring every hint key in every file references a real NPC. Cross-file drift gets caught on the first push.
- Total project test count: **276/276 across 20 scripts** (537 assertions).

### Why it matters
The eavesdrop-clue hint system from the original game design is now wired. Walking past the corridor shopper on day 1 reveals *"Georgia's state fruit always looks so fuzzy in the produce aisle"* — and PEACH is exactly the 1-Down answer for day 1's puzzle. Sleep to day 2 and the same NPC now mentions alder cones (3-Across is ALDER). Each day's three NPCs collectively hint at 3 of the 5 answers — enough to nudge a stuck player without taking the joy out of the solve.

### Architecture
- **Hint data is per-puzzle, not per-day-of-week.** Files key on `puzzle_id` so `PuzzleSchedule` can rearrange days without breaking hint linkage. The `mall_day_three.json` filename happens to match because that's how `PuzzleSchedule` currently maps day 3 — a future schedule shuffle automatically keeps hints attached to puzzles.
- **`HintRoster` knows nothing about NPCs.** It's a flat key/value file loader. `NPCRoster` defines who the NPCs are; `HintRoster` defines what they might say. Combining them is `MallGreybox`'s job.
- **`MallGreybox` is the only consumer that touches the NPC instances directly.** `GameController` just calls `apply_npc_hints_for_day`. Phase 9.2+ wandering NPCs would slot in here without controller changes.
- **Re-application is destructive but cheap.** Each call resets every NPC's dialog from scratch (hint-or-flavor). Means there's no stale-dialog edge case after multiple sleeps or after the player leaves and re-enters the food court.

### UX details
- Hints are written in conversational English, not crossword-clue voice — they sound like things mall regulars would actually say.
- Each NPC has a consistent "personality" across days:
  - **patron_a** (blue, MIDI table) — talks about activities: golf, marching bands, theater clubs.
  - **patron_b** (reddish-brown, FULL table) — talks about possessions / interests: books, tools, hunting traps.
  - **corridor_shopper** (green, near Store 1) — talks about appearances / impressions: fruit colors, coffee burns, hat prices.
- The fill-in-the-blank style (`"taken ___"`) is reserved for day-3 hints where it fits the answer (ABACK is hard to evoke otherwise).

### Tests
- `tests/test_hint_roster.gd` — direct API tests + two cross-file meta-tests catching drift between schedule, NPC roster, and hint files.
- Existing puzzle-validate CI step is unchanged; hints aren't run through it (different validator rules). A future CI step could check JSON validity of `data/hints/*` too.

### Pre-push checklist (Phase 9.1)
- [x] `godot --headless --import` clean.
- [x] `godot --headless --quit` exit 0.
- [x] `godot --headless --quit-after 60 res://scenes/Main.tscn` exit 0 (hint application during `_ready` runs without error).
- [x] GUT: 276/276 tests passing across 20 scripts (537 asserts), exit 0.

### Known limitations
- **One hint per NPC per day.** No randomized rotation, no escalating-specificity, no "you've heard this already" tracking. Phase 9.2+ could vary hints across approaches.
- **Hints aren't validated against actual answers.** A bad hint pointing at a wrong cell would still pass — the validator only checks dict shape + roster cross-references. Could add a heuristic check ("does the hint mention the answer word?") but that's brittle.
- **No "hint already given" audio cue.** Walking past the same NPC twice shows the same line both times.
- **Hints aren't part of the puzzle JSON.** Kept as separate files for clear separation of concerns; means a Phase 7-style "drop in a new puzzle" requires two files now (puzzle + hints). The puzzle-validate CI step ensures puzzles are clean; hints are validated by the GUT meta-test.

[0.9.1]: https://github.com/NickSanft/MallCross/releases/tag/v0.9.1

## [0.9.0] - 2026-05-22 — Phase 9: Mall NPCs with proximity-triggered dialog

### Added
- **`scripts/NPC.gd` + `scenes/NPC.tscn`** — placed mall NPC built programmatically in `_ready`:
  - `StaticBody3D` body with `CapsuleShape3D` collision so the player can't walk through.
  - `CapsuleMesh` body (radius 0.3, height 1.6) + `BoxMesh` head (0.42³).
  - Both use the Phase 8 PS1 vertex-snap shader (`ps1_box.gdshader`) with per-NPC body/head colors — they fit visually with the rest of the mall instead of looking like Unity grey-mannequins parked in a PS1 game.
  - Billboarded `Label3D` speech bubble ~2.6 m above the floor, `no_depth_test = true` so it floats clean above geometry without z-fighting (same fix as the store labels).
  - `Area3D` with a 4 m radius `SphereShape3D` trigger reveals the speech label on `body_entered(Player)` and hides on `body_exited(Player)`.
- **`scripts/NPCRoster.gd`** — pure static list of 3 placed NPCs (id, position, facing, dialog, body color, head color):
  - `food_court_patron_a` — sitting near the MIDI table: *"I always start with the down clues — they feel easier."*
  - `food_court_patron_b` — sitting near the FULL table: *"The food court has the best ambient light for puzzling."*
  - `corridor_shopper` — standing facing Store 1: *"That coffee from Store 1 is how I catch my typos."*
  - `required_keys()` helper for tests that need to assert dict shape without duplicating the field list.
- **`MallGreybox._spawn_npcs`** iterates the roster, instantiates `NPC.tscn` per entry, copies the data onto the instance, and positions/rotates it. Called once during the existing `_ready` chain.
- **10 new GUT tests** in `tests/test_npc_roster.gd`: roster size, required-keys coverage, ID uniqueness + non-empty, dialog non-empty, positions inside mall bounds, ground-level y, facing normalized to [-360, 360], colors in [0,1], required-keys list contains the obvious fields.
- Total project test count: **265/265 across 19 scripts** (498 assertions).

### Why it matters
The mall feels populated for the first time. Walking through the corridor or food court, you pass NPCs whose dialog only appears when you're close enough to "overhear" them — exactly the eavesdrop-clue UX the project memory called for in Phase 9. The infrastructure is now in place for Phase 9.1 to swap the flavor lines for per-day puzzle hints (e.g., "Today's 1-Across is a golf-bag staple" → hinting PUTTS).

### Architecture
- **NPC visuals built in code, not authored as a `.tscn`.** Same pattern as `MallGreybox`, `CrosswordUI`, `HUD` — keeps the `.tscn` to a single root + script, lets per-NPC color/dialog be a Dictionary lookup.
- **Roster is pure data**, no node refs. Trivially testable; the `MallGreybox` spawner is the only consumer that walks the list. A Phase 9.1 swap to `data/npcs.json` is mechanical.
- **Proximity detection via `Area3D.body_entered`**, not per-frame distance checks. Godot's physics broadphase does the work; the NPC script just toggles label visibility.
- **NPCs are NOT in the `interactable` group.** The HUD prompt stays silent around them — eavesdropping is passive, not "press E to talk." That keeps interaction prompt real-estate clear for tables, shops, and the sleep cushion.
- **Speech labels use `no_depth_test`** for the same reason as store labels — vertex wobble of the PS1 shader would otherwise z-fight the floating text. Lessons from `v0.8.1` reapplied.

### UX details
- Speech labels appear instantly on entry, vanish instantly on exit — no fade. Could become a fade-tween in a polish pass, but the abrupt toggle reads as "oh, I can hear them now" which matches the eavesdrop framing.
- Bodies block the player so you can't run THROUGH NPCs, but you can walk all the way around them. The 4 m proximity radius is bigger than the capsule (0.3 m), so the speech triggers well before any physical contact.
- NPCs face whatever direction the roster specifies (`facing_y_degrees`). For now the food court patrons face the corridor mouth (so you see them as you walk in); the corridor shopper faces Store 1 (looks like they're browsing).

### Tests
- `tests/test_npc_roster.gd` — 10 tests on the roster data: bound checks, required keys, uniqueness, color validity. The `NPC` scene itself isn't unit-tested (heavy on scene-tree behavior), but the 60-frame `Main.tscn` smoke-run boots all three NPCs without runtime errors.

### Pre-push checklist (Phase 9)
- [x] `godot --headless --import` clean.
- [x] `godot --headless --quit` exit 0.
- [x] `godot --headless --quit-after 60 res://scenes/Main.tscn` exit 0 (3 NPCs instantiate + integrate into physics without crashing).
- [x] GUT: 265/265 tests passing across 19 scripts (498 asserts), exit 0.

### Known limitations
- **Static NPCs.** No wandering, no patrol, no idle animations. Phase 9.1+ could add a simple `target_position`-based wander.
- **Dialog is hardcoded flavor**, not tied to today's puzzle. Phase 9.1 will wire a `data/hints/<puzzle_id>.json` lookup so NPCs hint at clue answers contextually.
- **Each NPC has one line.** Could rotate through several, especially per-day.
- **Same NPC body model for all three.** Just color swaps. Phase 8.x art pass could add hat / outfit variation, especially once the Mall Cap cosmetic actually renders on the player.
- **No NPC audio.** Pure visual speech bubble. A future polish could add a low mumble loop near each NPC that fades in/out with proximity.
- **Speech text doesn't wrap.** Long lines extend horizontally; current lines were authored to stay short.

[0.9.0]: https://github.com/NickSanft/MallCross/releases/tag/v0.9.0

## [0.8.2] - 2026-05-22 — Phase 8.1: Procedural footstep audio

### Added
- **`scripts/FootstepAudio.gd`** — synthesizes a footstep "thump" `AudioStreamWAV` at runtime. 22.05 kHz mono 16-bit, 60 ms duration, single-pole IIR-low-passed white noise with an exponential decay envelope (`exp(-t * 40)`). Deterministic via a fixed seed so the same sound plays every time; total cost is ~2.6 KB of computed PCM data — no binary audio asset shipped.
- **`AudioStreamPlayer3D` on the Player** created in `_ready` (programmatic — keeps `Player.tscn` untouched). Stream is the procedural footstep, base volume `-8 dB`, `unit_size = 1.0`.
- **Step detection in `_update_head_bob`**: reuses the existing `_bob_distance` accumulator (which already tracks ground-truth meters walked, freezing when standing still or in the air). Every `FOOTSTEP_DISTANCE = 1.8 m` the player crosses, `_play_footstep` fires. Pitch is randomized per step in `[0.92, 1.08]` so consecutive footfalls don't sound mechanical.
- **9 new GUT tests** in `tests/test_footstep_audio.gd`: non-null + correct format / mix rate / channel count, data length matches the duration × sample rate computation, mid-envelope sample is non-zero (synth pipeline is alive), end-of-envelope sample is smaller than early-envelope (decay works), deterministic output (same seed → identical PCM data on repeat calls).
- Total project test count: **255/255 across 18 scripts** (428 assertions).

### Why it matters
The mall finally **sounds** like you're walking through it. Combined with Phase 8's vertex wobble + fog, the lo-fi PS1 vibe is now in both eyes and ears. Sprinting visibly + audibly speeds the step cadence; standing still goes silent.

### Architecture
- **No binary audio asset.** Synthesizing the footstep at startup keeps the repo lean and means a future "settings → footstep volume" or "themed alternate footstep" change is a one-line code edit, not an asset re-roll.
- **Step trigger lives on the same accumulator as head-bob.** One source of truth for "how far did the player walk this physics frame" — head-bob and footstep stay perfectly in sync, and pausing for a UI modal pauses both.
- **AudioStreamPlayer3D, not 2D.** The player IS the source, so spatial falloff is irrelevant in practice — but the 3D variant lets a future "NPC footsteps" feature drop the same generator into other characters without architectural changes.
- **Pitch randomization is uniform, not curve-shaped.** Tested by ear at ±8% — wider feels artificial, tighter sounds robotic. Easy dial if it needs tweaking.

### UX details
- Sprinting (Shift) doubles cadence vs. walking, exactly as you'd expect — same step distance, faster traversal.
- Jumping silences mid-air (the accumulator only advances when `is_on_floor()` and horizontal speed > 0.1).
- Modal open (puzzle / shop / sleep transition) → physics paused → no spurious footsteps during a fade.

### Tests
- `tests/test_footstep_audio.gd` — format/rate sanity, data-size math, envelope decay verification, determinism. Headless-friendly: tests inspect the PCM byte buffer directly, no audio device required.

### Pre-push checklist (Phase 8.1)
- [x] `godot --headless --import` clean.
- [x] `godot --headless --quit` exit 0.
- [x] `godot --headless --quit-after 60 res://scenes/Main.tscn` exit 0 (audio system initializes silently in headless).
- [x] GUT: 255/255 tests passing across 18 scripts (428 asserts), exit 0.

### Known limitations
- **One footstep sound for all surfaces.** Floor, food court tile, sleep cushion — same thump. Future polish could swap stream by ground type via a raycast under the player.
- **No surface volume variance.** Carpet would feel quieter than tile in a real mall; current build is flat-volume.
- **No "first step heavier" or "stop sound."** Real footsteps have transient differences when accelerating; this is a steady 1.8m cadence.
- **Mall has no other ambient audio yet** — no music, no crowd murmur, no shop chime. Phase 9 (NPCs) likely brings ambience.

[0.8.2]: https://github.com/NickSanft/MallCross/releases/tag/v0.8.2

## [0.8.1] - 2026-05-22 — Fix Label3D flicker against vertex-snapped facades

### Fixed
- **Store-front, food-court, and sleep-cushion labels flickered violently when walking around.** Root cause: Phase 8's PS1 vertex-snap shader jitters facade vertices in NDC space — at typical viewing distance that's ~7 cm of world-space wobble, which crossed the tiny 2 cm clearance between each store label and the facade behind it. Every frame the label and the facade alternated which one passed the depth test, producing pixel-level strobing across the glyph edges.

### Changed
- Every `Label3D` in `MallGreybox` (store names, MINI/MIDI/FULL table labels, SLEEP cushion label) now sets `no_depth_test = true`. Labels always render on top of 3D geometry regardless of the depth buffer — wobble can no longer "hide" them.

### Trade-off
Labels are now visible through any geometry that would otherwise occlude them. In the current closed-corridor mall this is invisible to the player (you can't get behind a store-front to see its label through a wall). If a future open-mall layout exposes a viewing angle where this matters, the fix is to add a small per-label `outline_size` and rely on outline-on-fog rather than depth comparison.

### Pre-push checklist
- [x] `godot --headless --quit` exit 0.
- [x] `godot --headless --quit-after 60 res://scenes/Main.tscn` exit 0.
- [x] GUT: 246/246, exit 0 (no test changes — fix is property-only).

[0.8.1]: https://github.com/NickSanft/MallCross/releases/tag/v0.8.1

## [0.8.0] - 2026-05-22 — Phase 8: PS1/N64 art pass (vertex snap + atmospheric fog)

### Added
- **`shaders/ps1_box.gdshader`** — spatial shader implementing the classic PS1 vertex-snap wobble:
  - `skip_vertex_transform` render mode so the shader owns the model→view→projection chain.
  - Snaps clip-space xy positions to a low-res NDC grid (controlled by `vertex_snap` uniform; default 100 ≈ 320-pixel snap).
  - Behind-near-plane guard skips the snap on degenerate vertices (avoids w-divide artifacts at the camera).
  - `vertex_lighting` render mode shades faces per-vertex instead of per-pixel — the omni lights along the corridor now cast that authentic chunky lo-fi shading across each wall and floor panel.
- **`MallGreybox._make_ps1_material`** — factory that builds a `ShaderMaterial` from the PS1 shader with a per-box albedo color. Replaces every prior `StandardMaterial3D` in the mall (floor, ceiling, corridor walls, store-front facades, food court walls, tables, sleep cushion — ~60 surfaces).
- **Atmospheric fog** in the WorldEnvironment: dark blue-purple (`Color(0.18, 0.18, 0.24)`) at density `0.025`, with sky/sun scatter zeroed. Calibrated so the entrance is just visible from the food court while distant geometry softly falls into the dark.
- **Ambient light tuned** — slightly cooler (`Color(0.75, 0.80, 0.95)`) and dimmer (`0.30`) to let the omni lights pop and to make the fog visible.

### Why it matters
The mall finally has *vibes*. The geometry jitters subtly as the player walks (vertex snap), light falls in chunky bands across each face (vertex lighting), and distant corridor stretches fade into atmospheric haze (fog). Same blocky greybox geometry as Phase 2, but now it reads as "lo-fi PS1 mall" rather than "Godot test scene."

### Architecture
- **One shader, many materials.** Every box has its own `ShaderMaterial` so colors can vary, but they all share the same compiled `ps1_box.gdshader`. Adding textured surfaces in a future phase is a one-uniform change.
- **`PS1_VERTEX_SNAP` constant in `MallGreybox`** controls the snap intensity globally. Tuning is a one-line change; could become a settings-menu option in Phase 10.
- **Fog lives on the existing WorldEnvironment** — no new node, no new system. Fog density is the dial; color is the mood.
- **`Label3D` text and the CrosswordUI/HUD remain crisp.** The shader only applies to box meshes (via `_make_box`), so all UI text rendering is untouched. Authenticity in the world, readability in the UI.

### UX details
- Wobble is gentle enough that close-up text labels (STORE 1, MINI, SLEEP) on the billboarded `Label3D` nodes stay readable. Those nodes don't use the shader.
- Fog density was tuned at the corridor's full ~40 m length so the player can still spot the food court tables from the entrance — atmosphere without disorientation.
- Vertex lighting makes the four corridor omni lights *look* like actual fixtures bathing the walls in pools of light, instead of the previous evenly-lit per-pixel result.

### Tests
- No GUT additions — shader behavior is graphical and not unit-testable. The 60-frame headless smoke-run boots the shader without compile errors, and the existing test suite (246/246) still passes since gameplay logic is untouched.

### Pre-push checklist (Phase 8)
- [x] `godot --headless --import` clean (shader compiled and imported with the project).
- [x] `godot --headless --quit` exit 0.
- [x] `godot --headless --quit-after 60 res://scenes/Main.tscn` exit 0 (shader runs in headless mode).
- [x] GUT: 246/246 tests passing, exit 0.

### Known limitations
- **No textures yet.** The shader has a texture sampler hook ready but the game still uses solid colors. Phase 8.1+ can drop in 64–128 px textures with `filter_nearest` and the look snaps into "real PS1."
- **No affine texture mapping.** Implementing the famous PS1 texture warp requires `noperspective` varyings, which Godot 4's shader language doesn't expose directly. A workaround using per-vertex UV pre-multiplication is possible but didn't fit Phase 8's narrow scope.
- **No low-res SubViewport render.** Rendering at 480x270 and upscaling with nearest-neighbor filtering would push the look even further toward authentic PS1 — but the project's UI scaling currently assumes full window resolution, so this is Phase 8.2 architectural work.
- **No footstep audio.** Phase 8.1 will add an `AudioStreamPlayer3D` on the Player firing on each step (synthesized click or short WAV asset).
- **Player has no visible body or shadow.** Cosmetic items (Mall Cap) still don't appear on the player. Phase 8.x rendering pass.
- **Vertex snap is global, not per-room.** A future polish could vary the wobble (e.g. tamer in the food court, more aggressive in dark corridors) by swapping shader uniforms based on player position.

[0.8.0]: https://github.com/NickSanft/MallCross/releases/tag/v0.8.0

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

[Unreleased]: https://github.com/NickSanft/MallCross/compare/v0.10.3...HEAD
[0.0.1]: https://github.com/NickSanft/MallCross/releases/tag/v0.0.1
