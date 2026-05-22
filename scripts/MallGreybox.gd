class_name MallGreybox
extends Node3D

# Phase 2 greybox: rectangular corridor with 6 store-front facades (3 per side)
# leading into a food court with 3 tables (mini/midi/full crossword stations,
# wired up in Phase 4). No store interiors (Phase 6). No navmesh (Phase 9).
# Geometry built programmatically so layout constants stay editable as code.

const CORRIDOR_WIDTH: float = 8.0
const CORRIDOR_LENGTH: float = 40.0
const WALL_HEIGHT: float = 5.0
const WALL_THICKNESS: float = 0.4
const FLOOR_THICKNESS: float = 0.4

const STORE_COUNT_PER_SIDE: int = 3
const STORE_WIDTH: float = 10.0
const STORE_GAP: float = 1.5
const STORE_FRONT_THICKNESS: float = 0.2
const STORE_FRONT_HEIGHT: float = WALL_HEIGHT - 1.0  # leaves gap above for "header"

const FOOD_COURT_WIDTH: float = 20.0
const FOOD_COURT_DEPTH: float = 18.0
const TABLE_COUNT: int = 3
const TABLE_SPACING: float = 4.5
const TABLE_TOP_HEIGHT: float = 0.78
const TABLE_TOP_SIZE: Vector3 = Vector3(1.6, 0.08, 1.6)
const TABLE_LEG_SIZE: Vector3 = Vector3(0.08, 0.78, 0.08)

const PLAYER_SPAWN_Z_OFFSET: float = 3.0  # from entrance wall

const FLOOR_COLOR: Color = Color(0.30, 0.30, 0.34)
const CEILING_COLOR: Color = Color(0.78, 0.78, 0.74)
const CORRIDOR_WALL_COLOR: Color = Color(0.52, 0.50, 0.46)
const FOOD_COURT_WALL_COLOR: Color = Color(0.46, 0.42, 0.40)
const ENTRANCE_WALL_COLOR: Color = Color(0.38, 0.34, 0.30)
const TABLE_TOP_COLOR: Color = Color(0.55, 0.40, 0.30)
const TABLE_LEG_COLOR: Color = Color(0.30, 0.22, 0.18)
const FOOD_COURT_FLOOR_TINT: Color = Color(0.34, 0.34, 0.38)

var _store_front_colors: Array[Color] = [
	Color(0.70, 0.35, 0.30),
	Color(0.35, 0.60, 0.40),
	Color(0.30, 0.45, 0.70),
	Color(0.75, 0.65, 0.30),
	Color(0.62, 0.32, 0.68),
	Color(0.30, 0.62, 0.62),
]


func _ready() -> void:
	_build_environment()
	_build_lighting()
	_build_corridor_floor_and_ceiling()
	_build_food_court_floor_and_ceiling()
	_build_corridor_walls()
	_build_corridor_endcap()
	_build_store_fronts()
	_build_food_court_walls()
	_build_food_court_tables()
	_position_player()


func _build_environment() -> void:
	var world_env: WorldEnvironment = WorldEnvironment.new()
	world_env.name = "Env"
	var env: Environment = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.08, 0.08, 0.10)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.85, 0.95)
	env.ambient_light_energy = 0.35
	world_env.environment = env
	add_child(world_env)


func _build_lighting() -> void:
	# Indoor mall — overhead omni lights along corridor + food court.
	var corridor_light_zs: Array[float] = [
		-CORRIDOR_LENGTH * 0.35,
		-CORRIDOR_LENGTH * 0.10,
		CORRIDOR_LENGTH * 0.15,
		CORRIDOR_LENGTH * 0.40,
	]
	for z in corridor_light_zs:
		var light: OmniLight3D = OmniLight3D.new()
		light.name = "CorridorLight"
		light.position = Vector3(0.0, WALL_HEIGHT - 0.4, z)
		light.light_energy = 1.4
		light.omni_range = 14.0
		add_child(light)

	var fc_light: OmniLight3D = OmniLight3D.new()
	fc_light.name = "FoodCourtLight"
	fc_light.position = Vector3(0.0, WALL_HEIGHT - 0.4, CORRIDOR_LENGTH * 0.5 + FOOD_COURT_DEPTH * 0.5)
	fc_light.light_energy = 1.8
	fc_light.omni_range = 22.0
	add_child(fc_light)


func _build_corridor_floor_and_ceiling() -> void:
	var floor_size: Vector3 = Vector3(CORRIDOR_WIDTH, FLOOR_THICKNESS, CORRIDOR_LENGTH)
	var floor_pos: Vector3 = Vector3(0.0, -FLOOR_THICKNESS * 0.5, 0.0)
	add_child(_make_box("CorridorFloor", floor_pos, floor_size, FLOOR_COLOR))

	var ceiling_pos: Vector3 = Vector3(0.0, WALL_HEIGHT + FLOOR_THICKNESS * 0.5, 0.0)
	add_child(_make_box("CorridorCeiling", ceiling_pos, floor_size, CEILING_COLOR))


