extends "res://addons/gut/test.gd"


func test_horizontal_velocity_along_x_axis() -> void:
	var v: Vector3 = MovementMath.compute_horizontal_velocity(Vector3(1.0, 0.0, 0.0), 5.0)
	assert_eq(v, Vector3(5.0, 0.0, 0.0))


func test_horizontal_velocity_zero_input_gives_zero_output() -> void:
	var v: Vector3 = MovementMath.compute_horizontal_velocity(Vector3.ZERO, 8.5)
	assert_eq(v, Vector3.ZERO)


func test_horizontal_velocity_strips_y_component() -> void:
	# Even if direction has Y, output Y should always be 0 — gravity owns Y.
	var v: Vector3 = MovementMath.compute_horizontal_velocity(Vector3(0.5, 0.7, 0.5), 4.0)
	assert_eq(v.y, 0.0)


func test_horizontal_velocity_diagonal_normalized() -> void:
	var dir: Vector3 = Vector3(1.0, 0.0, 1.0).normalized()
	var v: Vector3 = MovementMath.compute_horizontal_velocity(dir, 5.0)
	assert_almost_eq(v.length(), 5.0, 0.001)


func test_speed_for_input_walks_by_default() -> void:
	assert_eq(MovementMath.speed_for_input(5.0, 8.5, false), 5.0)


func test_speed_for_input_sprints_when_pressed() -> void:
	assert_eq(MovementMath.speed_for_input(5.0, 8.5, true), 8.5)


func test_head_bob_zero_at_t_zero() -> void:
	var offset: Vector3 = MovementMath.head_bob_offset(0.0, 0.06)
	assert_almost_eq(offset.y, 0.0, 0.0001)
	assert_almost_eq(offset.x, 0.0, 0.0001)
	assert_eq(offset.z, 0.0)


func test_head_bob_peaks_vertical_at_quarter_cycle() -> void:
	# sin(TAU * 0.25) = 1 → vertical bob hits +amplitude
	var offset: Vector3 = MovementMath.head_bob_offset(0.25, 0.06)
	assert_almost_eq(offset.y, 0.06, 0.0001)


func test_head_bob_returns_to_zero_at_half_cycle() -> void:
	var offset: Vector3 = MovementMath.head_bob_offset(0.5, 0.06)
	assert_almost_eq(offset.y, 0.0, 0.0001)


func test_head_bob_horizontal_half_frequency_of_vertical() -> void:
	# At t=1.0 vertical completes one cycle (back to 0), but horizontal is at
	# half-cycle, so horizontal is also 0 — confirms phase alignment.
	var offset: Vector3 = MovementMath.head_bob_offset(1.0, 0.06)
	assert_almost_eq(offset.y, 0.0, 0.0001)
	assert_almost_eq(offset.x, 0.0, 0.0001)


func test_head_bob_horizontal_peaks_at_half_cycle() -> void:
	# Horizontal frequency is 0.5x vertical, so at t=0.5 horizontal hits its peak
	# (sin(TAU * 0.5 * 0.5) = sin(PI/2) = 1) at half amplitude.
	var offset: Vector3 = MovementMath.head_bob_offset(0.5, 0.06)
	assert_almost_eq(offset.x, 0.03, 0.0001)


func test_clamp_pitch_inside_range_passthrough() -> void:
	assert_eq(MovementMath.clamp_pitch(0.5), 0.5)


func test_clamp_pitch_clamps_to_positive_half_pi() -> void:
	assert_almost_eq(MovementMath.clamp_pitch(10.0), PI / 2.0, 0.0001)


func test_clamp_pitch_clamps_to_negative_half_pi() -> void:
	assert_almost_eq(MovementMath.clamp_pitch(-10.0), -PI / 2.0, 0.0001)


func test_clamp_pitch_custom_range() -> void:
	assert_almost_eq(MovementMath.clamp_pitch(2.0, -1.0, 1.0), 1.0, 0.0001)


func test_mouse_yaw_inverts_relative_x() -> void:
	# A rightward mouse move should rotate the player to the right, which in
	# Godot is a negative Y rotation — hence the inversion.
	assert_almost_eq(MovementMath.mouse_yaw_delta(100.0, 0.002), -0.2, 0.0001)


func test_mouse_pitch_inverts_relative_y() -> void:
	# Downward mouse move (positive y) should tilt camera down (negative pitch).
	assert_almost_eq(MovementMath.mouse_pitch_delta(50.0, 0.002), -0.1, 0.0001)


func test_mouse_deltas_scale_linearly_with_sensitivity() -> void:
	var low: float = MovementMath.mouse_yaw_delta(100.0, 0.001)
	var high: float = MovementMath.mouse_yaw_delta(100.0, 0.002)
	assert_almost_eq(high, low * 2.0, 0.0001)
