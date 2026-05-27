class_name SettingsManager
extends RefCounted

# Disk I/O + clamping for user-tunable settings. JSON at user://settings.json
# by default; tests pass a temp path. All failure modes (missing file,
# malformed JSON, out-of-range values) fall through to a clamped default so
# the game always boots into a playable state.

const DEFAULT_PATH: String = "user://settings.json"

const KEY_MOUSE_SENSITIVITY: String = "mouse_sensitivity"
const KEY_MASTER_VOLUME_DB: String = "master_volume_db"
const KEY_FOOTSTEP_VOLUME_DB: String = "footstep_volume_db"  # legacy; auto-migrates into KEY_SFX_VOLUME_DB at load
const KEY_SFX_VOLUME_DB: String = "sfx_volume_db"
const KEY_MUSIC_VOLUME_DB: String = "music_volume_db"
const KEY_SKIP_TITLE: String = "skip_title"
const KEY_FOV: String = "fov"
const KEY_BINDINGS: String = "key_bindings"  # action_name -> physical_keycode (int)

const DEFAULT_MOUSE_SENSITIVITY: float = 0.002
const DEFAULT_MASTER_VOLUME_DB: float = 0.0
const DEFAULT_FOOTSTEP_VOLUME_DB: float = -8.0
const DEFAULT_SFX_VOLUME_DB: float = 0.0
const DEFAULT_MUSIC_VOLUME_DB: float = -6.0
const DEFAULT_SKIP_TITLE: bool = false
const DEFAULT_FOV: float = 75.0

const MIN_MOUSE_SENSITIVITY: float = 0.0005
const MAX_MOUSE_SENSITIVITY: float = 0.01
const MIN_MASTER_VOLUME_DB: float = -60.0
const MAX_MASTER_VOLUME_DB: float = 6.0
const MIN_FOOTSTEP_VOLUME_DB: float = -40.0
const MAX_FOOTSTEP_VOLUME_DB: float = 0.0
const MIN_SFX_VOLUME_DB: float = -60.0
const MAX_SFX_VOLUME_DB: float = 6.0
const MIN_MUSIC_VOLUME_DB: float = -60.0
const MAX_MUSIC_VOLUME_DB: float = 6.0
const MIN_FOV: float = 60.0
const MAX_FOV: float = 110.0

# Actions exposed in the rebind UI. Order = display order. Anything not on
# this list (`ui_*`, in-puzzle bindings, etc.) stays locked to its
# project.godot default — Esc in particular must never be rebindable.
const REBINDABLE_ACTIONS: Array[String] = [
	"move_forward",
	"move_back",
	"move_left",
	"move_right",
	"jump",
	"sprint",
	"interact",
]


static func default_settings() -> Dictionary:
	return {
		KEY_MOUSE_SENSITIVITY: DEFAULT_MOUSE_SENSITIVITY,
		KEY_MASTER_VOLUME_DB: DEFAULT_MASTER_VOLUME_DB,
		KEY_FOOTSTEP_VOLUME_DB: DEFAULT_FOOTSTEP_VOLUME_DB,
		KEY_SFX_VOLUME_DB: DEFAULT_SFX_VOLUME_DB,
		KEY_MUSIC_VOLUME_DB: DEFAULT_MUSIC_VOLUME_DB,
		KEY_SKIP_TITLE: DEFAULT_SKIP_TITLE,
		KEY_FOV: DEFAULT_FOV,
		KEY_BINDINGS: {},
	}


