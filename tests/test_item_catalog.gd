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


# ----- v1.4.0 home_goods catalog + shop filtering -----------------------

func test_items_for_mall_general_includes_existing_perks() -> void:
	# Regression: the new shop_id filter must not drop the v1.0.x perks.
	var ids: Array = []
	for item in ItemCatalog.items_for_shop(Item.SHOP_MALL_GENERAL):
		ids.append(item.id)
	assert_has(ids, "coffee")
	assert_has(ids, "mall_cap")


func test_items_for_home_goods_excludes_perks() -> void:
	# Furniture is in its own shop; perks must NOT leak through.
	var ids: Array = []
	for item in ItemCatalog.items_for_shop(Item.SHOP_HOME_GOODS):
		ids.append(item.id)
	assert_does_not_have(ids, "coffee")
	assert_does_not_have(ids, "mall_cap")


func test_items_for_home_goods_has_at_least_one_poster() -> void:
	var has_poster: bool = false
	for item in ItemCatalog.items_for_shop(Item.SHOP_HOME_GOODS):
		if item.category == "poster":
			has_poster = true
			break
	assert_true(has_poster, "home_goods catalog should include at least one poster")


func test_all_home_goods_items_have_furniture_slot() -> void:
	for item in ItemCatalog.items_for_shop(Item.SHOP_HOME_GOODS):
		assert_eq(item.slot, Item.SLOT_FURNITURE, "Item %s should be SLOT_FURNITURE" % item.id)


func test_all_home_goods_items_are_placeable() -> void:
	# Anchor must be set so Phase 17.2's placement UI knows what surface
	# each item drops onto. A non-placeable furniture entry would silently
	# break placement; catch it here.
	for item in ItemCatalog.items_for_shop(Item.SHOP_HOME_GOODS):
		assert_true(item.is_placeable(), "Item %s should have a placement anchor" % item.id)


func test_items_for_unknown_shop_returns_empty() -> void:
	# Defensive: an interactable mis-tagged with a nonexistent shop_id
	# should yield an empty ShopUI rather than crash.
	assert_eq(ItemCatalog.items_for_shop("nonexistent_shop"), [])


func test_home_goods_costs_positive() -> void:
	for item in ItemCatalog.items_for_shop(Item.SHOP_HOME_GOODS):
		assert_gt(item.cost, 0, "Item %s should cost > 0 Woints" % item.id)


func test_home_goods_ids_are_distinct() -> void:
	var seen: Dictionary = {}
	for item in ItemCatalog.items_for_shop(Item.SHOP_HOME_GOODS):
		assert_false(seen.has(item.id), "Duplicate id %s in home_goods catalog" % item.id)
		seen[item.id] = true


# ----- v1.6.0 Music Store + Arcade (upstairs shops) ---------------------

func test_music_store_has_at_least_one_track() -> void:
	# Music Store sells track packs. Empty catalog means the upstairs
	# shop facade would render a "(No items in this shop yet.)" stub,
	# which is the wrong story shape for v1.6.0.
	assert_gt(ItemCatalog.items_for_shop(Item.SHOP_MUSIC_STORE).size(), 0)


func test_music_store_excludes_furniture() -> void:
	# Track packs are SLOT_FUNCTIONAL, not SLOT_FURNITURE. Catch a
	# regression where a future commit accidentally tags a home_goods
	# item with the music shop id.
	for item in ItemCatalog.items_for_shop(Item.SHOP_MUSIC_STORE):
		assert_ne(item.slot, Item.SLOT_FURNITURE, "Music store item %s should not be furniture" % item.id)


func test_arcade_sells_token_items() -> void:
	# Loose check: arcade catalog should contain at least one item with
	# 'token' in its id. Locks in the "token sink" story.
	var has_token: bool = false
	for item in ItemCatalog.items_for_shop(Item.SHOP_ARCADE):
		if item.id.contains("token"):
			has_token = true
			break
	assert_true(has_token, "Arcade catalog should have at least one token item")


func test_upstairs_shop_costs_positive() -> void:
	# Same guarantee as the home_goods test — no free items.
	for shop in [Item.SHOP_MUSIC_STORE, Item.SHOP_ARCADE]:
		for item in ItemCatalog.items_for_shop(shop):
			assert_gt(item.cost, 0, "Item %s should cost > 0 Woints" % item.id)


func test_upstairs_shop_ids_are_distinct_within_each_shop() -> void:
	for shop in [Item.SHOP_MUSIC_STORE, Item.SHOP_ARCADE]:
		var seen: Dictionary = {}
		for item in ItemCatalog.items_for_shop(shop):
			assert_false(seen.has(item.id), "Duplicate id %s in %s catalog" % [item.id, shop])
			seen[item.id] = true


func test_all_four_shops_cataloged() -> void:
	# Single test that pins the full set of wired shops. If a future
	# patch adds a new shop, this test will need updating — that's the
	# point (forces the matching CHANGELOG entry).
	var expected: Array = [Item.SHOP_MALL_GENERAL, Item.SHOP_HOME_GOODS, Item.SHOP_MUSIC_STORE, Item.SHOP_ARCADE]
	for shop in expected:
		assert_gt(ItemCatalog.items_for_shop(shop).size(), 0, "Shop %s should have at least one item" % shop)


func test_no_item_belongs_to_multiple_shops() -> void:
	# Each Item carries exactly one shop_id field; this test asserts
	# the catalog respects that. Effectively a sanity check that we
	# didn't accidentally duplicate a single item across two shops.
	var item_to_shop: Dictionary = {}
	for shop in [Item.SHOP_MALL_GENERAL, Item.SHOP_HOME_GOODS, Item.SHOP_MUSIC_STORE, Item.SHOP_ARCADE]:
		for item in ItemCatalog.items_for_shop(shop):
			assert_false(item_to_shop.has(item.id), "Item %s appears in multiple shops" % item.id)
			item_to_shop[item.id] = shop
