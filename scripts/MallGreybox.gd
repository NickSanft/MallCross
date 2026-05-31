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

# v1.4.1 (Phase 17.2) apartment zone: a small back-of-food-court area for
# furniture placement. The sleep cushion already lived here; this just
# adds a desk prop + an "edit apartment" kiosk + raycast-target groups on
# the floor / back-wall meshes. Future Phase 19 promotes this to a real
# room behind a door; today it's just a labeled patch of the food court.
const APARTMENT_DESK_HEIGHT: float = 0.78
const APARTMENT_DESK_SIZE: Vector3 = Vector3(1.6, 0.78, 0.7)
const APARTMENT_DESK_COLOR: Color = Color(0.40, 0.28, 0.22)
const APARTMENT_KIOSK_SIZE: Vector3 = Vector3(0.7, 1.1, 0.4)
const APARTMENT_KIOSK_COLOR: Color = Color(0.30, 0.55, 0.85)

# Groups the PlacementController uses to validate raycast hits.
const APARTMENT_ANCHOR_GROUPS: Dictionary = {
	Item.ANCHOR_FLOOR: "anchor_floor",
	Item.ANCHOR_WALL: "anchor_wall",
	Item.ANCHOR_DESK: "anchor_desk",
}

# Phase 8 PS1/N64 aesthetic. Lower vertex_snap = chunkier wobble. 100 is the
# sweet spot for a 5–40 m mall: noticeable jitter, no broken-looking geometry.
const PS1_VERTEX_SNAP: float = 100.0
const PS1_SHADER: Shader = preload("res://shaders/ps1_box.gdshader")
const NPC_SCENE: PackedScene = preload("res://scenes/NPC.tscn")

# v1.5.0 Phase 18 — ambient NPCs that wander between two hand-authored
# waypoints. Pure presentation: no dialog, no interaction, no collision.
# Patrol routes deliberately stay on open floor so the NPCs don't need
# any pathfinding logic (no walls in the way; floor is flat).
const AMBIENT_NPC_DATA: Array = [
	{
		# Window-shopper drifting along the west side of the corridor.
		"start": Vector3(-2.6, 0.0, -16.0),
		"end": Vector3(-2.6, 0.0, 16.0),
		"body_color": Color(0.45, 0.55, 0.70),
		"head_color": Color(0.85, 0.70, 0.55),
	},
	{
		# Counterpart on the east side, walking the opposite way.
		"start": Vector3(2.6, 0.0, 16.0),
		"end": Vector3(2.6, 0.0, -16.0),
		"body_color": Color(0.55, 0.40, 0.45),
		"head_color": Color(0.80, 0.65, 0.50),
	},
	{
		# Food court patron crossing east-to-west in front of the tables.
		"start": Vector3(-7.0, 0.0, 26.0),
		"end": Vector3(7.0, 0.0, 26.0),
		"body_color": Color(0.40, 0.60, 0.50),
		"head_color": Color(0.72, 0.62, 0.50),
	},
	{
		# Another food-court wanderer, deeper into the court.
		"start": Vector3(6.0, 0.0, 31.0),
		"end": Vector3(-6.0, 0.0, 31.0),
		"body_color": Color(0.65, 0.50, 0.30),
		"head_color": Color(0.85, 0.75, 0.60),
	},
]

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

# npc_id -> NPC instance. Filled by _spawn_npcs so GameController can
# refresh per-day dialog via apply_npc_hints_for_day.
var _spawned_npcs: Dictionary = {}


var _apartment_desk: StaticBody3D  # cached so spawn_placed_furniture knows where the desk anchor is
# Track spawned furniture nodes by item_id so removal can free the right
# one without walking the scene tree. Populated by spawn_placed_furniture.
var _placed_furniture_nodes: Dictionary = {}


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
	_build_sleep_cushion()
	_build_apartment_zone()
	_spawn_npcs()
	_spawn_ambient_npcs()
	_position_player()
	_mark_apartment_anchor_surfaces()


func _spawn_ambient_npcs() -> void:
	# Builds the patrol set defined in AMBIENT_NPC_DATA. The Player node
	# is added later by the existing _position_player flow, so we look it
	# up from the parent so each ambient NPC can cache the reference for
	# LOD checks. If the Player isn't found (e.g. headless smoke test
	# without the full scene), the LOD check falls through to always-on
	# and the NPCs still simulate — slightly more CPU but no failure.
	var player: Node3D = get_node_or_null("Player")
	for entry in AMBIENT_NPC_DATA:
		var npc: AmbientNPC = AmbientNPC.new()
		npc.name = "AmbientNPC"
		npc.configure(
			entry["start"] as Vector3,
			entry["end"] as Vector3,
			entry["body_color"] as Color,
			entry["head_color"] as Color
		)
		if player != null:
			npc.cache_player(player)
		add_child(npc)


