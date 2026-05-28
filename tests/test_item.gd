extends "res://addons/gut/test.gd"


func test_from_dict_full_payload() -> void:
	var item: Item = Item.from_dict({
		"id": "x",
		"name": "X",
		"description": "desc",
		"cost": 42,
		"slot": Item.SLOT_FUNCTIONAL,
	})
	assert_eq(item.id, "x")
	assert_eq(item.name, "X")
	assert_eq(item.description, "desc")
	assert_eq(item.cost, 42)
	assert_eq(item.slot, Item.SLOT_FUNCTIONAL)


func test_from_dict_defaults_for_missing_fields() -> void:
	var item: Item = Item.from_dict({})
	assert_eq(item.id, "")
	assert_eq(item.cost, 0)
	assert_eq(item.slot, Item.SLOT_FUNCTIONAL)


func test_from_dict_clamps_negative_cost() -> void:
	var item: Item = Item.from_dict({"cost": -10})
	assert_eq(item.cost, 0)


func test_from_dict_unknown_slot_falls_back_to_functional() -> void:
	var item: Item = Item.from_dict({"slot": "weird"})
	assert_eq(item.slot, Item.SLOT_FUNCTIONAL)


func test_from_dict_cosmetic_slot_preserved() -> void:
	var item: Item = Item.from_dict({"slot": Item.SLOT_COSMETIC})
	assert_eq(item.slot, Item.SLOT_COSMETIC)


func test_to_dict_round_trip() -> void:
	var original: Item = Item.from_dict({
		"id": "hat",
		"name": "Hat",
		"description": "A hat.",
		"cost": 100,
		"slot": Item.SLOT_COSMETIC,
	})
	var restored: Item = Item.from_dict(original.to_dict())
	assert_eq(restored.id, "hat")
	assert_eq(restored.name, "Hat")
	assert_eq(restored.cost, 100)
	assert_eq(restored.slot, Item.SLOT_COSMETIC)


func test_slot_constants_distinct() -> void:
	assert_ne(Item.SLOT_COSMETIC, Item.SLOT_FUNCTIONAL)
	assert_ne(Item.SLOT_COSMETIC, Item.SLOT_FURNITURE)
	assert_ne(Item.SLOT_FUNCTIONAL, Item.SLOT_FURNITURE)


# ----- v1.4.0 fields: shop_id / category / anchor / color ---------------

func test_default_shop_id_is_mall_general() -> void:
	# Existing perks created without an explicit shop_id default to
	# mall_general so the Store 1 wiring keeps working.
	var item: Item = Item.from_dict({"id": "x"})
	assert_eq(item.shop_id, Item.SHOP_MALL_GENERAL)


func test_explicit_shop_id_preserved() -> void:
	var item: Item = Item.from_dict({"id": "x", "shop_id": Item.SHOP_HOME_GOODS})
	assert_eq(item.shop_id, Item.SHOP_HOME_GOODS)


func test_furniture_slot_round_trips() -> void:
	var item: Item = Item.from_dict({"slot": Item.SLOT_FURNITURE})
	assert_eq(item.slot, Item.SLOT_FURNITURE)


func test_anchor_floor_wall_desk_all_preserved() -> void:
	for anchor in [Item.ANCHOR_FLOOR, Item.ANCHOR_WALL, Item.ANCHOR_DESK]:
		var item: Item = Item.from_dict({"anchor": anchor})
		assert_eq(item.anchor, anchor)


func test_unknown_anchor_falls_back_to_none() -> void:
	var item: Item = Item.from_dict({"anchor": "ceiling"})  # not a valid anchor
	assert_eq(item.anchor, Item.ANCHOR_NONE)


func test_default_anchor_is_none() -> void:
	# Perks and cosmetics aren't placeable; default anchor is empty.
	var item: Item = Item.from_dict({"id": "coffee"})
	assert_eq(item.anchor, Item.ANCHOR_NONE)
	assert_false(item.is_placeable())


func test_is_placeable_true_when_anchor_set() -> void:
	var item: Item = Item.from_dict({"anchor": Item.ANCHOR_WALL})
	assert_true(item.is_placeable())


func test_color_from_rgb_array() -> void:
	var item: Item = Item.from_dict({"color": [0.5, 0.25, 0.75]})
	assert_eq(item.color.r, 0.5)
	assert_eq(item.color.g, 0.25)
	assert_eq(item.color.b, 0.75)


func test_color_from_hex_string() -> void:
	var item: Item = Item.from_dict({"color": "#ff0000"})
	assert_eq(item.color, Color.RED)


func test_category_preserved() -> void:
	var item: Item = Item.from_dict({"category": "poster"})
	assert_eq(item.category, "poster")


func test_extended_round_trip_via_to_dict() -> void:
	var original: Item = Item.from_dict({
		"id": "poster_geometric",
		"name": "Geometric Poster",
		"cost": 50,
		"slot": Item.SLOT_FURNITURE,
		"shop_id": Item.SHOP_HOME_GOODS,
		"category": "poster",
		"anchor": Item.ANCHOR_WALL,
		"color": [0.20, 0.85, 0.95],
	})
	var restored: Item = Item.from_dict(original.to_dict())
	assert_eq(restored.shop_id, Item.SHOP_HOME_GOODS)
	assert_eq(restored.category, "poster")
	assert_eq(restored.anchor, Item.ANCHOR_WALL)
	assert_eq(restored.slot, Item.SLOT_FURNITURE)
	# Float roundtrip via Array<float>; tolerate tiny epsilon.
	assert_almost_eq(restored.color.r, 0.20, 0.001)
	assert_almost_eq(restored.color.g, 0.85, 0.001)
	assert_almost_eq(restored.color.b, 0.95, 0.001)
