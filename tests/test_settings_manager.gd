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


# ----- FOV (introduced in v1.1.0) ------------------------------------

func test_defaults_include_fov() -> void:
	var defaults: Dictionary = SettingsManager.default_settings()
	assert_true(defaults.has(SettingsManager.KEY_FOV))
	assert_eq(defaults[SettingsManager.KEY_FOV], SettingsManager.DEFAULT_FOV)


func test_normalize_clamps_fov_low() -> void:
	var normalized: Dictionary = SettingsManager.normalize({
		SettingsManager.KEY_FOV: 1.0,
	})
	assert_eq(normalized[SettingsManager.KEY_FOV], SettingsManager.MIN_FOV)


func test_normalize_clamps_fov_high() -> void:
	var normalized: Dictionary = SettingsManager.normalize({
		SettingsManager.KEY_FOV: 999.0,
	})
	assert_eq(normalized[SettingsManager.KEY_FOV], SettingsManager.MAX_FOV)


func test_fov_round_trips_via_disk() -> void:
	var path: String = _temp_path()
	SettingsManager.save_to_path({
		SettingsManager.KEY_FOV: 90.0,
	}, path)
	var restored: Dictionary = SettingsManager.load_from_path(path)
	assert_eq(restored[SettingsManager.KEY_FOV], 90.0)


# ----- SFX / Music buses (introduced in v1.1.0) ----------------------

func test_defaults_include_sfx_and_music() -> void:
	var defaults: Dictionary = SettingsManager.default_settings()
	assert_true(defaults.has(SettingsManager.KEY_SFX_VOLUME_DB))
	assert_true(defaults.has(SettingsManager.KEY_MUSIC_VOLUME_DB))


func test_normalize_clamps_sfx_volume_high() -> void:
	var normalized: Dictionary = SettingsManager.normalize({
		SettingsManager.KEY_SFX_VOLUME_DB: 999.0,
	})
	assert_eq(normalized[SettingsManager.KEY_SFX_VOLUME_DB], SettingsManager.MAX_SFX_VOLUME_DB)


func test_normalize_clamps_music_volume_low() -> void:
	var normalized: Dictionary = SettingsManager.normalize({
		SettingsManager.KEY_MUSIC_VOLUME_DB: -999.0,
	})
	assert_eq(normalized[SettingsManager.KEY_MUSIC_VOLUME_DB], SettingsManager.MIN_MUSIC_VOLUME_DB)


func test_sfx_music_round_trip_via_disk() -> void:
	var path: String = _temp_path()
	SettingsManager.save_to_path({
		SettingsManager.KEY_SFX_VOLUME_DB: -3.0,
		SettingsManager.KEY_MUSIC_VOLUME_DB: -12.0,
	}, path)
	var restored: Dictionary = SettingsManager.load_from_path(path)
	assert_eq(restored[SettingsManager.KEY_SFX_VOLUME_DB], -3.0)
	assert_eq(restored[SettingsManager.KEY_MUSIC_VOLUME_DB], -12.0)


# ----- v1.0.x → v1.1.0 footstep_volume_db → sfx_volume_db migration --

func test_footstep_migrates_into_sfx_when_sfx_missing() -> void:
	# v1.0.x save: has footstep_volume_db, no sfx_volume_db. After load,
	# the footstep value should populate sfx_volume_db so loudness doesn't
	# reset on upgrade.
	var normalized: Dictionary = SettingsManager.normalize({
		SettingsManager.KEY_FOOTSTEP_VOLUME_DB: -16.0,
	})
	assert_eq(normalized[SettingsManager.KEY_SFX_VOLUME_DB], -16.0)


func test_explicit_sfx_value_overrides_legacy_footstep() -> void:
	# v1.1.0+ save: both keys present. Explicit sfx_volume_db wins; we
	# don't overwrite it with the legacy footstep value.
	var normalized: Dictionary = SettingsManager.normalize({
		SettingsManager.KEY_FOOTSTEP_VOLUME_DB: -30.0,
		SettingsManager.KEY_SFX_VOLUME_DB: -2.0,
	})
	assert_eq(normalized[SettingsManager.KEY_SFX_VOLUME_DB], -2.0)


# ----- Key bindings (introduced in v1.1.0) ---------------------------

func test_defaults_include_empty_key_bindings() -> void:
	var defaults: Dictionary = SettingsManager.default_settings()
	assert_true(defaults.has(SettingsManager.KEY_BINDINGS))
	assert_true(defaults[SettingsManager.KEY_BINDINGS] is Dictionary)
	assert_eq((defaults[SettingsManager.KEY_BINDINGS] as Dictionary).size(), 0)


func test_key_bindings_accept_known_actions() -> void:
	var normalized: Dictionary = SettingsManager.normalize({
		SettingsManager.KEY_BINDINGS: {
			"move_forward": KEY_W,
			"jump": KEY_SPACE,
		},
	})
	var bindings: Dictionary = normalized[SettingsManager.KEY_BINDINGS]
	assert_eq(bindings["move_forward"], KEY_W)
	assert_eq(bindings["jump"], KEY_SPACE)


func test_key_bindings_reject_unknown_actions() -> void:
	# Unknown action names get filtered — settings can't smuggle bindings
	# for actions the rebind UI doesn't expose.
	var normalized: Dictionary = SettingsManager.normalize({
		SettingsManager.KEY_BINDINGS: {
			"move_forward": KEY_W,
			"secret_admin_console": KEY_F12,
			"ui_cancel": KEY_ESCAPE,
		},
	})
	var bindings: Dictionary = normalized[SettingsManager.KEY_BINDINGS]
	assert_true(bindings.has("move_forward"))
	assert_false(bindings.has("secret_admin_console"))
	assert_false(bindings.has("ui_cancel"))


func test_key_bindings_reject_zero_or_negative_codes() -> void:
	var normalized: Dictionary = SettingsManager.normalize({
		SettingsManager.KEY_BINDINGS: {
			"move_forward": 0,
			"jump": -100,
			"sprint": KEY_SHIFT,
		},
	})
	var bindings: Dictionary = normalized[SettingsManager.KEY_BINDINGS]
	assert_false(bindings.has("move_forward"))
	assert_false(bindings.has("jump"))
	assert_eq(bindings["sprint"], KEY_SHIFT)


func test_key_bindings_round_trip_via_disk() -> void:
	var path: String = _temp_path()
	SettingsManager.save_to_path({
		SettingsManager.KEY_BINDINGS: {
			"move_forward": KEY_W,
			"interact": KEY_F,
		},
	}, path)
	var restored: Dictionary = SettingsManager.load_from_path(path)
	var bindings: Dictionary = restored[SettingsManager.KEY_BINDINGS]
	assert_eq(bindings["move_forward"], KEY_W)
	assert_eq(bindings["interact"], KEY_F)


func test_rebindable_actions_list_matches_default_inputmap() -> void:
	# Every action in REBINDABLE_ACTIONS should be a real action in the
	# project.godot InputMap. Guards against typos or actions being
	# removed without updating SettingsManager.
	for action in SettingsManager.REBINDABLE_ACTIONS:
		assert_true(InputMap.has_action(action), "Action '%s' should exist in InputMap" % action)
