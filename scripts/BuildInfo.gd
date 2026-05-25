class_name BuildInfo
extends RefCounted

# Reads `res://data/build_info.json`, which the release workflow rewrites
# right before the export step so the resulting binary embeds the real
# git commit, build timestamp, and tag name.
#
# In a dev workspace the committed file holds placeholder "dev" values;
# in a release build it holds e.g.:
#     {"version": "v1.0.1", "commit": "149a6a8", "built_at": "2026-05-24T16:00:00Z"}
#
# Defensive: a missing or malformed file falls back to "dev" so the game
# never crashes on a startup label.

const PATH: String = "res://data/build_info.json"

const VERSION_DEV: String = "dev"
const COMMIT_DEV: String = "dev"
const BUILT_AT_DEV: String = "dev"

# Cached after first load so we don't re-read the file on every label refresh.
static var _cache: Dictionary = {}
static var _loaded: bool = false


static func _load() -> Dictionary:
	if _loaded:
		return _cache
	_loaded = true
	_cache = {
		"version": _project_version_or_dev(),
		"commit": COMMIT_DEV,
		"built_at": BUILT_AT_DEV,
	}
	if not FileAccess.file_exists(PATH):
		return _cache
	var content: String = FileAccess.get_file_as_string(PATH)
	if content == "":
		return _cache
	var parsed: Variant = JSON.parse_string(content)
	if typeof(parsed) != TYPE_DICTIONARY:
		return _cache
	# Only overwrite known keys with non-empty string values. Anything else
	# stays at its dev-fallback so a partially-written file (e.g. a CI step
	# that rewrote only one field) doesn't blank out the others.
	for key in ["version", "commit", "built_at"]:
		var v: Variant = parsed.get(key, "")
		if v is String and String(v) != "":
			_cache[key] = String(v)
	return _cache


static func version() -> String:
	return _load()["version"]


static func commit() -> String:
	return _load()["commit"]


static func built_at() -> String:
	return _load()["built_at"]


static func version_string() -> String:
	# Single human-readable line. "v1.0.1 (149a6a8)" in release builds,
	# "dev (dev)" in a freshly-cloned workspace.
	return "%s (%s)" % [version(), commit()]


static func is_dev_build() -> bool:
	return commit() == COMMIT_DEV


# Allows tests to swap the cache for a specific scenario.
static func _override_for_test(version_str: String, commit_str: String, built_at_str: String) -> void:
	_loaded = true
	_cache = {"version": version_str, "commit": commit_str, "built_at": built_at_str}


# Drops the cache so the next accessor re-reads the file.
static func _reset_for_test() -> void:
	_loaded = false
	_cache = {}


static func _project_version_or_dev() -> String:
	var v: Variant = ProjectSettings.get_setting("application/config/version", "")
	if v is String and String(v) != "":
		return String(v)
	return VERSION_DEV
