extends CanvasLayer

signal rp_skill_requested
signal rp_skill_cancelled
signal monster_info_close_requested

const HEROINE_PORTRAIT := preload("res://assets/characters/tsuki_portrait.png")
const RP_CUTIN_ART := preload("res://assets/card/cardart_full/tsuki_moon_slash.png")
const CARD_PREVIEW_SCENE := preload("res://scenes/ui/cards/CardViewLarge.tscn")
const PANEL_BG_COLOR := Color(0.05, 0.07, 0.11, 0.74)
const PANEL_BORDER_COLOR := Color(0.4, 0.65, 0.9, 0.4)
const HP_FILL_COLOR := Color(0.32, 0.85, 0.45)
const HP_FILL_LOW_COLOR := Color(0.95, 0.55, 0.2)
const HP_BACK_COLOR := Color(0.07, 0.1, 0.08, 0.9)
const EP_FILL_COLOR := Color(0.35, 0.75, 1.0)
const EP_EMPTY_COLOR := Color(0.16, 0.22, 0.3, 0.85)
const RP_READY_COLOR := Color(0.75, 0.92, 1.0)
const RP_AIM_COLOR := Color(0.35, 0.92, 1.0, 0.92)
const BLOCK_CHIP_COLOR := Color(0.3, 0.55, 0.95, 0.92)
const END_TURN_COLOR := Color(0.16, 0.42, 0.85)
const END_TURN_HOVER_COLOR := Color(0.24, 0.55, 1.0)
const END_TURN_DISABLED_COLOR := Color(0.2, 0.24, 0.3, 0.8)
const MONSTER_INFO_WIDTH := 420.0
const TOAST_LIFETIME := 2.4
const MAX_TOASTS := 4
const POPUP_STACK_WINDOW_MS := 450
const POPUP_STACK_BUCKET_SIZE := 48.0
const POPUP_STACK_OFFSETS := [
	Vector2(-34, -30),
	Vector2(18, -56),
	Vector2(-8, -82),
	Vector2(42, -38),
	Vector2(-48, -66),
]

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
var player_status_panel: Panel
var energy_value_label: Label
var energy_gauge_panel: Panel
var energy_segments: Array[Panel] = []
var energy_segment_container: VBoxContainer
var energy_max := 0
var rp_portrait_button: Button
var rp_cancel_button: Button
var rp_skill_card: Control
var rp_aim_layer: Control
var rp_pulse_tween: Tween
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
var recent_popup_slots: Dictionary = {}

