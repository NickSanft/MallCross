class_name AmbientNPC
extends Node3D

# Non-interactive background NPC that walks back and forth between two
# pre-authored points, pausing briefly at each endpoint. Visually similar
# to the dialog-bearing NPCs (capsule body + box head, PS1 material) but
# stripped of the speech label + proximity area.
#
# AmbientNPC has no collision body and doesn't interact with the player —
# the patrol routes are authored to stay on open floor. Pure presentation.

const DEFAULT_WALK_SPEED: float = 1.4         # m/s — strolling pace
const DEFAULT_BOB_AMPLITUDE: float = 0.03
const DEFAULT_BOB_CYCLES_PER_METER: float = 0.7
const DEFAULT_IDLE_DURATION_S: float = 1.5
# Beyond this distance from the player, _physics_process skips entirely.
# 20 m is past the corridor's visible-fog range, so the NPC freezing is
# invisible. Saves 80%+ CPU when the player is on the other side of the
# mall from any given ambient NPC.
const DEFAULT_LOD_DISTANCE: float = 20.0

# Visual constants — small NPC (~1.45m total) so it's distinguishable
# from the dialog NPCs at a glance.
const BODY_HEIGHT: float = 1.4
const BODY_RADIUS: float = 0.26
const HEAD_SIZE: Vector3 = Vector3(0.36, 0.36, 0.36)
const HEAD_OFFSET_Y: float = BODY_HEIGHT * 0.5 + HEAD_SIZE.y * 0.5

const PS1_SHADER: Shader = preload("res://shaders/ps1_box.gdshader")
const PS1_VERTEX_SNAP: float = 100.0

var walk_speed: float = DEFAULT_WALK_SPEED
var bob_amplitude: float = DEFAULT_BOB_AMPLITUDE
var bob_cycles_per_meter: float = DEFAULT_BOB_CYCLES_PER_METER
var idle_duration_s: float = DEFAULT_IDLE_DURATION_S
var lod_distance: float = DEFAULT_LOD_DISTANCE

var _start_pos: Vector3
var _end_pos: Vector3
var _target_pos: Vector3
var _idle_remaining: float = 0.0
var _walking: bool = true
var _bob_distance: float = 0.0
var _body_root: Node3D  # holds the body + head; we offset this for the bob
var _body_base_y: float = 0.0
var _player: Node3D


func configure(start_pos: Vector3, end_pos: Vector3, body_color: Color, head_color: Color) -> void:
	# Must be called by the spawner BEFORE the NPC enters the scene tree.
	# Sets initial position, builds the visual, and orients toward the
	# first patrol target. configure-then-add is the standard
	# programmatic-spawn pattern used elsewhere in MallGreybox.
	_start_pos = start_pos
	_end_pos = end_pos
	_target_pos = end_pos
	position = start_pos
	rotation = Vector3(0.0, AmbientNPCMath.yaw_toward(start_pos, end_pos), 0.0)
	_build_visual(body_color, head_color)


func cache_player(player: Node3D) -> void:
	# Optional: spawner can pass the Player reference for LOD checks.
	# Without it, the NPC simulates every frame regardless of distance
	# (still cheap at 4-6 NPCs, but the LOD path is worth it).
	_player = player


func _physics_process(delta: float) -> void:
	if _player != null and not AmbientNPCMath.is_within_lod(global_position, _player.global_position, lod_distance):
		return
	if _walking:
		_advance_walking(delta)
	else:
		_advance_idle(delta)


func _advance_walking(delta: float) -> void:
	var step_result: Dictionary = AmbientNPCMath.step_toward(position, _target_pos, walk_speed, delta)
	var new_position: Vector3 = step_result["position"]
	var reached: bool = bool(step_result["reached"])
	# Track distance walked even when we cap at the target — keeps the
	# bob phase continuous across the brief idle so the next walk
	# segment doesn't reset the gait awkwardly.
	_bob_distance += new_position.distance_to(position)
	position = new_position
	_apply_bob()
	if reached:
		_walking = false
		_idle_remaining = idle_duration_s


func _advance_idle(delta: float) -> void:
	_idle_remaining -= delta
	# Settle the body back to its base position while idle so the NPC
	# doesn't freeze mid-bob.
	if _body_root != null:
		_body_root.position.y = _body_base_y
	if _idle_remaining <= 0.0:
		# Flip target — patrol the other direction.
		_target_pos = _start_pos if _target_pos == _end_pos else _end_pos
		rotation = Vector3(0.0, AmbientNPCMath.yaw_toward(position, _target_pos), 0.0)
		_walking = true


func _apply_bob() -> void:
	if _body_root == null:
		return
	var dy: float = AmbientNPCMath.bob_y_offset(_bob_distance, bob_amplitude, bob_cycles_per_meter)
	_body_root.position.y = _body_base_y + dy


func _build_visual(body_color: Color, head_color: Color) -> void:
	_body_root = Node3D.new()
	_body_root.name = "BodyRoot"
	_body_root.position = Vector3(0.0, BODY_HEIGHT * 0.5, 0.0)
	_body_base_y = _body_root.position.y
	add_child(_body_root)

	# Capsule body (mesh only — no collision shape; AmbientNPCs don't
	# block the player).
	var body_mesh_instance: MeshInstance3D = MeshInstance3D.new()
	body_mesh_instance.name = "Body"
	var body_mesh: CapsuleMesh = CapsuleMesh.new()
	body_mesh.radius = BODY_RADIUS
	body_mesh.height = BODY_HEIGHT
	body_mesh_instance.mesh = body_mesh
	body_mesh_instance.set_surface_override_material(0, _make_ps1_material(body_color))
	_body_root.add_child(body_mesh_instance)

	# Box head, offset up from body center.
	var head_mesh_instance: MeshInstance3D = MeshInstance3D.new()
	head_mesh_instance.name = "Head"
	var head_mesh: BoxMesh = BoxMesh.new()
	head_mesh.size = HEAD_SIZE
	head_mesh_instance.mesh = head_mesh
	head_mesh_instance.position = Vector3(0.0, HEAD_OFFSET_Y, 0.0)
	head_mesh_instance.set_surface_override_material(0, _make_ps1_material(head_color))
	_body_root.add_child(head_mesh_instance)


func _make_ps1_material(color: Color) -> ShaderMaterial:
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = PS1_SHADER
	material.set_shader_parameter("albedo", Vector3(color.r, color.g, color.b))
	material.set_shader_parameter("vertex_snap", PS1_VERTEX_SNAP)
	return material
