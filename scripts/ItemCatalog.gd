class_name ItemCatalog
extends RefCounted

# Static registry of all purchasable items across every shop in the mall.
# Each Item carries a `shop_id` field; ShopUI calls `items_for_shop(...)`
# at open time to filter the display.
#
# Phase 6 launched with two perks (mall_general). Phase 17.1 (v1.4.0)
# adds the home_goods catalog (posters, lamp, jukebox, coffee maker)
# whose behaviors land in 17.2 (placement) and 17.3 (active effects).


static func all_items() -> Array:
	# Constructed fresh each call (Items are lightweight RefCounted). Order
	# here is the display order in each shop. Items in the same shop sit
	# together — keep that property when adding new entries.
	return [
		# --- mall_general (perks) ----------------------------------------
		Item.from_dict({
			"id": "coffee",
			"name": "Coffee",
			"description": "Press C in a crossword to flash incorrect letters in the current word.",
			"cost": 40,
			"slot": Item.SLOT_FUNCTIONAL,
			"shop_id": Item.SHOP_MALL_GENERAL,
		}),
		Item.from_dict({
			"id": "mall_cap",
			"name": "Mall Cap",
			"description": "A jaunty mall-branded cap. Cosmetic — visible on the player in a future art pass.",
			"cost": 100,
			"slot": Item.SLOT_COSMETIC,
			"shop_id": Item.SHOP_MALL_GENERAL,
		}),
		# --- home_goods (apartment furniture) ----------------------------
		# 17.1 ships the data layer; placement is 17.2, functional behaviors
		# are 17.3. Until then, buying an item just records it in
		# Profile.owned_items; nothing visible happens in the apartment yet.
		Item.from_dict({
			"id": "poster_geometric",
			"name": "Geometric Poster",
			"description": "Cyan-and-magenta op-art print for the apartment wall.",
			"cost": 50,
			"slot": Item.SLOT_FURNITURE,
			"shop_id": Item.SHOP_HOME_GOODS,
			"category": "poster",
			"anchor": Item.ANCHOR_WALL,
			"color": [0.20, 0.85, 0.95],
		}),
		Item.from_dict({
			"id": "poster_landscape",
			"name": "Mountain Landscape Poster",
			"description": "Stylized peaks in dusk gradients. Looks great over the bed.",
			"cost": 50,
			"slot": Item.SLOT_FURNITURE,
			"shop_id": Item.SHOP_HOME_GOODS,
			"category": "poster",
			"anchor": Item.ANCHOR_WALL,
			"color": [0.65, 0.45, 0.70],
		}),
		Item.from_dict({
			"id": "poster_movie",
			"name": "B-Movie Poster",
			"description": "Garish red-and-yellow ad for a film no one remembers.",
			"cost": 50,
			"slot": Item.SLOT_FURNITURE,
			"shop_id": Item.SHOP_HOME_GOODS,
			"category": "poster",
			"anchor": Item.ANCHOR_WALL,
			"color": [0.90, 0.30, 0.20],
		}),
		Item.from_dict({
			"id": "poster_band",
			"name": "Band Tour Poster",
			"description": "A fictional indie band's 1998 west-coast tour dates.",
			"cost": 50,
			"slot": Item.SLOT_FURNITURE,
			"shop_id": Item.SHOP_HOME_GOODS,
			"category": "poster",
			"anchor": Item.ANCHOR_WALL,
			"color": [0.30, 0.30, 0.35],
		}),
		Item.from_dict({
			"id": "poster_cat",
			"name": "Hang In There Cat",
			"description": "A small orange kitten clinging to a bough. Motivational.",
			"cost": 50,
			"slot": Item.SLOT_FURNITURE,
			"shop_id": Item.SHOP_HOME_GOODS,
			"category": "poster",
			"anchor": Item.ANCHOR_WALL,
			"color": [0.95, 0.75, 0.55],
		}),
		Item.from_dict({
			"id": "poster_abstract",
			"name": "Abstract Poster",
			"description": "Bright primary shapes on a black background. Very late-80s.",
			"cost": 50,
			"slot": Item.SLOT_FURNITURE,
			"shop_id": Item.SHOP_HOME_GOODS,
			"category": "poster",
			"anchor": Item.ANCHOR_WALL,
			"color": [0.95, 0.90, 0.25],
		}),
		Item.from_dict({
			"id": "desk_lamp",
			"name": "Desk Lamp",
			"description": "Articulated lamp for the desk. Lights up at night (when the day/night cycle ships).",
			"cost": 80,
			"slot": Item.SLOT_FURNITURE,
			"shop_id": Item.SHOP_HOME_GOODS,
			"category": "lighting",
			"anchor": Item.ANCHOR_DESK,
			"color": [0.85, 0.78, 0.40],
		}),
		Item.from_dict({
			"id": "coffee_maker",
			"name": "Coffee Maker",
			"description": "Brews a cup once per in-game day for a +20%% bonus on your next solve.",
			"cost": 150,
			"slot": Item.SLOT_FURNITURE,
			"shop_id": Item.SHOP_HOME_GOODS,
			"category": "appliance",
			"anchor": Item.ANCHOR_DESK,
			"color": [0.25, 0.20, 0.30],
		}),
		Item.from_dict({
			"id": "jukebox",
			"name": "Mini Jukebox",
			"description": "Plays one of three procedural muzak loops while you're in the apartment.",
			"cost": 200,
			"slot": Item.SLOT_FURNITURE,
			"shop_id": Item.SHOP_HOME_GOODS,
			"category": "appliance",
			"anchor": Item.ANCHOR_FLOOR,
			"color": [0.65, 0.20, 0.45],
		}),
	]


static func items_for_shop(shop_id: String) -> Array:
	# Filter the full catalog by shop. Constant-time-ish: linear over the
	# small (<20) catalog. Returns a fresh array.
	var out: Array = []
	for item in all_items():
		if item.shop_id == shop_id:
			out.append(item)
	return out


static func get_item(item_id: String) -> Item:
	if item_id == "":
		return null
	for item in all_items():
		if item.id == item_id:
			return item
	return null


static func has_item(item_id: String) -> bool:
	return get_item(item_id) != null
