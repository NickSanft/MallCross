class_name GameController
extends Node3D

# Top-level orchestrator. Listens to the Player's interaction signals,
# drives the HUD prompt, opens the CrosswordUI when an interactable is
# triggered, and pauses player input while the modal is up.
#
# Holds an in-memory cache of solve states keyed by puzzle_id so that
# closing + re-opening the same puzzle preserves the player's entries.
# Disk persistence (survives game restart) is Phase 5's job.

@onready var _player: Player = $MallGreybox/Player
@onready var _hud: HUD = $HUD
@onready var _crossword_ui: CrosswordUI = $CrosswordUI

var _puzzle_states: Dictionary = {}  # puzzle_id (String) -> CrosswordState
var _solved_puzzles: Dictionary = {}  # puzzle_id (String) -> bool — for Phase 5 dedup
var _current_puzzle_id: String = ""


func _ready() -> void:
	_player.interactable_changed.connect(_on_interactable_changed)
	_player.interaction_triggered.connect(_on_interaction_triggered)
	_crossword_ui.closed.connect(_on_ui_closed)
	_crossword_ui.puzzle_solved.connect(_on_puzzle_solved)


func _on_interactable_changed(interactable: Node) -> void:
	if interactable == null:
		_hud.hide_prompt()
		return
	if not interactable.has_meta("puzzle_id"):
		_hud.hide_prompt()
		return
	var label: String = interactable.get_meta("puzzle_label", "Crossword")
	_hud.show_prompt("[E] " + label)


func _on_interaction_triggered(interactable: Node) -> void:
	if interactable == null:
		return
	if not interactable.has_meta("puzzle_id"):
		return
	var puzzle_id: String = interactable.get_meta("puzzle_id")
	var puzzle: Dictionary = PuzzleLoader.load_by_id(puzzle_id)
	var loaded_grid: CrosswordGrid = puzzle.get("grid", CrosswordGrid.new())
	if loaded_grid.size <= 0:
		push_warning("Puzzle id '%s' could not be loaded." % puzzle_id)
		return
	var cached_state: CrosswordState = _puzzle_states.get(puzzle_id, null)
	_current_puzzle_id = puzzle_id
	_crossword_ui.open_puzzle(puzzle, cached_state)
	_player.set_paused_for_ui(true)
	_hud.hide_prompt()


func _on_ui_closed() -> void:
	if _current_puzzle_id != "":
		var live_state: CrosswordState = _crossword_ui.get_current_state()
		if live_state != null:
			_puzzle_states[_current_puzzle_id] = live_state
		_current_puzzle_id = ""
	_player.set_paused_for_ui(false)


func _on_puzzle_solved() -> void:
	# Phase 5 will award Woints + advance the day here. The _solved_puzzles
	# dict already gates repeat-awards per puzzle_id within a game session.
	if _current_puzzle_id == "":
		return
	if _solved_puzzles.get(_current_puzzle_id, false):
		return
	_solved_puzzles[_current_puzzle_id] = true
	print("[GameController] Puzzle '%s' solved." % _current_puzzle_id)
