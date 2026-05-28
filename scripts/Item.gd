class_name Item
extends RefCounted

# Pure data class describing a purchasable item. Catalog assembles these;
# Profile stores owned IDs only — never serializes the full Item.
#
# v1.4.0 (Phase 17.1) adds shop_id / category / anchor / color fields to
# support the apartment-customization furniture line. Existing perks
# (coffee, mall_cap) keep their behavior — they default to the original
# mall_general shop and to empty category/anchor (no placement needed).

const SLOT_COSMETIC: String = "cosmetic"
const SLOT_FUNCTIONAL: String = "functional"
const SLOT_FURNITURE: String = "furniture"

# Shop IDs. Story-shaped, not enforced — any string works. These constants
# just keep callers honest about what's wired up.
const SHOP_MALL_GENERAL: String = "mall_general"
const SHOP_HOME_GOODS: String = "home_goods"

# Furniture anchor types. Used by Phase 17.2 placement to decide where the
# ghost-preview can land. Empty string = non-placeable (perks, cosmetics).
const ANCHOR_NONE: String = ""
const ANCHOR_FLOOR: String = "floor"
const ANCHOR_WALL: String = "wall"
const ANCHOR_DESK: String = "desk"

var id: String = ""
var name: String = ""
var description: String = ""
var cost: int = 0
var slot: String = SLOT_FUNCTIONAL
var shop_id: String = SHOP_MALL_GENERAL
# Furniture-only; left empty for perks/cosmetics. Coarse grouping so a
# future "Furniture Catalog" tab could organize by Posters / Lighting /
# Appliances. Free-form string today.
var category: String = ""
# Placement anchor (Phase 17.2). Empty means the item isn't placeable.
var anchor: String = ANCHOR_NONE
# Display color used by both the shop preview and the placement ghost.
# Black is a fine non-furniture default (the ShopUI doesn't render it).
var color: Color = Color.BLACK


static func from_dict(payload: Dictionary) -> Item:
	var item: Item = Item.new()
	item.id = String(payload.get("id", ""))
	item.name = String(payload.get("name", ""))
	item.description = String(payload.get("description", ""))
	item.cost = max(0, int(payload.get("cost", 0)))
	var requested_slot: String = String(payload.get("slot", SLOT_FUNCTIONAL))
	if requested_slot == SLOT_COSMETIC or requested_slot == SLOT_FUNCTIONAL or requested_slot == SLOT_FURNITURE:
		item.slot = requested_slot
	else:
		item.slot = SLOT_FUNCTIONAL
	item.shop_id = String(payload.get("shop_id", SHOP_MALL_GENERAL))
	item.category = String(payload.get("category", ""))
	var requested_anchor: String = String(payload.get("anchor", ANCHOR_NONE))
	if requested_anchor == ANCHOR_FLOOR or requested_anchor == ANCHOR_WALL or requested_anchor == ANCHOR_DESK:
		item.anchor = requested_anchor
	else:
		item.anchor = ANCHOR_NONE
	# Color can come as a Color, an [r,g,b] array, or a #hex string. Defensive
	# parsing keeps the test fixtures readable without forcing every caller
	# into one shape.
	var raw_color: Variant = payload.get("color", null)
	if raw_color is Color:
		item.color = raw_color
	elif raw_color is Array and (raw_color as Array).size() >= 3:
		var arr: Array = raw_color
		item.color = Color(float(arr[0]), float(arr[1]), float(arr[2]))
	elif raw_color is String and String(raw_color) != "":
		item.color = Color(String(raw_color))
	return item


func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"description": description,
		"cost": cost,
		"slot": slot,
		"shop_id": shop_id,
		"category": category,
		"anchor": anchor,
		"color": [color.r, color.g, color.b],
	}


func is_placeable() -> bool:
	return anchor != ANCHOR_NONE
