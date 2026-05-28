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
# Cached target for re-rendering the daily-puzzle prompt out-of-band (e.g.
# after a sleep transition refreshes the day-of-week).
var _last_seen_interactable: Node = null
# Achievement plumbing introduced in v1.2.0. Service holds the unlock state
# in memory; the toast queues popups; the menu lists everything. Both UIs
# are spawned dynamically (rather than instanced from .tscn) so the
# Main.tscn diff stays small and the lifecycle stays in this file.
var _achievements: AchievementService
var _achievements_toast: AchievementToast
var _achievements_menu: AchievementsMenu
# Snapshot of owned_items taken on shop open. Used in _on_shop_closed to
# diff against the post-close state — anything new is a fresh purchase
# that needs notify_item_purchased.
var _owned_items_before_shop: Array = []
# v1.3.0 Phase 16: modal picker for user://puzzles/. Spawned dynamically
# like the achievement UIs. The currently-selected community puzzle's
# parsed-dict + reward are cached here so _open_community_puzzle can hand
# them straight to CrosswordUI without re-reading the file.
var _community_picker: CommunityPuzzlePicker
var _pending_community_result: Dictionary = {}


func _ready() -> void:
	_profile = ProfileStore.load_from_path()
	_settings = SettingsManager.load_from_path()
	_setup_achievements()
	_setup_community_picker()
	_refresh_hud()
	_apply_settings(_settings)
	_player.interactable_changed.connect(_on_interactable_changed)
	_player.interaction_triggered.connect(_on_interaction_triggered)
	_crossword_ui.closed.connect(_on_crossword_closed)
	# puzzle_solved carries (elapsed_ms, used_check_letter) since v1.2.0 so
	# we can record per-puzzle bests AND gate the no_checks achievement.
	_crossword_ui.puzzle_solved.connect(_on_puzzle_solved)
	_shop_ui.closed.connect(_on_shop_closed)
	_hud.fade_to_black_done.connect(_on_fade_to_black_done)
	_settings_menu.settings_changed.connect(_on_settings_changed)
	_settings_menu.closed.connect(_on_settings_closed)
	_settings_menu.reset_save_requested.connect(_on_reset_save_requested)
	_settings_menu.achievements_requested.connect(_on_achievements_requested)
	# MallGreybox.spawn_npcs() ran inside its own _ready before us. Rewrite
	# each NPC's dialog with today's puzzle hint where one exists.
	_mall.apply_npc_hints_for_day(_profile.current_day)
	# Check the "hoarder" threshold once at startup so a player who already
	# has 1000+ Woints in their save gets the unlock the moment they boot,
	# not the next time they earn one Woint.
	var fired: Array = _achievements.notify_woints(_profile.woints, _profile.current_day)
	_push_unlocks(fired)


func _setup_achievements() -> void:
	var catalog: Array = AchievementCatalog.load_all()
	var saved_unlocks: Dictionary = AchievementStore.load_from_path()
	_achievements = AchievementService.new(catalog, saved_unlocks)

	_achievements_menu = AchievementsMenu.new()
	_achievements_menu.name = "AchievementsMenu"
	_achievements_menu.anchor_right = 1.0
	_achievements_menu.anchor_bottom = 1.0
	_achievements_menu.closed.connect(_on_achievements_menu_closed)
	add_child(_achievements_menu)

	_achievements_toast = AchievementToast.new()
	_achievements_toast.name = "AchievementsToast"
	# Toast is added last so it z-orders above the menu/HUD when both are
	# visible (rare, but the order is the cheap insurance policy).
	add_child(_achievements_toast)


func _setup_community_picker() -> void:
	# Spawned in _ready alongside the achievement UIs. Same lifecycle
	# pattern: dynamic Control children of GameController, no Main.tscn diff.
	_community_picker = CommunityPuzzlePicker.new()
	_community_picker.name = "CommunityPuzzlePicker"
	_community_picker.anchor_right = 1.0
	_community_picker.anchor_bottom = 1.0
	_community_picker.puzzle_chosen.connect(_on_community_puzzle_chosen)
	_community_picker.closed.connect(_on_community_picker_closed)
	add_child(_community_picker)


