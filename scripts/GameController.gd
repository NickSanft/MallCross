class_name GameController
extends Node3D

# Top-level orchestrator. Loads the Profile on startup, dispatches Player
# interaction signals to either the CrosswordUI (puzzle_id metadata), the
# ShopUI (shop_id metadata), or the day-advance sleep transition
# (sleep_action metadata), awards Woints + streak bonus on first puzzle
# solve, and saves the profile to disk after every meaningful change.

@onready var _player: Player = $MallGreybox/Player
@onready var _mall: MallGreybox = $MallGreybox
@onready var _hud: HUD = $HUD
@onready var _crossword_ui: CrosswordUI = $CrosswordUI
@onready var _shop_ui: ShopUI = $ShopUI
@onready var _settings_menu: SettingsMenu = $SettingsMenu

var _profile: Profile
var _settings: Dictionary
var _current_puzzle_id: String = ""
var _current_reward: int = 0
var _sleeping: bool = false


func _ready() -> void:
	_profile = ProfileStore.load_from_path()
	_settings = SettingsManager.load_from_path()
	_refresh_hud()
	_apply_settings(_settings)
	_player.interactable_changed.connect(_on_interactable_changed)
	_player.interaction_triggered.connect(_on_interaction_triggered)
	_crossword_ui.closed.connect(_on_crossword_closed)
	_crossword_ui.puzzle_solved.connect(_on_puzzle_solved)
	_shop_ui.closed.connect(_on_shop_closed)
	_hud.fade_to_black_done.connect(_on_fade_to_black_done)
	_settings_menu.settings_changed.connect(_on_settings_changed)
	_settings_menu.closed.connect(_on_settings_closed)
	_settings_menu.reset_save_requested.connect(_on_reset_save_requested)
	# MallGreybox.spawn_npcs() ran inside its own _ready before us. Rewrite
	# each NPC's dialog with today's puzzle hint where one exists.
	_mall.apply_npc_hints_for_day(_profile.current_day)


func _unhandled_input(event: InputEvent) -> void:
	# Esc opens the settings menu when no other modal is up. Modals catch
	# Esc themselves to close their own UI before this handler runs.
	if not event.is_action_pressed("ui_cancel"):
		return
	if _is_any_modal_open() or _sleeping:
		return
	_open_settings_menu()
	get_viewport().set_input_as_handled()


func _is_any_modal_open() -> bool:
	return _crossword_ui.visible or _shop_ui.visible or _settings_menu.visible


func _open_settings_menu() -> void:
	_settings_menu.open_menu(_settings)
	_player.set_paused_for_ui(true)
	_hud.hide_prompt()


func _on_settings_changed(updated: Dictionary) -> void:
	# Live apply — slider drag should immediately change mouse feel + volume.
	_settings = updated.duplicate(true)
	_apply_settings(_settings)


func _on_settings_closed() -> void:
	# Final snapshot from the menu in case any unsynced slider value lingers.
	_settings = _settings_menu.get_current_settings()
	_apply_settings(_settings)
	SettingsManager.save_to_path(_settings)
	_player.set_paused_for_ui(false)
	_player.refresh_interaction_target()


func _on_reset_save_requested() -> void:
	ProfileStore.delete_at_path()
	_profile = ProfileStore.load_from_path()  # fresh defaults
	_refresh_hud()
	_mall.apply_npc_hints_for_day(_profile.current_day)


func _apply_settings(settings: Dictionary) -> void:
	var clean: Dictionary = SettingsManager.normalize(settings)
	_player.set_mouse_sensitivity(float(clean[SettingsManager.KEY_MOUSE_SENSITIVITY]))
	_player.set_footstep_volume_db(float(clean[SettingsManager.KEY_FOOTSTEP_VOLUME_DB]))
	var master_bus: int = AudioServer.get_bus_index("Master")
	if master_bus >= 0:
		AudioServer.set_bus_volume_db(master_bus, float(clean[SettingsManager.KEY_MASTER_VOLUME_DB]))


func _refresh_hud() -> void:
	_hud.update_woints(_profile.woints)
	_hud.update_day(_profile.current_day)
	_hud.update_streak(_profile.streak)