func _spawn_npcs() -> void:
	for npc_data in NPCRoster.all_npcs():
		var npc: NPC = NPC_SCENE.instantiate()
		npc.npc_id = npc_data["id"]
		npc.dialog_text = npc_data["dialog"]
		npc.body_color = npc_data["body_color"]
		npc.head_color = npc_data["head_color"]
		add_child(npc)
		# Setting transform after add_child ensures the @export defaults on the
		# NPC have already been applied; rotation/position then override.
		npc.position = npc_data["position"]
		npc.rotation_degrees = Vector3(0.0, float(npc_data["facing_y_degrees"]), 0.0)
		_spawned_npcs[npc.npc_id] = npc


func apply_npc_hints_for_day(current_day: int) -> void:
	# Overrides each NPC's dialog with today's puzzle hint when one exists.
	# NPCs without a hint for this day fall back to their flavor line — we
	# explicitly re-apply the roster default to guarantee that's what shows.
	var hints: Dictionary = HintRoster.hints_for_day(current_day)
	for npc_data in NPCRoster.all_npcs():
		var npc_id: String = String(npc_data["id"])
		if not _spawned_npcs.has(npc_id):
			continue
		var npc: NPC = _spawned_npcs[npc_id]
		var hint: String = String(hints.get(npc_id, ""))
		if hint != "":
			npc.set_dialog(hint)
		else:
			npc.set_dialog(String(npc_data["dialog"]))


func _build_environment() -> void:
	var world_env: WorldEnvironment = WorldEnvironment.new()
	world_env.name = "Env"
	var env: Environment = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.05, 0.05, 0.08)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.75, 0.80, 0.95)
	env.ambient_light_energy = 0.30
	# PS1-style atmospheric fog. Tuned so the entrance is just visible from
	# the food court but distant geometry softly fades into the dark.
	env.fog_enabled = true
	env.fog_light_color = Color(0.18, 0.18, 0.24)
	env.fog_density = 0.025
	env.fog_sky_affect = 0.0
	env.fog_sun_scatter = 0.0
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
	# Phase 6: Store 1 wired as mall_general (perks).
	# Phase 17.1 (v1.4.0): Store 2 wired as home_goods (apartment furniture).
	# Stores 3-6 stay decorative until future shop themes land.
	var shop_ids_by_store_number: Dictionary = {
		1: Item.SHOP_MALL_GENERAL,
		2: Item.SHOP_HOME_GOODS,
	}
	# Friendly per-shop title strings shown in the ShopUI header. Falls back
	# to "Enter Store N" for any store_number without an explicit entry.
	var shop_titles_by_store_number: Dictionary = {
		1: "Mall General Store",
		2: "Home Goods",
	}
	var label_index: int = 0
	for side in sides:
		var x: float = MallLayoutMath.store_front_x(side, CORRIDOR_WIDTH, STORE_FRONT_THICKNESS)
		for i in range(z_positions.size()):
			var store_number: int = label_index + 1
			var color: Color = _store_front_colors[label_index % _store_front_colors.size()]
			var size: Vector3 = Vector3(STORE_FRONT_THICKNESS, STORE_FRONT_HEIGHT, STORE_WIDTH)
			var pos: Vector3 = Vector3(x, STORE_FRONT_HEIGHT * 0.5, z_positions[i])
			var facade: StaticBody3D = _make_box("StoreFront_" + str(store_number), pos, size, color)
			if shop_ids_by_store_number.has(store_number):
				facade.add_to_group(Player.INTERACTION_GROUP)
				facade.set_meta("shop_id", shop_ids_by_store_number[store_number])
				var title: String = shop_titles_by_store_number.get(store_number, "Enter Store " + str(store_number))
				facade.set_meta("shop_label", title)
			add_child(facade)
			_add_store_label(pos, side, str(store_number))
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
	# PS1 vertex snap jiggles facade vertices in NDC space (~7 cm at typical
	# viewing distance). Without no_depth_test, the label and the facade
	# behind it z-fight every frame as the wobble crosses the small clearance.
	label.no_depth_test = true
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


