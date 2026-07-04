extends CanvasLayer

const HEROINE_SHEET := preload("res://assets/characters/spritesheets/HeroineSheet.png")
const PORTRAIT_REGION := Rect2(30, 0, 70, 64)
const PANEL_BG_COLOR := Color(0.05, 0.07, 0.11, 0.74)
const PANEL_BORDER_COLOR := Color(0.4, 0.65, 0.9, 0.4)
const HP_FILL_COLOR := Color(0.32, 0.85, 0.45)
const HP_FILL_LOW_COLOR := Color(0.95, 0.55, 0.2)
const HP_BACK_COLOR := Color(0.07, 0.1, 0.08, 0.9)
const EP_FILL_COLOR := Color(0.35, 0.75, 1.0)
const EP_EMPTY_COLOR := Color(0.16, 0.22, 0.3, 0.85)
const BLOCK_CHIP_COLOR := Color(0.3, 0.55, 0.95, 0.92)
const END_TURN_COLOR := Color(0.16, 0.42, 0.85)
const END_TURN_HOVER_COLOR := Color(0.24, 0.55, 1.0)
const END_TURN_DISABLED_COLOR := Color(0.2, 0.24, 0.3, 0.8)
const TOAST_LIFETIME := 2.4
const MAX_TOASTS := 4

@onready var ui_root: Control = %UIRoot
@onready var deck_hand: Control = %DeckHand
@onready var deck_tomb: Control = %DeckTomb
@onready var hand_container: Control = %HandContainer
@onready var targeting_dot: Panel = %TargetingDot
@onready var end_turn_button: Button = %EndTurnButton
@onready var restart_button: Button = %RestartButton

var player_hp_fill: Panel
var player_hp_fill_style: StyleBoxFlat
var player_hp_label: Label
var player_block_label: Label
var energy_value_label: Label
var energy_segments: Array[Panel] = []
var energy_segment_container: VBoxContainer
var energy_max := 0
var energy_orb_label: Label
var hand_rail: HandRail
var hand_count_label: Label
var turn_chip_label: Label
var toast_container: VBoxContainer
var popup_layer: Control
var banner_root: Control
var banner_label: Label
var banner_tween: Tween
var monster_info_panel: Panel
var monster_info_name_label: Label
var monster_info_count_label: Label
var monster_info_rows: VBoxContainer

func _ready():
	_build_player_panel()
	_build_energy_gauge()
	_build_hand_rail()
	_build_energy_orb()
	_build_hand_counter()
	_build_turn_chip()
	_build_toast_container()
	_build_banner()
	_build_popup_layer()
	_style_end_turn_button()
	_style_restart_button()
	_position_deck_panels()

# --- Layout construction -------------------------------------------------

