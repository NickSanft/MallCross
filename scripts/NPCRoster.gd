class_name NPCRoster
extends RefCounted

# Static list of NPCs placed in the mall. Phase 9 ships three with hardcoded
# flavor dialog. Phase 9.1 may load per-day hints from a data file so NPCs
# overhear hints tied to today's puzzle.


static func all_npcs() -> Array:
	return [
		{
			"id": "food_court_patron_a",
			"position": Vector3(0.0, 0.0, 33.0),
			"facing_y_degrees": 0.0,
			"dialog": "I always start with the down clues — they feel easier.",
			"body_color": Color(0.45, 0.55, 0.75),
			"head_color": Color(0.85, 0.70, 0.55),
		},
		{
			"id": "food_court_patron_b",
			"position": Vector3(4.5, 0.0, 33.0),
			"facing_y_degrees": 0.0,
			"dialog": "The food court has the best ambient light for puzzling.",
			"body_color": Color(0.60, 0.45, 0.50),
			"head_color": Color(0.70, 0.55, 0.45),
		},
		{
			"id": "corridor_shopper",
			"position": Vector3(-2.5, 0.0, -10.0),
			"facing_y_degrees": 90.0,
			"dialog": "That coffee from Store 1 is how I catch my typos.",
			"body_color": Color(0.40, 0.65, 0.50),
			"head_color": Color(0.75, 0.65, 0.50),
		},
	]


static func required_keys() -> Array:
	return ["id", "position", "facing_y_degrees", "dialog", "body_color", "head_color"]
