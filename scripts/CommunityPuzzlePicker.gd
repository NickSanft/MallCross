class_name CommunityPuzzlePicker
extends Control

# Modal that lists every puzzle in user://puzzles/. Valid entries are
# clickable and emit `puzzle_chosen`; invalid entries display their
# rejection reason so a modder can see what to fix without leaving the
# game. Rescans the directory on every open() so newly-dropped files
# appear immediately.

signal puzzle_chosen(result: Dictionary)
signal closed

const PANEL_WIDTH: float = 560.0
const PANEL_MIN_HEIGHT: float = 460.0

var _profile: Profile  # used to render "(already solved)" badges
var _list_vbox: VBoxContainer
var _header_label: Label
var _hint_label: Label


func _ready() -> void:
	_build_layout()
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	anchor_right = 1.0
	anchor_bottom = 1.0


func open(profile: Profile) -> void:
	_profile = profile
	_refresh()
	visible = true
	grab_focus()


func close_picker() -> void:
	visible = false
	closed.emit()


func _build_layout() -> void:
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.7)
	dim.anchor_right = 1.0
	dim.anchor_bottom = 1.0
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var center: CenterContainer = CenterContainer.new()
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	add_child(center)

	var panel: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.10, 0.14, 1.0)
	style.border_color = Color(0.55, 0.95, 0.65, 1.0)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.content_margin_left = 22.0
	style.content_margin_top = 16.0
	style.content_margin_right = 22.0
	style.content_margin_bottom = 16.0
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	vbox.custom_minimum_size = Vector2(PANEL_WIDTH, PANEL_MIN_HEIGHT)
	panel.add_child(vbox)

	# Header row
	var header_row: HBoxContainer = HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 12)
	vbox.add_child(header_row)

	var title: Label = Label.new()
	title.text = "Community Puzzles"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.55, 0.95, 0.65))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(title)

	_header_label = Label.new()
	_header_label.add_theme_font_size_override("font_size", 14)
	_header_label.add_theme_color_override("font_color", Color(0.80, 0.90, 1.00))
	header_row.add_child(_header_label)

	# How-to hint (shown when the list is empty AND every time as a footer
	# reminder). Modders need to know where to drop the files.
	_hint_label = Label.new()
	_hint_label.text = "Drop .json files into user://puzzles/ — see docs/MOD_PUZZLES.md for the format."
	_hint_label.add_theme_font_size_override("font_size", 11)
	_hint_label.add_theme_color_override("font_color", Color(0.65, 0.70, 0.75))
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_hint_label)

	# Scrollable list
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0.0, PANEL_MIN_HEIGHT - 130.0)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	_list_vbox = VBoxContainer.new()
	_list_vbox.add_theme_constant_override("separation", 8)
	_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list_vbox)

	# Footer
	var footer: HBoxContainer = HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	vbox.add_child(footer)
	var close_button: Button = Button.new()
	close_button.text = "Close (Esc)"
	close_button.pressed.connect(close_picker)
	footer.add_child(close_button)


func _refresh() -> void:
	for child in _list_vbox.get_children():
		child.queue_free()
	var results: Array = CommunityPuzzleLoader.scan_user_dir()
	var valid_count: int = 0
	for r in results:
		if bool(r.get("valid", false)):
			valid_count += 1
	_header_label.text = "%d / %d valid" % [valid_count, results.size()]
	if results.is_empty():
		var empty_row: Label = Label.new()
		empty_row.text = "No community puzzles found.\nCreate user://puzzles/ and drop .json files there."
		empty_row.add_theme_color_override("font_color", Color(0.65, 0.65, 0.70))
		empty_row.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_list_vbox.add_child(empty_row)
		return
	for r in results:
		_list_vbox.add_child(_build_row(r))


func _build_row(result: Dictionary) -> Control:
	var valid: bool = bool(result.get("valid", false))
	var puzzle_id: String = String(result.get("puzzle_id", ""))
	var solved: bool = (_profile != null and _profile.is_puzzle_solved(puzzle_id))

	var row_panel: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	if valid:
		style.bg_color = Color(0.10, 0.16, 0.14, 1.0)
		style.border_color = Color(0.55, 0.95, 0.65, 1.0)
	else:
		style.bg_color = Color(0.16, 0.10, 0.10, 1.0)
		style.border_color = Color(0.85, 0.40, 0.40, 1.0)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.content_margin_left = 12.0
	style.content_margin_top = 10.0
	style.content_margin_right = 12.0
	style.content_margin_bottom = 10.0
	row_panel.add_theme_stylebox_override("panel", style)

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	row_panel.add_child(hbox)

	var text_vbox: VBoxContainer = VBoxContainer.new()
	text_vbox.add_theme_constant_override("separation", 2)
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(text_vbox)

	var title_label: Label = Label.new()
	title_label.text = String(result.get("title", ""))
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.90))
	text_vbox.add_child(title_label)

	var meta_label: Label = Label.new()
	var size: int = int(result.get("size", 0))
	var author: String = String(result.get("author", "(unknown)"))
	meta_label.text = "%dx%d · by %s" % [size, size, author]
	meta_label.add_theme_font_size_override("font_size", 11)
	meta_label.add_theme_color_override("font_color", Color(0.70, 0.75, 0.80))
	text_vbox.add_child(meta_label)

	if not valid:
		var error_label: Label = Label.new()
		error_label.text = "✗ %s" % String(result.get("error", "Validation failed"))
		error_label.add_theme_font_size_override("font_size", 11)
		error_label.add_theme_color_override("font_color", Color(0.95, 0.55, 0.55))
		error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text_vbox.add_child(error_label)
	elif solved:
		var solved_label: Label = Label.new()
		solved_label.text = "✓ Already solved"
		solved_label.add_theme_font_size_override("font_size", 11)
		solved_label.add_theme_color_override("font_color", Color(0.55, 0.95, 0.65))
		text_vbox.add_child(solved_label)

	if valid:
		var play_button: Button = Button.new()
		play_button.text = "Play"
		play_button.custom_minimum_size = Vector2(96.0, 36.0)
		# .bind(result) captures the dict at row-build time. Godot's bind is
		# by-value for non-Object args; we duplicate to be safe against any
		# future mutation of the source list.
		play_button.pressed.connect(_on_play_pressed.bind(result.duplicate(true)))
		hbox.add_child(play_button)

	return row_panel


func _on_play_pressed(result: Dictionary) -> void:
	# The picker is closed before emitting so the GameController can open
	# the CrosswordUI without two modals fighting for focus.
	visible = false
	closed.emit()
	puzzle_chosen.emit(result)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			close_picker()
			accept_event()