func _build_player_panel():
	var panel := Panel.new()
	panel.name = "PlayerStatusPanel"
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_BG_COLOR
	style.border_color = PANEL_BORDER_COLOR
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", style)
	panel.position = Vector2(20, 16)
	panel.size = Vector2(372, 96)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(panel)

	var portrait_frame := Panel.new()
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color(0.1, 0.13, 0.2, 0.95)
	frame_style.border_color = Color(0.55, 0.8, 1.0, 0.7)
	frame_style.set_border_width_all(2)
	frame_style.set_corner_radius_all(8)
	portrait_frame.add_theme_stylebox_override("panel", frame_style)
	portrait_frame.position = Vector2(10, 10)
	portrait_frame.size = Vector2(76, 76)
	portrait_frame.clip_contents = true
	portrait_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(portrait_frame)

	var portrait := TextureRect.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = HEROINE_SHEET
	atlas.region = PORTRAIT_REGION
	portrait.texture = atlas
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.position = Vector2(2, 2)
	portrait.size = Vector2(72, 72)
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_frame.add_child(portrait)

	var name_label := Label.new()
	name_label.text = "HEROINE"
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.add_theme_color_override("font_color", Color(0.75, 0.88, 1.0, 0.95))
	name_label.position = Vector2(98, 8)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(name_label)

	var hp_back := Panel.new()
	var back_style := StyleBoxFlat.new()
	back_style.bg_color = HP_BACK_COLOR
	back_style.border_color = Color(0.6, 0.9, 0.7, 0.4)
	back_style.set_border_width_all(1)
	back_style.set_corner_radius_all(4)
	hp_back.add_theme_stylebox_override("panel", back_style)
	hp_back.position = Vector2(98, 30)
	hp_back.size = Vector2(258, 24)
	hp_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(hp_back)

	player_hp_fill = Panel.new()
	player_hp_fill_style = StyleBoxFlat.new()
	player_hp_fill_style.bg_color = HP_FILL_COLOR
	player_hp_fill_style.set_corner_radius_all(4)
	player_hp_fill.add_theme_stylebox_override("panel", player_hp_fill_style)
	player_hp_fill.position = Vector2(1, 1)
	player_hp_fill.size = Vector2(256, 22)
	player_hp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_back.add_child(player_hp_fill)

	player_hp_label = Label.new()
	player_hp_label.text = "0 / 0"
	player_hp_label.add_theme_font_size_override("font_size", 15)
	player_hp_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.98))
	player_hp_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	player_hp_label.add_theme_constant_override("outline_size", 4)
	player_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	player_hp_label.position = Vector2.ZERO
	player_hp_label.size = hp_back.size
	player_hp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_back.add_child(player_hp_label)

	player_block_label = Label.new()
	player_block_label.add_theme_font_size_override("font_size", 13)
	player_block_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.98))
	var chip_style := StyleBoxFlat.new()
	chip_style.bg_color = BLOCK_CHIP_COLOR
	chip_style.border_color = Color(1, 1, 1, 0.3)
	chip_style.set_border_width_all(1)
	chip_style.set_corner_radius_all(9)
	chip_style.content_margin_left = 8.0
	chip_style.content_margin_right = 8.0
	chip_style.content_margin_top = 1.0
	chip_style.content_margin_bottom = 1.0
	player_block_label.add_theme_stylebox_override("normal", chip_style)
	player_block_label.position = Vector2(98, 62)
	player_block_label.visible = false
	player_block_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(player_block_label)

func _build_energy_gauge():
	var panel := Panel.new()
	panel.name = "EnergyGauge"
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_BG_COLOR
	style.border_color = PANEL_BORDER_COLOR
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", style)
	panel.position = Vector2(24, 540)
	panel.size = Vector2(88, 160)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(panel)

	var ep_label := Label.new()
	ep_label.text = "EP"
	ep_label.add_theme_font_size_override("font_size", 14)
	ep_label.add_theme_color_override("font_color", Color(0.6, 0.85, 1.0, 0.9))
	ep_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ep_label.position = Vector2(0, 6)
	ep_label.size = Vector2(88, 18)
	ep_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(ep_label)

	# The left EP gauge is the character skill resource, not the card energy.
	# Its charge mechanic is not implemented yet, so it displays a placeholder.
	var ep_caption := Label.new()
	ep_caption.text = "SKILL"
	ep_caption.add_theme_font_size_override("font_size", 9)
	ep_caption.add_theme_color_override("font_color", Color(0.55, 0.72, 0.9, 0.7))
	ep_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ep_caption.position = Vector2(0, 22)
	ep_caption.size = Vector2(88, 12)
	ep_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(ep_caption)

	energy_value_label = Label.new()
	energy_value_label.text = "0"
	energy_value_label.add_theme_font_size_override("font_size", 40)
	energy_value_label.add_theme_color_override("font_color", Color(0.75, 0.92, 1.0))
	energy_value_label.add_theme_color_override("font_outline_color", Color(0.05, 0.15, 0.35, 0.9))
	energy_value_label.add_theme_constant_override("outline_size", 5)
	energy_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	energy_value_label.position = Vector2(0, 34)
	energy_value_label.size = Vector2(88, 44)
	energy_value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(energy_value_label)

	energy_segment_container = VBoxContainer.new()
	energy_segment_container.add_theme_constant_override("separation", 4)
	energy_segment_container.position = Vector2(24, 82)
	energy_segment_container.size = Vector2(40, 70)
	energy_segment_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(energy_segment_container)

	# Placeholder charge display until the skill-resource system exists.
	_rebuild_energy_segments(3)
	energy_value_label.text = "0"

