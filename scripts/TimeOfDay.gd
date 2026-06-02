class_name TimeOfDay
extends Node

# Drives the visual day/night cycle. The pure math lives in
# TimeOfDayMath; this node is the scene-tree-bound wrapper that:
#   - advances the time-of-day each frame (or pauses when modal-locked),
#   - applies fog + ambient color to the WorldEnvironment,
#   - recolors the upstairs skylight tile,
#   - brightens night-only lamps (desk lamps from Phase 17.3, store
#     signage labels in a future pass).
#
# Time-of-day model: 0.0 = midnight, 0.25 = dawn, 0.5 = noon, 0.75 = dusk.
# In-game-day length is configurable; default is one cycle per 15 real
# minutes, which means a typical 10-minute play session sees one
# full dawn→day transition.

signal time_changed(time_of_day: float)

# 1.0 / 900 seconds == one cycle per 15 real minutes (0.00111/s). Slow
# enough that lighting doesn't strobe; fast enough that a session sees
# noticeable progression.
const DEFAULT_RATE_PER_SECOND: float = 1.0 / 900.0
const SLEEP_WAKE_TIME: float = 0.30  # just past dawn — the "wake up the next morning" target

# Lamps and skylights register themselves with TimeOfDay by joining
# these groups in their _ready (or at spawn time, for programmatically-
# created nodes). The cycle iterates them each frame.
const GROUP_NIGHT_LAMP: String = "night_lamp"
const GROUP_SKYLIGHT: String = "skylight"

# Color keyframes. Tuned for the PS1 fog aesthetic — saturated dawn/dusk
# tones, muted noon (since the PS1 vertex-lit materials don't respond to
# the ambient anyway). 4 keyframes is enough; an artist can swap these
# in the future without touching code.
const FOG_KEYFRAMES: Array = [
	{"time": 0.00, "color": Color(0.04, 0.05, 0.12)},   # midnight — deep navy
	{"time": 0.25, "color": Color(0.46, 0.28, 0.30)},   # dawn — warm pink
	{"time": 0.50, "color": Color(0.18, 0.18, 0.24)},   # noon — neutral gray (mall is indoor, so noon isn't bright)
	{"time": 0.75, "color": Color(0.48, 0.22, 0.22)},   # dusk — burnt orange
]
const AMBIENT_KEYFRAMES: Array = [
	{"time": 0.00, "color": Color(0.10, 0.12, 0.20)},
	{"time": 0.25, "color": Color(0.65, 0.60, 0.60)},
	{"time": 0.50, "color": Color(0.75, 0.80, 0.95)},
	{"time": 0.75, "color": Color(0.55, 0.40, 0.35)},
]
const AMBIENT_ENERGY_KEYFRAMES: Array = [
	{"time": 0.00, "value": 0.10},
	{"time": 0.25, "value": 0.30},
	{"time": 0.50, "value": 0.30},
	{"time": 0.75, "value": 0.22},
]
const SKYLIGHT_KEYFRAMES: Array = [
	{"time": 0.00, "color": Color(0.04, 0.05, 0.15)},
	{"time": 0.25, "color": Color(0.95, 0.75, 0.65)},
	{"time": 0.50, "color": Color(0.65, 0.78, 0.95)},
	{"time": 0.75, "color": Color(0.85, 0.55, 0.35)},
]

# Lamp energy multiplier. Lamps in the scene store their base energy
# in their `light_energy`; we multiply by this factor each frame.
# Night = full energy, day = ~10% (small ambient glow even when sun is up,
# matches the way real lamps stay on indoors at lower-than-night).
const LAMP_NIGHT_ENERGY_FACTOR: float = 1.0
const LAMP_DAY_ENERGY_FACTOR: float = 0.10

var time_of_day: float = 0.30
var rate_per_second: float = DEFAULT_RATE_PER_SECOND
var paused: bool = false

var _env: Environment
var _skylight_base_colors: Dictionary = {}  # node id -> base color (from material's albedo) so we can restore on quit
var _lamp_base_energies: Dictionary = {}    # node id -> base energy


