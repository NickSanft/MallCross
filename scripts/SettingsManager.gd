class_name SettingsManager
extends RefCounted

# Disk I/O + clamping for user-tunable settings. JSON at user://settings.json
# by default; tests pass a temp path. All failure modes (missing file,
# malformed JSON, out-of-range values) fall through to a clamped default so
# the game always boots into a playable state.

const DEFAULT_PATH: String = "user://settings.json"

const KEY_MOUSE_SENSITIVITY: String = "mouse_sensitivity"
const KEY_MASTER_VOLUME_DB: String = "master_volume_db"
const KEY_FOOTSTEP_VOLUME_DB: String = "footstep_volume_db"

const DEFAULT_MOUSE_SENSITIVITY: float = 0.002
const DEFAULT_MASTER_VOLUME_DB: float = 0.0
const DEFAULT_FOOTSTEP_VOLUME_DB: float = -8.0

const MIN_MOUSE_SENSITIVITY: float = 0.0005
const MAX_MOUSE_SENSITIVITY: float = 0.01
const MIN_MASTER_VOLUME_DB: float = -60.0
const MAX_MASTER_VOLUME_DB: float = 6.0
const MIN_FOOTSTEP_VOLUME_DB: float = -40.0
const MAX_FOOTSTEP_VOLUME_DB: float = 0.0


static func default_settings() -> Dictionary:
	return {
		KEY_MOUSE_SENSITIVITY: DEFAULT_MOUSE_SENSITIVITY,
		KEY_MASTER_VOLUME_DB: DEFAULT_MASTER_VOLUME_DB,
		KEY_FOOTSTEP_VOLUME_DB: DEFAULT_FOOTSTEP_VOLUME_DB,
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
	for key in out.keys():
		if loaded.has(key):
			out[key] = float(loaded[key])
	out[KEY_MOUSE_SENSITIVITY] = clampf(out[KEY_MOUSE_SENSITIVITY], MIN_MOUSE_SENSITIVITY, MAX_MOUSE_SENSITIVITY)
	out[KEY_MASTER_VOLUME_DB] = clampf(out[KEY_MASTER_VOLUME_DB], MIN_MASTER_VOLUME_DB, MAX_MASTER_VOLUME_DB)
	out[KEY_FOOTSTEP_VOLUME_DB] = clampf(out[KEY_FOOTSTEP_VOLUME_DB], MIN_FOOTSTEP_VOLUME_DB, MAX_FOOTSTEP_VOLUME_DB)
	return out
