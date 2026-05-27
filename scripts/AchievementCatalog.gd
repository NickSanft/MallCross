class_name AchievementCatalog
extends RefCounted

# Loads res://data/achievements.json — the bundled catalog of achievements
# the game ships with. Pure read-only access; player unlock state lives in
# AchievementService / AchievementStore.
#
# Entry shape:
#   { "id": "first_solve", "name": "First Solve",
#     "description": "...", "hidden": false }
#
# Defensive: missing file / malformed JSON / non-array `achievements` all
# fall through to an empty list. Entries that lack a non-empty `id` are
# dropped. Duplicate IDs keep the first occurrence.

const PATH: String = "res://data/achievements.json"


static func load_all(path: String = PATH) -> Array:
	if not FileAccess.file_exists(path):
		return []
	var content: String = FileAccess.get_file_as_string(path)
	if content == "":
		return []
	var parsed: Variant = JSON.parse_string(content)
	if typeof(parsed) != TYPE_DICTIONARY:
		return []
	var raw: Variant = (parsed as Dictionary).get("achievements", [])
	if not (raw is Array):
		return []
	var out: Array = []
	var seen_ids: Dictionary = {}
	for entry_variant in raw:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entry_variant
		var id: String = String(entry.get("id", ""))
		if id == "" or seen_ids.has(id):
			continue
		seen_ids[id] = true
		out.append({
			"id": id,
			"name": String(entry.get("name", id)),
			"description": String(entry.get("description", "")),
			"hidden": bool(entry.get("hidden", false)),
		})
	return out


static func find_by_id(catalog: Array, id: String) -> Dictionary:
	# Linear scan; catalogs stay under a few dozen entries. Returns {} if
	# the id isn't present — callers should treat that as "no such achievement"
	# rather than crashing.
	for entry in catalog:
		if entry.get("id") == id:
			return entry
	return {}
