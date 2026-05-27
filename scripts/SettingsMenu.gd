class_name SettingsMenu
extends Control

# Modal pause/settings menu. Sliders for mouse sensitivity, master/SFX/music
# volumes, footstep volume (per-source offset within SFX), and FOV; a
# skip-title checkbox; a key-rebind list for the 7 movement actions; reset
# save + close buttons. Mutates a Settings dict passed in by reference and
# emits a `settings_changed` signal on every slider tick / rebind so the
# GameController can apply changes live. Save-to-disk happens on close.

signal closed
signal settings_changed(settings: Dictionary)
signal reset_save_requested

var _settings: Dictionary
var _mouse_slider: HSlider
var _mouse_value_label: Label
var _master_slider: HSlider
var _master_value_label: Label
var _sfx_slider: HSlider
var _sfx_value_label: Label
var _music_slider: HSlider
var _music_value_label: Label
var _footstep_slider: HSlider
var _footstep_value_label: Label
var _fov_slider: HSlider
var _fov_value_label: Label
var _skip_title_checkbox: CheckBox
var _confirm_dialog: ConfirmationDialog

# Rebind state: when non-empty, the next keypress sets this action's binding.
# Esc during listening cancels (does not close the menu).
var _listening_for_action: String = ""
# action_name -> Button. Used to refresh labels after a rebind without
# rebuilding the whole panel.
var _rebind_buttons: Dictionary = {}

# Internal scratch — `_build_slider` returns the slider via this so the
# caller can also pick up the value label without juggling tuples.
var _last_value_label: Label


func _ready() -> void:
	_build_layout()
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP


func open_menu(settings: Dictionary) -> void:
	_settings = settings.duplicate(true)
	_sync_sliders_from_settings()
	_refresh_rebind_button_labels()
	visible = true
	grab_focus()


func get_current_settings() -> Dictionary:
	return _settings.duplicate(true)


func _sync_sliders_from_settings() -> void:
	_mouse_slider.value = float(_settings.get(SettingsManager.KEY_MOUSE_SENSITIVITY, SettingsManager.DEFAULT_MOUSE_SENSITIVITY))
	_master_slider.value = float(_settings.get(SettingsManager.KEY_MASTER_VOLUME_DB, SettingsManager.DEFAULT_MASTER_VOLUME_DB))
	_sfx_slider.value = float(_settings.get(SettingsManager.KEY_SFX_VOLUME_DB, SettingsManager.DEFAULT_SFX_VOLUME_DB))
	_music_slider.value = float(_settings.get(SettingsManager.KEY_MUSIC_VOLUME_DB, SettingsManager.DEFAULT_MUSIC_VOLUME_DB))
	_footstep_slider.value = float(_settings.get(SettingsManager.KEY_FOOTSTEP_VOLUME_DB, SettingsManager.DEFAULT_FOOTSTEP_VOLUME_DB))
	_fov_slider.value = float(_settings.get(SettingsManager.KEY_FOV, SettingsManager.DEFAULT_FOV))
	if _skip_title_checkbox != null:
		_skip_title_checkbox.button_pressed = bool(_settings.get(SettingsManager.KEY_SKIP_TITLE, SettingsManager.DEFAULT_SKIP_TITLE))
	_update_value_labels()


func _update_value_labels() -> void:
	_mouse_value_label.text = "%.4f" % _mouse_slider.value
	_master_value_label.text = "%d dB" % int(round(_master_slider.value))
	_sfx_value_label.text = "%d dB" % int(round(_sfx_slider.value))
	_music_value_label.text = "%d dB" % int(round(_music_slider.value))
	_footstep_value_label.text = "%d dB" % int(round(_footstep_slider.value))
	_fov_value_label.text = "%d°" % int(round(_fov_slider.value))


