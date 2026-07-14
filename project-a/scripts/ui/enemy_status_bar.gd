@tool
extends Control
class_name EnemyStatusBar

const PANEL_SIZE := Vector2(250, 64)
const BAR_ORIGIN := Vector2(58, 26)
const BAR_SIZE := Vector2(188, 12)
const HP_FILL_COLOR := Color(0.94, 0.26, 0.42)
const HP_FILL_LOW_COLOR := Color(1.0, 0.45, 0.2)
const HP_BACK_COLOR := Color(0.09, 0.04, 0.08, 0.88)
const HP_BORDER_COLOR := Color(0.85, 0.55, 0.65, 0.55)
const BADGE_ATTACK_COLOR := Color(0.9, 0.14, 0.42)
const BADGE_BLOCK_COLOR := Color(0.28, 0.5, 0.92)
const BADGE_SKILL_COLOR := Color(0.64, 0.38, 0.95)
const BLOCK_CHIP_COLOR := Color(0.3, 0.55, 0.95, 0.92)

var hp_label: Label
var hp_fill: Panel
var hp_fill_style: StyleBoxFlat
var block_label: Label
var badge_diamond: Panel
var badge_diamond_style: StyleBoxFlat
var count_label: Label
var icon_disc: Panel
var icon_disc_style: StyleBoxFlat
var intent_icon: IntentIcon
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
	hp_label.add_theme_font_size_override("font_size", 16)
	hp_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.98))
	hp_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	hp_label.add_theme_constant_override("outline_size", 5)
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hp_label.position = Vector2(BAR_ORIGIN.x, BAR_ORIGIN.y - 17)
	hp_label.size = Vector2(BAR_SIZE.x, 22)
	hp_label.z_index = 10
	hp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hp_label)

	var hp_back := Panel.new()
	var back_style := StyleBoxFlat.new()
	back_style.bg_color = HP_BACK_COLOR
	back_style.border_color = HP_BORDER_COLOR
	back_style.set_border_width_all(1)
	back_style.set_corner_radius_all(3)
	hp_back.add_theme_stylebox_override("panel", back_style)
	hp_back.position = BAR_ORIGIN
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

	block_label = _make_chip(Vector2(BAR_ORIGIN.x, 44), BLOCK_CHIP_COLOR)
	block_label.visible = false

	_build_action_badge()

func _build_action_badge():
	# Diamond badge: a square panel rotated 45 degrees around its center.
	badge_diamond = Panel.new()
	badge_diamond_style = StyleBoxFlat.new()
	badge_diamond_style.bg_color = BADGE_ATTACK_COLOR
	badge_diamond_style.border_color = Color(1, 0.8, 0.88, 0.95)
	badge_diamond_style.set_border_width_all(2)
	badge_diamond_style.set_corner_radius_all(5)
	badge_diamond.add_theme_stylebox_override("panel", badge_diamond_style)
	badge_diamond.size = Vector2(32, 32)
	badge_diamond.pivot_offset = Vector2(16, 16)
	badge_diamond.position = Vector2(26, 28) - badge_diamond.pivot_offset
	badge_diamond.rotation_degrees = 45.0
	badge_diamond.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(badge_diamond)

	count_label = Label.new()
	count_label.text = "0"
	count_label.add_theme_font_size_override("font_size", 19)
	count_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	count_label.add_theme_color_override("font_outline_color", Color(0.2, 0.0, 0.08, 0.9))
	count_label.add_theme_constant_override("outline_size", 4)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count_label.position = Vector2(26 - 20, 28 - 15)
	count_label.size = Vector2(40, 30)
	count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(count_label)

	# Small intent-type disc attached at the lower-right of the diamond.
	icon_disc = Panel.new()
	icon_disc_style = StyleBoxFlat.new()
	icon_disc_style.bg_color = Color(0.08, 0.04, 0.1, 0.96)
	icon_disc_style.border_color = BADGE_ATTACK_COLOR.lightened(0.15)
	icon_disc_style.set_border_width_all(2)
	icon_disc_style.set_corner_radius_all(11)
	icon_disc.add_theme_stylebox_override("panel", icon_disc_style)
	icon_disc.size = Vector2(22, 22)
	icon_disc.position = Vector2(34, 34)
	icon_disc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icon_disc)

	intent_icon = IntentIcon.new()
	intent_icon.position = Vector2(3, 3)
	intent_icon.size = Vector2(16, 16)
	intent_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_disc.add_child(intent_icon)

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
	hp_label.text = str(safe_current)
	var ratio := float(safe_current) / float(safe_max)
	hp_fill.size = Vector2(max((BAR_SIZE.x - 2.0) * ratio, 0.0), BAR_SIZE.y - 2.0)
	hp_fill_style.bg_color = HP_FILL_LOW_COLOR if ratio <= 0.3 else HP_FILL_COLOR
	block_label.visible = block > 0
	if block > 0:
		block_label.text = "DEF %d" % block

# amount is unused on the bar itself (shown in the click detail panel), but
# kept in the signature so the caller can pass full intent context.
func set_intent(intent_type: StringName, _amount: int, action_count_remaining: int, _display_name := ""):
	_build()
	badge_diamond.visible = true
	count_label.visible = true
	icon_disc.visible = true
	count_label.text = str(max(action_count_remaining, 0))
	var is_attack: bool = intent_type == &"attack"
	var is_block: bool = intent_type == &"block" or intent_type == &"defense"
	var accent := BADGE_ATTACK_COLOR if is_attack else (BADGE_BLOCK_COLOR if is_block else BADGE_SKILL_COLOR)
	badge_diamond_style.bg_color = accent
	icon_disc_style.border_color = accent.lightened(0.15)
	var icon_kind := IntentIcon.Kind.SWORD if is_attack else (IntentIcon.Kind.SHIELD if is_block else IntentIcon.Kind.SKILL)
	intent_icon.set_icon(icon_kind, Color(1, 1, 1, 0.98))

func clear_intent():
	_build()
	if badge_diamond != null:
		badge_diamond.visible = false
		count_label.visible = false
		icon_disc.visible = false
