class_name CrosswordUI
extends Control

# Modal crossword UI. Layout is built programmatically in _ready to avoid a
# fragile .tscn with 20+ container nodes. Holds puzzle state + cursor +
# pencil mode; delegates rendering to a child CrosswordGridView. Emits
# `closed` when the player Esc's out; `puzzle_solved(elapsed_ms)` the
# moment every white cell matches the solution.
#
# v1.0.1 additions:
#   - elapsed_ms timing from open_puzzle to solve. Emitted alongside the
#     puzzle_solved signal so the GameController can store per-puzzle bests.
#     Timer pauses while the modal is closed (e.g. player Esc'd out to mall
#     mid-solve) and resumes on re-open.
#   - Solve animation: cell-by-cell highlight sweep before the banner.
#   - Hotkey overlay: `?` (KEY_QUESTION) toggles a translucent help card.

signal closed
signal puzzle_solved(elapsed_ms: int)

# Per-cell delay for the solve sweep animation. 30ms × 225 cells (15x15) =
# ~6.7s for FULL, ~270ms for MINI. Feels celebratory without being long.
const SOLVE_SWEEP_PER_CELL_S: float = 0.03

var grid: CrosswordGrid
var state: CrosswordState
var cursor: CrosswordCursor
var slots: Array
var clues: Array
var title: String = ""
var pencil_mode: bool = false

var _solved_emitted: bool = false
var _reward_amount: int = 0
var _reward_already_taken: bool = false
var _profile: Profile
var _check_letter_timer: SceneTreeTimer
var _grid_view: CrosswordGridView
var _title_label: Label
var _progress_label: Label
var _direction_label: Label
var _pencil_label: Label
var _timer_label: Label
var _current_clue_label: Label
var _clue_list: RichTextLabel
var _footer_label: Label
var _grid_view_holder: PanelContainer
var _solved_banner: PanelContainer
var _solved_reward_label: Label
var _solved_time_label: Label
var _solved_continue_button: Button
var _hotkey_overlay: PanelContainer
var _hotkey_button: Button

# Wall-clock timer that pauses when the modal closes mid-solve. We track
# total elapsed ms in `_elapsed_ms` and the current resume-point in
# `_resume_ticks_msec`; the running total = _elapsed_ms + (now - resume).
var _elapsed_ms: int = 0
var _resume_ticks_msec: int = 0
var _timer_running: bool = false
var _current_puzzle_id: String = ""
# Latched once the sweep starts, so a player who clears + re-solves while
# the sweep is mid-flight doesn't trigger a second overlapping animation.
var _solve_sweep_active: bool = false


func _ready() -> void:
	_build_layout()
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP


func open_puzzle(puzzle: Dictionary, existing_state: CrosswordState = null, reward_amount: int = 0, reward_already_taken: bool = false, profile: Profile = null, puzzle_id: String = "", elapsed_ms_resume: int = 0) -> void:
	grid = puzzle.get("grid", CrosswordGrid.new())
	clues = puzzle.get("clues", [])
	title = puzzle.get("title", "Crossword")
	# Reuse the cached state if it matches this grid's size; otherwise start
	# fresh. Mismatches happen if the puzzle file was edited between runs.
	if existing_state != null and existing_state.size == grid.size:
		state = existing_state
	else:
		state = CrosswordState.empty_for_grid(grid)
	cursor = CrosswordCursor.at_start(grid)
	slots = CrosswordNumbering.find_word_slots(grid)
	pencil_mode = false
	_reward_amount = max(0, reward_amount)
	_reward_already_taken = reward_already_taken
	_profile = profile
	_current_puzzle_id = puzzle_id
	_clear_check_letter_flash()
	# Hide the hotkey overlay if it was left up from a previous puzzle.
	if _hotkey_overlay != null:
		_hotkey_overlay.visible = false
	_solve_sweep_active = false
	# If we loaded an already-solved state, suppress the puzzle_solved signal
	# so re-opening a solved puzzle doesn't re-fire it (GameController would
	# otherwise try to double-award).
	var already_solved: bool = CrosswordValidator.is_puzzle_solved(grid, state)
	_solved_emitted = already_solved

	# Timer: an already-solved puzzle re-opens with the timer parked; a
	# mid-solve re-open resumes from where it left off (passed in from
	# GameController via the cached profile state).
	_elapsed_ms = max(0, elapsed_ms_resume)
	if already_solved or _current_puzzle_id == "":
		_timer_running = false
	else:
		_resume_ticks_msec = Time.get_ticks_msec()
		_timer_running = true

	visible = true
	_redraw_all()
	_update_footer()
	_update_timer_label()
	_refresh_solved_banner()
	grab_focus()