func close_menu() -> void:
	# Cancel any in-flight rebind so the next time the menu opens we're not
	# stuck in listen mode with a stale "Press a key..." label.
	_listening_for_action = ""
	_refresh_rebind_button_labels()
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
	vbox.add_theme_constant_override("separation", 10)
	vbox.custom_minimum_size = Vector2(480.0, 0.0)
	panel.add_child(vbox)

	var title: Label = Label.new()
	title.text = "Settings"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.85, 0.95, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# --- Input section ---------------------------------------------------
	_section_label(vbox, "Input")

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

	_fov_slider = _build_slider(
		vbox,
		"Field of view",
		SettingsManager.MIN_FOV,
		SettingsManager.MAX_FOV,
		1.0,
		SettingsManager.DEFAULT_FOV,
	)
	_fov_value_label = _last_value_label
	_fov_slider.value_changed.connect(_on_fov_changed)

	# --- Audio section ---------------------------------------------------
	_section_label(vbox, "Audio")

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

	_sfx_slider = _build_slider(
		vbox,
		"SFX volume",
		SettingsManager.MIN_SFX_VOLUME_DB,
		SettingsManager.MAX_SFX_VOLUME_DB,
		1.0,
		SettingsManager.DEFAULT_SFX_VOLUME_DB,
	)
	_sfx_value_label = _last_value_label
	_sfx_slider.value_changed.connect(_on_sfx_volume_changed)

	_music_slider = _build_slider(
		vbox,
		"Music volume",
		SettingsManager.MIN_MUSIC_VOLUME_DB,
		SettingsManager.MAX_MUSIC_VOLUME_DB,
		1.0,
		SettingsManager.DEFAULT_MUSIC_VOLUME_DB,
	)
	_music_value_label = _last_value_label
	_music_slider.value_changed.connect(_on_music_volume_changed)

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

	# --- Key bindings section --------------------------------------------
	_section_label(vbox, "Key bindings")

	for action in SettingsManager.REBINDABLE_ACTIONS:
		_build_rebind_row(vbox, action)

	# --- Misc section ----------------------------------------------------
	_section_label(vbox, "Other")

	var skip_row: HBoxContainer = HBoxContainer.new()
	skip_row.add_theme_constant_override("separation", 12)
	vbox.add_child(skip_row)
	var skip_label: Label = Label.new()
	skip_label.text = "Skip title screen"
	skip_label.custom_minimum_size = Vector2(160.0, 0.0)
	skip_row.add_child(skip_label)
	_skip_title_checkbox = CheckBox.new()
	_skip_title_checkbox.toggled.connect(_on_skip_title_toggled)
	skip_row.add_child(_skip_title_checkbox)

	# --- Footer ----------------------------------------------------------
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

	# Build-info footer (centered, dim) — useful when a player reports a
	# bug from the pause menu.
	var version_label: Label = Label.new()
	version_label.text = BuildInfo.version_string()
	version_label.add_theme_font_size_override("font_size", 11)
	version_label.add_theme_color_override("font_color", Color(0.45, 0.45, 0.50))
	version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(version_label)

	_confirm_dialog = ConfirmationDialog.new()
	_confirm_dialog.dialog_text = "Reset all save data? This deletes your Woints, day, solved puzzles, and inventory. Cannot be undone."
	_confirm_dialog.confirmed.connect(_on_reset_confirmed)
	add_child(_confirm_dialog)


func _section_label(parent: Container, text: String) -> void:
	# Subtle "Input / Audio / Key bindings / Other" group headers between
	# slider blocks. Cheaper than a real separator and easier to scan.
	var lbl: Label = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(0.65, 0.85, 1.0))
	parent.add_child(lbl)


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


func _build_rebind_row(parent: Container, action: String) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)

	var name_label: Label = Label.new()
	name_label.text = _humanize_action(action)
	name_label.custom_minimum_size = Vector2(160.0, 0.0)
	row.add_child(name_label)

	var bind_button: Button = Button.new()
	bind_button.text = _current_keycode_label(action)
	bind_button.custom_minimum_size = Vector2(180.0, 0.0)
	# focus_mode = NONE so clicking a button doesn't steal keyboard focus
	# from the menu (we need _unhandled_input to keep firing while
	# listening for the next key press).
	bind_button.focus_mode = Control.FOCUS_NONE
	bind_button.pressed.connect(_on_rebind_pressed.bind(action))
	row.add_child(bind_button)
	_rebind_buttons[action] = bind_button


static func _humanize_action(action: String) -> String:
	# "move_forward" -> "Move forward". Cheap enough for 7 actions.
	var parts: PackedStringArray = action.split("_")
	if parts.is_empty():
		return action
	var first: String = String(parts[0])
	var head: String = first.substr(0, 1).to_upper() + first.substr(1)
	if parts.size() == 1:
		return head
	var tail: PackedStringArray = parts.slice(1)
	return head + " " + " ".join(tail)


