extends "res://addons/gut/test.gd"


func test_all_items_returns_at_least_two() -> void:
	assert_gte(ItemCatalog.all_items().size(), 2)


func test_all_items_contains_coffee() -> void:
	var ids: Array = []
	for item in ItemCatalog.all_items():
		ids.append(item.id)
	assert_has(ids, "coffee")


func test_all_items_contains_mall_cap() -> void:
	var ids: Array = []
	for item in ItemCatalog.all_items():
		ids.append(item.id)
	assert_has(ids, "mall_cap")


func test_get_item_by_id() -> void:
	var item: Item = ItemCatalog.get_item("coffee")
	assert_not_null(item)
	assert_eq(item.id, "coffee")
	assert_eq(item.slot, Item.SLOT_FUNCTIONAL)


func test_get_item_unknown_id_returns_null() -> void:
	assert_null(ItemCatalog.get_item("nope_does_not_exist"))


func test_get_item_empty_id_returns_null() -> void:
	assert_null(ItemCatalog.get_item(""))


func test_has_item_true_for_known() -> void:
	assert_true(ItemCatalog.has_item("coffee"))


func test_has_item_false_for_unknown() -> void:
	assert_false(ItemCatalog.has_item("xyz"))


func test_mall_cap_is_cosmetic() -> void:
	var hat: Item = ItemCatalog.get_item("mall_cap")
	assert_eq(hat.slot, Item.SLOT_COSMETIC)


func test_coffee_costs_positive_amount() -> void:
	var coffee: Item = ItemCatalog.get_item("coffee")
	assert_gt(coffee.cost, 0)