func _build_apartment_zone() -> void:
	# Position the desk + kiosk near the back of the food court, on the
	# east side of the sleep cushion. Far enough from the cushion that
	# walking up to one doesn't accidentally trigger the other.
	var fc_z_back: float = CORRIDOR_LENGTH * 0.5 + FOOD_COURT_DEPTH
	# Desk: against the east wall, ~1m in from the back. Players can place
	# desk-anchored items (lamp, coffee maker) on the top surface.
	var desk_position: Vector3 = Vector3(
		FOOD_COURT_WIDTH * 0.5 - APARTMENT_DESK_SIZE.x * 0.5 - 0.3,
		APARTMENT_DESK_HEIGHT * 0.5,
		fc_z_back - 2.4
	)
	_apartment_desk = _make_box("ApartmentDesk", desk_position, APARTMENT_DESK_SIZE, APARTMENT_DESK_COLOR)
	add_child(_apartment_desk)

	# Kiosk: an interactable in front of the desk. Walking up + pressing E
	# opens the apartment edit menu (handled by GameController).
	var kiosk_position: Vector3 = Vector3(
		FOOD_COURT_WIDTH * 0.5 - APARTMENT_KIOSK_SIZE.x * 0.5 - 0.3,
		APARTMENT_KIOSK_SIZE.y * 0.5,
		fc_z_back - 4.2
	)
	var kiosk: StaticBody3D = _make_box("ApartmentKiosk", kiosk_position, APARTMENT_KIOSK_SIZE, APARTMENT_KIOSK_COLOR)
	kiosk.add_to_group(Player.INTERACTION_GROUP)
	kiosk.set_meta("edit_apartment", true)
	kiosk.set_meta("apartment_label", "Customize apartment")
	add_child(kiosk)

	# Hover label so the kiosk is findable.
	var label: Label3D = Label3D.new()
	label.text = "APARTMENT"
	label.font_size = 120
	label.modulate = Color(0.85, 0.95, 1.0)
	label.outline_size = 8
	label.outline_modulate = Color.BLACK
	label.position = kiosk_position + Vector3(0.0, APARTMENT_KIOSK_SIZE.y * 0.5 + 0.5, 0.0)
	label.pixel_size = 0.005
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	add_child(label)


func _mark_apartment_anchor_surfaces() -> void:
	# Tags meshes the PlacementController will accept as raycast targets
	# for each anchor type. The check runs once at _ready end, after every
	# build step has created its node, so we don't have to remember to
	# add_to_group inline at each box construction site.
	#
	# Anchor mapping:
	#   FloorPaths: the food court floor (any placement away from the desk).
	#   Wall: the food court back wall (posters go here).
	#   Desk: the top face of the apartment desk we just built.
	var floor_node: Node = get_node_or_null("FoodCourtFloor")
	if floor_node != null:
		floor_node.add_to_group(APARTMENT_ANCHOR_GROUPS[Item.ANCHOR_FLOOR])
	var back_wall: Node = get_node_or_null("FoodCourtBackWall")
	if back_wall != null:
		back_wall.add_to_group(APARTMENT_ANCHOR_GROUPS[Item.ANCHOR_WALL])
	if _apartment_desk != null:
		_apartment_desk.add_to_group(APARTMENT_ANCHOR_GROUPS[Item.ANCHOR_DESK])


func spawn_placed_furniture(profile: Profile) -> void:
	# Called by GameController on _ready and after every placement/removal.
	# Idempotent: walks the existing _placed_furniture_nodes dict and
	# reconciles against profile.placed_furniture. Items present in the
	# profile but not the scene get spawned; items in the scene but not
	# the profile get freed; items in both get their transform updated.
	#
	# This stays cheap because the furniture count is small (handful) and
	# the dict ops are O(1).
	if profile == null:
		return
	# Free any nodes whose item_id no longer appears in the profile.
	var live_ids: Dictionary = {}
	for id in profile.placed_furniture_ids():
		live_ids[id] = true
	var stale: Array = []
	for existing_id in _placed_furniture_nodes:
		if not live_ids.has(existing_id):
			stale.append(existing_id)
	for id in stale:
		var node: Node = _placed_furniture_nodes[id]
		if node != null and is_instance_valid(node):
			node.queue_free()
		_placed_furniture_nodes.erase(id)
	# Spawn or update each placed item.
	for id in profile.placed_furniture_ids():
		var item: Item = ItemCatalog.get_item(id)
		if item == null:
			continue
		var pos: Vector3 = profile.furniture_position(id)
		var yaw: float = profile.furniture_rotation(id)
		if _placed_furniture_nodes.has(id):
			var existing: Node3D = _placed_furniture_nodes[id]
			existing.position = pos
			existing.rotation = Vector3(0.0, deg_to_rad(yaw), 0.0)
		else:
			var node: Node3D = _make_furniture_visual(item, pos, yaw)
			_placed_furniture_nodes[id] = node
			add_child(node)


