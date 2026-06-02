extends "res://addons/gut/test.gd"


# TimeOfDayMath is the testable layer behind the day/night cycle. The
# scene-tree-bound TimeOfDay node forwards to these helpers per frame,
# so locking in the math keeps the visual layer easy to refactor.


# ----- advance ----------------------------------------------------------

func test_advance_zero_delta_returns_current() -> void:
	assert_eq(TimeOfDayMath.advance(0.5, 0.0, 0.01), 0.5)


func test_advance_moves_forward_proportionally_to_rate() -> void:
	# 1 second at rate 0.1/s should add exactly 0.1.
	assert_almost_eq(TimeOfDayMath.advance(0.0, 1.0, 0.1), 0.1, 0.0001)


func test_advance_wraps_past_one() -> void:
	# 0.95 + 0.1 = 1.05 wraps to 0.05.
	assert_almost_eq(TimeOfDayMath.advance(0.95, 1.0, 0.1), 0.05, 0.0001)


func test_advance_clamps_negative_delta() -> void:
	# Time only moves forward — negative delta is a no-op.
	assert_eq(TimeOfDayMath.advance(0.5, -10.0, 1.0), 0.5)


# ----- snap_to ----------------------------------------------------------

func test_snap_to_in_range_passthrough() -> void:
	assert_eq(TimeOfDayMath.snap_to(0.30), 0.30)


func test_snap_to_wraps_past_one() -> void:
	assert_almost_eq(TimeOfDayMath.snap_to(1.30), 0.30, 0.0001)


func test_snap_to_wraps_negative() -> void:
	# fposmod brings -0.10 into [0, 1) as 0.90.
	assert_almost_eq(TimeOfDayMath.snap_to(-0.10), 0.90, 0.0001)


# ----- interpolate_color ------------------------------------------------

func _color_keyframes() -> Array:
	# Four keyframes: black at midnight, red at dawn, white at noon,
	# blue at dusk. Distinct enough that each segment has a verifiable
	# midpoint color.
	return [
		{"time": 0.00, "color": Color.BLACK},
		{"time": 0.25, "color": Color.RED},
		{"time": 0.50, "color": Color.WHITE},
		{"time": 0.75, "color": Color.BLUE},
	]


func test_interpolate_color_exact_keyframe_returns_color() -> void:
	var c: Color = TimeOfDayMath.interpolate_color(0.25, _color_keyframes())
	assert_eq(c, Color.RED)


func test_interpolate_color_midpoint_lerps_halfway() -> void:
	# t=0.125 sits halfway between midnight (black) and dawn (red).
	var c: Color = TimeOfDayMath.interpolate_color(0.125, _color_keyframes())
	assert_almost_eq(c.r, 0.5, 0.01)
	assert_almost_eq(c.g, 0.0, 0.01)
	assert_almost_eq(c.b, 0.0, 0.01)


func test_interpolate_color_wraps_across_midnight() -> void:
	# t=0.875 sits halfway between dusk (blue) and the next midnight (black).
	# Linearly: half black + half blue.
	var c: Color = TimeOfDayMath.interpolate_color(0.875, _color_keyframes())
	assert_almost_eq(c.r, 0.0, 0.01)
	assert_almost_eq(c.g, 0.0, 0.01)
	assert_almost_eq(c.b, 0.5, 0.01)


func test_interpolate_color_empty_keyframes_returns_black() -> void:
	assert_eq(TimeOfDayMath.interpolate_color(0.5, []), Color.BLACK)


func test_interpolate_color_handles_t_outside_zero_one() -> void:
	# fposmod brings t back into [0,1) before the lookup.
	var c1: Color = TimeOfDayMath.interpolate_color(1.25, _color_keyframes())
	assert_eq(c1, Color.RED)
	var c2: Color = TimeOfDayMath.interpolate_color(-0.75, _color_keyframes())
	assert_eq(c2, Color.RED)


# ----- interpolate_float ------------------------------------------------

func _float_keyframes() -> Array:
	return [
		{"time": 0.00, "value": 0.0},
		{"time": 0.25, "value": 1.0},
		{"time": 0.50, "value": 4.0},
		{"time": 0.75, "value": 1.0},
	]


func test_interpolate_float_exact_keyframe() -> void:
	assert_eq(TimeOfDayMath.interpolate_float(0.50, _float_keyframes()), 4.0)


func test_interpolate_float_midpoint() -> void:
	# Between 0.25 (1.0) and 0.50 (4.0), midpoint t=0.375 yields 2.5.
	assert_almost_eq(TimeOfDayMath.interpolate_float(0.375, _float_keyframes()), 2.5, 0.0001)


# ----- is_night --------------------------------------------------------

func test_is_night_at_midnight() -> void:
	assert_true(TimeOfDayMath.is_night(0.0))


func test_is_night_at_dawn_boundary_is_false() -> void:
	# Dawn (0.25) is the start of day, not night.
	assert_false(TimeOfDayMath.is_night(0.25))


func test_is_night_at_noon_is_false() -> void:
	assert_false(TimeOfDayMath.is_night(0.50))


func test_is_night_at_dusk_boundary_is_true() -> void:
	# Dusk (0.75) is the start of night.
	assert_true(TimeOfDayMath.is_night(0.75))


func test_is_night_just_before_dawn_is_true() -> void:
	assert_true(TimeOfDayMath.is_night(0.24))


func test_is_night_just_before_dusk_is_false() -> void:
	assert_false(TimeOfDayMath.is_night(0.74))


func test_is_night_wraps_t_outside_zero_one() -> void:
	# 1.10 wraps to 0.10 — still night (between midnight and dawn).
	assert_true(TimeOfDayMath.is_night(1.10))
