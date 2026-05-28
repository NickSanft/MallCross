class_name PlacementController
extends Node3D

# Handles the in-world placement loop for one piece of furniture:
#   1. start(item, camera) — spawns a ghost MeshInstance3D.
#   2. _process — raycasts from the camera at the screen center, finds
#      the hit point, checks whether the hit collider is in the matching
#      anchor group, updates the ghost's transform + tint.
#   3. _unhandled_input — Confirm (E) finalizes the placement (only on
#      a valid anchor); Cancel (Esc) bails. Both signal back to the
#      GameController, which persists + spawns the real furniture.
#
# The controller doesn't talk to Profile or scene-spawn anything itself —
# pure presentation + raycast logic. Keeps it testable and lets the
# GameController be the single owner of the save lifecycle.

signal placement_confirmed(item_id: String, position: Vector3, rotation_degrees: float)
signal placement_cancelled

const RAY_LENGTH: float = 8.0
# Tints applied to the ghost mesh material.
const COLOR_VALID: Color = Color(0.40, 0.95, 0.50, 0.55)
const COLOR_INVALID: Color = Color(0.95, 0.30, 0.30, 0.55)

var _item: Item
var _camera: Camera3D
var _ghost: MeshInstance3D
var _ghost_material: StandardMaterial3D
var _valid_anchor_hit: bool = false
var _last_valid_position: Vector3 = Vector3.ZERO
var _active: bool = false
# Header instruction label shown in the bottom-center of the screen while
# placement is active. Attached to the SceneTree's CanvasLayer at start()
# so it z-orders above the world but below the HUD's prompt.
var _hud_label: Label


func start(item: Item, camera: Camera3D) -> void:
	# Called by GameController after the ApartmentEditMenu closes with a
	# Place request. The Player must already be paused-for-UI so movement
	# input doesn't fight placement input.
	if item == null or not item.is_placeable() or camera == null:
		# Defensive: if any of these are missing, immediately cancel so
		# we don't leave the game in a half-locked state.
		placement_cancelled.emit()
		return
	_item = item
	_camera = camera
	_active = true
	_spawn_ghost()
	_spawn_hud_label()


func stop() -> void:
	# Idempotent teardown. Called by both the Confirm and Cancel paths.
	_active = false
	if _ghost != null and is_instance_valid(_ghost):
		_ghost.queue_free()
	_ghost = null
	_ghost_material = null
	if _hud_label != null and is_instance_valid(_hud_label):
		_hud_label.queue_free()
	_hud_label = null
	_item = null
	_camera = null


func is_active() -> bool:
	return _active


func _spawn_ghost() -> void:
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = MallGreybox._visual_size_for_anchor(_item.anchor)
	_ghost = MeshInstance3D.new()
	_ghost.mesh = mesh
	_ghost.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ghost_material = StandardMaterial3D.new()
	_ghost_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ghost_material.albedo_color = COLOR_INVALID
	_ghost_material.no_depth_test = false
	_ghost.material_override = _ghost_material
	add_child(_ghost)


func _spawn_hud_label() -> void:
	# Lightweight overlay label rendered as a child of `self`. CenterContainer
	# pins it bottom-center via anchors; it's small enough that we don't need
	# a full separate scene.
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 50
	add_child(layer)
	_hud_label = Label.new()
	_hud_label.text = "Placing %s — E to confirm · Esc to cancel" % _item.name
	_hud_label.add_theme_font_size_override("font_size", 16)
	_hud_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.85))
	_hud_label.anchor_left = 0.0
	_hud_label.anchor_right = 1.0
	_hud_label.anchor_top = 1.0
	_hud_label.anchor_bottom = 1.0
	_hud_label.offset_top = -52.0
	_hud_label.offset_bottom = -20.0
	_hud_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layer.add_child(_hud_label)


