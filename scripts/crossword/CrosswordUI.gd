class_name CrosswordUI
extends Control

# Modal crossword UI. Layout is built programmatically in _ready to avoid a
# fragile .tscn with 20+ container nodes. Holds puzzle state + cursor +
# pencil mode; delegates rendering to a child CrosswordGridView. Emits
# `closed` when the player Esc's out; `puzzle_solved` the moment every
# white cell matches the solution.

signal closed
signal puzzle_solved

var grid: CrosswordGrid
var state: CrosswordState
var cursor: CrosswordCursor
var slots: Array
var clues: Array
var title: String = ""
var pencil_mode: bool = false

var _solved_emitted: bool = false
var _grid_view: CrosswordGridView
var _title_label: Label
var _progress_label: Label
var _direction_label: Label
var _pencil_label: Label
var _current_clue_label: Label
var _clue_list: RichTextLabel
var _footer_label: Label
var _grid_view_holder: PanelContainer
var _solved_banner: PanelContainer
var _solved_continue_button: Button


func _ready() -> void:
	_build_layout()
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP


func open_puzzle(puzzle: Dictionary, existing_state: CrosswordState = null) -> void:
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
	# If we loaded an already-solved state, suppress the puzzle_solved signal
	# so re-opening a solved puzzle doesn't re-fire it (Phase 5 will award
	# Woints on this signal — we don't want double awards).
	var already_solved: bool = CrosswordValidator.is_puzzle_solved(grid, state)
	_solved_emitted = already_solved

	visible = true
	_redraw_all()
	_refresh_solved_banner()
	grab_focus()


func close_puzzle() -> void:
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
	_footer_label.text = "TAB toggle direction · P pencil · Arrows move · BACKSPACE clear · ESC exit"
	vbox.add_child(_footer_label)

	_build_solved_banner()


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
	_solved_banner.visible = solved
	if solved:
		if not _solved_emitted:
			_solved_emitted = true
			puzzle_solved.emit()
		# Hand focus to the Continue button so Enter/Space closes the modal.
		_solved_continue_button.grab_focus()
	else:
		# Allow re-firing puzzle_solved if the player erases and re-solves.
		_solved_emitted = false


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
		KEY_P:
			pencil_mode = not pencil_mode
			_update_header()
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
