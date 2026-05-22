class_name Player
extends CharacterBody3D

const WALK_SPEED: float = 5.0
const SPRINT_SPEED: float = 8.5
const JUMP_VELOCITY: float = 4.8
const MOUSE_SENSITIVITY: float = 0.002
const HEAD_BOB_AMPLITUDE: float = 0.06
# Cycles per meter walked — keeps bob frequency tied to actual movement, not
# wall-clock time, so standing still freezes the bob.
const HEAD_BOB_CYCLES_PER_METER: float = 0.5

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D

var _bob_distance: float = 0.0
var _camera_base_position: Vector3 = Vector3.ZERO


func _ready() -> void:
	_camera_base_position = camera.position
	if not OS.has_feature("headless"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var motion: InputEventMouseMotion = event
		rotate_y(MovementMath.mouse_yaw_delta(motion.relative.x, MOUSE_SENSITIVITY))
		camera_pivot.rotate_x(MovementMath.mouse_pitch_delta(motion.relative.y, MOUSE_SENSITIVITY))
		camera_pivot.rotation.x = MovementMath.clamp_pitch(camera_pivot.rotation.x)
	elif event.is_action_pressed("ui_cancel"):
		_toggle_mouse_capture()


func _toggle_mouse_capture() -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
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


func _update_head_bob(delta: float) -> void:
	var horizontal_speed: float = Vector2(velocity.x, velocity.z).length()
	if is_on_floor() and horizontal_speed > 0.1:
		_bob_distance += horizontal_speed * delta
	var bob_t: float = _bob_distance * HEAD_BOB_CYCLES_PER_METER
	camera.position = _camera_base_position + MovementMath.head_bob_offset(bob_t, HEAD_BOB_AMPLITUDE)
