class_name HUD
extends CanvasLayer

# World-space HUD: interaction prompt + persistent Woints balance + current
# day + streak indicator. Also owns the full-screen fade overlay used by the
# sleep-bench day-advance transition.

signal fade_to_black_done

const FADE_HALF_DURATION: float = 0.5

var _prompt_label: Label
var _woints_label: Label
var _day_label: Label
var _streak_label: Label
var _fade_rect: ColorRect


func _ready() -> void:
	_build_layout()


func _build_layout() -> void:
	_prompt_label = Label.new()
	_prompt_label.name = "Prompt"
	_prompt_label.text = ""
	_prompt_label.add_theme_font_size_override("font_size", 22)
	_prompt_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.55))
	_prompt_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_prompt_label.add_theme_constant_override("outline_size", 6)
	_prompt_label.anchor_left = 0.5
	_prompt_label.anchor_right = 0.5
	_prompt_label.anchor_top = 0.66
	_prompt_label.anchor_bottom = 0.66
	_prompt_label.offset_left = -260.0
	_prompt_label.offset_right = 260.0
	_prompt_label.offset_top = 0.0
	_prompt_label.offset_bottom = 30.0
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.visible = false
	add_child(_prompt_label)

	_woints_label = Label.new()
	_woints_label.name = "Woints"
	_woints_label.add_theme_font_size_override("font_size", 20)
	_woints_label.add_theme_color_override("font_color", Color(1.0, 0.90, 0.35))
	_woints_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_woints_label.add_theme_constant_override("outline_size", 5)
	_woints_label.anchor_left = 1.0
	_woints_label.anchor_right = 1.0
	_woints_label.anchor_top = 0.0
	_woints_label.anchor_bottom = 0.0
	_woints_label.offset_left = -220.0
	_woints_label.offset_top = 16.0
	_woints_label.offset_right = -16.0
	_woints_label.offset_bottom = 44.0
	_woints_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_woints_label.text = "0 Woints"
	add_child(_woints_label)

	_day_label = Label.new()
	_day_label.name = "Day"
	_day_label.add_theme_font_size_override("font_size", 18)
	_day_label.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
	_day_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_day_label.add_theme_constant_override("outline_size", 5)
	_day_label.anchor_left = 0.0
	_day_label.anchor_top = 0.0
	_day_label.offset_left = 16.0
	_day_label.offset_top = 16.0
	_day_label.offset_right = 200.0
	_day_label.offset_bottom = 40.0
	_day_label.text = "Day 1"
	add_child(_day_label)

	_streak_label = Label.new()
	_streak_label.name = "Streak"
	_streak_label.add_theme_font_size_override("font_size", 16)
	_streak_label.add_theme_color_override("font_color", Color(1.0, 0.65, 0.40))
	_streak_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_streak_label.add_theme_constant_override("outline_size", 4)
	_streak_label.anchor_left = 0.0
	_streak_label.anchor_top = 0.0
	_streak_label.offset_left = 16.0
	_streak_label.offset_top = 44.0
	_streak_label.offset_right = 240.0
	_streak_label.offset_bottom = 66.0
	_streak_label.text = ""
	_streak_label.visible = false
	add_child(_streak_label)

	_fade_rect = ColorRect.new()
	_fade_rect.name = "Fade"
	_fade_rect.color = Color(0.0, 0.0, 0.0, 0.0)
	_fade_rect.anchor_right = 1.0
	_fade_rect.anchor_bottom = 1.0
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.visible = false
	add_child(_fade_rect)


func show_prompt(text: String) -> void:
	_prompt_label.text = text
	_prompt_label.visible = true


func hide_prompt() -> void:
	_prompt_label.visible = false


func update_woints(amount: int) -> void:
	_woints_label.text = "%d Woints" % amount


func update_day(day: int) -> void:
	_day_label.text = "Day %d" % day


func update_streak(streak: int) -> void:
	if streak <= 1:
		_streak_label.visible = false
		return
	_streak_label.text = "Streak: %d days" % streak
	_streak_label.visible = true


func fade_to_black_and_back() -> void:
	# 0 → 1 alpha over FADE_HALF_DURATION, emit fade_to_black_done, then
	# 1 → 0 over FADE_HALF_DURATION. The caller advances the day in between
	# via the signal.
	_fade_rect.visible = true
	_fade_rect.color = Color(0.0, 0.0, 0.0, 0.0)
	var tween: Tween = create_tween()
	tween.tween_property(_fade_rect, "color:a", 1.0, FADE_HALF_DURATION)
	tween.tween_callback(_emit_fade_to_black_done)
	tween.tween_property(_fade_rect, "color:a", 0.0, FADE_HALF_DURATION)
	tween.tween_callback(_finish_fade)


func _emit_fade_to_black_done() -> void:
	fade_to_black_done.emit()


func _finish_fade() -> void:
	_fade_rect.visible = false