func _current_keycode_label(action: String) -> String:
	# Read the live InputMap to render the current binding. Falls back to
	# "(unbound)" if the action has no events (shouldn't happen for our 7
	# default-mapped actions, but guard for it anyway).
	if not InputMap.has_action(action):
		return "(missing)"
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			var key_event: InputEventKey = event
			var code: int = key_event.physical_keycode
			if code <= 0:
				code = key_event.keycode
			if code > 0:
				return OS.get_keycode_string(code)
	return "(unbound)"


func _refresh_rebind_button_labels() -> void:
	for action in _rebind_buttons:
		var btn: Button = _rebind_buttons[action]
		if btn == null:
			continue
		if _listening_for_action == action:
			btn.text = "Press a key..."
		else:
			btn.text = _current_keycode_label(action)


func _on_rebind_pressed(action: String) -> void:
	# Enter listen mode for this action. Esc cancels; any other key sets
	# the new binding. While listening, the matching button shows "Press a
	# key..." so the player has visual confirmation.
	_listening_for_action = action
	_refresh_rebind_button_labels()


func _consume_rebind_key(event: InputEventKey) -> void:
	# Called from _unhandled_input when a key arrives during listen mode.
	if event.physical_keycode == KEY_ESCAPE:
		# Cancel rebind without changing anything.
		_listening_for_action = ""
		_refresh_rebind_button_labels()
		return
	var action: String = _listening_for_action
	_listening_for_action = ""
	if not InputMap.has_action(action):
		_refresh_rebind_button_labels()
		return
	var code: int = event.physical_keycode
	if code <= 0:
		code = event.keycode
	if code <= 0:
		_refresh_rebind_button_labels()
		return
	InputMap.action_erase_events(action)
	var new_event: InputEventKey = InputEventKey.new()
	new_event.physical_keycode = code
	InputMap.action_add_event(action, new_event)
	var bindings: Dictionary = _settings.get(SettingsManager.KEY_BINDINGS, {})
	if not (bindings is Dictionary):
		bindings = {}
	bindings[action] = code
	_settings[SettingsManager.KEY_BINDINGS] = bindings
	_refresh_rebind_button_labels()
	settings_changed.emit(_settings)


func _on_mouse_sensitivity_changed(value: float) -> void:
	_settings[SettingsManager.KEY_MOUSE_SENSITIVITY] = value
	_update_value_labels()
	settings_changed.emit(_settings)


func _on_master_volume_changed(value: float) -> void:
	_settings[SettingsManager.KEY_MASTER_VOLUME_DB] = value
	_update_value_labels()
	settings_changed.emit(_settings)


func _on_sfx_volume_changed(value: float) -> void:
	_settings[SettingsManager.KEY_SFX_VOLUME_DB] = value
	_update_value_labels()
	settings_changed.emit(_settings)


func _on_music_volume_changed(value: float) -> void:
	_settings[SettingsManager.KEY_MUSIC_VOLUME_DB] = value
	_update_value_labels()
	settings_changed.emit(_settings)


func _on_footstep_volume_changed(value: float) -> void:
	_settings[SettingsManager.KEY_FOOTSTEP_VOLUME_DB] = value
	_update_value_labels()
	settings_changed.emit(_settings)


func _on_fov_changed(value: float) -> void:
	_settings[SettingsManager.KEY_FOV] = value
	_update_value_labels()
	settings_changed.emit(_settings)


func _on_skip_title_toggled(pressed: bool) -> void:
	_settings[SettingsManager.KEY_SKIP_TITLE] = pressed
	settings_changed.emit(_settings)


func _on_reset_pressed() -> void:
	_confirm_dialog.popup_centered()


func _on_reset_confirmed() -> void:
	reset_save_requested.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var ke: InputEventKey = event
	# Rebind capture takes priority. Even Esc routes here so cancellation
	# is local to the rebind state — doesn't close the whole menu by
	# accident when the player just wants to back out of binding.
	if _listening_for_action != "":
		_consume_rebind_key(ke)
		accept_event()
		return
	if ke.physical_keycode == KEY_ESCAPE:
		close_menu()
		accept_event()
