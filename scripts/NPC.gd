class_name NPC
extends Node3D

# Placed mall NPC. Capsule body + box head, PS1-shaded so it sits visually
# with the rest of the mall. Has a billboarded speech Label3D hidden by
# default — a child Area3D triggers it on player proximity.
#
# Phase 9 ships flavor dialog. Phase 9.1 may pipe per-day puzzle hints in.

const BODY_HEIGHT: float = 1.6
const BODY_RADIUS: float = 0.3
const HEAD_SIZE: Vector3 = Vector3(0.42, 0.42, 0.42)
const HEAD_OFFSET_Y: float = BODY_HEIGHT * 0.5 + HEAD_SIZE.y * 0.5
const SPEECH_OFFSET_Y: float = HEAD_OFFSET_Y + HEAD_SIZE.y * 0.5 + 0.4
const PROXIMITY_RADIUS: float = 4.0

const PS1_SHADER: Shader = preload("res://shaders/ps1_box.gdshader")
const PS1_VERTEX_SNAP: float = 100.0

@export var dialog_text: String = "..."
@export var npc_id: String = ""
@export var body_color: Color = Color(0.50, 0.50, 0.70)
@export var head_color: Color = Color(0.85, 0.70, 0.55)

var _speech_label: Label3D


func _ready() -> void:
	_build_visuals()
	_build_proximity_area()


func _build_visuals() -> void:
	var body: StaticBody3D = StaticBody3D.new()
	body.name = "Body"
	body.position = Vector3(0.0, BODY_HEIGHT * 0.5, 0.0)
	add_child(body)

	var body_shape: CollisionShape3D = CollisionShape3D.new()
	var capsule_collision: CapsuleShape3D = CapsuleShape3D.new()
	capsule_collision.radius = BODY_RADIUS
	capsule_collision.height = BODY_HEIGHT
	body_shape.shape = capsule_collision
	body.add_child(body_shape)

	var body_mesh_instance: MeshInstance3D = MeshInstance3D.new()
	var body_mesh: CapsuleMesh = CapsuleMesh.new()
	body_mesh.radius = BODY_RADIUS
	body_mesh.height = BODY_HEIGHT
	body_mesh_instance.mesh = body_mesh
	body_mesh_instance.set_surface_override_material(0, _make_ps1_material(body_color))
	body.add_child(body_mesh_instance)

	var head_mesh_instance: MeshInstance3D = MeshInstance3D.new()
	var head_mesh: BoxMesh = BoxMesh.new()
	head_mesh.size = HEAD_SIZE
	head_mesh_instance.mesh = head_mesh
	head_mesh_instance.position = Vector3(0.0, HEAD_OFFSET_Y, 0.0)
	head_mesh_instance.set_surface_override_material(0, _make_ps1_material(head_color))
	body.add_child(head_mesh_instance)

	_speech_label = Label3D.new()
	_speech_label.name = "SpeechLabel"
	_speech_label.text = dialog_text
	_speech_label.font_size = 96
	_speech_label.modulate = Color(1.0, 0.95, 0.65)
	_speech_label.outline_size = 6
	_speech_label.outline_modulate = Color.BLACK
	_speech_label.pixel_size = 0.004
	_speech_label.position = Vector3(0.0, SPEECH_OFFSET_Y, 0.0)
	_speech_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_speech_label.no_depth_test = true
	_speech_label.visible = false
	add_child(_speech_label)


func _build_proximity_area() -> void:
	var area: Area3D = Area3D.new()
	area.name = "ProximityArea"
	# Default monitoring picks up the Player on layer 1.
	add_child(area)

	var prox_shape: CollisionShape3D = CollisionShape3D.new()
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = PROXIMITY_RADIUS
	prox_shape.shape = sphere
	prox_shape.position = Vector3(0.0, BODY_HEIGHT * 0.5, 0.0)
	area.add_child(prox_shape)

	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)


func _on_body_entered(other: Node3D) -> void:
	if other is Player:
		_speech_label.visible = true


func _on_body_exited(other: Node3D) -> void:
	if other is Player:
		_speech_label.visible = false


func set_dialog(text: String) -> void:
	dialog_text = text
	if _speech_label != null:
		_speech_label.text = text


func _make_ps1_material(color: Color) -> ShaderMaterial:
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = PS1_SHADER
	material.set_shader_parameter("albedo", Vector3(color.r, color.g, color.b))
	material.set_shader_parameter("vertex_snap", PS1_VERTEX_SNAP)
	return material
