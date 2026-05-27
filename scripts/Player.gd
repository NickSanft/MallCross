class_name Player
extends CharacterBody3D

const WALK_SPEED: float = 5.0
const SPRINT_SPEED: float = 8.5
const JUMP_VELOCITY: float = 4.8
const DEFAULT_MOUSE_SENSITIVITY: float = 0.002
const HEAD_BOB_AMPLITUDE: float = 0.06
# Cycles per meter walked — keeps bob frequency tied to actual movement, not
# wall-clock time, so standing still freezes the bob.
const HEAD_BOB_CYCLES_PER_METER: float = 0.5

const INTERACTION_GROUP: String = "interactable"

# Meters walked between footstep triggers. Tuned to feel natural at the
# 5 m/s walk speed and 8.5 m/s sprint speed (≈3 steps/sec sprinting).
const FOOTSTEP_DISTANCE: float = 1.8
# Pitch jitter applied per step so footsteps don't sound mechanical.
const FOOTSTEP_PITCH_MIN: float = 0.92
const FOOTSTEP_PITCH_MAX: float = 1.08
const FOOTSTEP_VOLUME_DB: float = -8.0

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var interaction_ray: RayCast3D = $CameraPivot/Camera3D/InteractionRay

var _bob_distance: float = 0.0
var _camera_base_position: Vector3 = Vector3.ZERO
var _paused_for_ui: bool = false
var _current_interactable: Node = null
var _footstep_player: AudioStreamPlayer3D = null
var _last_footstep_distance: float = 0.0
var _mouse_sensitivity: float = DEFAULT_MOUSE_SENSITIVITY

signal interactable_changed(interactable: Node)
signal interaction_triggered(interactable: Node)


func _ready() -> void:
	_camera_base_position = camera.position
	_setup_footstep_player()
	if not OS.has_feature("headless"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _setup_footstep_player() -> void:
	_footstep_player = AudioStreamPlayer3D.new()
	_footstep_player.name = "FootstepPlayer"
	_footstep_player.stream = FootstepAudio.make_footstep_stream()
	_footstep_player.volume_db = FOOTSTEP_VOLUME_DB
	# Route through the SFX bus introduced in v1.1.0. The bus volume is the
	# player-facing "SFX" slider; per-source volume_db stays as a fine-grain
	# offset for future polish (e.g. quieter footsteps on carpet).
	_footstep_player.bus = "SFX"
	# Player IS the source — keep audio simple, no spatial falloff math needed.
	_footstep_player.unit_size = 1.0
	add_child(_footstep_player)


func set_paused_for_ui(paused: bool) -> void:
	_paused_for_ui = paused
	if paused:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		velocity = Vector3.ZERO
		_set_current_interactable(null)
	elif not OS.has_feature("headless"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if _paused_for_ui:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var motion: InputEventMouseMotion = event
		rotate_y(MovementMath.mouse_yaw_delta(motion.relative.x, _mouse_sensitivity))
		camera_pivot.rotate_x(MovementMath.mouse_pitch_delta(motion.relative.y, _mouse_sensitivity))
		camera_pivot.rotation.x = MovementMath.clamp_pitch(camera_pivot.rotation.x)
		return
	if event.is_action_pressed("interact") and _current_interactable != null:
		interaction_triggered.emit(_current_interactable)
		return
	# Esc no longer toggles mouse capture from here — GameController owns it
	# and routes Esc to the settings menu (or to the active modal).


func set_mouse_sensitivity(value: float) -> void:
	_mouse_sensitivity = value


func set_footstep_volume_db(volume_db: float) -> void:
	if _footstep_player != null:
		_footstep_player.volume_db = volume_db


func set_fov(degrees: float) -> void:
	# Sets the camera's vertical field-of-view. Standard FPS values are
	# 70-90; the SettingsManager clamps to 60-110 (matches what most
	# first-person games expose).
	if camera != null:
		camera.fov = degrees


func _physics_process(delta: float) -> void:
	if _paused_for_ui:
		return
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	var speed: float = MovementMath.speed_for_input(WALK_SPEED, SPRINT_SPEED, Input.is_action_pressed("sprint"))

	var target: Vector3 = MovementMath.compute_horizontal_velocity(direction, speed)
	velocity.x = target.x
	velocity.z = target.z

	move_and_slide()

	_update_head_bob(delta)
	_update_interaction_target()


func _update_head_bob(delta: float) -> void:
	var horizontal_speed: float = Vector2(velocity.x, velocity.z).length()
	if is_on_floor() and horizontal_speed > 0.1:
		_bob_distance += horizontal_speed * delta
		if _bob_distance - _last_footstep_distance >= FOOTSTEP_DISTANCE:
			_last_footstep_distance = _bob_distance
			_play_footstep()
	var bob_t: float = _bob_distance * HEAD_BOB_CYCLES_PER_METER
	camera.position = _camera_base_position + MovementMath.head_bob_offset(bob_t, HEAD_BOB_AMPLITUDE)


func _play_footstep() -> void:
	if _footstep_player == null:
		return
	_footstep_player.pitch_scale = randf_range(FOOTSTEP_PITCH_MIN, FOOTSTEP_PITCH_MAX)
	_footstep_player.play()


func _update_interaction_target() -> void:
	var hit: Node = null
	if interaction_ray != null and interaction_ray.is_colliding():
		var collider: Object = interaction_ray.get_collider()
		if collider is Node and (collider as Node).is_in_group(INTERACTION_GROUP):
			hit = collider as Node
	if hit != _current_interactable:
		_set_current_interactable(hit)


func _set_current_interactable(node: Node) -> void:
	_current_interactable = node
	interactable_changed.emit(_current_interactable)


func refresh_interaction_target() -> void:
	# Re-emit interactable_changed for the current target without changing it.
	# GameController calls this after the day advances or a modal closes so the
	# HUD prompt updates immediately (the prompt text often depends on game
	# state, not just which interactable is under the crosshair).
	interactable_changed.emit(_current_interactable)