func _ready():
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_player_panel()
	_build_energy_gauge()
	_build_rp_skill_controls()
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
	player_status_panel = %PlayerStatusPanel as Panel
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_BG_COLOR
	style.border_color = PANEL_BORDER_COLOR
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	player_status_panel.add_theme_stylebox_override("panel", style)
	player_status_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var portrait_frame := %PortraitFrame as Panel
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color(0.1, 0.13, 0.2, 0.95)
	frame_style.border_color = Color(0.55, 0.8, 1.0, 0.7)
	frame_style.set_border_width_all(2)
	frame_style.set_corner_radius_all(8)
	portrait_frame.add_theme_stylebox_override("panel", frame_style)
	portrait_frame.clip_contents = true
	portrait_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var portrait := %Portrait as TextureRect
	portrait.texture = HEROINE_PORTRAIT
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var name_label := %PlayerNameLabel as Label
	name_label.text = "츠키"
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.add_theme_color_override("font_color", Color(0.75, 0.88, 1.0, 0.95))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var hp_back := %PlayerHpBack as Panel
	var back_style := StyleBoxFlat.new()
	back_style.bg_color = HP_BACK_COLOR
	back_style.border_color = Color(0.6, 0.9, 0.7, 0.4)
	back_style.set_border_width_all(1)
	back_style.set_corner_radius_all(4)
	hp_back.add_theme_stylebox_override("panel", back_style)
	hp_back.mouse_filter = Control.MOUSE_FILTER_IGNORE

	player_hp_fill = %PlayerHpFill as Panel
	player_hp_fill_style = StyleBoxFlat.new()
	player_hp_fill_style.bg_color = HP_FILL_COLOR
	player_hp_fill_style.set_corner_radius_all(4)
	player_hp_fill.add_theme_stylebox_override("panel", player_hp_fill_style)
	player_hp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE

	player_hp_label = %PlayerHpLabel as Label
	player_hp_label.text = "0 / 0"
	player_hp_label.add_theme_font_size_override("font_size", 15)
	player_hp_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.98))
	player_hp_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	player_hp_label.add_theme_constant_override("outline_size", 4)
	player_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	player_hp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	player_block_label = %PlayerBlockLabel as Label
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
	player_block_label.visible = false
	player_block_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _build_energy_gauge():
	energy_gauge_panel = %EnergyGauge as Panel
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_BG_COLOR
	style.border_color = PANEL_BORDER_COLOR
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	energy_gauge_panel.add_theme_stylebox_override("panel", style)
	energy_gauge_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var ep_label := $UIRoot/EnergyGauge/EpLabel as Label
	ep_label.text = "RP"
	ep_label.add_theme_font_size_override("font_size", 14)
	ep_label.add_theme_color_override("font_color", Color(0.6, 0.85, 1.0, 0.9))
	ep_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ep_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var ep_caption := $UIRoot/EnergyGauge/EpCaption as Label
	ep_caption.text = "RAGE"
	ep_caption.add_theme_font_size_override("font_size", 9)
	ep_caption.add_theme_color_override("font_color", Color(0.55, 0.72, 0.9, 0.7))
	ep_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ep_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE

	energy_value_label = %EnergyValueLabel as Label
	energy_value_label.add_theme_font_size_override("font_size", 25)
	energy_value_label.add_theme_color_override("font_color", Color(0.75, 0.92, 1.0))
	energy_value_label.add_theme_color_override("font_outline_color", Color(0.05, 0.15, 0.35, 0.9))
	energy_value_label.add_theme_constant_override("outline_size", 5)
	energy_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	energy_value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	energy_segment_container = %EnergySegmentContainer as VBoxContainer
	energy_segment_container.add_theme_constant_override("separation", 2)
	energy_segment_container.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_rebuild_energy_segments(7)
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
		segment.custom_minimum_size = Vector2(40, 11)
		segment.mouse_filter = Control.MOUSE_FILTER_IGNORE
		energy_segment_container.add_child(segment)
		energy_segments.append(segment)

func _build_rp_skill_controls():
	rp_aim_layer = Control.new()
	rp_aim_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	rp_aim_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rp_aim_layer.z_index = 320
	ui_root.add_child(rp_aim_layer)

	rp_portrait_button = Button.new()
	rp_portrait_button.position = Vector2(120, 607)
	rp_portrait_button.size = Vector2(76, 76)
	rp_portrait_button.icon = HEROINE_PORTRAIT
	rp_portrait_button.expand_icon = true
	rp_portrait_button.tooltip_text = "MOON SLASH"
	rp_portrait_button.z_index = 520
	_style_rp_button(rp_portrait_button, false)
	rp_portrait_button.pressed.connect(func(): rp_skill_requested.emit())
	ui_root.add_child(rp_portrait_button)

	rp_cancel_button = Button.new()
	rp_cancel_button.position = rp_portrait_button.position
	rp_cancel_button.size = rp_portrait_button.size
	rp_cancel_button.text = "취소"
	rp_cancel_button.add_theme_font_size_override("font_size", 19)
	rp_cancel_button.z_index = 520
	_style_rp_button(rp_cancel_button, true)
	rp_cancel_button.visible = false
	rp_cancel_button.pressed.connect(func(): rp_skill_cancelled.emit())
	ui_root.add_child(rp_cancel_button)

	rp_skill_card = CARD_PREVIEW_SCENE.instantiate() as Control
	rp_skill_card.position = Vector2(205, 278)
	rp_skill_card.z_index = 510
	rp_skill_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rp_skill_card.visible = false
	ui_root.add_child(rp_skill_card)

