# MallCross

First-person 3D mall exploration. Each in-game day you walk to a food court table and solve a full NYT-style (15x15) crossword. Solving earns **Woints**, the in-game currency you spend at mall stores on a mix of cosmetic items (visible on hands/shadow) and functional items that modify puzzle UX.

## Status

Pre-1.0. **Phase 0** — project skeleton, CI green.

Full roadmap lives in [CHANGELOG.md](CHANGELOG.md).

## Tech

- **Engine:** Godot 4.6+
- **Language:** GDScript
- **Tests:** [GUT](https://github.com/bitwes/Gut)
- **CI:** GitHub Actions (headless Godot + GUT on every push)
- **Aesthetic:** PS1/N64 lo-fi — vertex-snap, point-filtered low-res textures, fog (Phase 8)

## Planned controls

| Input | Action |
|---|---|
| WASD | Move |
| Mouse | Look |
| Space | Jump |
| Shift | Sprint |
| E | Interact (food court tables, shop counters) |
| Tab | Inventory / mall directory |
| Esc | Pause / menu |

## Local development

1. Install [Godot 4.6+](https://godotengine.org/download).
2. Open the project in the editor or run: `godot --path .`
3. Press F5 in the editor to run the current main scene.

## Running tests

GUT lives at `addons/gut/`. From the project root:

```bash
godot --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://tests/ -gexit
```

CI runs this same command on every push.

## License

TBD.