func _make_furniture_visual(item: Item, pos: Vector3, yaw: float) -> Node3D:
	# Programmatic box per item, sized by anchor so wall items stay flat,
	# floor items are tall, desk items are small. Color comes from the
	# catalog. Future Phase 18+ replaces these with real mesh assets per
	# item id.
	var size: Vector3 = _visual_size_for_anchor(item.anchor)
	# Render through the existing PS1 material so the placed furniture
	# matches the mall's aesthetic out of the box.
	var node: StaticBody3D = _make_box("PlacedFurniture_" + item.id, Vector3.ZERO, size, item.color)
	node.position = pos
	node.rotation = Vector3(0.0, deg_to_rad(yaw), 0.0)
	# Group used by PlacementController to detect "this is already placed
	# furniture, don't snap to it" in future rotation/move support.
	node.add_to_group("placed_furniture")
	# v1.4.2 Phase 17.3 — functional behaviors attached as children of
	# the visual node. Each item id wires its own behavior:
	_attach_furniture_behavior(node, item)
	return node


func _attach_furniture_behavior(visual: StaticBody3D, item: Item) -> void:
	# Dispatch on item.id so the data layer (ItemCatalog entries) stays
	# behavior-agnostic. Adding a new behavior in 17.x is a single new
	# match arm here plus the catalog entry.
	match item.id:
		"coffee_maker":
			_make_coffee_maker_interactable(visual)
		"desk_lamp":
			_attach_lamp_light(visual)
		"jukebox":
			_attach_jukebox_audio(visual)
		_:
			# Posters and any other future cosmetic-only furniture have
			# no behavior — purely visual. No-op intentionally.
			pass


func _make_coffee_maker_interactable(visual: StaticBody3D) -> void:
	# Tag the visual itself as an interactable. GameController dispatches
	# on `coffee_maker_brew` to call Profile.brew_coffee.
	visual.add_to_group(Player.INTERACTION_GROUP)
	visual.set_meta("coffee_maker_brew", true)


func _attach_lamp_light(visual: StaticBody3D) -> void:
	# Small warm OmniLight3D centered above the lamp base. Energy is
	# constant for now; Phase 20 (day/night cycle) will modulate it so
	# the lamp visibly turns on at night. The light range is short
	# enough not to wash out the food court's existing mall lighting.
	var light: OmniLight3D = OmniLight3D.new()
	light.name = "LampLight"
	light.position = Vector3(0.0, 0.30, 0.0)
	light.light_color = Color(1.0, 0.92, 0.75)
	light.light_energy = 0.80
	light.omni_range = 3.5
	visual.add_child(light)


func _attach_jukebox_audio(visual: StaticBody3D) -> void:
	# Generate a procedural muzak loop and attach it as an
	# AudioStreamPlayer3D. Routed through the Music bus we wired in
	# v1.1.0, so the existing Music volume slider already controls it.
	# Distance attenuation via unit_size + max_distance limits hearing
	# range so the muzak doesn't carry across the entire mall.
	var player: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	player.name = "JukeboxPlayer"
	# Procedural track index chosen from the placed jukebox's position
	# hash so the same placement always plays the same loop, but
	# different placements (or a remove-and-replace) can sound different.
	var track_index: int = abs(hash(str(visual.position))) % JukeboxAudio.track_count()
	player.stream = JukeboxAudio.make_stream(track_index)
	player.bus = "Music"
	player.autoplay = true
	# Tuned so the muzak is audible inside the apartment zone (~4 m) but
	# fades to silence at corridor distance (~10 m).
	player.unit_size = 1.5
	player.max_distance = 12.0
	player.position = Vector3(0.0, 0.6, 0.0)
	visual.add_child(player)


static func _visual_size_for_anchor(anchor: String) -> Vector3:
	match anchor:
		Item.ANCHOR_WALL:
			# Posters: 60x80 cm, thin against the wall.
			return Vector3(0.60, 0.80, 0.04)
		Item.ANCHOR_DESK:
			# Small appliances/lamps: ~30x30 footprint, ~35cm tall.
			return Vector3(0.30, 0.35, 0.30)
		Item.ANCHOR_FLOOR:
			# Jukebox-ish: ~50x90x40.
			return Vector3(0.50, 0.90, 0.40)
		_:
			return Vector3(0.30, 0.30, 0.30)


