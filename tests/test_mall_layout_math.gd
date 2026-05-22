extends "res://addons/gut/test.gd"


func test_store_z_positions_empty_when_zero_count() -> void:
	var positions: Array[float] = MallLayoutMath.store_z_positions(0, 10.0, 1.0)
	assert_eq(positions.size(), 0)


func test_store_z_positions_single_store_centered_at_zero() -> void:
	var positions: Array[float] = MallLayoutMath.store_z_positions(1, 10.0, 1.0)
	assert_eq(positions.size(), 1)
	assert_almost_eq(positions[0], 0.0, 0.0001)


func test_store_z_positions_three_stores_centered_around_zero() -> void:
	var positions: Array[float] = MallLayoutMath.store_z_positions(3, 10.0, 1.0)
	assert_eq(positions.size(), 3)
	# Middle store should be at 0; outer stores symmetric around it
	assert_almost_eq(positions[1], 0.0, 0.0001)
	assert_almost_eq(positions[0], -11.0, 0.0001)
	assert_almost_eq(positions[2], 11.0, 0.0001)


func test_store_z_positions_spacing_is_store_width_plus_gap() -> void:
	var positions: Array[float] = MallLayoutMath.store_z_positions(3, 10.0, 1.5)
	var step: float = positions[1] - positions[0]
	assert_almost_eq(step, 11.5, 0.0001)


func test_store_z_positions_two_stores_uses_gap_of_one_segment() -> void:
	var positions: Array[float] = MallLayoutMath.store_z_positions(2, 10.0, 2.0)
	# Total extent = 2*10 + 1*2 = 22; centers at -6, +6
	assert_almost_eq(positions[0], -6.0, 0.0001)
	assert_almost_eq(positions[1], 6.0, 0.0001)


func test_store_front_x_west_is_negative() -> void:
	var x: float = MallLayoutMath.store_front_x(-1, 8.0, 0.2)
	assert_lt(x, 0.0)


func test_store_front_x_east_is_positive() -> void:
	var x: float = MallLayoutMath.store_front_x(1, 8.0, 0.2)
	assert_gt(x, 0.0)


func test_store_front_x_is_symmetric_around_zero() -> void:
	var west: float = MallLayoutMath.store_front_x(-1, 8.0, 0.2)
	var east: float = MallLayoutMath.store_front_x(1, 8.0, 0.2)
	assert_almost_eq(west, -east, 0.0001)


func test_store_front_x_inside_corridor_half_width() -> void:
	# Front sits flush against inside of wall, so its center is inside the
	# half-width by half its thickness.
	var x: float = MallLayoutMath.store_front_x(1, 8.0, 0.2)
	assert_almost_eq(x, 3.9, 0.0001)


func test_food_court_table_positions_returns_count_entries() -> void:
	var positions: Array[Vector3] = MallLayoutMath.food_court_table_positions(3, 4.0, Vector3.ZERO)
	assert_eq(positions.size(), 3)


func test_food_court_table_positions_centered_around_center() -> void:
	var positions: Array[Vector3] = MallLayoutMath.food_court_table_positions(3, 4.0, Vector3(0.0, 0.0, 10.0))
	assert_almost_eq(positions[1].x, 0.0, 0.0001)
	assert_almost_eq(positions[1].z, 10.0, 0.0001)


func test_food_court_table_positions_spacing_uniform() -> void:
	var positions: Array[Vector3] = MallLayoutMath.food_court_table_positions(3, 4.0, Vector3.ZERO)
	var d01: float = positions[1].x - positions[0].x
	var d12: float = positions[2].x - positions[1].x
	assert_almost_eq(d01, 4.0, 0.0001)
	assert_almost_eq(d12, 4.0, 0.0001)


func test_food_court_table_positions_zero_count_empty() -> void:
	var positions: Array[Vector3] = MallLayoutMath.food_court_table_positions(0, 4.0, Vector3.ZERO)
	assert_eq(positions.size(), 0)


func test_food_court_table_positions_single_at_center() -> void:
	var positions: Array[Vector3] = MallLayoutMath.food_court_table_positions(1, 4.0, Vector3(2.0, 0.0, 5.0))
	assert_eq(positions.size(), 1)
	assert_almost_eq(positions[0].x, 2.0, 0.0001)
	assert_almost_eq(positions[0].z, 5.0, 0.0001)


func test_player_spawn_at_entrance_end() -> void:
	# Entrance is at -Z half of corridor; spawn should be just inside it.
	var spawn: Vector3 = MallLayoutMath.player_spawn_position(40.0, 3.0, 0.1)
	assert_almost_eq(spawn.z, -17.0, 0.0001)
	assert_almost_eq(spawn.x, 0.0, 0.0001)
	assert_almost_eq(spawn.y, 0.1, 0.0001)


func test_player_spawn_eye_height_default() -> void:
	var spawn: Vector3 = MallLayoutMath.player_spawn_position(40.0, 3.0)
	assert_almost_eq(spawn.y, 0.1, 0.0001)


func test_is_inside_box_interior_point() -> void:
	assert_true(MallLayoutMath.is_inside_box(Vector3.ZERO, Vector3.ZERO, Vector3(2.0, 2.0, 2.0)))


func test_is_inside_box_on_face_inclusive() -> void:
	# Exactly on the +X face — counts as inside (half-open vs closed: closed).
	assert_true(MallLayoutMath.is_inside_box(Vector3(1.0, 0.0, 0.0), Vector3.ZERO, Vector3(2.0, 2.0, 2.0)))


func test_is_inside_box_just_outside_x() -> void:
	assert_false(MallLayoutMath.is_inside_box(Vector3(1.5, 0.0, 0.0), Vector3.ZERO, Vector3(2.0, 2.0, 2.0)))


func test_is_inside_box_outside_y() -> void:
	assert_false(MallLayoutMath.is_inside_box(Vector3(0.0, 5.0, 0.0), Vector3.ZERO, Vector3(2.0, 2.0, 2.0)))


func test_is_inside_box_offset_center() -> void:
	assert_true(MallLayoutMath.is_inside_box(Vector3(10.0, 0.0, 10.0), Vector3(10.0, 0.0, 10.0), Vector3(2.0, 2.0, 2.0)))
