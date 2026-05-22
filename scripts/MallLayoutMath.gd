class_name MallLayoutMath
extends RefCounted

# Pure helpers for placing mall geometry. No node refs — fully GUT-testable
# without instantiating a scene.


static func store_z_positions(
	store_count: int,
	store_width: float,
	store_gap: float
) -> Array[float]:
	# Returns the Z-axis center of each store, with the run of stores centered
	# at Z=0. Stores spaced edge-to-edge with `store_gap` between them.
	var positions: Array[float] = []
	if store_count <= 0:
		return positions
	var total_extent: float = store_count * store_width + max(store_count - 1, 0) * store_gap
	var first_center: float = -total_extent * 0.5 + store_width * 0.5
	for i in range(store_count):
		positions.append(first_center + i * (store_width + store_gap))
	return positions


static func store_front_x(
	side: int,
	corridor_width: float,
	store_front_thickness: float
) -> float:
	# Side: -1 for west, +1 for east. Store front sits flush against the inside
	# of the corridor wall, half its thickness toward the corridor center.
	return float(side) * (corridor_width * 0.5 - store_front_thickness * 0.5)


static func food_court_table_positions(
	count: int,
	spacing: float,
	center: Vector3
) -> Array[Vector3]:
	var positions: Array[Vector3] = []
	if count <= 0:
		return positions
	var start_offset: float = -float(count - 1) * spacing * 0.5
	for i in range(count):
		positions.append(center + Vector3(start_offset + i * spacing, 0.0, 0.0))
	return positions


static func player_spawn_position(
	corridor_length: float,
	z_offset_from_entrance: float,
	eye_height: float = 0.1
) -> Vector3:
	# Entrance is at -Z half, food court at +Z half. Player spawns just
	# inside the entrance, facing into the corridor.
	return Vector3(0.0, eye_height, -corridor_length * 0.5 + z_offset_from_entrance)


static func is_inside_box(
	point: Vector3,
	center: Vector3,
	size: Vector3
) -> bool:
	var half: Vector3 = size * 0.5
	var rel: Vector3 = (point - center).abs()
	return rel.x <= half.x and rel.y <= half.y and rel.z <= half.z