func _push_unlocks(ids: Array) -> void:
	# Routes newly-fired achievement ids to the toast queue and persists
	# the unlock state. No-op for an empty array, so the standard pattern is:
	#   var fired = _achievements.notify_*(...)
	#   _push_unlocks(fired)
	# without conditional plumbing at every call site.
	if ids == null or ids.is_empty():
		return
	for id in ids:
		_achievements_toast.enqueue(_achievements.recently_unlocked_entry(String(id)))
	AchievementStore.save_to_path(_achievements.unlocks)


func _on_achievements_requested() -> void:
	# Opened from inside the SettingsMenu's Achievements button. Layers on
	# top of the settings; closing the achievements menu returns focus to
	# settings without closing settings itself.
	_achievements_menu.open_menu(_achievements)


func _on_achievements_menu_closed() -> void:
	# Re-grab focus on the settings menu so Esc + arrow nav keep working.
	if _settings_menu.visible:
		_settings_menu.grab_focus()


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
	return _crossword_ui.visible or _shop_ui.visible or _settings_menu.visible or _achievements_menu.visible or _community_picker.visible


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
	AchievementStore.delete_at_path()
	_profile = ProfileStore.load_from_path()  # fresh defaults
	_achievements = AchievementService.new(AchievementCatalog.load_all(), {})
	_refresh_hud()
	_mall.apply_npc_hints_for_day(_profile.current_day)


func _apply_settings(settings: Dictionary) -> void:
	var clean: Dictionary = SettingsManager.normalize(settings)
	_player.set_mouse_sensitivity(float(clean[SettingsManager.KEY_MOUSE_SENSITIVITY]))
	_player.set_footstep_volume_db(float(clean[SettingsManager.KEY_FOOTSTEP_VOLUME_DB]))
	_player.set_fov(float(clean[SettingsManager.KEY_FOV]))
	# v1.1.0: route through 3-bus layout. AudioServer.get_bus_index returns
	# -1 if a named bus is missing — guard each lookup so a misconfigured
	# default_bus_layout.tres doesn't crash startup.
	_set_bus_volume("Master", float(clean[SettingsManager.KEY_MASTER_VOLUME_DB]))
	_set_bus_volume("SFX", float(clean[SettingsManager.KEY_SFX_VOLUME_DB]))
	_set_bus_volume("Music", float(clean[SettingsManager.KEY_MUSIC_VOLUME_DB]))
	# Apply any persisted key rebindings to the live InputMap.
	_apply_key_bindings(clean.get(SettingsManager.KEY_BINDINGS, {}))


func _set_bus_volume(bus_name: String, db: float) -> void:
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, db)


func _apply_key_bindings(bindings: Dictionary) -> void:
	# Reinstall every rebindable action's keycode from the persisted dict.
	# Actions not in the dict keep their project.godot defaults — settings
	# only overrides; it doesn't store the full InputMap.
	for action in SettingsManager.REBINDABLE_ACTIONS:
		if not bindings.has(action):
			continue
		var code: int = int(bindings[action])
		if code <= 0:
			continue
		if not InputMap.has_action(action):
			continue
		InputMap.action_erase_events(action)
		var event: InputEventKey = InputEventKey.new()
		event.physical_keycode = code
		InputMap.action_add_event(action, event)


func _refresh_hud() -> void:
	_hud.update_woints(_profile.woints)
	_hud.update_day(_profile.current_day)
	_hud.update_streak(_profile.streak)


func _on_interactable_changed(interactable: Node) -> void:
	_last_seen_interactable = interactable
	if interactable == null:
		_hud.hide_prompt()
		return
	if interactable.has_meta("puzzle_id"):
		_hud.show_prompt("[E] " + interactable.get_meta("puzzle_label", "Crossword"))
	elif interactable.has_meta("daily_puzzle"):
		_show_daily_puzzle_prompt()
	elif interactable.has_meta("community_puzzle"):
		_hud.show_prompt("[E] Browse community puzzles")
	elif interactable.has_meta("shop_id"):
		_hud.show_prompt("[E] " + interactable.get_meta("shop_label", "Shop"))
	elif interactable.has_meta("sleep_action"):
		_hud.show_prompt("[E] " + interactable.get_meta("sleep_label", "Sleep — advance to next day"))
	else:
		_hud.hide_prompt()


