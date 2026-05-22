class_name CrosswordGridView
extends Control

# Custom-drawn crossword grid. Single _draw call paints all NxN cells —
# avoids spawning 225 child nodes for a 15x15 puzzle. Parent CrosswordUI
# calls render() after every input change.

const CELL_SIZE: float = 40.0
const BORDER_THICKNESS: float = 1.0

const COLOR_CELL_BG: Color = Color.WHITE
const COLOR_BLOCK: Color = Color(0.08, 0.08, 0.08)
const COLOR_BORDER: Color = Color(0.55, 0.55, 0.55)
const COLOR_CURSOR_BG: Color = Color(0.45, 0.75, 1.0)
const COLOR_WORD_BG: Color = Color(0.84, 0.92, 1.0)
const COLOR_CORRECT_BG: Color = Color(0.86, 0.96, 0.86)
const COLOR_TEXT: Color = Color.BLACK
const COLOR_TEXT_PENCIL: Color = Color(0.45, 0.45, 0.45)
const COLOR_NUMBER: Color = Color(0.2, 0.2, 0.2)

const NUMBER_FONT_SIZE: int = 11
const LETTER_FONT_SIZE: int = 22

var grid: CrosswordGrid
var state: CrosswordState
var cursor: CrosswordCursor
var numbers: Array
var show_correct_highlights: bool = false
var _word_cell_set: Dictionary = {}


func render(p_grid: CrosswordGrid, p_state: CrosswordState, p_cursor: CrosswordCursor) -> void:
	grid = p_grid
	state = p_state
	cursor = p_cursor
	numbers = CrosswordNumbering.compute_numbers(grid)
	_refresh_word_set()
	custom_minimum_size = Vector2(grid.size * CELL_SIZE, grid.size * CELL_SIZE)
	queue_redraw()


func _refresh_word_set() -> void:
	_word_cell_set.clear()
	if cursor == null:
		return
	for cell in cursor.current_word_cells():
		_word_cell_set[_cell_key(cell["row"], cell["col"])] = true


func _draw() -> void:
	if grid == null:
		return
	for r in range(grid.size):
		for c in range(grid.size):
			_draw_cell(r, c)


func _draw_cell(r: int, c: int) -> void:
	var rect: Rect2 = Rect2(c * CELL_SIZE, r * CELL_SIZE, CELL_SIZE, CELL_SIZE)

	if grid.is_block(r, c):
		draw_rect(rect, COLOR_BLOCK)
		return

	var bg: Color = COLOR_CELL_BG
	if cursor != null and r == cursor.row and c == cursor.col:
		bg = COLOR_CURSOR_BG
	elif _word_cell_set.has(_cell_key(r, c)):
		bg = COLOR_WORD_BG

	draw_rect(rect, bg)
	draw_rect(rect, COLOR_BORDER, false, BORDER_THICKNESS)

	var font: Font = get_theme_default_font()

	if numbers[r][c] > 0:
		var number_pos: Vector2 = Vector2(c * CELL_SIZE + 3.0, r * CELL_SIZE + NUMBER_FONT_SIZE + 1.0)
		draw_string(font, number_pos, str(numbers[r][c]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, NUMBER_FONT_SIZE, COLOR_NUMBER)

	if state != null:
		var entry: String = state.entry_at(r, c)
		if entry != CrosswordState.EMPTY_CHAR:
			var color: Color = COLOR_TEXT_PENCIL if state.is_pencil(r, c) else COLOR_TEXT
			var letter_pos: Vector2 = Vector2(c * CELL_SIZE, r * CELL_SIZE + CELL_SIZE * 0.5 + LETTER_FONT_SIZE * 0.35)
			draw_string(font, letter_pos, entry, HORIZONTAL_ALIGNMENT_CENTER, CELL_SIZE, LETTER_FONT_SIZE, color)


func _cell_key(r: int, c: int) -> String:
	return str(r) + "_" + str(c)
