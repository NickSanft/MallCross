extends "res://addons/gut/test.gd"


# AchievementCatalog loads res://data/achievements.json. The tests below
# exercise the bundled file (real-world fixture) plus a handful of
# defensive cases by passing temp paths with hand-built JSON.


func _temp_path() -> String:
	# Unique per-test so parallel-runner safety holds.
	return "user://test_catalog_%d.json" % Time.get_ticks_msec()


func _write(path: String, contents: String) -> void:
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if f != null:
		f.store_string(contents)
		f.close()


func _delete(path: String) -> void:
	if FileAccess.file_exists(path):
		var dir: DirAccess = DirAccess.open(path.get_base_dir())
		if dir != null:
			dir.remove(path.get_file())


# ----- bundled catalog ---------------------------------------------------

func test_bundled_catalog_has_entries() -> void:
	var entries: Array = AchievementCatalog.load_all()
	assert_gt(entries.size(), 0, "bundled catalog should have at least one entry")


func test_bundled_entries_have_required_fields() -> void:
	for entry in AchievementCatalog.load_all():
		assert_true(entry.has("id"))
		assert_true(entry.has("name"))
		assert_true(entry.has("description"))
		assert_true(entry.has("hidden"))
		assert_ne(String(entry["id"]), "")


func test_find_by_id_returns_existing() -> void:
	var entries: Array = AchievementCatalog.load_all()
	var entry: Dictionary = AchievementCatalog.find_by_id(entries, "first_solve")
	assert_eq(String(entry.get("id")), "first_solve")


func test_find_by_id_returns_empty_for_unknown() -> void:
	var entries: Array = AchievementCatalog.load_all()
	var entry: Dictionary = AchievementCatalog.find_by_id(entries, "no_such_id")
	assert_true(entry.is_empty())


# ----- defensive cases --------------------------------------------------

func test_missing_file_returns_empty() -> void:
	assert_eq(AchievementCatalog.load_all("user://does_not_exist.json"), [])


func test_malformed_json_returns_empty() -> void:
	var path: String = _temp_path()
	_write(path, "{not valid json")
	var entries: Array = AchievementCatalog.load_all(path)
	_delete(path)
	assert_eq(entries, [])


func test_non_array_achievements_field_returns_empty() -> void:
	var path: String = _temp_path()
	_write(path, '{"achievements": "not an array"}')
	var entries: Array = AchievementCatalog.load_all(path)
	_delete(path)
	assert_eq(entries, [])


func test_entries_without_id_are_dropped() -> void:
	var path: String = _temp_path()
	_write(path, '{"achievements": [{"name": "no id here"}, {"id": "ok", "name": "OK"}]}')
	var entries: Array = AchievementCatalog.load_all(path)
	_delete(path)
	assert_eq(entries.size(), 1)
	assert_eq(String(entries[0]["id"]), "ok")


func test_duplicate_ids_keep_first_occurrence() -> void:
	var path: String = _temp_path()
	_write(path, '{"achievements": [{"id": "a", "name": "First"}, {"id": "a", "name": "Second"}]}')
	var entries: Array = AchievementCatalog.load_all(path)
	_delete(path)
	assert_eq(entries.size(), 1)
	assert_eq(String(entries[0]["name"]), "First")


func test_hidden_defaults_to_false() -> void:
	var path: String = _temp_path()
	_write(path, '{"achievements": [{"id": "a", "name": "A"}]}')
	var entries: Array = AchievementCatalog.load_all(path)
	_delete(path)
	assert_false(bool(entries[0]["hidden"]))