func get_elapsed_ms() -> int:
	# Current total elapsed time. Paused-aware — equal to the stored running
	# total when the timer is parked, or running-total + (now - resume) when
	# active.
	if not _timer_running:
		return _elapsed_ms
	var now: int = Time.get_ticks_msec()
	return _elapsed_ms + max(0, now - _resume_ticks_msec)


func _pause_timer() -> void:
	if not _timer_running:
		return
	_elapsed_ms = get_elapsed_ms()
	_timer_running = false


func close_puzzle() -> void:
	# Pause the timer so a mid-solve close doesn't keep accumulating while
	# the player walks around the mall. Resume happens on next open_puzzle.
	_pause_timer()
	visible = false
	closed.emit()


func get_current_state() -> CrosswordState:
	return state


func _build_layout() -> void:
	# Full-screen dim
	var dim: ColorRect = ColorRect.new()
	dim.name = "Dim"
	dim.color = Color(0.0, 0.0, 0.0, 0.7)
	dim.anchor_right = 1.0
	dim.anchor_bottom = 1.0
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	# Centered modal panel
	var center: CenterContainer = CenterContainer.new()
	center.name = "Center"
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	add_child(center)

	var panel: PanelContainer = PanelContainer.new()
	panel.name = "Modal"
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.10, 0.10, 0.14, 1.0)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.90, 0.80, 0.30, 1.0)
	panel_style.content_margin_left = 18.0
	panel_style.content_margin_top = 14.0
	panel_style.content_margin_right = 18.0
	panel_style.content_margin_bottom = 14.0
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	# Header row
	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", 24)
	vbox.add_child(header)

	_title_label = Label.new()
	_title_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.55))
	_title_label.add_theme_font_size_override("font_size", 22)
	header.add_child(_title_label)

	var header_spacer: Control = Control.new()
	header_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(header_spacer)

	_progress_label = Label.new()
	_progress_label.add_theme_color_override("font_color", Color.WHITE)
	header.add_child(_progress_label)

	_direction_label = Label.new()
	_direction_label.add_theme_color_override("font_color", Color(0.6, 0.85, 1.0))
	header.add_child(_direction_label)

	_pencil_label = Label.new()
	_pencil_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	header.add_child(_pencil_label)

	_timer_label = Label.new()
	_timer_label.add_theme_color_override("font_color", Color(0.85, 0.90, 0.85))
	_timer_label.add_theme_font_size_override("font_size", 16)
	_timer_label.custom_minimum_size = Vector2(70.0, 0.0)
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(_timer_label)

	_hotkey_button = Button.new()
	_hotkey_button.text = "?"
	_hotkey_button.tooltip_text = "Show / hide hotkeys"
	_hotkey_button.custom_minimum_size = Vector2(28.0, 28.0)
	_hotkey_button.add_theme_font_size_override("font_size", 14)
	_hotkey_button.focus_mode = Control.FOCUS_NONE  # never steal keyboard from grid
	_hotkey_button.pressed.connect(_toggle_hotkey_overlay)
	header.add_child(_hotkey_button)

	# Body: grid + clue list side-by-side
	var body: HBoxContainer = HBoxContainer.new()
	body.add_theme_constant_override("separation", 18)
	vbox.add_child(body)

	_grid_view_holder = PanelContainer.new()
	var grid_panel_style: StyleBoxFlat = StyleBoxFlat.new()
	grid_panel_style.bg_color = Color(0.20, 0.20, 0.22, 1.0)
	grid_panel_style.content_margin_left = 6.0
	grid_panel_style.content_margin_top = 6.0
	grid_panel_style.content_margin_right = 6.0
	grid_panel_style.content_margin_bottom = 6.0
	_grid_view_holder.add_theme_stylebox_override("panel", grid_panel_style)
	body.add_child(_grid_view_holder)

	_grid_view = CrosswordGridView.new()
	_grid_view.name = "GridView"
	_grid_view_holder.add_child(_grid_view)

	var clue_scroll: ScrollContainer = ScrollContainer.new()
	clue_scroll.custom_minimum_size = Vector2(320.0, 0.0)
	clue_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(clue_scroll)

	_clue_list = RichTextLabel.new()
	_clue_list.bbcode_enabled = true
	_clue_list.fit_content = true
	_clue_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_clue_list.add_theme_color_override("default_color", Color(0.9, 0.9, 0.9))
	clue_scroll.add_child(_clue_list)

	# Current clue (under grid)
	_current_clue_label = Label.new()
	_current_clue_label.add_theme_font_size_override("font_size", 18)
	_current_clue_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.55))
	_current_clue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_current_clue_label)

	_footer_label = Label.new()
	_footer_label.add_theme_font_size_override("font_size", 13)
	_footer_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	_footer_label.text = _base_footer_text()
	vbox.add_child(_footer_label)

	_build_solved_banner()
	_build_hotkey_overlay()