func _process(_delta: float) -> void:
	if not _active or _camera == null or _ghost == null:
		return
	var hit: Dictionary = _raycast_from_camera()
	if hit.is_empty():
		_valid_anchor_hit = false
		_ghost.visible = false
		_update_label_state(false)
		return
	_ghost.visible = true
	var collider: Object = hit.get("collider")
	var hit_position: Vector3 = hit.get("position", Vector3.ZERO)
	var expected_group: String = MallGreybox.APARTMENT_ANCHOR_GROUPS.get(_item.anchor, "")
	if collider is Node and expected_group != "" and (collider as Node).is_in_group(expected_group):
		_valid_anchor_hit = true
		_last_valid_position = _adjust_for_anchor(hit_position, hit.get("normal", Vector3.UP))
		_ghost.position = _last_valid_position
		_ghost_material.albedo_color = COLOR_VALID
		_update_label_state(true)
	else:
		_valid_anchor_hit = false
		_ghost.position = hit_position
		_ghost_material.albedo_color = COLOR_INVALID
		_update_label_state(false)


func _update_label_state(valid: bool) -> void:
	if _hud_label == null:
		return
	if valid:
		_hud_label.text = "Placing %s — E to confirm · Esc to cancel" % _item.name
		_hud_label.add_theme_color_override("font_color", Color(0.85, 1.0, 0.85))
	else:
		_hud_label.text = "Aim at a %s surface · Esc to cancel" % _humanize_anchor(_item.anchor)
		_hud_label.add_theme_color_override("font_color", Color(1.0, 0.75, 0.75))


static func _humanize_anchor(anchor: String) -> String:
	match anchor:
		Item.ANCHOR_FLOOR:
			return "floor"
		Item.ANCHOR_WALL:
			return "wall"
		Item.ANCHOR_DESK:
			return "desk"
		_:
			return "valid"


func _adjust_for_anchor(hit_pos: Vector3, normal: Vector3) -> Vector3:
	# Nudge the ghost slightly off the surface so the box doesn't z-fight
	# the floor/wall/desk mesh. The amount depends on the item's depth in
	# the surface-normal direction — half the item's depth keeps it
	# centered on the surface.
	var size: Vector3 = MallGreybox._visual_size_for_anchor(_item.anchor)
	var half_thickness: float = size.z * 0.5 if _item.anchor == Item.ANCHOR_WALL else size.y * 0.5
	return hit_pos + normal.normalized() * half_thickness


func _raycast_from_camera() -> Dictionary:
	if _camera == null:
		return {}
	var space: PhysicsDirectSpaceState3D = _camera.get_world_3d().direct_space_state
	if space == null:
		return {}
	var from: Vector3 = _camera.global_position
	var forward: Vector3 = -_camera.global_transform.basis.z
	var to: Vector3 = from + forward * RAY_LENGTH
	var params: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, to)
	# Exclude any placed-furniture nodes so the ghost doesn't snap to
	# already-placed pieces (the floor/wall/desk behind them is what we
	# care about).
	var exclude: Array[RID] = []
	for node in get_tree().get_nodes_in_group("placed_furniture"):
		if node is CollisionObject3D:
			exclude.append((node as CollisionObject3D).get_rid())
	params.exclude = exclude
	return space.intersect_ray(params)


func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var ke: InputEventKey = event
	if ke.physical_keycode == KEY_ESCAPE:
		var cancelled_item: String = _item.id if _item != null else ""
		stop()
		get_viewport().set_input_as_handled()
		placement_cancelled.emit()
		return
	# Confirm key = the same E used everywhere else. We watch the actual
	# `interact` action, not just KEY_E, so the player's rebind survives.
	if event.is_action_pressed("interact"):
		if not _valid_anchor_hit:
			# Buzz the label red briefly via _update_label_state — no extra
			# work here; just consume the key so the interact prompt
			# elsewhere doesn't double-fire.
			get_viewport().set_input_as_handled()
			return
		var item_id: String = _item.id
		var pos: Vector3 = _last_valid_position
		stop()
		get_viewport().set_input_as_handled()
		placement_confirmed.emit(item_id, pos, 0.0)
