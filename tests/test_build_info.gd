extends "res://addons/gut/test.gd"


# BuildInfo reads res://data/build_info.json. In the dev workspace that file
# holds "dev" placeholders; CI overwrites them before the export step. These
# tests use the _override_for_test / _reset_for_test hooks to exercise the
# accessors against known values without touching disk.


func before_each() -> void:
	BuildInfo._reset_for_test()


func after_each() -> void:
	BuildInfo._reset_for_test()


func test_version_returns_dev_in_workspace() -> void:
	# The committed build_info.json has version="dev". A fresh clone +
	# `godot --headless -s ...` reads that file and should see "dev"
	# (or the project_settings fallback). Either way: not empty.
	var v: String = BuildInfo.version()
	assert_true(v != "", "version() should never return empty string")


func test_commit_returns_dev_in_workspace() -> void:
	# Same reasoning as above for the commit field.
	var c: String = BuildInfo.commit()
	assert_true(c != "", "commit() should never return empty string")


func test_version_string_combines_version_and_commit() -> void:
	BuildInfo._override_for_test("v1.0.1", "abc1234", "2026-05-24T00:00:00Z")
	assert_eq(BuildInfo.version_string(), "v1.0.1 (abc1234)")


func test_is_dev_build_when_commit_is_dev_placeholder() -> void:
	BuildInfo._override_for_test("v1.0.1", BuildInfo.COMMIT_DEV, "dev")
	assert_true(BuildInfo.is_dev_build())


func test_is_dev_build_false_for_real_commit() -> void:
	BuildInfo._override_for_test("v1.0.1", "abc1234", "2026-05-24T00:00:00Z")
	assert_false(BuildInfo.is_dev_build())


func test_override_for_test_replaces_all_fields() -> void:
	BuildInfo._override_for_test("v9.9.9", "deadbee", "2099-12-31T23:59:59Z")
	assert_eq(BuildInfo.version(), "v9.9.9")
	assert_eq(BuildInfo.commit(), "deadbee")
	assert_eq(BuildInfo.built_at(), "2099-12-31T23:59:59Z")


func test_reset_for_test_reloads_from_disk() -> void:
	BuildInfo._override_for_test("v9.9.9", "deadbee", "2099-12-31T23:59:59Z")
	assert_eq(BuildInfo.version(), "v9.9.9")
	BuildInfo._reset_for_test()
	# After reset, accessors re-read the on-disk file. We don't assert the
	# exact value (CI rewrites it for release builds) — just that it's not
	# the override string anymore.
	assert_ne(BuildInfo.version(), "v9.9.9")