func _base_footer_text() -> String:
	return "TAB toggle direction · ` pencil · Arrows move · BACKSPACE clear · ? hotkeys · ESC exit"


func _process(_delta: float) -> void:
	# Cheap label refresh — only when the modal is visible and the timer is
	# running. Updating the label every frame at 60fps keeps the seconds
	# digit smooth without burning much cost (one String allocation/tick).
	if visible and _timer_running:
		_update_timer_label()


func _update_timer_label() -> void:
	if _timer_label == null:
		return
	_timer_label.text = Profile.format_time_ms(get_elapsed_ms())


func _update_footer() -> void:
	var text: String = _base_footer_text()
	if _profile != null and _profile.owns("coffee"):
		text += " · / check letter (Coffee)"
	_footer_label.text = text


func _build_solved_banner() -> void:
	# Centered overlay shown when the puzzle is fully correct. Holds focus on
	# its Continue button so Enter/Space closes the modal without the player
	# hunting for the mouse.
	_solved_banner = PanelContainer.new()
	_solved_banner.name = "SolvedBanner"
	_solved_banner.anchor_left = 0.5
	_solved_banner.anchor_right = 0.5
	_solved_banner.anchor_top = 0.5
	_solved_banner.anchor_bottom = 0.5
	_solved_banner.offset_left = -180.0
	_solved_banner.offset_right = 180.0
	_solved_banner.offset_top = -110.0
	_solved_banner.offset_bottom = 110.0
	_solved_banner.visible = false
	_solved_banner.mouse_filter = Control.MOUSE_FILTER_STOP

	var banner_style: StyleBoxFlat = StyleBoxFlat.new()
	banner_style.bg_color = Color(0.10, 0.40, 0.16, 1.0)
	banner_style.border_color = Color(1.0, 0.95, 0.45, 1.0)
	banner_style.border_width_left = 3
	banner_style.border_width_top = 3
	banner_style.border_width_right = 3
	banner_style.border_width_bottom = 3
	banner_style.corner_radius_top_left = 8
	banner_style.corner_radius_top_right = 8
	banner_style.corner_radius_bottom_left = 8
	banner_style.corner_radius_bottom_right = 8
	banner_style.content_margin_left = 32.0
	banner_style.content_margin_top = 24.0
	banner_style.content_margin_right = 32.0
	banner_style.content_margin_bottom = 24.0
	_solved_banner.add_theme_stylebox_override("panel", banner_style)
	add_child(_solved_banner)

	var banner_vbox: VBoxContainer = VBoxContainer.new()
	banner_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	banner_vbox.add_theme_constant_override("separation", 14)
	_solved_banner.add_child(banner_vbox)

	var headline: Label = Label.new()
	headline.text = "PUZZLE SOLVED"
	headline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	headline.add_theme_font_size_override("font_size", 30)
	headline.add_theme_color_override("font_color", Color(1.0, 1.0, 0.70))
	banner_vbox.add_child(headline)

	var subline: Label = Label.new()
	subline.text = "Nice work!"
	subline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subline.add_theme_font_size_override("font_size", 16)
	subline.add_theme_color_override("font_color", Color(0.92, 0.92, 0.92))
	banner_vbox.add_child(subline)

	_solved_reward_label = Label.new()
	_solved_reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_solved_reward_label.add_theme_font_size_override("font_size", 18)
	_solved_reward_label.add_theme_color_override("font_color", Color(1.0, 0.90, 0.35))
	banner_vbox.add_child(_solved_reward_label)

	_solved_time_label = Label.new()
	_solved_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_solved_time_label.add_theme_font_size_override("font_size", 14)
	_solved_time_label.add_theme_color_override("font_color", Color(0.85, 0.95, 0.85))
	banner_vbox.add_child(_solved_time_label)

	_solved_continue_button = Button.new()
	_solved_continue_button.text = "Continue"
	_solved_continue_button.add_theme_font_size_override("font_size", 18)
	_solved_continue_button.custom_minimum_size = Vector2(160.0, 36.0)
	_solved_continue_button.pressed.connect(close_puzzle)
	banner_vbox.add_child(_solved_continue_button)


