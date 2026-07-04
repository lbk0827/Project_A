extends Control
class_name EnemyStatusBar

const BAR_SIZE := Vector2(200, 12)
const PANEL_SIZE := Vector2(220, 62)
const HP_FILL_COLOR := Color(0.94, 0.26, 0.42)
const HP_FILL_LOW_COLOR := Color(1.0, 0.45, 0.2)
const HP_BACK_COLOR := Color(0.09, 0.04, 0.08, 0.88)
const HP_BORDER_COLOR := Color(0.85, 0.55, 0.65, 0.55)
const INTENT_ATTACK_COLOR := Color(0.85, 0.18, 0.25, 0.92)
const INTENT_BLOCK_COLOR := Color(0.25, 0.5, 0.9, 0.92)
const BLOCK_CHIP_COLOR := Color(0.3, 0.55, 0.95, 0.92)

var hp_label: Label
var hp_fill: Panel
var hp_fill_style: StyleBoxFlat
var intent_label: Label
var block_label: Label
var built := false

func _ready():
	_build()

func _build():
	if built:
		return
	built = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = PANEL_SIZE

	hp_label = Label.new()
	hp_label.text = "0"
	hp_label.add_theme_font_size_override("font_size", 17)
	hp_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.98))
	hp_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	hp_label.add_theme_constant_override("outline_size", 5)
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_label.position = Vector2(10, 0)
	hp_label.size = Vector2(BAR_SIZE.x, 20)
	hp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hp_label)

	var hp_back := Panel.new()
	var back_style := StyleBoxFlat.new()
	back_style.bg_color = HP_BACK_COLOR
	back_style.border_color = HP_BORDER_COLOR
	back_style.set_border_width_all(1)
	back_style.set_corner_radius_all(3)
	hp_back.add_theme_stylebox_override("panel", back_style)
	hp_back.position = Vector2(10, 22)
	hp_back.size = BAR_SIZE
	hp_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hp_back)

	hp_fill = Panel.new()
	hp_fill_style = StyleBoxFlat.new()
	hp_fill_style.bg_color = HP_FILL_COLOR
	hp_fill_style.set_corner_radius_all(3)
	hp_fill.add_theme_stylebox_override("panel", hp_fill_style)
	hp_fill.position = Vector2(1, 1)
	hp_fill.size = BAR_SIZE - Vector2(2, 2)
	hp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_back.add_child(hp_fill)

	intent_label = _make_chip(Vector2(10, 40), INTENT_ATTACK_COLOR)
	intent_label.visible = false
	block_label = _make_chip(Vector2(150, 40), BLOCK_CHIP_COLOR)
	block_label.visible = false

func _make_chip(chip_position: Vector2, bg_color: Color) -> Label:
	var chip := Label.new()
	chip.add_theme_font_size_override("font_size", 13)
	chip.add_theme_color_override("font_color", Color(1, 1, 1, 0.98))
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = Color(1, 1, 1, 0.3)
	style.set_border_width_all(1)
	style.set_corner_radius_all(9)
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 1.0
	style.content_margin_bottom = 1.0
	chip.add_theme_stylebox_override("normal", style)
	chip.position = chip_position
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(chip)
	return chip

func set_status(current_hp: int, max_hp: int, block: int):
	_build()
	var safe_max: int = max(max_hp, 1)
	var safe_current: int = clamp(current_hp, 0, safe_max)
	hp_label.text = "%d / %d" % [safe_current, safe_max]
	var ratio := float(safe_current) / float(safe_max)
	hp_fill.size = Vector2(max((BAR_SIZE.x - 2.0) * ratio, 0.0), BAR_SIZE.y - 2.0)
	hp_fill_style.bg_color = HP_FILL_LOW_COLOR if ratio <= 0.3 else HP_FILL_COLOR
	block_label.visible = block > 0
	if block > 0:
		block_label.text = "DEF %d" % block

func set_intent(intent_type: StringName, amount: int, display_name := ""):
	_build()
	intent_label.visible = true
	var style: StyleBoxFlat = intent_label.get_theme_stylebox("normal")
	if intent_type == &"attack":
		intent_label.text = "ATK %d" % amount
		style.bg_color = INTENT_ATTACK_COLOR
	else:
		intent_label.text = "DEF %d" % amount
		style.bg_color = INTENT_BLOCK_COLOR
	if not display_name.is_empty():
		intent_label.tooltip_text = display_name

func clear_intent():
	_build()
	intent_label.visible = false
