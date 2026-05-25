extends "res://addons/gut/test.gd"

const TEST_PATH_PREFIX: String = "user://test_settings_"

var _paths_to_cleanup: Array = []


func after_each() -> void:
	for path in _paths_to_cleanup:
		SettingsManager.delete_at_path(path)
	_paths_to_cleanup.clear()


func _temp_path() -> String:
	var path: String = TEST_PATH_PREFIX + str(Time.get_ticks_usec()) + ".json"
	_paths_to_cleanup.append(path)
	return path


func test_default_settings_has_all_required_keys() -> void:
	var defaults: Dictionary = SettingsManager.default_settings()
	assert_true(defaults.has(SettingsManager.KEY_MOUSE_SENSITIVITY))
	assert_true(defaults.has(SettingsManager.KEY_MASTER_VOLUME_DB))
	assert_true(defaults.has(SettingsManager.KEY_FOOTSTEP_VOLUME_DB))


func test_default_mouse_sensitivity_matches_constant() -> void:
	var defaults: Dictionary = SettingsManager.default_settings()
	assert_eq(defaults[SettingsManager.KEY_MOUSE_SENSITIVITY], SettingsManager.DEFAULT_MOUSE_SENSITIVITY)


func test_load_missing_file_returns_defaults() -> void:
	var settings: Dictionary = SettingsManager.load_from_path(_temp_path())
	assert_eq(settings[SettingsManager.KEY_MOUSE_SENSITIVITY], SettingsManager.DEFAULT_MOUSE_SENSITIVITY)


func test_save_then_load_round_trip() -> void:
	var path: String = _temp_path()
	var to_save: Dictionary = {
		SettingsManager.KEY_MOUSE_SENSITIVITY: 0.005,
		SettingsManager.KEY_MASTER_VOLUME_DB: -10.0,
		SettingsManager.KEY_FOOTSTEP_VOLUME_DB: -15.0,
	}
	assert_true(SettingsManager.save_to_path(to_save, path))
	var restored: Dictionary = SettingsManager.load_from_path(path)
	assert_almost_eq(restored[SettingsManager.KEY_MOUSE_SENSITIVITY], 0.005, 1e-6)
	assert_almost_eq(restored[SettingsManager.KEY_MASTER_VOLUME_DB], -10.0, 1e-6)
	assert_almost_eq(restored[SettingsManager.KEY_FOOTSTEP_VOLUME_DB], -15.0, 1e-6)


func test_load_garbage_returns_defaults() -> void:
	var path: String = _temp_path()
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string("not json at all")
	file.close()
	var settings: Dictionary = SettingsManager.load_from_path(path)
	assert_eq(settings[SettingsManager.KEY_MOUSE_SENSITIVITY], SettingsManager.DEFAULT_MOUSE_SENSITIVITY)


func test_load_empty_file_returns_defaults() -> void:
	var path: String = _temp_path()
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string("")
	file.close()
	var settings: Dictionary = SettingsManager.load_from_path(path)
	assert_eq(settings[SettingsManager.KEY_MOUSE_SENSITIVITY], SettingsManager.DEFAULT_MOUSE_SENSITIVITY)


func test_normalize_clamps_mouse_sensitivity_too_high() -> void:
	var normalized: Dictionary = SettingsManager.normalize({
		SettingsManager.KEY_MOUSE_SENSITIVITY: 999.0,
	})
	assert_eq(normalized[SettingsManager.KEY_MOUSE_SENSITIVITY], SettingsManager.MAX_MOUSE_SENSITIVITY)


func test_normalize_clamps_mouse_sensitivity_too_low() -> void:
	var normalized: Dictionary = SettingsManager.normalize({
		SettingsManager.KEY_MOUSE_SENSITIVITY: -1.0,
	})
	assert_eq(normalized[SettingsManager.KEY_MOUSE_SENSITIVITY], SettingsManager.MIN_MOUSE_SENSITIVITY)


