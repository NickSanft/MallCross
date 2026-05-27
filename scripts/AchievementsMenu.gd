class_name AchievementsMenu
extends Control

# Modal that lists every achievement with its unlock state. Opened from the
# Settings menu. Locked entries render dimmer; hidden achievements that
# aren't yet unlocked show a "???" name + "Hidden until unlocked" blurb
# instead of revealing the win condition.

signal closed

const PANEL_WIDTH: float = 520.0
const PANEL_MIN_HEIGHT: float = 480.0

var _list_vbox: VBoxContainer
var _progress_label: Label
var _service: AchievementService


func _ready() -> void:
	_build_layout()
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP


func open_menu(service: AchievementService) -> void:
	_service = service
	_refresh()
	visible = true
	grab_focus()


func close_menu() -> void:
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
	style.border_color = Color(1.0, 0.85, 0.30, 1.0)
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

	var outer_vbox: VBoxContainer = VBoxContainer.new()
	outer_vbox.add_theme_constant_override("separation", 12)
	outer_vbox.custom_minimum_size = Vector2(PANEL_WIDTH, PANEL_MIN_HEIGHT)
	panel.add_child(outer_vbox)

	# Header
	var header_row: HBoxContainer = HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 12)
	outer_vbox.add_child(header_row)

	var title: Label = Label.new()
	title.text = "Achievements"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.30))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(title)

	_progress_label = Label.new()
	_progress_label.add_theme_font_size_override("font_size", 14)
	_progress_label.add_theme_color_override("font_color", Color(0.80, 0.90, 1.00))
	header_row.add_child(_progress_label)

	# Scrollable list
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0.0, PANEL_MIN_HEIGHT - 90.0)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer_vbox.add_child(scroll)

	_list_vbox = VBoxContainer.new()
	_list_vbox.add_theme_constant_override("separation", 8)
	_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list_vbox)

	# Footer
	var footer: HBoxContainer = HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	outer_vbox.add_child(footer)
	var close_button: Button = Button.new()
	close_button.text = "Close (Esc)"
	close_button.pressed.connect(close_menu)
	footer.add_child(close_button)


func _refresh() -> void:
	# Clear and rebuild. Achievement counts are small (~13); the per-open
	# tear-down is cheaper than maintaining incremental state for a screen
	# that's open for a few seconds at a time.
	for child in _list_vbox.get_children():
		child.queue_free()
	if _service == null:
		_progress_label.text = "0 / 0"
		return
	_progress_label.text = _service.progress_string()
	for entry in _service.all_with_state():
		_list_vbox.add_child(_build_row(entry))


func _build_row(entry: Dictionary) -> Control:
	var unlocked: bool = bool(entry.get("unlocked", false))
	var hidden: bool = bool(entry.get("hidden", false))
	var row_panel: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.14, 0.18, 0.24, 1.0) if unlocked else Color(0.10, 0.10, 0.12, 1.0)
	style.border_color = Color(1.0, 0.85, 0.30, 1.0) if unlocked else Color(0.30, 0.30, 0.35, 1.0)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.content_margin_left = 12.0
	style.content_margin_top = 8.0
	style.content_margin_right = 12.0
	style.content_margin_bottom = 8.0
	row_panel.add_theme_stylebox_override("panel", style)

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	row_panel.add_child(hbox)

	var marker: Label = Label.new()
	marker.text = "★" if unlocked else "○"
	marker.add_theme_font_size_override("font_size", 22)
	marker.add_theme_color_override("font_color", Color(1.0, 0.85, 0.30) if unlocked else Color(0.4, 0.4, 0.45))
	marker.custom_minimum_size = Vector2(28.0, 0.0)
	hbox.add_child(marker)

	var text_vbox: VBoxContainer = VBoxContainer.new()
	text_vbox.add_theme_constant_override("separation", 2)
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(text_vbox)

	var name_label: Label = Label.new()
	if hidden and not unlocked:
		name_label.text = "???"
		name_label.add_theme_color_override("font_color", Color(0.50, 0.50, 0.55))
	else:
		name_label.text = String(entry.get("name", ""))
		name_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.85) if unlocked else Color(0.70, 0.70, 0.75))
	name_label.add_theme_font_size_override("font_size", 16)
	text_vbox.add_child(name_label)

	var desc_label: Label = Label.new()
	if hidden and not unlocked:
		desc_label.text = "(hidden until unlocked)"
	else:
		desc_label.text = String(entry.get("description", ""))
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_color_override("font_color", Color(0.80, 0.85, 0.90) if unlocked else Color(0.55, 0.55, 0.60))
	text_vbox.add_child(desc_label)

	if unlocked and entry.has("unlock_day"):
		var day_label: Label = Label.new()
		day_label.text = "Day %d" % int(entry["unlock_day"])
		day_label.add_theme_font_size_override("font_size", 11)
		day_label.add_theme_color_override("font_color", Color(0.95, 0.80, 0.30))
		hbox.add_child(day_label)

	return row_panel


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			close_menu()
			accept_event()