func _style_rp_button(button: Button, is_cancel: bool):
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.22, 0.08, 0.09, 0.96) if is_cancel else Color(0.05, 0.12, 0.22, 0.96)
	normal.border_color = Color(1.0, 0.62, 0.5, 0.9) if is_cancel else Color(0.45, 0.86, 1.0, 0.9)
	normal.set_border_width_all(3)
	normal.set_corner_radius_all(12)
	button.add_theme_stylebox_override("normal", normal)
	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = normal.bg_color.lightened(0.12)
	button.add_theme_stylebox_override("hover", hover)
	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = normal.bg_color.darkened(0.15)
	button.add_theme_stylebox_override("pressed", pressed)
	var disabled: StyleBoxFlat = normal.duplicate()
	disabled.bg_color = Color(0.08, 0.1, 0.13, 0.88)
	disabled.border_color = Color(0.28, 0.34, 0.42, 0.65)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

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
	energy_orb_label = %EnergyOrbLabel as Label
	energy_orb_label.add_theme_font_size_override("font_size", 46)
	energy_orb_label.add_theme_color_override("font_color", Color(0.96, 0.99, 1.0))
	energy_orb_label.add_theme_color_override("font_outline_color", Color(0.06, 0.24, 0.5, 0.96))
	energy_orb_label.add_theme_constant_override("outline_size", 8)
	energy_orb_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	energy_orb_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	energy_orb_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	energy_orb_label.z_index = 500

func _build_hand_counter():
	hand_count_label = %HandCountLabel as Label
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
	hand_count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hand_count_label.z_index = 500

func _build_turn_chip():
	turn_chip_label = %TurnChipLabel as Label
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
	turn_chip_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

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
	deck_hand.position = Vector2(24, 390)
	deck_hand.scale = Vector2.ONE
	deck_tomb.position = Vector2(1172, 390)
	deck_tomb.scale = Vector2.ONE

# --- Runtime API ----------------------------------------------------------

func set_player_status(current_hp: int, max_hp: int, block: int):
	var safe_max: int = max(max_hp, 1)
	var safe_current: int = clamp(current_hp, 0, safe_max)
	player_hp_label.text = "%d / %d" % [safe_current, safe_max]
	var ratio := float(safe_current) / float(safe_max)
	var hp_back := player_hp_fill.get_parent() as Control
	var fill_size := Vector2(256.0, 22.0)
	if hp_back != null:
		fill_size = Vector2(max(hp_back.size.x - 2.0, 0.0), max(hp_back.size.y - 2.0, 0.0))
	player_hp_fill.size = Vector2(fill_size.x * ratio, fill_size.y)
	player_hp_fill_style.bg_color = HP_FILL_LOW_COLOR if ratio <= 0.3 else HP_FILL_COLOR
	player_block_label.visible = block > 0
	if block > 0:
		player_block_label.text = "DEF %d" % block

func set_rp_state(current_rp: float, max_rp: float, rp_cost: float, selected: bool, locked: bool):
	var segment_count: int = max(int(ceil(max_rp)), 1)
	if energy_segments.size() != segment_count:
		_rebuild_energy_segments(segment_count)
	for visual_index in range(energy_segments.size()):
		var logical_index := energy_segments.size() - 1 - visual_index
		var fill: float = clamp(current_rp - float(logical_index), 0.0, 1.0)
		var segment_style := energy_segments[visual_index].get_theme_stylebox("panel") as StyleBoxFlat
		if segment_style != null:
			segment_style.bg_color = EP_EMPTY_COLOR.lerp(EP_FILL_COLOR, fill)
	energy_value_label.text = "%s / %s" % [_format_rp(current_rp), _format_rp(max_rp)]

	var can_use := rp_cost > 0.0 and not locked and current_rp + 0.001 >= rp_cost
	var was_ready := not rp_portrait_button.disabled
	rp_portrait_button.visible = not selected
	rp_portrait_button.disabled = not can_use
	rp_cancel_button.visible = selected
	rp_cancel_button.disabled = locked
	rp_skill_card.visible = selected
	if can_use and not selected and (not was_ready or rp_pulse_tween == null or not rp_pulse_tween.is_valid()):
		_start_rp_ready_pulse()
	elif not can_use or selected:
		_stop_rp_ready_pulse()

