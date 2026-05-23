class_name SettingsMenu
extends Control

# Modal pause/settings menu. Three sliders + a destructive "Reset Save"
# button + a close button. Mutates a Settings dict passed in by reference
# and emits a `settings_changed` signal on every slider tick so the
# GameController can apply changes live (mouse sensitivity, volume).
# Save-to-disk happens on close.

signal closed
signal settings_changed(settings: Dictionary)
signal reset_save_requested

var _settings: Dictionary
var _mouse_slider: HSlider
var _mouse_value_label: Label
var _master_slider: HSlider
var _master_value_label: Label
var _footstep_slider: HSlider
var _footstep_value_label: Label
var _confirm_dialog: ConfirmationDialog


func _ready() -> void:
	_build_layout()
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP


func open_menu(settings: Dictionary) -> void:
	_settings = settings.duplicate(true)
	_sync_sliders_from_settings()
	visible = true
	grab_focus()


func get_current_settings() -> Dictionary:
	return _settings.duplicate(true)


func _sync_sliders_from_settings() -> void:
	_mouse_slider.value = float(_settings.get(SettingsManager.KEY_MOUSE_SENSITIVITY, SettingsManager.DEFAULT_MOUSE_SENSITIVITY))
	_master_slider.value = float(_settings.get(SettingsManager.KEY_MASTER_VOLUME_DB, SettingsManager.DEFAULT_MASTER_VOLUME_DB))
	_footstep_slider.value = float(_settings.get(SettingsManager.KEY_FOOTSTEP_VOLUME_DB, SettingsManager.DEFAULT_FOOTSTEP_VOLUME_DB))
	_update_value_labels()


func _update_value_labels() -> void:
	_mouse_value_label.text = "%.4f" % _mouse_slider.value
	_master_value_label.text = "%d dB" % int(round(_master_slider.value))
	_footstep_value_label.text = "%d dB" % int(round(_footstep_slider.value))


func close_menu() -> void:
	visible = false
	closed.emit()


func _build_layout() -> void:
	# Dim background
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
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.10, 0.10, 0.14, 1.0)
	panel_style.border_color = Color(0.55, 0.75, 0.95, 1.0)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.content_margin_left = 24.0
	panel_style.content_margin_top = 18.0
	panel_style.content_margin_right = 24.0
	panel_style.content_margin_bottom = 18.0
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	vbox.custom_minimum_size = Vector2(460.0, 0.0)
	panel.add_child(vbox)

	var title: Label = Label.new()
	title.text = "Settings"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.85, 0.95, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	_mouse_slider = _build_slider(
		vbox,
		"Mouse sensitivity",
		SettingsManager.MIN_MOUSE_SENSITIVITY,
		SettingsManager.MAX_MOUSE_SENSITIVITY,
		0.0001,
		SettingsManager.DEFAULT_MOUSE_SENSITIVITY,
	)
	_mouse_value_label = _last_value_label
	_mouse_slider.value_changed.connect(_on_mouse_sensitivity_changed)

	_master_slider = _build_slider(
		vbox,
		"Master volume",
		SettingsManager.MIN_MASTER_VOLUME_DB,
		SettingsManager.MAX_MASTER_VOLUME_DB,
		1.0,
		SettingsManager.DEFAULT_MASTER_VOLUME_DB,
	)
	_master_value_label = _last_value_label
	_master_slider.value_changed.connect(_on_master_volume_changed)

	_footstep_slider = _build_slider(
		vbox,
		"Footstep volume",
		SettingsManager.MIN_FOOTSTEP_VOLUME_DB,
		SettingsManager.MAX_FOOTSTEP_VOLUME_DB,
		1.0,
		SettingsManager.DEFAULT_FOOTSTEP_VOLUME_DB,
	)
	_footstep_value_label = _last_value_label
	_footstep_slider.value_changed.connect(_on_footstep_volume_changed)

	var footer: HBoxContainer = HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	footer.alignment = BoxContainer.ALIGNMENT_END
	vbox.add_child(footer)

	var reset_button: Button = Button.new()
	reset_button.text = "Reset Save"
	reset_button.add_theme_color_override("font_color", Color(1.0, 0.6, 0.6))
	reset_button.pressed.connect(_on_reset_pressed)
	footer.add_child(reset_button)

	var close_button: Button = Button.new()
	close_button.text = "Close (Esc)"
	close_button.pressed.connect(close_menu)
	footer.add_child(close_button)

	_confirm_dialog = ConfirmationDialog.new()
	_confirm_dialog.dialog_text = "Reset all save data? This deletes your Woints, day, solved puzzles, and inventory. Cannot be undone."
	_confirm_dialog.confirmed.connect(_on_reset_confirmed)
	add_child(_confirm_dialog)


# Internal scratch — `_build_slider` returns the slider via this so the
# caller can also pick up the value label without juggling tuples.
var _last_value_label: Label


func _build_slider(parent: Container, label_text: String, min_value: float, max_value: float, step: float, initial: float) -> HSlider:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)

	var name_label: Label = Label.new()
	name_label.text = label_text
	name_label.custom_minimum_size = Vector2(160.0, 0.0)
	row.add_child(name_label)

	var slider: HSlider = HSlider.new()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step
	slider.value = initial
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(180.0, 0.0)
	row.add_child(slider)

	var value_label: Label = Label.new()
	value_label.custom_minimum_size = Vector2(80.0, 0.0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value_label)

	_last_value_label = value_label
	return slider


func _on_mouse_sensitivity_changed(value: float) -> void:
	_settings[SettingsManager.KEY_MOUSE_SENSITIVITY] = value
	_update_value_labels()
	settings_changed.emit(_settings)


func _on_master_volume_changed(value: float) -> void:
	_settings[SettingsManager.KEY_MASTER_VOLUME_DB] = value
	_update_value_labels()
	settings_changed.emit(_settings)


func _on_footstep_volume_changed(value: float) -> void:
	_settings[SettingsManager.KEY_FOOTSTEP_VOLUME_DB] = value
	_update_value_labels()
	settings_changed.emit(_settings)


func _on_reset_pressed() -> void:
	_confirm_dialog.popup_centered()


func _on_reset_confirmed() -> void:
	reset_save_requested.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			close_menu()
			accept_event()