static func load_from_path(path: String = DEFAULT_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return default_settings()
	var content: String = FileAccess.get_file_as_string(path)
	if content == "":
		return default_settings()
	var parsed: Variant = JSON.parse_string(content)
	if typeof(parsed) != TYPE_DICTIONARY:
		return default_settings()
	return _normalize(parsed)


static func save_to_path(settings: Dictionary, path: String = DEFAULT_PATH) -> bool:
	# Dictionary is a value type — it can be empty but never null. The
	# `_normalize` call fills in defaults for any missing keys, so passing
	# an empty `{}` is a valid way to write a defaults-only file.
	var normalized: Dictionary = _normalize(settings)
	var content: String = JSON.stringify(normalized, "\t")
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(content)
	file.close()
	return true


static func delete_at_path(path: String = DEFAULT_PATH) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var dir: DirAccess = DirAccess.open(path.get_base_dir())
	if dir == null:
		return false
	return dir.remove(path.get_file()) == OK


# Returns a copy of `settings` with all required keys present and every value
# clamped into its acceptable range. Public so the SettingsMenu can sanitize
# slider input before saving.
static func normalize(settings: Dictionary) -> Dictionary:
	return _normalize(settings)


static func _normalize(loaded: Dictionary) -> Dictionary:
	var out: Dictionary = default_settings()
	# Numeric keys come through float(); boolean keys take the raw value so a
	# stored `true` / `false` survives the round-trip without being coerced
	# to 1.0 / 0.0.
	for key in [KEY_MOUSE_SENSITIVITY, KEY_MASTER_VOLUME_DB, KEY_FOOTSTEP_VOLUME_DB, KEY_SFX_VOLUME_DB, KEY_MUSIC_VOLUME_DB, KEY_FOV]:
		if loaded.has(key):
			out[key] = float(loaded[key])
	if loaded.has(KEY_SKIP_TITLE):
		out[KEY_SKIP_TITLE] = bool(loaded[KEY_SKIP_TITLE])
	# v1.1.0 migration: legacy KEY_FOOTSTEP_VOLUME_DB is the per-source
	# slider that controlled footstep volume in 1.0.x. With the new SFX bus,
	# it survives as a fine-grain offset within the bus. We also carry the
	# legacy value into KEY_SFX_VOLUME_DB the FIRST time a v1.0.x save is
	# loaded so the player's perceived footstep loudness doesn't reset.
	# Detection heuristic: footstep is present, sfx isn't.
	if loaded.has(KEY_FOOTSTEP_VOLUME_DB) and not loaded.has(KEY_SFX_VOLUME_DB):
		# Map old footstep_volume_db (range -40..0 dB) onto the SFX bus
		# (-60..+6). Direct copy is close enough — the bus is then summed
		# with the per-source value at runtime so the total stays similar.
		out[KEY_SFX_VOLUME_DB] = float(loaded[KEY_FOOTSTEP_VOLUME_DB])
	# Optional dict of action_name -> physical_keycode (int). Anything that
	# isn't a string -> int mapping for a known rebindable action is dropped.
	if loaded.has(KEY_BINDINGS) and (loaded[KEY_BINDINGS] is Dictionary):
		var raw_bindings: Dictionary = loaded[KEY_BINDINGS]
		var clean: Dictionary = {}
		for action in raw_bindings:
			if not (action is String):
				continue
			if not REBINDABLE_ACTIONS.has(String(action)):
				continue
			var code: int = int(raw_bindings[action])
			if code > 0:
				clean[String(action)] = code
		out[KEY_BINDINGS] = clean
	out[KEY_MOUSE_SENSITIVITY] = clampf(out[KEY_MOUSE_SENSITIVITY], MIN_MOUSE_SENSITIVITY, MAX_MOUSE_SENSITIVITY)
	out[KEY_MASTER_VOLUME_DB] = clampf(out[KEY_MASTER_VOLUME_DB], MIN_MASTER_VOLUME_DB, MAX_MASTER_VOLUME_DB)
	out[KEY_FOOTSTEP_VOLUME_DB] = clampf(out[KEY_FOOTSTEP_VOLUME_DB], MIN_FOOTSTEP_VOLUME_DB, MAX_FOOTSTEP_VOLUME_DB)
	out[KEY_SFX_VOLUME_DB] = clampf(out[KEY_SFX_VOLUME_DB], MIN_SFX_VOLUME_DB, MAX_SFX_VOLUME_DB)
	out[KEY_MUSIC_VOLUME_DB] = clampf(out[KEY_MUSIC_VOLUME_DB], MIN_MUSIC_VOLUME_DB, MAX_MUSIC_VOLUME_DB)
	out[KEY_FOV] = clampf(out[KEY_FOV], MIN_FOV, MAX_FOV)
	return out
