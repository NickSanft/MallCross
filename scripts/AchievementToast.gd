class_name AchievementToast
extends Control

# Bottom-right slide-in popup that announces an achievement unlock. Queue
# semantics: caller pushes one or more achievement entries, the toast plays
# them sequentially with a 4-second on-screen hold each. Multiple unlocks
# on the same frame (e.g. solving FULL Day 1 + First Solve + Polyglot all
# at once) get displayed in sequence rather than overlapping.

const HOLD_DURATION_S: float = 4.0
const SLIDE_IN_DURATION_S: float = 0.35
const SLIDE_OUT_DURATION_S: float = 0.25
const TOAST_WIDTH: float = 320.0
const TOAST_HEIGHT: float = 78.0
const MARGIN_PX: float = 24.0

var _queue: Array = []  # Array[Dictionary{name, description}]
var _showing: bool = false
var _panel: PanelContainer
var _name_label: Label
var _description_label: Label


func _ready() -> void:
	_build_layout()
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Pin to bottom-right so the toast doesn't compete with the crossword UI
	# (which lives centered).
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 1.0
	anchor_bottom = 1.0
	offset_left = -TOAST_WIDTH - MARGIN_PX
	offset_right = -MARGIN_PX
	offset_top = -TOAST_HEIGHT - MARGIN_PX
	offset_bottom = -MARGIN_PX


func enqueue(entry: Dictionary) -> void:
	# `entry` is the catalog-shaped dict {id, name, description, ...}.
	# Empty-name guard so a malformed catalog row doesn't show a blank toast.
	if entry == null or entry.is_empty():
		return
	if String(entry.get("name", "")) == "":
		return
	_queue.append(entry)
	if not _showing:
		_dequeue_and_show()


func enqueue_many(entries: Array) -> void:
	for entry in entries:
		if entry is Dictionary:
			enqueue(entry)


func _build_layout() -> void:
	_panel = PanelContainer.new()
	_panel.anchor_right = 1.0
	_panel.anchor_bottom = 1.0
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.12, 0.20, 0.94)
	style.border_color = Color(1.0, 0.85, 0.40, 1.0)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 14.0
	style.content_margin_top = 10.0
	style.content_margin_right = 14.0
	style.content_margin_bottom = 10.0
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	_panel.add_child(vbox)

	var header: Label = Label.new()
	header.text = "Achievement Unlocked"
	header.add_theme_font_size_override("font_size", 11)
	header.add_theme_color_override("font_color", Color(0.95, 0.80, 0.30))
	vbox.add_child(header)

	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 16)
	_name_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.85))
	vbox.add_child(_name_label)

	_description_label = Label.new()
	_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_description_label.add_theme_font_size_override("font_size", 11)
	_description_label.add_theme_color_override("font_color", Color(0.85, 0.90, 0.95))
	vbox.add_child(_description_label)


func _dequeue_and_show() -> void:
	if _queue.is_empty():
		_showing = false
		return
	_showing = true
	var entry: Dictionary = _queue.pop_front()
	_name_label.text = String(entry.get("name", ""))
	_description_label.text = String(entry.get("description", ""))
	_play_show_animation()


func _play_show_animation() -> void:
	visible = true
	# Slide-in from the right: start with the panel pushed off-screen, then
	# tween modulate.a (cheap stand-in for a real Tween that survives the
	# headless smoke run).
	modulate = Color(1.0, 1.0, 1.0, 0.0)
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, SLIDE_IN_DURATION_S)
	tween.tween_interval(HOLD_DURATION_S)
	tween.tween_property(self, "modulate:a", 0.0, SLIDE_OUT_DURATION_S)
	tween.tween_callback(_on_toast_complete)


func _on_toast_complete() -> void:
	visible = false
	_dequeue_and_show()