func _redraw_all() -> void:
	if _grid_view == null or grid == null:
		return
	_grid_view.render(grid, state, cursor)
	_update_header()
	_update_clues()


func _update_header() -> void:
	var solved: int = CrosswordValidator.correct_cell_count(grid, state)
	var total: int = grid.white_count()
	_title_label.text = title
	_progress_label.text = "%d / %d" % [solved, total]
	_direction_label.text = cursor.direction.to_upper()
	_pencil_label.text = "[PENCIL]" if pencil_mode else "[PEN]"


func _update_clues() -> void:
	var current: Dictionary = _current_slot()
	if current.is_empty():
		_current_clue_label.text = ""
	else:
		var direction_marker: String = current["direction"].substr(0, 1).to_upper()
		_current_clue_label.text = "%d%s — %s" % [current["number"], direction_marker, _clue_text_for(current)]

	_clue_list.clear()
	_clue_list.append_text("[b]Across[/b]\n")
	for slot in CrosswordNumbering.slots_by_direction(slots, CrosswordNumbering.ACROSS):
		_append_clue_line(slot, current)
	_clue_list.append_text("\n[b]Down[/b]\n")
	for slot in CrosswordNumbering.slots_by_direction(slots, CrosswordNumbering.DOWN):
		_append_clue_line(slot, current)


func _append_clue_line(slot: Dictionary, current: Dictionary) -> void:
	var text: String = _clue_text_for(slot)
	var is_current: bool = (not current.is_empty()) and current["number"] == slot["number"] and current["direction"] == slot["direction"]
	if is_current:
		_clue_list.append_text("[color=#ffeb3b][b]%d.[/b] %s[/color]\n" % [slot["number"], text])
	else:
		_clue_list.append_text("[b]%d.[/b] %s\n" % [slot["number"], text])


func _clue_text_for(slot: Dictionary) -> String:
	for clue in clues:
		if clue.get("number") == slot["number"] and clue.get("direction") == slot["direction"]:
			return clue.get("text", "")
	return "(no clue text)"


func _current_slot() -> Dictionary:
	if cursor == null:
		return {}
	var cells: Array = cursor.current_word_cells()
	if cells.is_empty():
		return {}
	var start: Dictionary = cells[0]
	for slot in slots:
		if slot["row"] == start["row"] and slot["col"] == start["col"] and slot["direction"] == cursor.direction:
			return slot
	return {}


func _refresh_solved_banner() -> void:
	if _solved_banner == null:
		return
	var solved: bool = CrosswordValidator.is_puzzle_solved(grid, state)
	if solved:
		# Stop the timer the instant the last correct letter goes in. We
		# capture the elapsed time *before* the sweep animation so the
		# player's "actual solve time" doesn't include the celebration.
		if _timer_running:
			_pause_timer()
		_update_timer_label()
		_solved_reward_label.text = _reward_text()
		_solved_time_label.text = _time_summary_text()
		if not _solved_emitted:
			_solved_emitted = true
			# Start the sweep, then reveal the banner. Both run concurrently
			# from here — the sweep awaits via `_play_solve_sweep`, the
			# banner shows immediately so Enter/Space can dismiss any time.
			puzzle_solved.emit(_elapsed_ms)
			_solved_banner.visible = true
			_solved_continue_button.grab_focus()
			_play_solve_sweep()
		else:
			_solved_banner.visible = true
			_solved_continue_button.grab_focus()
	else:
		_solved_banner.visible = false
		# Allow re-firing puzzle_solved if the player erases and re-solves.
		_solved_emitted = false