func attach_environment(env: Environment) -> void:
	# Caller (GameController) finds the WorldEnvironment node and passes
	# its .environment in. Done this way rather than searching the tree
	# so test setups can pass in a stub Environment.
	_env = env
	_apply_to_environment()


func set_time(t: float) -> void:
	time_of_day = TimeOfDayMath.snap_to(t)
	_apply_all()
	time_changed.emit(time_of_day)


func jump_to_morning() -> void:
	# Called by GameController on sleep. Advances time directly to just
	# past dawn so the player wakes into a bright mall.
	set_time(SLEEP_WAKE_TIME)


func pause() -> void:
	paused = true


func resume() -> void:
	paused = false


func _process(delta: float) -> void:
	if paused:
		return
	var prev: float = time_of_day
	time_of_day = TimeOfDayMath.advance(time_of_day, delta, rate_per_second)
	# Skip the re-apply if the time hasn't crossed a perceptible
	# threshold — saves work when the player is in a long modal. Threshold
	# is loose; 0.0001 corresponds to ~0.1 second of game time.
	if abs(time_of_day - prev) >= 0.0001:
		_apply_all()
		time_changed.emit(time_of_day)


func _apply_all() -> void:
	_apply_to_environment()
	_apply_to_skylights()
	_apply_to_lamps()


func _apply_to_environment() -> void:
	if _env == null:
		return
	_env.fog_light_color = TimeOfDayMath.interpolate_color(time_of_day, FOG_KEYFRAMES)
	_env.ambient_light_color = TimeOfDayMath.interpolate_color(time_of_day, AMBIENT_KEYFRAMES)
	_env.ambient_light_energy = TimeOfDayMath.interpolate_float(time_of_day, AMBIENT_ENERGY_KEYFRAMES)


func _apply_to_skylights() -> void:
	var color: Color = TimeOfDayMath.interpolate_color(time_of_day, SKYLIGHT_KEYFRAMES)
	for node in get_tree().get_nodes_in_group(GROUP_SKYLIGHT):
		_tint_skylight(node, color)


func _apply_to_lamps() -> void:
	# Continuous brightness curve: day energy at noon, full energy at night,
	# smoothly interpolated through dawn/dusk. Avoids the binary on/off
	# pop that a strict is_night threshold would cause.
	var t: float = time_of_day
	var night_strength: float = _night_strength(t)
	for node in get_tree().get_nodes_in_group(GROUP_NIGHT_LAMP):
		if not (node is OmniLight3D):
			continue
		var light: OmniLight3D = node
		var node_id: int = light.get_instance_id()
		if not _lamp_base_energies.has(node_id):
			_lamp_base_energies[node_id] = light.light_energy
		var base: float = float(_lamp_base_energies[node_id])
		var factor: float = lerp(LAMP_DAY_ENERGY_FACTOR, LAMP_NIGHT_ENERGY_FACTOR, night_strength)
		light.light_energy = base * factor


static func _night_strength(t: float) -> float:
	# Returns 0.0 at noon and 1.0 at midnight, smoothly interpolated.
	# Effectively a cosine that peaks at midnight and troughs at noon.
	# Compute the offset from noon (0.5) and normalize to [0, 1].
	var offset: float = abs(t - 0.5)
	# offset is 0.0 at noon, 0.5 at midnight. Multiply by 2 to fill [0, 1].
	return clamp(offset * 2.0, 0.0, 1.0)


static func _tint_skylight(node: Node, color: Color) -> void:
	# Skylight tiles are MeshInstance3D with a ShaderMaterial whose
	# "albedo" parameter we can tweak. Defensive: if the material isn't
	# a ShaderMaterial (e.g., StandardMaterial3D), fall back to its
	# albedo_color. No-op for nodes without surface materials.
	if not (node is MeshInstance3D):
		return
	var mesh_node: MeshInstance3D = node
	for surface_index in range(mesh_node.get_surface_override_material_count()):
		var mat: Material = mesh_node.get_surface_override_material(surface_index)
		if mat is ShaderMaterial:
			(mat as ShaderMaterial).set_shader_parameter("albedo", Vector3(color.r, color.g, color.b))
		elif mat is StandardMaterial3D:
			(mat as StandardMaterial3D).albedo_color = color
