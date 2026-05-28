class_name ShopUI
extends Control

# Modal shop browser. Lists every item in ItemCatalog with a per-row button
# whose state reflects ownership + affordability. Builds layout in code
# (same pattern as CrosswordUI).

signal closed

const ROW_HEIGHT: float = 80.0

var _profile: Profile
var _shop_title: String = "Mall Shop"
# Filters the catalog. Defaults to the original perks shop so existing
# call sites (the v1.0.x Store 1 mall_general wiring) keep working.
var _shop_id: String = Item.SHOP_MALL_GENERAL

var _title_label: Label
var _woints_label: Label
var _items_container: VBoxContainer
var _close_button: Button


func _ready() -> void:
	_build_layout()
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP


func open_shop(profile: Profile, shop_title: String = "Mall Shop", shop_id: String = Item.SHOP_MALL_GENERAL) -> void:
	_profile = profile
	_shop_title = shop_title
	_shop_id = shop_id
	visible = true
	_refresh()
	_close_button.grab_focus()


func close_shop() -> void:
	visible = false
	closed.emit()


func _build_layout() -> void:
	# Full-screen dim
	var dim: ColorRect = ColorRect.new()
	dim.name = "Dim"
	dim.color = Color(0.0, 0.0, 0.0, 0.7)
	dim.anchor_right = 1.0
	dim.anchor_bottom = 1.0
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

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
	panel_style.border_color = Color(0.50, 0.85, 0.55, 1.0)
	panel_style.content_margin_left = 22.0
	panel_style.content_margin_top = 18.0
	panel_style.content_margin_right = 22.0
	panel_style.content_margin_bottom = 18.0
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	vbox.custom_minimum_size = Vector2(520.0, 0.0)
	panel.add_child(vbox)

	# Header
	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", 18)
	vbox.add_child(header)

	_title_label = Label.new()
	_title_label.add_theme_font_size_override("font_size", 22)
	_title_label.add_theme_color_override("font_color", Color(0.85, 1.0, 0.85))
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title_label)

	_woints_label = Label.new()
	_woints_label.add_theme_font_size_override("font_size", 18)
	_woints_label.add_theme_color_override("font_color", Color(1.0, 0.90, 0.35))
	header.add_child(_woints_label)

	# Item list
	_items_container = VBoxContainer.new()
	_items_container.add_theme_constant_override("separation", 8)
	vbox.add_child(_items_container)

	# Footer
	var footer: HBoxContainer = HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	vbox.add_child(footer)

	_close_button = Button.new()
	_close_button.text = "Leave shop (Esc)"
	_close_button.add_theme_font_size_override("font_size", 16)
	_close_button.pressed.connect(close_shop)
	footer.add_child(_close_button)


func _refresh() -> void:
	if _profile == null:
		return
	_title_label.text = _shop_title
	_woints_label.text = "%d Woints" % _profile.woints
	for child in _items_container.get_children():
		child.queue_free()
	var items: Array = ItemCatalog.items_for_shop(_shop_id)
	if items.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "(No items in this shop yet.)"
		empty_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
		_items_container.add_child(empty_label)
		return
	for item in items:
		_items_container.add_child(_build_item_row(item))


func _build_item_row(item: Item) -> Control:
	var row_panel: PanelContainer = PanelContainer.new()
	var row_style: StyleBoxFlat = StyleBoxFlat.new()
	row_style.bg_color = Color(0.16, 0.16, 0.20, 1.0)
	row_style.content_margin_left = 10.0
	row_style.content_margin_top = 8.0
	row_style.content_margin_right = 10.0
	row_style.content_margin_bottom = 8.0
	row_panel.add_theme_stylebox_override("panel", row_style)
	row_panel.custom_minimum_size = Vector2(0.0, ROW_HEIGHT)

	var row_hbox: HBoxContainer = HBoxContainer.new()
	row_hbox.add_theme_constant_override("separation", 14)
	row_panel.add_child(row_hbox)

	var info: VBoxContainer = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_hbox.add_child(info)

	var name_line: Label = Label.new()
	var slot_marker: String = ""
	match item.slot:
		Item.SLOT_COSMETIC:
			slot_marker = "(cosmetic)"
		Item.SLOT_FURNITURE:
			slot_marker = "(furniture)"
		_:
			slot_marker = "(functional)"
	name_line.text = "%s  %s" % [item.name, slot_marker]
	name_line.add_theme_font_size_override("font_size", 18)
	name_line.add_theme_color_override("font_color", Color(1.0, 0.95, 0.65))
	info.add_child(name_line)

	var desc_line: Label = Label.new()
	desc_line.text = item.description
	desc_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_line.add_theme_font_size_override("font_size", 13)
	desc_line.add_theme_color_override("font_color", Color(0.82, 0.82, 0.82))
	desc_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(desc_line)

	var cost_line: Label = Label.new()
	cost_line.text = "%d Woints" % item.cost
	cost_line.add_theme_font_size_override("font_size", 14)
	cost_line.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	info.add_child(cost_line)

	var button: Button = Button.new()
	button.custom_minimum_size = Vector2(140.0, 36.0)
	button.add_theme_font_size_override("font_size", 15)
	if _profile.owns(item.id):
		button.text = "Owned"
		button.disabled = true
	elif not _profile.can_afford(item.cost):
		button.text = "Need %d more" % (item.cost - _profile.woints)
		button.disabled = true
	else:
		button.text = "Buy"
		button.pressed.connect(_on_buy_pressed.bind(item.id))
	row_hbox.add_child(button)

	return row_panel


func _on_buy_pressed(item_id: String) -> void:
	if _profile == null:
		return
	var item: Item = ItemCatalog.get_item(item_id)
	if item == null:
		return
	_profile.try_purchase(item_id, item.cost)
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			close_shop()
			accept_event()