func _rebuild_energy_segments(max_energy: int):
	energy_max = max_energy
	for segment in energy_segments:
		segment.queue_free()
	energy_segments.clear()
	for _i in range(max_energy):
		var segment := Panel.new()
		var style := StyleBoxFlat.new()
		style.bg_color = EP_EMPTY_COLOR
		style.set_corner_radius_all(3)
		style.border_color = Color(0.45, 0.65, 0.9, 0.4)
		style.set_border_width_all(1)
		segment.add_theme_stylebox_override("panel", style)
		segment.custom_minimum_size = Vector2(40, 16)
		segment.mouse_filter = Control.MOUSE_FILTER_IGNORE
		energy_segment_container.add_child(segment)
		energy_segments.append(segment)

func _build_hand_rail():
	# Foreground arch rail that occludes the lower part of the fanned cards.
	hand_rail = HandRail.new()
	hand_rail.position = Vector2(360, 660)
	hand_rail.size = Vector2(560, 60)
	hand_rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hand_rail.z_index = 150
	ui_root.add_child(hand_rail)

func _build_energy_orb():
	# Card-play energy: just the number, sitting on top of the arch rail line
	# (poking above the bright edge) so it reads clearly.
	energy_orb_label = Label.new()
	energy_orb_label.text = "0"
	energy_orb_label.add_theme_font_size_override("font_size", 46)
	energy_orb_label.add_theme_color_override("font_color", Color(0.96, 0.99, 1.0))
	energy_orb_label.add_theme_color_override("font_outline_color", Color(0.06, 0.24, 0.5, 0.96))
	energy_orb_label.add_theme_constant_override("outline_size", 8)
	energy_orb_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	energy_orb_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	energy_orb_label.size = Vector2(96, 50)
	energy_orb_label.position = Vector2(640 - 48, 640)
	energy_orb_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	energy_orb_label.z_index = 500
	ui_root.add_child(energy_orb_label)

func _build_hand_counter():
	hand_count_label = Label.new()
	hand_count_label.text = "0 / 7"
	hand_count_label.add_theme_font_size_override("font_size", 17)
	hand_count_label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0, 0.95))
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.07, 0.11, 0.82)
	style.border_color = PANEL_BORDER_COLOR
	style.set_border_width_all(1)
	style.set_corner_radius_all(11)
	style.content_margin_top = 1.0
	style.content_margin_bottom = 1.0
	hand_count_label.add_theme_stylebox_override("normal", style)
	hand_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hand_count_label.size = Vector2(108, 22)
	hand_count_label.position = Vector2(640 - 54, 700)
	hand_count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hand_count_label.z_index = 500
	ui_root.add_child(hand_count_label)

func _build_turn_chip():
	turn_chip_label = Label.new()
	turn_chip_label.text = "TURN 1"
	turn_chip_label.add_theme_font_size_override("font_size", 17)
	turn_chip_label.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.07, 0.11, 0.8)
	style.border_color = PANEL_BORDER_COLOR
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 3.0
	style.content_margin_bottom = 3.0
	turn_chip_label.add_theme_stylebox_override("normal", style)
	turn_chip_label.position = Vector2(1152, 22)
	turn_chip_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(turn_chip_label)

func _build_toast_container():
	toast_container = VBoxContainer.new()
	toast_container.position = Vector2(24, 330)
	toast_container.size = Vector2(340, 140)
	toast_container.add_theme_constant_override("separation", 6)
	toast_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(toast_container)

func _build_banner():
	banner_root = Control.new()
	banner_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	banner_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner_root.visible = false
	banner_root.z_index = 800
	ui_root.add_child(banner_root)

	var strip := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.03, 0.06, 0.62)
	style.border_color = Color(0.45, 0.75, 1.0, 0.55)
	style.border_width_top = 2
	style.border_width_bottom = 2
	strip.add_theme_stylebox_override("panel", style)
	strip.anchor_left = 0.0
	strip.anchor_right = 1.0
	strip.offset_top = 236.0
	strip.offset_bottom = 310.0
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner_root.add_child(strip)

	banner_label = Label.new()
	banner_label.text = "PLAYER TURN"
	banner_label.add_theme_font_size_override("font_size", 42)
	banner_label.add_theme_color_override("font_color", Color(0.85, 0.95, 1.0))
	banner_label.add_theme_color_override("font_outline_color", Color(0.05, 0.12, 0.3, 0.9))
	banner_label.add_theme_constant_override("outline_size", 8)
	banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	banner_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip.add_child(banner_label)

