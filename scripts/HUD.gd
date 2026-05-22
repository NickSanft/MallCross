class_name HUD
extends CanvasLayer

# Minimal world-space HUD: interaction prompt only for Phase 4. Phase 5 will
# add Woints counter; Phase 8 styles it.

var _prompt_label: Label


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
	_prompt_label.offset_left = -240.0
	_prompt_label.offset_right = 240.0
	_prompt_label.offset_top = 0.0
	_prompt_label.offset_bottom = 30.0
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.visible = false
	add_child(_prompt_label)


func show_prompt(text: String) -> void:
	_prompt_label.text = text
	_prompt_label.visible = true


func hide_prompt() -> void:
	_prompt_label.visible = false
