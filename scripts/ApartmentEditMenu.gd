class_name ApartmentEditMenu
extends Control

# Modal that lists every furniture item the player owns. Per row:
#   - title + description
#   - if placed: "Placed" badge + Remove button
#   - if not placed: Place button — triggers placement mode
#
# Emits `place_requested(item_id)` when the player clicks Place. The
# GameController catches that, closes this menu, and hands control to the
# PlacementController. Removal is in-place: clicking Remove unplaces the
# item, refreshes the row, and the GameController persists the change.

signal closed
signal place_requested(item_id: String)
signal remove_requested(item_id: String)

const PANEL_WIDTH: float = 540.0
const PANEL_MIN_HEIGHT: float = 480.0

var _profile: Profile
var _list_vbox: VBoxContainer
var _header_label: Label


func _ready() -> void:
	_build_layout()
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP


func open_menu(profile: Profile) -> void:
	_profile = profile
	_refresh()
	visible = true
	grab_focus()


func close_menu() -> void:
	visible = false
	closed.emit()


func refresh() -> void:
	# Public so the GameController can re-poll after a placement/removal
	# without re-opening the whole menu.
	_refresh()


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
	style.border_color = Color(0.55, 0.85, 1.00, 1.0)
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

	# Header
	var header_row: HBoxContainer = HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 12)
	vbox.add_child(header_row)
	var title: Label = Label.new()
	title.text = "Customize Apartment"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.85, 0.95, 1.00))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(title)
	_header_label = Label.new()
	_header_label.add_theme_font_size_override("font_size", 14)
	_header_label.add_theme_color_override("font_color", Color(0.80, 0.85, 0.90))
	header_row.add_child(_header_label)

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
	close_button.pressed.connect(close_menu)
	footer.add_child(close_button)


func _refresh() -> void:
	if _profile == null:
		return
	for child in _list_vbox.get_children():
		child.queue_free()
	# Owned furniture = owned_items intersected with the home_goods catalog.
	var owned_furniture: Array = []
	for item in ItemCatalog.items_for_shop(Item.SHOP_HOME_GOODS):
		if _profile.owns(item.id):
			owned_furniture.append(item)
	var placed_count: int = 0
	for item in owned_furniture:
		if _profile.is_furniture_placed(item.id):
			placed_count += 1
	_header_label.text = "%d placed / %d owned" % [placed_count, owned_furniture.size()]
	if owned_furniture.is_empty():
		var empty: Label = Label.new()
		empty.text = "No furniture owned yet. Buy some at the Home Goods shop (Store 2)."
		empty.add_theme_color_override("font_color", Color(0.65, 0.70, 0.75))
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_list_vbox.add_child(empty)
		return
	for item in owned_furniture:
		_list_vbox.add_child(_build_row(item))


func _build_row(item: Item) -> Control:
	var placed: bool = _profile.is_furniture_placed(item.id)
	var row_panel: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.16, 0.16, 0.20, 1.0)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.55, 0.85, 1.00, 0.5) if placed else Color(0.35, 0.40, 0.45, 1.0)
	style.content_margin_left = 12.0
	style.content_margin_top = 8.0
	style.content_margin_right = 12.0
	style.content_margin_bottom = 8.0
	row_panel.add_theme_stylebox_override("panel", style)

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	row_panel.add_child(hbox)

	# Color swatch (the same color the placed furniture will use).
	var swatch: ColorRect = ColorRect.new()
	swatch.color = item.color
	swatch.custom_minimum_size = Vector2(28.0, 28.0)
	hbox.add_child(swatch)

	var text_vbox: VBoxContainer = VBoxContainer.new()
	text_vbox.add_theme_constant_override("separation", 2)
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(text_vbox)

	var name_label: Label = Label.new()
	name_label.text = item.name
	name_label.add_theme_font_size_override("font_size", 15)
	name_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.85))
	text_vbox.add_child(name_label)

	var meta_label: Label = Label.new()
	var anchor_label: String = _humanize_anchor(item.anchor)
	if placed:
		meta_label.text = "Placed · %s anchor" % anchor_label
		meta_label.add_theme_color_override("font_color", Color(0.55, 0.85, 1.00))
	else:
		meta_label.text = "%s anchor" % anchor_label
		meta_label.add_theme_color_override("font_color", Color(0.70, 0.75, 0.80))
	meta_label.add_theme_font_size_override("font_size", 11)
	text_vbox.add_child(meta_label)

	if placed:
		var remove_button: Button = Button.new()
		remove_button.text = "Remove"
		remove_button.add_theme_color_override("font_color", Color(1.0, 0.65, 0.65))
		remove_button.custom_minimum_size = Vector2(96.0, 30.0)
		remove_button.pressed.connect(_on_remove_pressed.bind(item.id))
		hbox.add_child(remove_button)
	else:
		var place_button: Button = Button.new()
		place_button.text = "Place"
		place_button.custom_minimum_size = Vector2(96.0, 30.0)
		place_button.pressed.connect(_on_place_pressed.bind(item.id))
		hbox.add_child(place_button)

	return row_panel


static func _humanize_anchor(anchor: String) -> String:
	match anchor:
		Item.ANCHOR_FLOOR:
			return "Floor"
		Item.ANCHOR_WALL:
			return "Wall"
		Item.ANCHOR_DESK:
			return "Desk"
		_:
			return "—"


func _on_place_pressed(item_id: String) -> void:
	# Menu closes here so the placement controller has the full viewport
	# to work with. GameController handles the rest.
	visible = false
	closed.emit()
	place_requested.emit(item_id)


func _on_remove_pressed(item_id: String) -> void:
	# Stay open after a remove so the player can do several removals in a
	# row. GameController updates the profile + scene, then calls refresh.
	remove_requested.emit(item_id)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			close_menu()
			accept_event()