func set_rp_skill_card(skill: Dictionary):
	if rp_skill_card == null:
		return
	var damage_percent := float(skill.get("DamagePercent", 0.0))
	var hit_count := int(skill.get("HitCount", 5))
	var rp_cost := float(skill.get("RpCost", 0.0))
	var card := CardData.new()
	card.id = String(skill.get("Id", "MoonSlash"))
	card.character = String(skill.get("Character", "Tsuki"))
	card.display_name = String(skill.get("DisplayName", "달빛 베기"))
	card.cost = int(round(rp_cost))
	card.card_type = &"rp"
	card.motion_animation = StringName(skill.get("MotionAnimation", "MoonSlash"))
	card.requires_target = true
	card.text = "모든 적에게 공격력 %s%% 피해를 %d회 줍니다." % [_format_rp(damage_percent), hit_count]
	card.keywords = []
	card.effects = [{
		"type": "damage",
		"target": "all_enemies",
		"DamagePercent": damage_percent,
		"HitCount": hit_count,
	}]
	rp_skill_card.call("set_card", card, card.cost)
	if rp_skill_card.has_method("set_cost_text"):
		rp_skill_card.call("set_cost_text", _format_rp(rp_cost))

func set_rp_targeting_positions(screen_positions: Array):
	set_aim_targeting_positions(screen_positions)

func set_card_targeting_position(screen_position: Vector2, is_targeted: bool):
	if is_targeted:
		set_aim_targeting_positions([screen_position])
	else:
		clear_rp_targeting()

func set_card_targeting_positions(screen_positions: Array):
	set_aim_targeting_positions(screen_positions)

func set_aim_targeting_positions(screen_positions: Array):
	clear_rp_targeting()
	if rp_aim_layer == null:
		return
	for screen_position in screen_positions:
		_add_aim_ring(Vector2(screen_position))

func _add_aim_ring(screen_position: Vector2):
	var ring := Panel.new()
	var diameter := 132.0
	ring.position = screen_position - Vector2.ONE * diameter * 0.5
	ring.size = Vector2.ONE * diameter
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.65, 1.0, 0.08)
	style.border_color = RP_AIM_COLOR
	style.set_border_width_all(4)
	style.set_corner_radius_all(int(diameter * 0.5))
	ring.add_theme_stylebox_override("panel", style)
	ring.pivot_offset = ring.size * 0.5
	rp_aim_layer.add_child(ring)

	var tween := ring.create_tween()
	tween.set_loops()
	tween.tween_property(ring, "scale", Vector2(1.08, 1.08), 0.42).set_trans(Tween.TRANS_SINE)
	tween.tween_property(ring, "scale", Vector2.ONE, 0.42).set_trans(Tween.TRANS_SINE)

func clear_rp_targeting():
	if rp_aim_layer == null:
		return
	for child in rp_aim_layer.get_children():
		child.free()

