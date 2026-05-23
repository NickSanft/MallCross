class_name ItemCatalog
extends RefCounted

# Static registry of all purchasable items. Phase 6 hardcodes the list;
# Phase 7+ may load from JSON so puzzle packs can ship themed items
# (different cap colors, novelty items, etc.) without code changes.


static func all_items() -> Array:
	# Constructed fresh each call (Items are lightweight RefCounted). Order
	# here is the display order in ShopUI.
	return [
		Item.from_dict({
			"id": "coffee",
			"name": "Coffee",
			"description": "Press C in a crossword to flash incorrect letters in the current word.",
			"cost": 40,
			"slot": Item.SLOT_FUNCTIONAL,
		}),
		Item.from_dict({
			"id": "mall_cap",
			"name": "Mall Cap",
			"description": "A jaunty mall-branded cap. Cosmetic — visible on the player in a future art pass.",
			"cost": 100,
			"slot": Item.SLOT_COSMETIC,
		}),
	]


static func get_item(item_id: String) -> Item:
	if item_id == "":
		return null
	for item in all_items():
		if item.id == item_id:
			return item
	return null


static func has_item(item_id: String) -> bool:
	return get_item(item_id) != null