func _build_popup_layer():
	popup_layer = Control.new()
	popup_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup_layer.z_index = 900
	ui_root.add_child(popup_layer)

func _style_end_turn_button():
	var diameter := 104
	end_turn_button.position = Vector2(1132, 566)
	end_turn_button.size = Vector2(diameter, diameter)
	end_turn_button.custom_minimum_size = Vector2(diameter, diameter)
	end_turn_button.text = "END"
	end_turn_button.add_theme_font_size_override("font_size", 24)
	end_turn_button.add_theme_color_override("font_color", Color(1, 1, 1, 0.98))
	end_turn_button.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
	end_turn_button.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.45))
	end_turn_button.add_theme_color_override("font_outline_color", Color(0.03, 0.1, 0.25, 0.9))
	end_turn_button.add_theme_constant_override("outline_size", 4)
	end_turn_button.add_theme_stylebox_override("normal", _make_circle_style(diameter, END_TURN_COLOR))
	end_turn_button.add_theme_stylebox_override("hover", _make_circle_style(diameter, END_TURN_HOVER_COLOR))
	end_turn_button.add_theme_stylebox_override("pressed", _make_circle_style(diameter, END_TURN_COLOR.darkened(0.25)))
	end_turn_button.add_theme_stylebox_override("disabled", _make_circle_style(diameter, END_TURN_DISABLED_COLOR))
	end_turn_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

func _make_circle_style(diameter: int, color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(diameter / 2)
	style.border_color = Color(0.75, 0.9, 1.0, 0.75)
	style.set_border_width_all(3)
	return style

func _style_restart_button():
	restart_button.position = Vector2(1096, 496)
	restart_button.size = Vector2(176, 50)
	restart_button.add_theme_font_size_override("font_size", 17)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.12, 0.18, 0.94)
	style.border_color = Color(0.85, 0.72, 0.4, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	restart_button.add_theme_stylebox_override("normal", style)
	var hover_style: StyleBoxFlat = style.duplicate()
	hover_style.bg_color = Color(0.16, 0.19, 0.27, 0.96)
	restart_button.add_theme_stylebox_override("hover", hover_style)
	restart_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

func _position_deck_panels():
	deck_hand.position = Vector2(14, 376)
	deck_hand.scale = Vector2(0.5, 0.5)
	deck_tomb.position = Vector2(1138, 376)
	deck_tomb.scale = Vector2(0.5, 0.5)

# --- Runtime API ----------------------------------------------------------

func set_player_status(current_hp: int, max_hp: int, block: int):
	var safe_max: int = max(max_hp, 1)
	var safe_current: int = clamp(current_hp, 0, safe_max)
	player_hp_label.text = "%d / %d" % [safe_current, safe_max]
	var ratio := float(safe_current) / float(safe_max)
	player_hp_fill.size = Vector2(max(256.0 * ratio, 0.0), 22)
	player_hp_fill_style.bg_color = HP_FILL_LOW_COLOR if ratio <= 0.3 else HP_FILL_COLOR
	player_block_label.visible = block > 0
	if block > 0:
		player_block_label.text = "DEF %d" % block

# Card-play energy is shown as the bottom-center number. The left EP gauge is a
# separate character skill resource and is not driven from here.
func set_energy(current_energy: int, max_energy: int = 3):
	if energy_orb_label == null:
		return
	energy_orb_label.text = str(max(current_energy, 0))
	var dim := current_energy <= 0
	energy_orb_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6) if dim else Color(0.9, 0.96, 1.0))

func set_hand_count(current_count: int, max_count: int):
	hand_count_label.text = "%d / %d" % [max(current_count, 0), max(max_count, 0)]

