class_name TitleScreen
extends Control

# Logo card shown at startup. Press any key (or wait for the auto-skip when
# the player has toggled "skip title" in settings) to enter Main.tscn.
#
# Headless smoke runs (CI) target Main.tscn directly via --quit-after, so
# this scene only blocks an interactive launch. If settings.json says
# skip_title=true we still flash the card for one frame so the scene tree
# is exercised — that way a future test like
# `godot --headless --quit-after 60 res://scenes/TitleScreen.tscn` smokes
# the title-screen-then-main path without hanging.

const MAIN_SCENE_PATH: String = "res://scenes/Main.tscn"
# Minimum time the title sits on screen, even with skip_title=true, so
# a fast tester sees that something rendered. Long enough to read; short
# enough not to annoy.
const MIN_VISIBLE_SECONDS_FAST: float = 0.05
const MIN_VISIBLE_SECONDS_SLOW: float = 0.5

var _can_dismiss: bool = false
var _transitioning: bool = false
var _press_label: Label


func _ready() -> void:
	_build_layout()
	_schedule_dismiss_window()


func _build_layout() -> void:
	# Full-screen dark backdrop
	var bg: ColorRect = ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0.06, 0.06, 0.10, 1.0)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var center: CenterContainer = CenterContainer.new()
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(vbox)

	var logo: Label = Label.new()
	logo.text = "MALLCROSS"
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo.add_theme_font_size_override("font_size", 80)
	logo.add_theme_color_override("font_color", Color(1.0, 0.92, 0.30))
	vbox.add_child(logo)

	var subtitle: Label = Label.new()
	subtitle.text = "first-person mall · daily crosswords · woints"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
	vbox.add_child(subtitle)

	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(0.0, 40.0)
	vbox.add_child(spacer)

	_press_label = Label.new()
	_press_label.text = "Press any key to begin"
	_press_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_press_label.add_theme_font_size_override("font_size", 16)
	_press_label.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
	vbox.add_child(_press_label)

	# Version footer (bottom-right of the title screen).
	var version_label: Label = Label.new()
	version_label.text = BuildInfo.version_string()
	version_label.add_theme_font_size_override("font_size", 12)
	version_label.add_theme_color_override("font_color", Color(0.45, 0.45, 0.50))
	version_label.anchor_left = 1.0
	version_label.anchor_right = 1.0
	version_label.anchor_top = 1.0
	version_label.anchor_bottom = 1.0
	version_label.offset_left = -180.0
	version_label.offset_right = -12.0
	version_label.offset_top = -28.0
	version_label.offset_bottom = -8.0
	version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(version_label)


func _schedule_dismiss_window() -> void:
	# After the configured min-visible window, accept input (or auto-skip if
	# the player toggled skip_title in settings).
	var skip: bool = SettingsManager.load_from_path().get(SettingsManager.KEY_SKIP_TITLE, false)
	var delay: float = MIN_VISIBLE_SECONDS_FAST if skip else MIN_VISIBLE_SECONDS_SLOW
	await get_tree().create_timer(delay).timeout
	_can_dismiss = true
	if skip:
		_enter_main()


func _unhandled_input(event: InputEvent) -> void:
	if not _can_dismiss or _transitioning:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		_enter_main()
	elif event is InputEventMouseButton and event.pressed:
		_enter_main()


func _enter_main() -> void:
	if _transitioning:
		return
	_transitioning = true
	# change_scene_to_file returns OK / ERR_*. If it fails (missing scene
	# during dev), just bail — the user gets the title screen frozen rather
	# than a crash, and the print line aids debugging.
	var err: int = get_tree().change_scene_to_file(MAIN_SCENE_PATH)
	if err != OK:
		push_warning("TitleScreen: failed to load %s (err=%d)" % [MAIN_SCENE_PATH, err])
		_transitioning = false