func _build_sleep_cushion() -> void:
	# A purple cushion against the food court back wall. Interacting with it
	# advances Profile.current_day via GameController._start_sleep.
	var fc_z_back: float = CORRIDOR_LENGTH * 0.5 + FOOD_COURT_DEPTH
	var cushion_position: Vector3 = Vector3(0.0, 0.30, fc_z_back - 1.4)
	var cushion_size: Vector3 = Vector3(2.4, 0.60, 1.4)
	var cushion: StaticBody3D = _make_box("SleepCushion", cushion_position, cushion_size, Color(0.45, 0.30, 0.65))
	cushion.add_to_group(Player.INTERACTION_GROUP)
	cushion.set_meta("sleep_action", "advance_day")
	cushion.set_meta("sleep_label", "Sleep — advance to next day")
	add_child(cushion)

	# Hover label so the player can spot it.
	var label: Label3D = Label3D.new()
	label.text = "SLEEP"
	label.font_size = 140
	label.modulate = Color(1.0, 0.85, 1.0)
	label.outline_size = 8
	label.outline_modulate = Color.BLACK
	label.position = cushion_position + Vector3(0.0, 0.9, 0.0)
	label.pixel_size = 0.005
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	add_child(label)


func _build_food_court_tables() -> void:
	var fc_z_center: float = CORRIDOR_LENGTH * 0.5 + FOOD_COURT_DEPTH * 0.5
	# Tables sit toward the back half of the food court, leaving open space
	# near the corridor mouth for foot traffic.
	var table_row_center: Vector3 = Vector3(0.0, 0.0, fc_z_center + 2.0)
	# Phase 10.1: MINI/MIDI/FULL daily_puzzle tables.
	# Phase 16 (v1.3.0): COMMUNITY table added as a 4th interactable. The
	# row-position helper handles the extra entry transparently; food
	# court width has enough room (20m vs the 4-table span of ~13.5m).
	var labels: Array[String] = ["MINI", "MIDI", "FULL", "COMMUNITY"]
	var positions: Array[Vector3] = MallLayoutMath.food_court_table_positions(labels.size(), TABLE_SPACING, table_row_center)
	for i in range(positions.size()):
		var label: String = labels[i]
		if label == "COMMUNITY":
			_build_community_table(positions[i])
		else:
			_build_table("Table_" + label, positions[i], label, true)


func _build_community_table(table_position: Vector3) -> void:
	# Visually identical to the daily-puzzle tables but tagged with
	# community_puzzle metadata so GameController routes the interact to
	# the picker UI instead of CrosswordUI directly.
	var table_root: Node3D = Node3D.new()
	table_root.name = "Table_COMMUNITY"
	table_root.position = table_position
	add_child(table_root)

	var top_pos: Vector3 = Vector3(0.0, TABLE_TOP_HEIGHT, 0.0)
	# Distinct green tint so players can spot the community table at a glance.
	var community_color: Color = Color(0.35, 0.55, 0.42)
	var top: StaticBody3D = _make_box("Top", top_pos, TABLE_TOP_SIZE, community_color)
	top.add_to_group(Player.INTERACTION_GROUP)
	top.set_meta("community_puzzle", true)
	top.set_meta("woints_reward", WointsConfig.REWARD_COMMUNITY)
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
	hover_label.text = "COMMUNITY"
	hover_label.font_size = 130
	hover_label.modulate = Color(0.55, 0.95, 0.65)
	hover_label.outline_size = 8
	hover_label.outline_modulate = Color.BLACK
	hover_label.position = Vector3(0.0, TABLE_TOP_HEIGHT + 0.9, 0.0)
	hover_label.pixel_size = 0.005
	hover_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	hover_label.no_depth_test = true
	table_root.add_child(hover_label)


func _build_table(table_name: String, table_position: Vector3, label_text: String, daily_puzzle: bool = false) -> void:
	var table_root: Node3D = Node3D.new()
	table_root.name = table_name
	table_root.position = table_position
	add_child(table_root)

	var top_pos: Vector3 = Vector3(0.0, TABLE_TOP_HEIGHT, 0.0)
	var top: StaticBody3D = _make_box("Top", top_pos, TABLE_TOP_SIZE, TABLE_TOP_COLOR)
	if daily_puzzle:
		top.add_to_group(Player.INTERACTION_GROUP)
		top.set_meta("daily_puzzle", true)
		top.set_meta("difficulty", label_text.to_lower())
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
	hover_label.no_depth_test = true
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
	mesh.set_surface_override_material(0, _make_ps1_material(color))
	body.add_child(mesh)

	return body


func _make_ps1_material(color: Color) -> ShaderMaterial:
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = PS1_SHADER
	material.set_shader_parameter("albedo", Vector3(color.r, color.g, color.b))
	material.set_shader_parameter("vertex_snap", PS1_VERTEX_SNAP)
	return material