func _time_summary_text() -> String:
	var current_ms: int = _elapsed_ms
	var line: String = "Time: " + Profile.format_time_ms(current_ms)
	if _profile == null or _current_puzzle_id == "":
		return line
	var prev_best: int = _profile.best_time_ms(_current_puzzle_id)
	if prev_best <= 0:
		return line + "  (first solve)"
	if current_ms > 0 and current_ms < prev_best:
		return line + "  (new best — was %s)" % Profile.format_time_ms(prev_best)
	return line + "  (best %s)" % Profile.format_time_ms(prev_best)


func _play_solve_sweep() -> void:
	# Top-left to bottom-right cell-by-cell highlight sweep. Skips block
	# cells (they have no white background to override). Uses a tinted
	# overlay on the grid_view via a temporary highlight set.
	if _grid_view == null or grid == null or _solve_sweep_active:
		return
	_solve_sweep_active = true
	_run_solve_sweep()


func _run_solve_sweep() -> void:
	# Coroutine-style: each await yields a frame's-worth of timer time.
	# We tint cells in row-major order. The grid_view exposes
	# `set_solve_highlight_cells(...)` (new helper) for this.
	var cells: Array = []
	for r in range(grid.size):
		for c in range(grid.size):
			if grid.is_block(r, c):
				continue
			cells.append({"row": r, "col": c})
			_grid_view.set_solve_highlight_cells(cells.duplicate())
			if SOLVE_SWEEP_PER_CELL_S > 0.0:
				await get_tree().create_timer(SOLVE_SWEEP_PER_CELL_S).timeout
			# A player who Esc'd out of the banner mid-sweep means the modal
			# is gone — bail so we don't keep ticking after close.
			if not visible:
				_solve_sweep_active = false
				return
	# Brief hold after the sweep finishes, then clear so the regular grid
	# colors come back for any post-solve interaction.
	await get_tree().create_timer(0.4).timeout
	if _grid_view != null:
		_grid_view.set_solve_highlight_cells([])
	_solve_sweep_active = false


func _build_hotkey_overlay() -> void:
	# Translucent help card listing every binding the player has access to.
	# Toggled by `?` button in the header or KEY_QUESTION/KEY_F1 globally.
	# Centered above the modal, dismissable by any key press.
	_hotkey_overlay = PanelContainer.new()
	_hotkey_overlay.name = "HotkeyOverlay"
	_hotkey_overlay.anchor_left = 0.5
	_hotkey_overlay.anchor_right = 0.5
	_hotkey_overlay.anchor_top = 0.5
	_hotkey_overlay.anchor_bottom = 0.5
	_hotkey_overlay.offset_left = -220.0
	_hotkey_overlay.offset_right = 220.0
	_hotkey_overlay.offset_top = -180.0
	_hotkey_overlay.offset_bottom = 180.0
	_hotkey_overlay.visible = false
	_hotkey_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE  # don't block grid focus

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.10, 0.92)
	style.border_color = Color(0.60, 0.85, 1.0, 1.0)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 28.0
	style.content_margin_top = 20.0
	style.content_margin_right = 28.0
	style.content_margin_bottom = 20.0
	_hotkey_overlay.add_theme_stylebox_override("panel", style)
	add_child(_hotkey_overlay)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	_hotkey_overlay.add_child(vbox)

	var heading: Label = Label.new()
	heading.text = "Hotkeys"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 22)
	heading.add_theme_color_override("font_color", Color(1.0, 0.95, 0.55))
	vbox.add_child(heading)

	var lines: Array = [
		["A–Z", "Type letter"],
		["Backspace", "Delete & step back"],
		["Delete", "Clear current cell"],
		["Arrows", "Move cursor (auto-switches direction)"],
		["Tab / Space", "Toggle across / down"],
		["` (backtick)", "Pencil mode"],
		["/ (slash)", "Check letter (Coffee perk only)"],
		["?", "Show / hide this card"],
		["Esc", "Exit puzzle (saves progress)"],
	]
	for entry in lines:
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		var key_label: Label = Label.new()
		key_label.text = String(entry[0])
		key_label.custom_minimum_size = Vector2(120.0, 0.0)
		key_label.add_theme_color_override("font_color", Color(0.65, 0.95, 1.0))
		row.add_child(key_label)
		var desc_label: Label = Label.new()
		desc_label.text = String(entry[1])
		desc_label.add_theme_color_override("font_color", Color(0.92, 0.92, 0.92))
		row.add_child(desc_label)
		vbox.add_child(row)

	var hint: Label = Label.new()
	hint.text = "Click ? or press ? again to dismiss"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
	vbox.add_child(hint)


