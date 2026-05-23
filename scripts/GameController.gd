class_name GameController
extends Node3D

# Top-level orchestrator. Loads the Profile on startup, dispatches Player
# interaction signals to either the CrosswordUI (puzzle_id metadata) or
# ShopUI (shop_id metadata), awards Woints on first puzzle solve, and
# saves the profile to disk after every meaningful change.

@onready var _player: Player = $MallGreybox/Player
@onready var _hud: HUD = $HUD
@onready var _crossword_ui: CrosswordUI = $CrosswordUI
@onready var _shop_ui: ShopUI = $ShopUI

var _profile: Profile
var _current_puzzle_id: String = ""
var _current_reward: int = 0


func _ready() -> void:
	_profile = ProfileStore.load_from_path()
	_hud.update_woints(_profile.woints)
	_hud.update_day(_profile.current_day)
	_player.interactable_changed.connect(_on_interactable_changed)
	_player.interaction_triggered.connect(_on_interaction_triggered)
	_crossword_ui.closed.connect(_on_crossword_closed)
	_crossword_ui.puzzle_solved.connect(_on_puzzle_solved)
	_shop_ui.closed.connect(_on_shop_closed)


func _on_interactable_changed(interactable: Node) -> void:
	if interactable == null:
		_hud.hide_prompt()
		return
	if interactable.has_meta("puzzle_id"):
		_hud.show_prompt("[E] " + interactable.get_meta("puzzle_label", "Crossword"))
	elif interactable.has_meta("shop_id"):
		_hud.show_prompt("[E] " + interactable.get_meta("shop_label", "Shop"))
	else:
		_hud.hide_prompt()


func _on_interaction_triggered(interactable: Node) -> void:
	if interactable == null:
		return
	if interactable.has_meta("puzzle_id"):
		_open_puzzle(interactable)
	elif interactable.has_meta("shop_id"):
		_open_shop(interactable)


func _open_puzzle(interactable: Node) -> void:
	var puzzle_id: String = interactable.get_meta("puzzle_id")
	var puzzle: Dictionary = PuzzleLoader.load_by_id(puzzle_id)
	var loaded_grid: CrosswordGrid = puzzle.get("grid", CrosswordGrid.new())
	if loaded_grid.size <= 0:
		push_warning("Puzzle id '%s' could not be loaded." % puzzle_id)
		return

	var reward_remaining: int = 0
	if not _profile.is_puzzle_solved(puzzle_id):
		reward_remaining = int(interactable.get_meta("woints_reward", WointsConfig.REWARD_DEFAULT))

	_current_puzzle_id = puzzle_id
	_current_reward = reward_remaining
	var cached_state: CrosswordState = _profile.get_cached_state(puzzle_id)
	_crossword_ui.open_puzzle(puzzle, cached_state, reward_remaining, _profile.is_puzzle_solved(puzzle_id), _profile)
	_player.set_paused_for_ui(true)
	_hud.hide_prompt()


func _open_shop(interactable: Node) -> void:
	var shop_label: String = interactable.get_meta("shop_label", "Mall Shop")
	_shop_ui.open_shop(_profile, shop_label)
	_player.set_paused_for_ui(true)
	_hud.hide_prompt()


func _on_crossword_closed() -> void:
	if _current_puzzle_id != "":
		var live_state: CrosswordState = _crossword_ui.get_current_state()
		if live_state != null:
			_profile.cache_state(_current_puzzle_id, live_state)
		ProfileStore.save_to_path(_profile)
		_current_puzzle_id = ""
		_current_reward = 0
	_player.set_paused_for_ui(false)


func _on_shop_closed() -> void:
	# Shop UI mutates _profile in place via try_purchase. Persist before
	# handing the player back to mall control.
	ProfileStore.save_to_path(_profile)
	_hud.update_woints(_profile.woints)
	_player.set_paused_for_ui(false)


func _on_puzzle_solved() -> void:
	if _current_puzzle_id == "":
		return
	if not _profile.mark_puzzle_solved(_current_puzzle_id):
		return  # already solved before this session — no double award
	_profile.add_woints(_current_reward)
	_hud.update_woints(_profile.woints)
	ProfileStore.save_to_path(_profile)