func _show_daily_puzzle_prompt() -> void:
	var interactable: Node = _player_current_interactable()
	if interactable == null:
		return
	var difficulty: String = String(interactable.get_meta("difficulty", PuzzleSchedule.DIFFICULTY_MINI))
	var label: String = difficulty.to_upper()
	var day: int = _profile.current_day
	var puzzle_id: String = PuzzleSchedule.puzzle_id_for_day(day, difficulty)
	if puzzle_id == "":
		var last_day: int = PuzzleSchedule.last_scheduled_day(difficulty)
		if day > last_day:
			_hud.show_prompt("%s puzzles complete for now — more in a future update" % label)
		else:
			_hud.show_prompt("No %s puzzle today — sleep to advance the day" % label)
	elif _profile.is_puzzle_solved(puzzle_id):
		_hud.show_prompt("[E] %s Day %d (already solved%s)" % [label, day, _best_time_suffix(puzzle_id)])
	else:
		_hud.show_prompt("[E] Solve %s Day %d%s" % [label, day, _best_time_suffix(puzzle_id)])


func _best_time_suffix(puzzle_id: String) -> String:
	# Appended onto solve / already-solved prompts as e.g. " · best 4:17".
	# Returns "" when the puzzle has never been timed (existing v0.x save
	# files solve old puzzles without ever populating best_times — those
	# stay clean rather than displaying a "--:--" suffix).
	var ms: int = _profile.best_time_ms(puzzle_id)
	if ms <= 0:
		return ""
	return " · best %s" % Profile.format_time_ms(ms)


func _player_current_interactable() -> Node:
	# Convenience: GameController.on_interactable_changed gets the node passed
	# directly, but the daily prompt re-renders from inside other flows too
	# (e.g. settings close), so we need a way to look up the current target.
	# Re-emitting via Player.refresh_interaction_target() routes back through
	# _on_interactable_changed below, which calls _show_daily_puzzle_prompt
	# with no arg — so we read it from the Player's internal state.
	# Player intentionally doesn't expose this directly; we plumb through the
	# signal instead. This helper is set up so _on_interactable_changed can
	# pass the node along.
	return _last_seen_interactable


func _on_interaction_triggered(interactable: Node) -> void:
	if interactable == null or _sleeping:
		return
	if interactable.has_meta("puzzle_id"):
		_open_puzzle(interactable, interactable.get_meta("puzzle_id"))
	elif interactable.has_meta("daily_puzzle"):
		var difficulty: String = String(interactable.get_meta("difficulty", PuzzleSchedule.DIFFICULTY_MINI))
		var puzzle_id: String = PuzzleSchedule.puzzle_id_for_day(_profile.current_day, difficulty)
		if puzzle_id == "":
			# No puzzle scheduled for today at this difficulty — leave the
			# prompt up, do nothing.
			return
		_open_puzzle(interactable, puzzle_id)
	elif interactable.has_meta("community_puzzle"):
		_open_community_picker()
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
	# Pass puzzle_id and any prior partial-solve elapsed time. v1.0.1 doesn't
	# persist mid-solve elapsed_ms across game launches yet — that lives in
	# CrosswordUI's local var until the modal closes — so resume from 0 here.
	# A future patch can extend CrosswordState serialization to include it.
	_crossword_ui.open_puzzle(puzzle, cached_state, reward_remaining, _profile.is_puzzle_solved(puzzle_id), _profile, puzzle_id, 0)
	_player.set_paused_for_ui(true)
	_hud.hide_prompt()


func _open_community_picker() -> void:
	_community_picker.open(_profile)
	_player.set_paused_for_ui(true)
	_hud.hide_prompt()


func _on_community_puzzle_chosen(result: Dictionary) -> void:
	# Stash + open the puzzle. The picker has already closed itself before
	# emitting, so this is the only handler doing modal-state changes.
	_pending_community_result = result
	var puzzle: Dictionary = result.get("puzzle", {})
	var puzzle_id: String = String(result.get("puzzle_id", ""))
	if puzzle_id == "" or puzzle.get("grid") == null:
		push_warning("Community puzzle missing grid; aborting open.")
		_player.set_paused_for_ui(false)
		return
	var reward_remaining: int = 0
	if not _profile.is_puzzle_solved(puzzle_id):
		reward_remaining = WointsConfig.REWARD_COMMUNITY
	_current_puzzle_id = puzzle_id
	_current_reward = reward_remaining
	var cached_state: CrosswordState = _profile.get_cached_state(puzzle_id)
	_crossword_ui.open_puzzle(puzzle, cached_state, reward_remaining, _profile.is_puzzle_solved(puzzle_id), _profile, puzzle_id, 0)