func _build_food_court_floor_and_ceiling() -> void:
	var fc_z: float = CORRIDOR_LENGTH * 0.5 + FOOD_COURT_DEPTH * 0.5
	var floor_size: Vector3 = Vector3(FOOD_COURT_WIDTH, FLOOR_THICKNESS, FOOD_COURT_DEPTH)

	var floor_pos: Vector3 = Vector3(0.0, -FLOOR_THICKNESS * 0.5, fc_z)
	add_child(_make_box("FoodCourtFloor", floor_pos, floor_size, FOOD_COURT_FLOOR_TINT))

	var ceiling_pos: Vector3 = Vector3(0.0, WALL_HEIGHT + FLOOR_THICKNESS * 0.5, fc_z)
	add_child(_make_box("FoodCourtCeiling", ceiling_pos, floor_size, CEILING_COLOR))


func _build_corridor_walls() -> void:
	# Continuous side walls; store-front facades sit just inside these.
	var half: float = CORRIDOR_WIDTH * 0.5 + WALL_THICKNESS * 0.5
	var size: Vector3 = Vector3(WALL_THICKNESS, WALL_HEIGHT, CORRIDOR_LENGTH)
	add_child(_make_box("CorridorWallWest", Vector3(-half, WALL_HEIGHT * 0.5, 0.0), size, CORRIDOR_WALL_COLOR))
	add_child(_make_box("CorridorWallEast", Vector3(half, WALL_HEIGHT * 0.5, 0.0), size, CORRIDOR_WALL_COLOR))


func _build_corridor_endcap() -> void:
	# Entrance wall at the -Z end (closed for now).
	var entrance_pos: Vector3 = Vector3(0.0, WALL_HEIGHT * 0.5, -CORRIDOR_LENGTH * 0.5 + WALL_THICKNESS * 0.5)
	var entrance_size: Vector3 = Vector3(CORRIDOR_WIDTH, WALL_HEIGHT, WALL_THICKNESS)
	add_child(_make_box("EntranceWall", entrance_pos, entrance_size, ENTRANCE_WALL_COLOR))


func _build_store_fronts() -> void:
	var z_positions: Array[float] = MallLayoutMath.store_z_positions(STORE_COUNT_PER_SIDE, STORE_WIDTH, STORE_GAP)
	var sides: Array[int] = [-1, 1]
	var label_index: int = 0
	for side in sides:
		var x: float = MallLayoutMath.store_front_x(side, CORRIDOR_WIDTH, STORE_FRONT_THICKNESS)
		for i in range(z_positions.size()):
			var color: Color = _store_front_colors[label_index % _store_front_colors.size()]
			var size: Vector3 = Vector3(STORE_FRONT_THICKNESS, STORE_FRONT_HEIGHT, STORE_WIDTH)
			var pos: Vector3 = Vector3(x, STORE_FRONT_HEIGHT * 0.5, z_positions[i])
			add_child(_make_box("StoreFront_" + str(label_index + 1), pos, size, color))
			_add_store_label(pos, side, str(label_index + 1))
			label_index += 1


func _add_store_label(facade_pos: Vector3, side: int, store_number: String) -> void:
	var label: Label3D = Label3D.new()
	label.text = "STORE " + store_number
	label.font_size = 200
	label.modulate = Color.WHITE
	label.outline_size = 10
	label.outline_modulate = Color.BLACK
	# Sit the label slightly in front of the facade, facing the corridor.
	label.position = facade_pos + Vector3(-float(side) * (STORE_FRONT_THICKNESS * 0.5 + 0.02), STORE_FRONT_HEIGHT * 0.25, 0.0)
	label.rotation_degrees = Vector3(0.0, -90.0 * float(side), 0.0)
	label.pixel_size = 0.005
	add_child(label)


func _build_food_court_walls() -> void:
	var fc_z_center: float = CORRIDOR_LENGTH * 0.5 + FOOD_COURT_DEPTH * 0.5
	var fc_z_back: float = CORRIDOR_LENGTH * 0.5 + FOOD_COURT_DEPTH

	var back_size: Vector3 = Vector3(FOOD_COURT_WIDTH + WALL_THICKNESS * 2.0, WALL_HEIGHT, WALL_THICKNESS)
	add_child(_make_box("FoodCourtBackWall", Vector3(0.0, WALL_HEIGHT * 0.5, fc_z_back + WALL_THICKNESS * 0.5), back_size, FOOD_COURT_WALL_COLOR))

	var side_size: Vector3 = Vector3(WALL_THICKNESS, WALL_HEIGHT, FOOD_COURT_DEPTH)
	add_child(_make_box("FoodCourtWallWest", Vector3(-FOOD_COURT_WIDTH * 0.5 - WALL_THICKNESS * 0.5, WALL_HEIGHT * 0.5, fc_z_center), side_size, FOOD_COURT_WALL_COLOR))
	add_child(_make_box("FoodCourtWallEast", Vector3(FOOD_COURT_WIDTH * 0.5 + WALL_THICKNESS * 0.5, WALL_HEIGHT * 0.5, fc_z_center), side_size, FOOD_COURT_WALL_COLOR))

	# Front shoulders connecting the wider food court to the narrower corridor.
	var shoulder_width: float = (FOOD_COURT_WIDTH - CORRIDOR_WIDTH) * 0.5
	var shoulder_size: Vector3 = Vector3(shoulder_width, WALL_HEIGHT, WALL_THICKNESS)
	var shoulder_z: float = CORRIDOR_LENGTH * 0.5 + WALL_THICKNESS * 0.5
	add_child(_make_box("FoodCourtShoulderWest", Vector3(-CORRIDOR_WIDTH * 0.5 - shoulder_width * 0.5, WALL_HEIGHT * 0.5, shoulder_z), shoulder_size, FOOD_COURT_WALL_COLOR))
	add_child(_make_box("FoodCourtShoulderEast", Vector3(CORRIDOR_WIDTH * 0.5 + shoulder_width * 0.5, WALL_HEIGHT * 0.5, shoulder_z), shoulder_size, FOOD_COURT_WALL_COLOR))