func _on_interactable_changed(interactable: Node) -> void:
	if interactable == null:
		_hud.hide_prompt()
		return
	if interactable.has_meta("puzzle_id"):
		_hud.show_prompt("[E] " + interactable.get_meta("puzzle_label", "Crossword"))
	elif interactable.has_meta("daily_puzzle"):
		_show_daily_puzzle_prompt()
	elif interactable.has_meta("shop_id"):
		_hud.show_prompt("[E] " + interactable.get_meta("shop_label", "Shop"))
	elif interactable.has_meta("sleep_action"):
		_hud.show_prompt("[E] " + interactable.get_meta("sleep_label", "Sleep — advance to next day"))
	else:
		_hud.hide_prompt()


func _show_daily_puzzle_prompt() -> void:
	var day: int = _profile.current_day
	var puzzle_id: String = PuzzleSchedule.puzzle_id_for_day(day)
	if puzzle_id == "":
		var last_day: int = PuzzleSchedule.last_scheduled_day()
		if day > last_day:
			_hud.show_prompt("Week 1 complete — more puzzles in a future update")
		else:
			_hud.show_prompt("No puzzle today — sleep to advance the day")
	elif _profile.is_puzzle_solved(puzzle_id):
		_hud.show_prompt("[E] Day %d Crossword (already solved)" % day)
	else:
		_hud.show_prompt("[E] Solve Day %d Crossword" % day)


func _on_interaction_triggered(interactable: Node) -> void:
	if interactable == null or _sleeping:
		return
	if interactable.has_meta("puzzle_id"):
		_open_puzzle(interactable, interactable.get_meta("puzzle_id"))
	elif interactable.has_meta("daily_puzzle"):
		var puzzle_id: String = PuzzleSchedule.puzzle_id_for_day(_profile.current_day)
		if puzzle_id == "":
			# No puzzle scheduled for today — leave the prompt up, do nothing.
			return
		_open_puzzle(interactable, puzzle_id)
	elif interactable.has_meta("shop_id"):
		_open_shop(interactable)
	elif interactable.has_meta("sleep_action"):
		_start_sleep()


func _open_puzzle(interactable: Node, puzzle_id: String) -> void:
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


func _start_sleep() -> void:
	# Pause the player and fade to black. The fade_to_black_done signal
	# (fired at mid-fade) advances the day; the second half of the fade
	# reveals the new day's mall.
	_sleeping = true
	_player.set_paused_for_ui(true)
	_hud.hide_prompt()
	_hud.fade_to_black_and_back()


func _on_fade_to_black_done() -> void:
	if not _sleeping:
		return
	_profile.advance_day()
	ProfileStore.save_to_path(_profile)
	_refresh_hud()
	# New day = new puzzle = new NPC hints. Push them before unpausing so the
	# player sees the next puzzle's hints the moment they walk past an NPC.
	_mall.apply_npc_hints_for_day(_profile.current_day)
	# The fade-back will play; finish sleeping when it returns (next tick is fine).
	_sleeping = false
	_player.set_paused_for_ui(false)
	# Day changed — re-emit the prompt so a daily-puzzle table updates without
	# the player needing to walk off and back.
	_player.refresh_interaction_target()


func _on_crossword_closed() -> void:
	if _current_puzzle_id != "":
		var live_state: CrosswordState = _crossword_ui.get_current_state()
		if live_state != null:
			_profile.cache_state(_current_puzzle_id, live_state)
		ProfileStore.save_to_path(_profile)
		_current_puzzle_id = ""
		_current_reward = 0
	_player.set_paused_for_ui(false)
	# After solving, the table's prompt should switch to "(already solved)" —
	# refresh without making the player walk away and back.
	_player.refresh_interaction_target()


func _on_shop_closed() -> void:
	# Shop UI mutates _profile in place via try_purchase. Persist before
	# handing the player back to mall control.
	ProfileStore.save_to_path(_profile)
	_hud.update_woints(_profile.woints)
	_player.set_paused_for_ui(false)
	_player.refresh_interaction_target()


func _on_puzzle_solved() -> void:
	if _current_puzzle_id == "":
		return
	if not _profile.mark_puzzle_solved(_current_puzzle_id):
		return  # already solved before this session — no double award
	var bonus: int = WointsConfig.streak_bonus(_profile.streak)
	_profile.add_woints(_current_reward + bonus)
	ProfileStore.save_to_path(_profile)
	_refresh_hud()