func _on_community_picker_closed() -> void:
	# Picker was dismissed with Esc / Close (no puzzle chosen). Restore
	# player input. If the picker was closed because a puzzle WAS chosen,
	# CrosswordUI is up and Player stays paused — _on_crossword_closed will
	# release it later.
	if not _crossword_ui.visible:
		_player.set_paused_for_ui(false)
		_player.refresh_interaction_target()


func _open_shop(interactable: Node) -> void:
	var shop_label: String = interactable.get_meta("shop_label", "Mall Shop")
	# Snapshot owned_items so the close handler can diff to detect any new
	# purchases. .duplicate() is shallow-fine; owned_items holds Strings.
	_owned_items_before_shop = _profile.owned_items.duplicate()
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
	# Shop UI mutates _profile in place via try_purchase. Diff owned_items
	# against the pre-open snapshot to detect new purchases; each fires the
	# matching achievement notification. ShopUI typically allows only one
	# purchase per visit but the diff handles N gracefully.
	for item_id in _profile.owned_items:
		if _owned_items_before_shop.has(item_id):
			continue
		var fired: Array = _achievements.notify_item_purchased(String(item_id), _profile.woints, _profile.current_day)
		_push_unlocks(fired)
	_owned_items_before_shop = []
	ProfileStore.save_to_path(_profile)
	_hud.update_woints(_profile.woints)
	_player.set_paused_for_ui(false)
	_player.refresh_interaction_target()


func _on_puzzle_solved(elapsed_ms: int, used_check_letter: bool) -> void:
	if _current_puzzle_id == "":
		return
	# Community puzzles (user://puzzles/*.json) follow a different reward
	# model: half-MIDI flat reward, no streak bonus, no streak credit. The
	# update_streak=false flag on mark_puzzle_solved enforces that.
	var is_community: bool = _is_community_puzzle_id(_current_puzzle_id)
	# Record the time first — applies whether or not this is the first solve,
	# so a re-solve that improves the record still counts. Profile.record_solve_time
	# handles the "only if better than previous" check internally.
	_profile.record_solve_time(_current_puzzle_id, elapsed_ms)
	var first_solve: bool = _profile.mark_puzzle_solved(_current_puzzle_id, not is_community)
	if first_solve:
		if is_community:
			# Flat reward, no streak bonus.
			_profile.add_woints(_current_reward)
		else:
			var bonus: int = WointsConfig.streak_bonus(_profile.streak)
			_profile.add_woints(_current_reward + bonus)
		_refresh_hud()
	ProfileStore.save_to_path(_profile)
	# Achievement notifications fire whether or not it's a first solve — a
	# re-solve with a faster time can still earn speed_mini, and notify_woints
	# is idempotent so calling it on every solve is fine.
	# Community puzzles route through the same notify_* hooks but their
	# puzzle_ids won't match any tier-gated achievement (mall_day_one etc.),
	# so they only count toward universal achievements like first_solve.
	var difficulty: String = _difficulty_for_puzzle_id(_current_puzzle_id)
	var fired_solve: Array = _achievements.notify_puzzle_solved(
		_current_puzzle_id, difficulty, _profile.current_day,
		elapsed_ms, used_check_letter, _profile
	)
	_push_unlocks(fired_solve)
	var fired_streak: Array = _achievements.notify_streak(_profile.streak, _profile.current_day)
	_push_unlocks(fired_streak)
	var fired_hoard: Array = _achievements.notify_woints(_profile.woints, _profile.current_day)
	_push_unlocks(fired_hoard)


static func _is_community_puzzle_id(puzzle_id: String) -> bool:
	# Convention: community puzzle IDs are their res-style absolute paths,
	# which always start with "user://" (the loader emits that). Anything
	# else is bundled content.
	return puzzle_id.begins_with("user://")


func _difficulty_for_puzzle_id(puzzle_id: String) -> String:
	# Reverse-lookup which difficulty's schedule a puzzle belongs to.
	# Linear scan across all three tiers, total ~21 entries today — cheap.
	# Returns "" for unknown ids (the AchievementService treats that as
	# "no tier-specific check applies").
	for tier in PuzzleSchedule.all_difficulties():
		for day in PuzzleSchedule.scheduled_days(tier):
			if PuzzleSchedule.puzzle_id_for_day(int(day), tier) == puzzle_id:
				return tier
	return ""