func _build_food_court_tables() -> void:
	var fc_z_center: float = CORRIDOR_LENGTH * 0.5 + FOOD_COURT_DEPTH * 0.5
	# Tables sit toward the back half of the food court, leaving open space
	# near the corridor mouth for foot traffic.
	var table_row_center: Vector3 = Vector3(0.0, 0.0, fc_z_center + 2.0)
	var positions: Array[Vector3] = MallLayoutMath.food_court_table_positions(TABLE_COUNT, TABLE_SPACING, table_row_center)
	var difficulty_labels: Array[String] = ["MINI", "MIDI", "FULL"]
	# Phase 4: only MINI has a wired puzzle (demo_5x5). MIDI / FULL get filled
	# in Phase 7 once the authoring tool produces real 15x15s.
	var puzzle_ids: Array[String] = ["demo_5x5", "", ""]
	for i in range(positions.size()):
		_build_table("Table_" + difficulty_labels[i], positions[i], difficulty_labels[i], puzzle_ids[i])


func _build_table(table_name: String, table_position: Vector3, label_text: String, puzzle_id: String = "") -> void:
	var table_root: Node3D = Node3D.new()
	table_root.name = table_name
	table_root.position = table_position
	add_child(table_root)

	var top_pos: Vector3 = Vector3(0.0, TABLE_TOP_HEIGHT, 0.0)
	var top: StaticBody3D = _make_box("Top", top_pos, TABLE_TOP_SIZE, TABLE_TOP_COLOR)
	if puzzle_id != "":
		top.add_to_group(Player.INTERACTION_GROUP)
		top.set_meta("puzzle_id", puzzle_id)
		top.set_meta("puzzle_label", "Solve " + label_text + " Crossword")
		top.set_meta("woints_reward", WointsConfig.reward_for_difficulty(label_text))
	table_root.add_child(top)

	var leg_x: float = TABLE_TOP_SIZE.x * 0.5 - 0.12
	var leg_z: float = TABLE_TOP_SIZE.z * 0.5 - 0.12
	var leg_y: float = TABLE_LEG_SIZE.y * 0.5
	var leg_corners: Array[Vector3] = [
		Vector3(leg_x, leg_y, leg_z),
		Vector3(-leg_x, leg_y, leg_z),
		Vector3(leg_x, leg_y, -leg_z),
		Vector3(-leg_x, leg_y, -leg_z),
	]
	for i in range(leg_corners.size()):
		table_root.add_child(_make_box("Leg_" + str(i), leg_corners[i], TABLE_LEG_SIZE, TABLE_LEG_COLOR))

	var hover_label: Label3D = Label3D.new()
	hover_label.text = label_text
	hover_label.font_size = 160
	hover_label.modulate = Color(1.0, 0.95, 0.55)
	hover_label.outline_size = 8
	hover_label.outline_modulate = Color.BLACK
	hover_label.position = Vector3(0.0, TABLE_TOP_HEIGHT + 0.9, 0.0)
	hover_label.pixel_size = 0.005
	hover_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	table_root.add_child(hover_label)


func _position_player() -> void:
	var player_node: Node = get_node_or_null("Player")
	if player_node == null or not player_node is Node3D:
		return
	var player_3d: Node3D = player_node
	player_3d.position = MallLayoutMath.player_spawn_position(CORRIDOR_LENGTH, PLAYER_SPAWN_Z_OFFSET, 0.1)
	# Face into the mall (positive Z).
	player_3d.rotation = Vector3.ZERO


func _make_box(box_name: String, box_position: Vector3, box_size: Vector3, color: Color) -> StaticBody3D:
	var body: StaticBody3D = StaticBody3D.new()
	body.name = box_name
	body.position = box_position

	var shape: CollisionShape3D = CollisionShape3D.new()
	var collision: BoxShape3D = BoxShape3D.new()
	collision.size = box_size
	shape.shape = collision
	body.add_child(shape)

	var mesh: MeshInstance3D = MeshInstance3D.new()
	var box_mesh: BoxMesh = BoxMesh.new()
	box_mesh.size = box_size
	mesh.mesh = box_mesh
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	mesh.set_surface_override_material(0, material)
	body.add_child(mesh)

	return body