func test_normalize_clamps_master_volume() -> void:
	var normalized: Dictionary = SettingsManager.normalize({
		SettingsManager.KEY_MASTER_VOLUME_DB: -999.0,
	})
	assert_eq(normalized[SettingsManager.KEY_MASTER_VOLUME_DB], SettingsManager.MIN_MASTER_VOLUME_DB)


func test_normalize_clamps_footstep_volume() -> void:
	var normalized: Dictionary = SettingsManager.normalize({
		SettingsManager.KEY_FOOTSTEP_VOLUME_DB: 999.0,
	})
	assert_eq(normalized[SettingsManager.KEY_FOOTSTEP_VOLUME_DB], SettingsManager.MAX_FOOTSTEP_VOLUME_DB)


func test_normalize_missing_keys_fills_with_defaults() -> void:
	var normalized: Dictionary = SettingsManager.normalize({})
	assert_eq(normalized[SettingsManager.KEY_MOUSE_SENSITIVITY], SettingsManager.DEFAULT_MOUSE_SENSITIVITY)
	assert_eq(normalized[SettingsManager.KEY_MASTER_VOLUME_DB], SettingsManager.DEFAULT_MASTER_VOLUME_DB)
	assert_eq(normalized[SettingsManager.KEY_FOOTSTEP_VOLUME_DB], SettingsManager.DEFAULT_FOOTSTEP_VOLUME_DB)


func test_delete_removes_file() -> void:
	var path: String = _temp_path()
	SettingsManager.save_to_path(SettingsManager.default_settings(), path)
	assert_true(FileAccess.file_exists(path))
	assert_true(SettingsManager.delete_at_path(path))
	assert_false(FileAccess.file_exists(path))


func test_delete_returns_false_when_missing() -> void:
	assert_false(SettingsManager.delete_at_path(_temp_path()))


func test_save_persists_clamped_values_not_raw() -> void:
	# Out-of-range input should be clamped before write so disk never holds
	# nonsense values.
	var path: String = _temp_path()
	SettingsManager.save_to_path({
		SettingsManager.KEY_MOUSE_SENSITIVITY: 100.0,
	}, path)
	var restored: Dictionary = SettingsManager.load_from_path(path)
	assert_eq(restored[SettingsManager.KEY_MOUSE_SENSITIVITY], SettingsManager.MAX_MOUSE_SENSITIVITY)


# ----- skip_title (introduced in v1.0.1) -----------------------------

func test_defaults_include_skip_title_false() -> void:
	var defaults: Dictionary = SettingsManager.default_settings()
	assert_true(defaults.has(SettingsManager.KEY_SKIP_TITLE))
	assert_false(defaults[SettingsManager.KEY_SKIP_TITLE])


func test_normalize_preserves_skip_title_true() -> void:
	var normalized: Dictionary = SettingsManager.normalize({
		SettingsManager.KEY_SKIP_TITLE: true,
	})
	assert_true(normalized[SettingsManager.KEY_SKIP_TITLE])


func test_skip_title_round_trips_via_disk() -> void:
	var path: String = _temp_path()
	SettingsManager.save_to_path({
		SettingsManager.KEY_SKIP_TITLE: true,
	}, path)
	var restored: Dictionary = SettingsManager.load_from_path(path)
	assert_true(restored[SettingsManager.KEY_SKIP_TITLE])


func test_skip_title_coerces_non_bool_values() -> void:
	# A truthy non-bool (1, "true", non-empty array) should normalize to true.
	# Falsy values should normalize to false. Matches Godot's bool() semantics.
	var normalized: Dictionary = SettingsManager.normalize({
		SettingsManager.KEY_SKIP_TITLE: 1,
	})
	assert_true(normalized[SettingsManager.KEY_SKIP_TITLE])

	normalized = SettingsManager.normalize({
		SettingsManager.KEY_SKIP_TITLE: 0,
	})
	assert_false(normalized[SettingsManager.KEY_SKIP_TITLE])
