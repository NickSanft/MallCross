class_name TestRoom
extends Node3D

# Phase 1 test room: programmatic greybox so we can iterate on lighting and
# colors without editor scene fiddling. Phase 2 replaces this with the actual
# mall greybox.

const ROOM_SIZE: float = 24.0
const WALL_HEIGHT: float = 4.0
const WALL_THICKNESS: float = 0.5

const FLOOR_COLOR: Color = Color(0.45, 0.45, 0.50)
const WALL_COLOR_NORTH: Color = Color(0.65, 0.40, 0.40)
const WALL_COLOR_SOUTH: Color = Color(0.40, 0.65, 0.40)
const WALL_COLOR_WEST: Color = Color(0.40, 0.40, 0.65)
const WALL_COLOR_EAST: Color = Color(0.65, 0.60, 0.40)


func _ready() -> void:
	_build_environment()
	_build_lighting()
	_build_floor()
	_build_walls()
	_build_landmarks()


func _build_environment() -> void:
	var world_env: WorldEnvironment = WorldEnvironment.new()
	world_env.name = "Env"
	var environment: Environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.55, 0.72, 0.88)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.75, 0.82, 0.95)
	environment.ambient_light_energy = 0.35
	world_env.environment = environment
	add_child(world_env)


func _build_lighting() -> void:
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-50.0, -30.0, 0.0)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	add_child(sun)


func _build_floor() -> void:
	var size: Vector3 = Vector3(ROOM_SIZE, WALL_THICKNESS, ROOM_SIZE)
	var position: Vector3 = Vector3(0.0, -WALL_THICKNESS * 0.5, 0.0)
	add_child(_make_box("Floor", position, size, FLOOR_COLOR))


func _build_walls() -> void:
	var half: float = ROOM_SIZE * 0.5
	var y: float = WALL_HEIGHT * 0.5
	var ns_size: Vector3 = Vector3(ROOM_SIZE, WALL_HEIGHT, WALL_THICKNESS)
	var ew_size: Vector3 = Vector3(WALL_THICKNESS, WALL_HEIGHT, ROOM_SIZE)
	add_child(_make_box("WallNorth", Vector3(0.0, y, -half), ns_size, WALL_COLOR_NORTH))
	add_child(_make_box("WallSouth", Vector3(0.0, y, half), ns_size, WALL_COLOR_SOUTH))
	add_child(_make_box("WallWest", Vector3(-half, y, 0.0), ew_size, WALL_COLOR_WEST))
	add_child(_make_box("WallEast", Vector3(half, y, 0.0), ew_size, WALL_COLOR_EAST))


func _build_landmarks() -> void:
	# A few obstacles so the player can verify movement, jumping, and head-bob
	# feel right. Loose pillar arrangement.
	var pillar_color: Color = Color(0.85, 0.78, 0.62)
	var pillar_size: Vector3 = Vector3(0.8, 2.2, 0.8)
	var offsets: Array[Vector3] = [
		Vector3(4.0, 1.1, -4.0),
		Vector3(-4.0, 1.1, -4.0),
		Vector3(4.0, 1.1, 4.0),
		Vector3(-4.0, 1.1, 4.0),
		Vector3(0.0, 0.4, -8.0),  # short stepping block (for jump testing)
	]
	var sizes: Array[Vector3] = [
		pillar_size,
		pillar_size,
		pillar_size,
		pillar_size,
		Vector3(2.0, 0.8, 2.0),
	]
	for i in range(offsets.size()):
		add_child(_make_box("Landmark" + str(i), offsets[i], sizes[i], pillar_color))


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
