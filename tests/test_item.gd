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
