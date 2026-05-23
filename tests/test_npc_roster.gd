extends "res://addons/gut/test.gd"


func test_roster_has_at_least_three_npcs() -> void:
	assert_gte(NPCRoster.all_npcs().size(), 3)


func test_each_npc_has_required_keys() -> void:
	for npc in NPCRoster.all_npcs():
		for key in NPCRoster.required_keys():
			assert_true(npc.has(key), "NPC %s missing required key: %s" % [npc.get("id", "?"), key])


func test_npc_ids_are_unique() -> void:
	var seen: Dictionary = {}
	for npc in NPCRoster.all_npcs():
		var id: String = String(npc["id"])
		assert_false(seen.has(id), "Duplicate NPC id: %s" % id)
		seen[id] = true


func test_npc_ids_are_non_empty() -> void:
	for npc in NPCRoster.all_npcs():
		assert_ne(String(npc["id"]), "")


func test_npc_dialogs_are_non_empty() -> void:
	for npc in NPCRoster.all_npcs():
		assert_ne(String(npc["dialog"]), "")


func test_npc_positions_are_inside_mall_bounds() -> void:
	# Mall extents in MallGreybox:
	#   corridor x ∈ [-4, +4], food court x ∈ [-10, +10]
	#   corridor z ∈ [-20, +20], food court z ∈ [+20, +38]
	# Loosely: x ∈ [-15, +15], z ∈ [-25, +40] covers everything.
	for npc in NPCRoster.all_npcs():
		var pos: Vector3 = npc["position"]
		assert_lte(pos.x, 15.0, "%s x too far east" % npc["id"])
		assert_gte(pos.x, -15.0, "%s x too far west" % npc["id"])
		assert_lte(pos.z, 40.0, "%s z past food court back wall" % npc["id"])
		assert_gte(pos.z, -25.0, "%s z past entrance" % npc["id"])


func test_npc_positions_at_floor_height() -> void:
	# NPCs should be grounded — y near 0. Bodies handle the lift internally.
	for npc in NPCRoster.all_npcs():
		var pos: Vector3 = npc["position"]
		assert_almost_eq(pos.y, 0.0, 0.5, "%s should be on the floor" % npc["id"])


func test_facing_is_normalized() -> void:
	for npc in NPCRoster.all_npcs():
		var deg: float = float(npc["facing_y_degrees"])
		assert_gte(deg, -360.0)
		assert_lte(deg, 360.0)


func test_colors_are_valid_color_values() -> void:
	# Colors should be Color objects with values in [0, 1].
	for npc in NPCRoster.all_npcs():
		var body: Color = npc["body_color"]
		var head: Color = npc["head_color"]
		assert_between(body.r, 0.0, 1.0)
		assert_between(body.g, 0.0, 1.0)
		assert_between(body.b, 0.0, 1.0)
		assert_between(head.r, 0.0, 1.0)
		assert_between(head.g, 0.0, 1.0)
		assert_between(head.b, 0.0, 1.0)


func test_required_keys_list_includes_dialog_and_id() -> void:
	var keys: Array = NPCRoster.required_keys()
	assert_has(keys, "id")
	assert_has(keys, "dialog")
	assert_has(keys, "position")