func play_rp_cutin(hold_seconds: float = 1.0):
	var viewport_size := get_viewport().get_visible_rect().size
	var cutin_root := Control.new()
	cutin_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	cutin_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cutin_root.z_index = 1400
	ui_root.add_child(cutin_root)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.01, 0.02, 0.05, 0.0)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cutin_root.add_child(dim)

	var frame := Panel.new()
	var cutin_width: float = min(440.0, viewport_size.x * 0.38)
	frame.size = Vector2(cutin_width, viewport_size.y - 76.0)
	var cutin_visible_position := Vector2(28.0, 38.0)
	frame.position = Vector2(cutin_visible_position.x, viewport_size.y + 30.0)
	frame.clip_contents = true
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color(0.03, 0.08, 0.16, 0.96)
	frame_style.border_color = Color(0.62, 0.92, 1.0, 0.96)
	frame_style.border_width_right = 4
	frame_style.border_width_top = 2
	frame_style.border_width_bottom = 2
	frame_style.set_corner_radius_all(12)
	frame.add_theme_stylebox_override("panel", frame_style)
	cutin_root.add_child(frame)

	var portrait := TextureRect.new()
	portrait.texture = RP_CUTIN_ART
	var portrait_area: Vector2 = frame.size - Vector2(12, 12)
	var portrait_source_size := Vector2(RP_CUTIN_ART.get_width(), RP_CUTIN_ART.get_height())
	var portrait_scale: float = min(
		portrait_area.x / portrait_source_size.x,
		portrait_area.y / portrait_source_size.y
	)
	portrait.size = portrait_source_size * portrait_scale
	portrait.position = (frame.size - portrait.size) * 0.5
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_SCALE
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(portrait)

	var title := Label.new()
	title.text = "MOON SLASH"
	title.position = Vector2(18, frame.size.y - 76)
	title.size = Vector2(frame.size.x - 36, 52)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.88, 0.98, 1.0))
	title.add_theme_color_override("font_outline_color", Color(0.02, 0.06, 0.12, 0.96))
	title.add_theme_constant_override("outline_size", 7)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(title)

	var enter_tween := create_tween()
	enter_tween.set_parallel(true)
	enter_tween.tween_property(frame, "position", cutin_visible_position, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	enter_tween.tween_property(dim, "color:a", 0.45, 0.26)
	await enter_tween.finished
	await get_tree().create_timer(max(hold_seconds, 0.0)).timeout

	var exit_tween := create_tween()
	exit_tween.set_parallel(true)
	exit_tween.tween_property(frame, "position:y", -frame.size.y - 30.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	exit_tween.tween_property(dim, "color:a", 0.0, 0.3)
	await exit_tween.finished
	cutin_root.queue_free()

func _format_rp(value: float) -> String:
	if is_equal_approx(value, round(value)):
		return str(int(round(value)))
	return ("%.2f" % value).trim_suffix("0")

func _start_rp_ready_pulse():
	_stop_rp_ready_pulse()
	if rp_portrait_button == null:
		return
	rp_portrait_button.pivot_offset = rp_portrait_button.size * 0.5
	rp_portrait_button.modulate = RP_READY_COLOR
	rp_pulse_tween = create_tween()
	rp_pulse_tween.set_loops()
	rp_pulse_tween.tween_property(rp_portrait_button, "scale", Vector2(1.08, 1.08), 0.5).set_trans(Tween.TRANS_SINE)
	rp_pulse_tween.tween_property(rp_portrait_button, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_SINE)

func _stop_rp_ready_pulse():
	if rp_pulse_tween != null and rp_pulse_tween.is_valid():
		rp_pulse_tween.kill()
	rp_pulse_tween = null
	if rp_portrait_button != null:
		rp_portrait_button.scale = Vector2.ONE
		rp_portrait_button.modulate = Color.WHITE

func set_route_selection_mode(enabled: bool):
	if player_status_panel != null:
		player_status_panel.visible = true
	if energy_gauge_panel != null:
		energy_gauge_panel.visible = not enabled
	if deck_hand != null:
		deck_hand.visible = not enabled
	if deck_tomb != null:
		deck_tomb.visible = not enabled
	if hand_container != null:
		hand_container.visible = not enabled
	if targeting_dot != null:
		targeting_dot.visible = false
	if end_turn_button != null:
		end_turn_button.visible = not enabled
	if restart_button != null:
		if enabled:
			restart_button.visible = false
	if energy_orb_label != null:
		energy_orb_label.visible = not enabled
	if hand_rail != null:
		hand_rail.visible = not enabled
	if hand_count_label != null:
		hand_count_label.visible = not enabled
	if turn_chip_label != null:
		turn_chip_label.visible = not enabled
	if toast_container != null:
		toast_container.visible = not enabled
	if monster_info_panel != null:
		monster_info_panel.visible = false
	if rp_portrait_button != null:
		rp_portrait_button.visible = not enabled
	if rp_cancel_button != null:
		rp_cancel_button.visible = false
	if rp_skill_card != null:
		rp_skill_card.visible = false
	clear_rp_targeting()

# Card-play energy is shown as the bottom-center number. The left RP gauge is
# driven independently through set_rp_state().
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

func show_monster_info(monster_name: String, intents: Array, next_intent_index: int, action_count_remaining: int = 0, attack: int = 0):
	_ensure_monster_info_panel()
	monster_info_name_label.text = monster_name
	monster_info_count_label.text = "행동 카운트 %d회 후 발동" % max(action_count_remaining, 0)
	for child in monster_info_rows.get_children():
		child.free()
	if not intents.is_empty():
		var intent_index: int = clamp(next_intent_index, 0, intents.size() - 1)
		monster_info_rows.add_child(_make_intent_row(intents[intent_index], intent_index, true, attack))
	monster_info_panel.size = Vector2(MONSTER_INFO_WIDTH, 188)
	monster_info_panel.visible = true
	monster_info_panel.modulate = Color(1, 1, 1, 0)
	var tween := monster_info_panel.create_tween()
	tween.tween_property(monster_info_panel, "modulate:a", 1.0, 0.12)

func hide_monster_info():
	if monster_info_panel != null:
		monster_info_panel.visible = false

func is_monster_info_visible() -> bool:
	return monster_info_panel != null and monster_info_panel.visible

func is_monster_info_point_inside(screen_position: Vector2) -> bool:
	return is_monster_info_visible() and monster_info_panel.get_global_rect().has_point(screen_position)

func _ensure_monster_info_panel():
	if monster_info_panel != null:
		return
	monster_info_panel = Panel.new()
	monster_info_panel.name = "MonsterInfoPanel"
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.025, 0.03, 0.9)
	style.border_color = Color(0.88, 0.92, 1.0, 0.38)
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	monster_info_panel.add_theme_stylebox_override("panel", style)
	monster_info_panel.position = Vector2(0, 76)
	monster_info_panel.size = Vector2(MONSTER_INFO_WIDTH, 320)
	monster_info_panel.z_index = 700
	monster_info_panel.visible = false
	ui_root.add_child(monster_info_panel)

	monster_info_name_label = Label.new()
	monster_info_name_label.add_theme_font_size_override("font_size", 24)
	monster_info_name_label.add_theme_color_override("font_color", Color(0.96, 0.96, 1.0))
	monster_info_name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	monster_info_name_label.add_theme_constant_override("outline_size", 4)
	monster_info_name_label.position = Vector2(28, 16)
	monster_info_name_label.size = Vector2(286, 32)
	monster_info_panel.add_child(monster_info_name_label)

	var subtitle := Label.new()
	subtitle.text = "행동 예고"
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color(0.74, 0.84, 1.0, 0.9))
	subtitle.position = Vector2(28, 50)
	subtitle.size = Vector2(120, 24)
	monster_info_panel.add_child(subtitle)

	monster_info_count_label = Label.new()
	monster_info_count_label.add_theme_font_size_override("font_size", 15)
	monster_info_count_label.add_theme_color_override("font_color", Color(1.0, 0.42, 0.66))
	monster_info_count_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.78))
	monster_info_count_label.add_theme_constant_override("outline_size", 3)
	monster_info_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	monster_info_count_label.position = Vector2(168, 50)
	monster_info_count_label.size = Vector2(214, 24)
	monster_info_panel.add_child(monster_info_count_label)

	var close_button := Button.new()
	close_button.text = "×"
	close_button.add_theme_font_size_override("font_size", 15)
	close_button.flat = true
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.position = Vector2(378, 12)
	close_button.size = Vector2(30, 30)
	close_button.pressed.connect(func(): monster_info_close_requested.emit())
	monster_info_panel.add_child(close_button)

	monster_info_rows = VBoxContainer.new()
	monster_info_rows.position = Vector2(28, 84)
	monster_info_rows.size = Vector2(MONSTER_INFO_WIDTH - 56.0, 220)
	monster_info_rows.add_theme_constant_override("separation", 10)
	monster_info_panel.add_child(monster_info_rows)

