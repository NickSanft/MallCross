class_name AmbientNPCMath
extends RefCounted

# Testable math helpers for the ambient NPC patrol behavior.
# AmbientNPC stays a thin Node3D wrapper around these — keeps the
# scene-tree-dependent code (set position, look_at, etc.) separate
# from the pure math that drives it.


# Returns the new position one step toward `target` from `current`,
# capped at exactly `target` if the step would overshoot. Plus a flag
# indicating whether the target was reached this step.
#
# Used in AmbientNPC._physics_process to advance the NPC each frame.
# `delta` is the frame time in seconds, `speed` is m/s.
static func step_toward(current: Vector3, target: Vector3, speed: float, delta: float) -> Dictionary:
	var to_target: Vector3 = target - current
	var distance: float = to_target.length()
	var step_size: float = max(0.0, speed) * max(0.0, delta)
	if distance <= 0.0001 or step_size >= distance:
		return {"position": target, "reached": true}
	return {"position": current + to_target.normalized() * step_size, "reached": false}


# Y-offset applied to the NPC's body mesh while walking. Mirrors the
# player's head-bob pattern from MovementMath, scaled smaller because
# the NPC is viewed from outside and a 6 cm bob would look ridiculous.
#
# `distance_walked` is the total meters traveled since the NPC was
# spawned. `cycles_per_meter` controls how fast the bob oscillates —
# 0.7 feels naturally paced at 1.4 m/s.
static func bob_y_offset(distance_walked: float, amplitude: float, cycles_per_meter: float) -> float:
	var phase: float = distance_walked * cycles_per_meter * TAU
	return amplitude * sin(phase)


# Yaw (Y-axis rotation) in radians such that an NPC at `from` facing
# along its +Z axis ends up facing `to`. The Y components are ignored
# so vertical separation doesn't tilt the NPC.
#
# Returns 0 (facing default) when `from == to` so a degenerate call
# doesn't introduce a discontinuity.
static func yaw_toward(from: Vector3, to: Vector3) -> float:
	var dx: float = to.x - from.x
	var dz: float = to.z - from.z
	if abs(dx) < 0.0001 and abs(dz) < 0.0001:
		return 0.0
	# atan2(x, z) lines up with Godot's Y-rotation convention: facing the
	# +Z axis when rotation.y == 0; positive rotation turns toward +X.
	return atan2(dx, dz)


# Returns true iff the NPC is close enough to the player that its
# _physics_process update should run. Beyond the cutoff we skip
# updates entirely — the NPC freezes in place, but since the player
# can't see it anyway, the visual cost is zero and the CPU saving
# scales linearly with NPC count.
static func is_within_lod(npc_position: Vector3, player_position: Vector3, lod_distance: float) -> bool:
	return npc_position.distance_to(player_position) <= max(0.0, lod_distance)
