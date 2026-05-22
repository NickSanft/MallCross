class_name MovementMath
extends RefCounted

# Pure static helpers for first-person movement and camera math.
# Kept dependency-free so they're exhaustively GUT-testable without
# spinning up a CharacterBody3D or a Camera3D.


static func compute_horizontal_velocity(direction: Vector3, speed: float) -> Vector3:
	return Vector3(direction.x * speed, 0.0, direction.z * speed)


static func speed_for_input(walk_speed: float, sprint_speed: float, sprinting: bool) -> float:
	return sprint_speed if sprinting else walk_speed


static func head_bob_offset(t: float, amplitude: float) -> Vector3:
	# Vertical bob at full frequency, horizontal sway at half frequency
	# (so each footfall pairs with a sway swing). Standard FPS feel.
	var vertical: float = sin(t * TAU) * amplitude
	var horizontal: float = sin(t * TAU * 0.5) * amplitude * 0.5
	return Vector3(horizontal, vertical, 0.0)


static func clamp_pitch(pitch: float, min_pitch: float = -PI / 2.0, max_pitch: float = PI / 2.0) -> float:
	return clampf(pitch, min_pitch, max_pitch)


static func mouse_yaw_delta(relative_x: float, sensitivity: float) -> float:
	return -relative_x * sensitivity


static func mouse_pitch_delta(relative_y: float, sensitivity: float) -> float:
	return -relative_y * sensitivity