func set_deck_count(count: int):
	if deck_hand.has_method("set_deck_count"):
		deck_hand.call("set_deck_count", count)

func set_tomb_count(count: int):
	if deck_tomb.has_method("set_tomb_count"):
		deck_tomb.call("set_tomb_count", count)

func set_turn(turn_number: int):
	turn_chip_label.text = "TURN %d" % turn_number

func show_turn_banner(text: String, color: Color = Color(0.85, 0.95, 1.0)):
	banner_label.text = text
	banner_label.add_theme_color_override("font_color", color)
	if banner_tween != null:
		banner_tween.kill()
	banner_root.visible = true
	banner_root.modulate = Color(1, 1, 1, 0)
	banner_tween = create_tween()
	banner_tween.tween_property(banner_root, "modulate:a", 1.0, 0.18)
	banner_tween.tween_interval(0.75)
	banner_tween.tween_property(banner_root, "modulate:a", 0.0, 0.3)
	banner_tween.tween_callback(func(): banner_root.visible = false)

func show_toast(message: String):
	var toast := Label.new()
	toast.text = message
	toast.add_theme_font_size_override("font_size", 15)
	toast.add_theme_color_override("font_color", Color(0.92, 0.95, 1.0, 0.98))
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.06, 0.1, 0.78)
	style.border_color = Color(0.4, 0.65, 0.9, 0.3)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 3.0
	style.content_margin_bottom = 3.0
	toast.add_theme_stylebox_override("normal", style)
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_container.add_child(toast)
	while toast_container.get_child_count() > MAX_TOASTS:
		toast_container.get_child(0).free()
	var tween := toast.create_tween()
	tween.tween_interval(TOAST_LIFETIME)
	tween.tween_property(toast, "modulate:a", 0.0, 0.45)
	tween.tween_callback(toast.queue_free)

func show_monster_info(monster_name: String, intents: Array, next_intent_index: int, action_count_remaining: int = 0):
	_ensure_monster_info_panel()
	monster_info_name_label.text = monster_name
	monster_info_count_label.text = "다음 행동까지 %d회 후 발동" % max(action_count_remaining, 0)
	for child in monster_info_rows.get_children():
		child.free()
	for i in range(intents.size()):
		monster_info_rows.add_child(_make_intent_row(intents[i], i, i == next_intent_index))
	monster_info_panel.size = Vector2(360, 66 + intents.size() * 42 + 8)
	monster_info_panel.visible = true
	monster_info_panel.modulate = Color(1, 1, 1, 0)
	var tween := monster_info_panel.create_tween()
	tween.tween_property(monster_info_panel, "modulate:a", 1.0, 0.12)

func hide_monster_info():
	if monster_info_panel != null:
		monster_info_panel.visible = false

func is_monster_info_visible() -> bool:
	return monster_info_panel != null and monster_info_panel.visible

func _ensure_monster_info_panel():
	if monster_info_panel != null:
		return
	monster_info_panel = Panel.new()
	monster_info_panel.name = "MonsterInfoPanel"
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.045, 0.08, 0.94)
	style.border_color = Color(0.45, 0.75, 1.0, 0.55)
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	monster_info_panel.add_theme_stylebox_override("panel", style)
	monster_info_panel.position = Vector2(24, 128)
	monster_info_panel.size = Vector2(360, 200)
	monster_info_panel.z_index = 700
	monster_info_panel.visible = false
	ui_root.add_child(monster_info_panel)

	monster_info_name_label = Label.new()
	monster_info_name_label.add_theme_font_size_override("font_size", 20)
	monster_info_name_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.6))
	monster_info_name_label.position = Vector2(16, 10)
	monster_info_name_label.size = Vector2(280, 28)
	monster_info_panel.add_child(monster_info_name_label)

	var subtitle := Label.new()
	subtitle.text = "ACTION PATTERN"
	subtitle.add_theme_font_size_override("font_size", 11)
	subtitle.add_theme_color_override("font_color", Color(0.6, 0.75, 0.95, 0.85))
	subtitle.position = Vector2(16, 38)
	monster_info_panel.add_child(subtitle)

	monster_info_count_label = Label.new()
	monster_info_count_label.add_theme_font_size_override("font_size", 12)
	monster_info_count_label.add_theme_color_override("font_color", Color(1.0, 0.62, 0.78))
	monster_info_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	monster_info_count_label.position = Vector2(150, 37)
	monster_info_count_label.size = Vector2(166, 18)
	monster_info_panel.add_child(monster_info_count_label)

	var close_button := Button.new()
	close_button.text = "X"
	close_button.add_theme_font_size_override("font_size", 15)
	close_button.flat = true
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.position = Vector2(322, 8)
	close_button.size = Vector2(30, 30)
	close_button.pressed.connect(hide_monster_info)
	monster_info_panel.add_child(close_button)

	monster_info_rows = VBoxContainer.new()
	monster_info_rows.position = Vector2(16, 58)
	monster_info_rows.size = Vector2(328, 134)
	monster_info_rows.add_theme_constant_override("separation", 6)
	monster_info_panel.add_child(monster_info_rows)