func _make_intent_row(intent: EnemyIntentData, order: int, is_next: bool, attack: int = 0) -> Panel:
	var row := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.13, 0.14, 0.16, 0.88) if is_next else Color(0.04, 0.045, 0.052, 0.68)
	style.border_color = Color(0.95, 0.95, 1.0, 0.62) if is_next else Color(0.72, 0.76, 0.82, 0.34)
	style.border_width_top = 1
	style.border_width_bottom = 1
	row.add_theme_stylebox_override("panel", style)
	var row_height := 92.0 if is_next else 66.0
	row.custom_minimum_size = Vector2(MONSTER_INFO_WIDTH - 56.0, row_height)

	var marker := Label.new()
	marker.text = "◆" if is_next else str(order + 1)
	marker.add_theme_font_size_override("font_size", 20)
	marker.add_theme_color_override("font_color", Color(1.0, 0.36, 0.68) if is_next else Color(0.6, 0.65, 0.75))
	marker.position = Vector2(10, 0)
	marker.size = Vector2(28, row_height)
	marker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(marker)

	var icon := IntentIcon.new()
	icon.position = Vector2(44, 27) if is_next else Vector2(44, 18)
	icon.size = Vector2(38, 38) if is_next else Vector2(30, 30)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)

	var name_label := Label.new()
	name_label.text = intent.display_name
	name_label.add_theme_font_size_override("font_size", 22 if is_next else 17)
	name_label.add_theme_color_override("font_color", Color(0.95, 0.97, 1.0))
	name_label.position = Vector2(96, 16) if is_next else Vector2(86, 7)
	name_label.size = Vector2(194, 30) if is_next else Vector2(174, 24)
	row.add_child(name_label)

	var effect_label := Label.new()
	var is_attack: bool = intent.intent_type == &"attack"
	var is_block: bool = intent.intent_type == &"block" or intent.intent_type == &"defense"
	if is_attack:
		effect_label.text = "피해 %d%% (%d)" % [intent.amount, int(round(attack * float(intent.amount) / 100.0))]
	elif is_block:
		effect_label.text = "방어 %d" % intent.amount
	else:
		effect_label.text = "기술 %d" % intent.amount
	var icon_kind := IntentIcon.Kind.SWORD if is_attack else (IntentIcon.Kind.SHIELD if is_block else IntentIcon.Kind.SKILL)
	icon.set_icon(icon_kind, Color(1, 1, 1, 0.98))
	effect_label.add_theme_font_size_override("font_size", 16 if is_next else 13)
	effect_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.98))
	var chip_style := StyleBoxFlat.new()
	chip_style.bg_color = Color(0.85, 0.18, 0.25, 0.92) if is_attack else (Color(0.25, 0.5, 0.9, 0.92) if is_block else Color(0.55, 0.32, 0.9, 0.92))
	chip_style.set_corner_radius_all(9)
	chip_style.content_margin_left = 8.0
	chip_style.content_margin_right = 8.0
	chip_style.content_margin_top = 1.0
	chip_style.content_margin_bottom = 1.0
	effect_label.add_theme_stylebox_override("normal", chip_style)
	effect_label.position = Vector2(96, 54) if is_next else Vector2(86, 34)
	row.add_child(effect_label)

	if is_next:
		var next_tag := Label.new()
		next_tag.text = "NEXT"
		next_tag.add_theme_font_size_override("font_size", 11)
		next_tag.add_theme_color_override("font_color", Color(1.0, 0.42, 0.66))
		next_tag.position = Vector2(300, 10)
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
	popup.position = _popup_start_position(screen_position)
	popup.scale = Vector2(0.6, 0.6)
	popup.pivot_offset = Vector2(30, 20)
	var tween := popup.create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(popup, "position:y", popup.position.y - 46.0, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(popup, "modulate:a", 0.0, 0.3).set_delay(0.4)
	tween.chain().tween_callback(popup.queue_free)

func _popup_start_position(screen_position: Vector2) -> Vector2:
	var bucket := "%d:%d" % [
		int(round(screen_position.x / POPUP_STACK_BUCKET_SIZE)),
		int(round(screen_position.y / POPUP_STACK_BUCKET_SIZE)),
	]
	var now := Time.get_ticks_msec()
	var slot := 0
	if recent_popup_slots.has(bucket):
		var previous: Dictionary = recent_popup_slots[bucket]
		if now - int(previous.get("time", 0)) <= POPUP_STACK_WINDOW_MS:
			slot = int(previous.get("slot", 0)) + 1
	recent_popup_slots[bucket] = {
		"time": now,
		"slot": slot,
	}
	_prune_popup_slots(now)
	var offset: Vector2 = POPUP_STACK_OFFSETS[slot % POPUP_STACK_OFFSETS.size()]
	return screen_position + offset + Vector2(randf_range(-6.0, 6.0), randf_range(-4.0, 4.0))

func _prune_popup_slots(now: int):
	for bucket in recent_popup_slots.keys():
		var previous: Dictionary = recent_popup_slots[bucket]
		if now - int(previous.get("time", 0)) > POPUP_STACK_WINDOW_MS:
			recent_popup_slots.erase(bucket)
