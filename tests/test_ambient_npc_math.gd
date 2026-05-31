extends "res://addons/gut/test.gd"


# AmbientNPCMath is a pure-function helper used by AmbientNPC's
# _physics_process. Testing the math alone keeps the Phase 18 coverage
# fast (no scene-tree spin-up) and decoupled from the visual layer.


# ----- step_toward ------------------------------------------------------

func test_step_toward_advances_by_speed_times_delta() -> void:
	var result: Dictionary = AmbientNPCMath.step_toward(Vector3.ZERO, Vector3(10, 0, 0), 2.0, 0.5)
	# 2 m/s * 0.5 s = 1 m along +X.
	assert_eq(result["position"], Vector3(1, 0, 0))
	assert_false(bool(result["reached"]))


func test_step_toward_caps_at_target_when_step_overshoots() -> void:
	# Target is 0.5 m away, step would be 5 m. Should stop exactly on target.
	var result: Dictionary = AmbientNPCMath.step_toward(Vector3.ZERO, Vector3(0.5, 0, 0), 10.0, 1.0)
	assert_eq(result["position"], Vector3(0.5, 0, 0))
	assert_true(bool(result["reached"]))


func test_step_toward_returns_target_when_already_arrived() -> void:
	var result: Dictionary = AmbientNPCMath.step_toward(Vector3(3, 0, 4), Vector3(3, 0, 4), 1.0, 0.1)
	assert_eq(result["position"], Vector3(3, 0, 4))
	assert_true(bool(result["reached"]))


func test_step_toward_negative_speed_clamps_to_zero() -> void:
	# Defensive: a bug elsewhere shouldn't run NPCs backwards.
	var result: Dictionary = AmbientNPCMath.step_toward(Vector3.ZERO, Vector3(5, 0, 0), -3.0, 1.0)
	assert_eq(result["position"], Vector3.ZERO)
	assert_false(bool(result["reached"]))


func test_step_toward_diagonal_uses_unit_direction() -> void:
	# From origin to (3, 0, 4), distance 5. Step 1 m moves to (0.6, 0, 0.8).
	var result: Dictionary = AmbientNPCMath.step_toward(Vector3.ZERO, Vector3(3, 0, 4), 5.0, 0.2)
	assert_almost_eq(result["position"].x, 0.6, 0.0001)
	assert_almost_eq(result["position"].z, 0.8, 0.0001)
	assert_false(bool(result["reached"]))


# ----- bob_y_offset -----------------------------------------------------

func test_bob_y_offset_is_zero_at_start() -> void:
	# sin(0) == 0 — first frame of walking has no offset.
	assert_eq(AmbientNPCMath.bob_y_offset(0.0, 0.05, 0.7), 0.0)


func test_bob_y_offset_oscillates_within_amplitude() -> void:
	# For any distance, |offset| <= amplitude.
	var amplitude: float = 0.05
	for d in [0.5, 1.0, 1.5, 2.0, 3.14, 7.0]:
		var offset: float = AmbientNPCMath.bob_y_offset(d, amplitude, 0.7)
		assert_true(offset >= -amplitude - 0.0001 and offset <= amplitude + 0.0001,
			"At distance %f, offset %f outside [-%f, %f]" % [d, offset, amplitude, amplitude])


func test_bob_y_offset_completes_full_cycle_per_unit() -> void:
	# cycles_per_meter = 1.0 means one full period per meter walked.
	# After 1 m, sin(TAU) == 0 again.
	assert_almost_eq(AmbientNPCMath.bob_y_offset(1.0, 0.05, 1.0), 0.0, 0.0001)


# ----- yaw_toward -------------------------------------------------------

func test_yaw_toward_north_is_zero() -> void:
	# Default facing is +Z; pointing at a +Z target yields yaw 0.
	assert_almost_eq(AmbientNPCMath.yaw_toward(Vector3.ZERO, Vector3(0, 0, 1)), 0.0, 0.0001)


func test_yaw_toward_east_is_positive_half_pi() -> void:
	# Facing +X needs rotation.y == TAU / 4.
	assert_almost_eq(AmbientNPCMath.yaw_toward(Vector3.ZERO, Vector3(1, 0, 0)), PI * 0.5, 0.0001)


func test_yaw_toward_west_is_negative_half_pi() -> void:
	assert_almost_eq(AmbientNPCMath.yaw_toward(Vector3.ZERO, Vector3(-1, 0, 0)), -PI * 0.5, 0.0001)


func test_yaw_toward_south_is_pi() -> void:
	# atan2(0, -1) == PI
	assert_almost_eq(AmbientNPCMath.yaw_toward(Vector3.ZERO, Vector3(0, 0, -1)), PI, 0.0001)


func test_yaw_toward_ignores_y_component() -> void:
	# An elevated target doesn't tilt the NPC; only horizontal direction matters.
	var yaw: float = AmbientNPCMath.yaw_toward(Vector3.ZERO, Vector3(1, 5, 0))
	assert_almost_eq(yaw, PI * 0.5, 0.0001)


func test_yaw_toward_returns_zero_when_from_equals_to() -> void:
	# Degenerate case: avoid a NaN from atan2(0, 0).
	assert_eq(AmbientNPCMath.yaw_toward(Vector3(2, 1, 3), Vector3(2, 1, 3)), 0.0)


# ----- is_within_lod ----------------------------------------------------

func test_is_within_lod_true_at_origin() -> void:
	assert_true(AmbientNPCMath.is_within_lod(Vector3.ZERO, Vector3.ZERO, 20.0))


func test_is_within_lod_true_inside_threshold() -> void:
	assert_true(AmbientNPCMath.is_within_lod(Vector3(5, 0, 0), Vector3.ZERO, 10.0))


func test_is_within_lod_false_beyond_threshold() -> void:
	assert_false(AmbientNPCMath.is_within_lod(Vector3(15, 0, 0), Vector3.ZERO, 10.0))


func test_is_within_lod_exact_boundary_inclusive() -> void:
	# Threshold inclusive: == should count as within.
	assert_true(AmbientNPCMath.is_within_lod(Vector3(10, 0, 0), Vector3.ZERO, 10.0))


func test_is_within_lod_negative_threshold_clamps_to_zero() -> void:
	# Defensive: negative threshold means "always LOD'd out", but we
	# clamp to 0 so any distance-from-self of 0 still passes.
	assert_true(AmbientNPCMath.is_within_lod(Vector3.ZERO, Vector3.ZERO, -5.0))
	assert_false(AmbientNPCMath.is_within_lod(Vector3(0.1, 0, 0), Vector3.ZERO, -5.0))