func _toggle_hotkey_overlay() -> void:
	if _hotkey_overlay == null:
		return
	_hotkey_overlay.visible = not _hotkey_overlay.visible
	# Don't steal focus from the grid; the player should still be able to
	# type immediately after closing.
	if visible:
		grab_focus()


func _reward_text() -> String:
	if _reward_already_taken:
		return "(Already solved — no new Woints)"
	if _reward_amount > 0:
		return "+%d Woints" % _reward_amount
	return ""


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var ke: InputEventKey = event

	# When the solved banner is up, only Esc/Enter/Space close the modal.
	# Letter input is locked out so a stray key doesn't corrupt the win state.
	if _solved_banner != null and _solved_banner.visible:
		match ke.physical_keycode:
			KEY_ESCAPE, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
				close_puzzle()
				accept_event()
		return

	# `?` toggles the hotkey overlay. Caught before the A-Z range so the
	# Shift+/ that produces `?` doesn't pass through to letter entry.
	# 63 = unicode for '?'. KEY_F1 also works for the keyboard-shortcut crowd.
	if ke.unicode == 63 or ke.physical_keycode == KEY_F1:
		_toggle_hotkey_overlay()
		accept_event()
		return

	if ke.unicode >= 65 and ke.unicode <= 90:
		_enter_letter(char(ke.unicode))
		accept_event()
		return
	if ke.unicode >= 97 and ke.unicode <= 122:
		_enter_letter(char(ke.unicode).to_upper())
		accept_event()
		return

	match ke.physical_keycode:
		KEY_BACKSPACE:
			_backspace()
		KEY_DELETE:
			state.clear_cell(cursor.row, cursor.col)
			_redraw_all()
			_refresh_solved_banner()
		KEY_LEFT:
			cursor.direction = CrosswordCursor.ACROSS
			cursor.move(0, -1)
			_redraw_all()
		KEY_RIGHT:
			cursor.direction = CrosswordCursor.ACROSS
			cursor.move(0, 1)
			_redraw_all()
		KEY_UP:
			cursor.direction = CrosswordCursor.DOWN
			cursor.move(-1, 0)
			_redraw_all()
		KEY_DOWN:
			cursor.direction = CrosswordCursor.DOWN
			cursor.move(1, 0)
			_redraw_all()
		KEY_TAB:
			cursor.toggle_direction()
			_redraw_all()
		KEY_SPACE:
			cursor.toggle_direction()
			_redraw_all()
		KEY_QUOTELEFT:
			# Backtick toggles pencil. Can't bind this to P — P is a valid
			# letter (PUTTS, PEACH, etc.) and the unicode handler above
			# would have consumed the event before we got here.
			pencil_mode = not pencil_mode
			_update_header()
		KEY_SLASH:
			# Slash triggers check-letter. Same reasoning as above for C.
			_check_letter()
		KEY_ESCAPE:
			close_puzzle()
			accept_event()
			return
		_:
			return
	accept_event()


func _enter_letter(letter: String) -> void:
	if grid.is_block(cursor.row, cursor.col):
		return
	state.set_letter(cursor.row, cursor.col, letter, pencil_mode)
	cursor.advance()
	_redraw_all()
	_refresh_solved_banner()


func _backspace() -> void:
	if state.is_blank(cursor.row, cursor.col):
		cursor.retreat()
	state.clear_cell(cursor.row, cursor.col)
	_redraw_all()
	_refresh_solved_banner()


func _check_letter() -> void:
	# Only available while the player owns Coffee. Flashes incorrect entries
	# in the current word with a red border for 2 seconds.
	if _profile == null or not _profile.owns("coffee"):
		return
	if cursor == null:
		return
	var wrong_cells: Array = []
	for cell_pos in cursor.current_word_cells():
		var r: int = int(cell_pos["row"])
		var c: int = int(cell_pos["col"])
		if state.is_blank(r, c):
			continue
		if state.entry_at(r, c) != grid.cell(r, c):
			wrong_cells.append({"row": r, "col": c})
	_grid_view.set_wrong_cells(wrong_cells)
	_check_letter_timer = get_tree().create_timer(2.0)
	_check_letter_timer.timeout.connect(_clear_check_letter_flash)


func _clear_check_letter_flash() -> void:
	_check_letter_timer = null
	if _grid_view != null:
		_grid_view.set_wrong_cells([])
