class_name Item
extends RefCounted

# Pure data class describing a purchasable item. Catalog assembles these;
# Profile stores owned IDs only — never serializes the full Item.

const SLOT_COSMETIC: String = "cosmetic"
const SLOT_FUNCTIONAL: String = "functional"

var id: String = ""
var name: String = ""
var description: String = ""
var cost: int = 0
var slot: String = SLOT_FUNCTIONAL


static func from_dict(payload: Dictionary) -> Item:
	var item: Item = Item.new()
	item.id = String(payload.get("id", ""))
	item.name = String(payload.get("name", ""))
	item.description = String(payload.get("description", ""))
	item.cost = max(0, int(payload.get("cost", 0)))
	var requested_slot: String = String(payload.get("slot", SLOT_FUNCTIONAL))
	item.slot = requested_slot if requested_slot == SLOT_COSMETIC or requested_slot == SLOT_FUNCTIONAL else SLOT_FUNCTIONAL
	return item


func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"description": description,
		"cost": cost,
		"slot": slot,
	}