func _make_intent_row(intent: EnemyIntentData, order: int, is_next: bool) -> Panel:
	var row := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.14, 0.22, 0.9) if is_next else Color(0.06, 0.08, 0.13, 0.7)
	style.border_color = Color(0.55, 0.85, 1.0, 0.8) if is_next else Color(0.3, 0.4, 0.55, 0.3)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	row.add_theme_stylebox_override("panel", style)
	row.custom_minimum_size = Vector2(328, 36)

	var marker := Label.new()
	marker.text = ">" if is_next else str(order + 1)
	marker.add_theme_font_size_override("font_size", 15)
	marker.add_theme_color_override("font_color", Color(0.55, 0.9, 1.0) if is_next else Color(0.6, 0.65, 0.75))
	marker.position = Vector2(10, 0)
	marker.size = Vector2(20, 36)
	marker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(marker)

	var name_label := Label.new()
	name_label.text = intent.display_name
	name_label.add_theme_font_size_override("font_size", 15)
	name_label.add_theme_color_override("font_color", Color(0.95, 0.97, 1.0))
	name_label.position = Vector2(36, 0)
	name_label.size = Vector2(190, 36)
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(name_label)

	var effect_label := Label.new()
	var is_attack: bool = intent.intent_type == &"attack"
	effect_label.text = ("ATK %d" if is_attack else "DEF %d") % intent.amount
	effect_label.add_theme_font_size_override("font_size", 13)
	effect_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.98))
	var chip_style := StyleBoxFlat.new()
	chip_style.bg_color = Color(0.85, 0.18, 0.25, 0.92) if is_attack else Color(0.25, 0.5, 0.9, 0.92)
	chip_style.set_corner_radius_all(9)
	chip_style.content_margin_left = 8.0
	chip_style.content_margin_right = 8.0
	chip_style.content_margin_top = 1.0
	chip_style.content_margin_bottom = 1.0
	effect_label.add_theme_stylebox_override("normal", chip_style)
	effect_label.position = Vector2(252, 7)
	row.add_child(effect_label)

	if is_next:
		var next_tag := Label.new()
		next_tag.text = "NEXT"
		next_tag.add_theme_font_size_override("font_size", 10)
		next_tag.add_theme_color_override("font_color", Color(0.55, 0.9, 1.0))
		next_tag.position = Vector2(210, 10)
		row.add_child(next_tag)

	return row

func show_damage_popup(screen_position: Vector2, text: String, color: Color, font_size: int = 34):
	var popup := Label.new()
	popup.text = text
	popup.add_theme_font_size_override("font_size", font_size)
	popup.add_theme_color_override("font_color", color)
	popup.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	popup.add_theme_constant_override("outline_size", 7)
	popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup_layer.add_child(popup)
	popup.position = screen_position + Vector2(randf_range(-14.0, 14.0) - 30.0, -30.0)
	popup.scale = Vector2(0.6, 0.6)
	popup.pivot_offset = Vector2(30, 20)
	var tween := popup.create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(popup, "position:y", popup.position.y - 46.0, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(popup, "modulate:a", 0.0, 0.3).set_delay(0.4)
	tween.chain().tween_callback(popup.queue_free)
