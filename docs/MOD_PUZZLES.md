# Modding crossword puzzles into MallCross

Drop a `.json` file into your local puzzle directory and it shows up on the **COMMUNITY** table in the food court the next time you walk up. No menu setting to enable, no rebuild required.

## Where to put the files

The puzzle directory lives next to your save file:

| OS | Path |
|---|---|
| Windows | `%APPDATA%\Godot\app_userdata\MallCross\puzzles\` |
| macOS | `~/Library/Application Support/Godot/app_userdata/MallCross/puzzles/` |
| Linux | `~/.local/share/godot/app_userdata/MallCross/puzzles/` |

Internally the game refers to this as `user://puzzles/`. The directory is created on first community-puzzle launch — or you can create it by hand. Any `.json` file inside is picked up; subdirectories are ignored.

## File format

A community puzzle uses the same shape as the bundled ones in `data/puzzles/`. The minimum required fields:

```json
{
    "version": 1,
    "title": "My Custom MINI",
    "author": "YourName",
    "theme": "A puzzle about my cat",
    "size": 5,
    "grid": [
        ".....",
        ".###.",
        ".....",
        ".###.",
        "....."
    ],
    "clues": [
        {"number": 1, "direction": "across", "row": 0, "col": 0, "length": 5, "text": "Your clue here"},
        ...
    ]
}
```

### Grid rules

- **Square.** `size × size` rows and columns. The validator rejects non-square grids.
- **180° rotational symmetry.** Black squares at `(r, c)` must mirror to `(size-1-r, size-1-c)`. This is the standard American-crossword constraint and the rule the validator enforces.
- **No two-letter words.** Every slot (across or down) must be at least 3 letters long. Slots shorter than 3 trigger a `short_word` error.
- **Block character.** Use `#` for black squares, letters (uppercase) for filled cells. Lowercase letters are accepted but uppercased on load.

### Clue rules

- **One clue per slot.** Each across/down slot needs an entry in the `clues` array with matching `number`, `direction` ("across" or "down"), `row`, `col`, and `length`.
- **Non-empty text.** Empty clue strings fail validation.
- **No duplicates.** `(number, direction)` pairs must be unique.

## Validating before you ship

Drop your file into `user://puzzles/`, launch the game, walk to the COMMUNITY table. The picker lists every file with one of two states:

- **✓ Valid** — clickable, plays normally.
- **✗ Error: <reason>** — un-clickable. The first error from the validator is shown so you can see what to fix without leaving the game.

If you want to validate from the command line without launching:

```sh
godot --headless -s res://tools/puzzle_validate.gd -- /path/to/your/puzzle.json
```

Exit code 0 means no errors, 1 means at least one error. Warnings (e.g. orphan clues that don't match any slot) print but don't fail.

## Rewards

Solving a community puzzle pays **60 Woints** (half the MIDI rate). Community solves intentionally do *not* extend your daily streak — otherwise dropping 7 of your own puzzles in could trivially run the streak counter up without engaging the curated content.

Achievements that don't reference specific puzzle IDs (First Solve, Going It Alone, Hoarder, etc.) DO count community solves. Tier-gated achievements (MINI Day 1, Polyglot, etc.) don't.

## A worked example

A complete 5×5 MINI you can drop into `user://puzzles/` to test:

```json
{
    "version": 1,
    "title": "Modder Test",
    "author": "ExampleAuthor",
    "theme": "Smoke-test puzzle",
    "size": 5,
    "grid": [
        "PUTTS",
        "E###C",
        "AMIGO",
        "C###R",
        "HALVE"
    ],
    "clues": [
        {"number": 1, "direction": "across", "row": 0, "col": 0, "length": 5, "text": "Golf strokes on the green"},
        {"number": 3, "direction": "across", "row": 2, "col": 0, "length": 5, "text": "Spanish word for friend"},
        {"number": 4, "direction": "across", "row": 4, "col": 0, "length": 5, "text": "Cut in two equal parts"},
        {"number": 1, "direction": "down", "row": 0, "col": 0, "length": 5, "text": "Fuzzy stone fruit"},
        {"number": 2, "direction": "down", "row": 0, "col": 4, "length": 5, "text": "Twenty (a score)"}
    ]
}
```

This is `data/puzzles/mall_day_one.json` repurposed — useful as a sanity check that your install is reading `user://puzzles/` correctly.

## Bigger puzzles?

The validator doesn't cap grid size. A 9×9 or 15×15 community puzzle works the same way. The auto-generator at `tools/puzzle_generate.gd` can produce these for you with hand-cluable answers:

```sh
godot --headless -s res://tools/puzzle_generate.gd -- midi /tmp/draft.json 42
```

Output is written with `"TODO: <ANSWER>"` placeholder clues; edit those before shipping.
