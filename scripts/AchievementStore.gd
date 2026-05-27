class_name AchievementStore
extends RefCounted

# Disk I/O for per-player achievement unlock state at
# user://achievements.json. Stores a dict of id -> int (the in-game day on
# which the achievement was first unlocked; useful for future "unlocked on
# day X" UI). Mirrors the SettingsManager pattern: pure static methods,
# tests can pass a temp path.

const DEFAULT_PATH: String = "user://achievements.json"
const FORMAT_VERSION: int = 1


static func load_from_path(path: String = DEFAULT_PATH) -> Dictionary:
	# Returns { id -> int (unlock day) }. Empty dict on any failure.
	if not FileAccess.file_exists(path):
		return {}
	var content: String = FileAccess.get_file_as_string(path)
	if content == "":
		return {}
	var parsed: Variant = JSON.parse_string(content)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var unlocks_variant: Variant = (parsed as Dictionary).get("unlocks", {})
	if not (unlocks_variant is Dictionary):
		return {}
	var out: Dictionary = {}
	for id in unlocks_variant:
		if not (id is String) or String(id) == "":
			continue
		var day: int = int(unlocks_variant[id])
		# day 0 is fine ("unlocked before day tracking was added"); negative
		# days are nonsense and get dropped.
		if day < 0:
			continue
		out[String(id)] = day
	return out


static func save_to_path(unlocks: Dictionary, path: String = DEFAULT_PATH) -> bool:
	var clean: Dictionary = {}
	for id in unlocks:
		if not (id is String) or String(id) == "":
			continue
		var day: int = int(unlocks[id])
		if day < 0:
			continue
		clean[String(id)] = day
	var payload: Dictionary = {
		"version": FORMAT_VERSION,
		"unlocks": clean,
	}
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	return true


static func delete_at_path(path: String = DEFAULT_PATH) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var dir: DirAccess = DirAccess.open(path.get_base_dir())
	if dir == null:
		return false
	return dir.remove(path.get_file()) == OK
