extends Control

signal card_drag_started(index: int)
signal card_drag_moved(index: int, screen_position: Vector2)
signal card_dropped(index: int, screen_position: Vector2)

const DEFAULT_SETTINGS := preload("res://scenes/ui/cards/CardHandSettings.tres")
const NORMAL_MODULATE := Color.WHITE
const DISABLED_MODULATE := Color(0.58, 0.58, 0.58, 0.92)

var visual_root: Control
var art: TextureRect
var type_strip: ColorRect
var cost_label: Label
var name_label: Label
var keyword_label: Label
var type_label: Label
var body_label: Label
var click_area: Button

var card_index := -1
var is_disabled := false
var normal_z_index := 0
var hover_tween: Tween
var inactive_tween: Tween
var is_dragging := false
var is_targeting_mode := false
var drag_offset := Vector2.ZERO
var drag_start_global_position := Vector2.ZERO
var drag_start_rotation := 0.0
var inactive_offset := Vector2.ZERO
var rest_rotation_degrees := 0.0
var inspired_glow: Panel
var settings: CardHandSettings = DEFAULT_SETTINGS

func _ready():
	_bind_nodes()
	if not click_area.gui_input.is_connected(_on_click_area_gui_input):
		click_area.gui_input.connect(_on_click_area_gui_input)
	if not click_area.mouse_entered.is_connected(_on_mouse_entered):
		click_area.mouse_entered.connect(_on_mouse_entered)
	if not click_area.mouse_exited.is_connected(_on_mouse_exited):
		click_area.mouse_exited.connect(_on_mouse_exited)
	# Refit once in-tree, when label sizes are valid.
	_set_body_expanded(false)

func set_card(card: CardData, index: int, disabled: bool, hand_settings: CardHandSettings = DEFAULT_SETTINGS):
	_bind_nodes()
	card_index = index
	is_disabled = disabled
	settings = hand_settings
	_apply_type_style(card.card_type)
	var art_path := "res://assets/card/cardart_full/%s.png" % card.id
	art.texture = load(art_path) if ResourceLoader.exists(art_path) else null
	cost_label.text = str(card.cost)
	name_label.text = card.display_name
	keyword_label.text = _keyword_text(card)
	type_label.text = "[%s]" % _type_text(card.card_type)
	body_label.text = card.text
	click_area.disabled = disabled
	modulate = DISABLED_MODULATE if disabled else NORMAL_MODULATE
	# Small cards show the name only; the description appears when enlarged.
	_set_body_expanded(false)
	_reset_visual()

# Refits the name and description so text never spills past the card frame
# (font shrinks to fit its box). The description is always shown.
func _set_body_expanded(_expanded: bool):
	if body_label == null:
		return
	body_label.visible = true
	_fit_label(name_label, 13, 7)
	_fit_label(keyword_label, 10, 7)
	_fit_label(type_label, 10, 7)
	_fit_label(body_label, 11, 7)

func _fit_label(label: Label, max_size: int, min_size: int):
	if label == null or label.text.is_empty():
		return
	var font := label.get_theme_font(&"font")
	if font == null:
		return
	var avail := label.size
	if avail.x <= 1.0 or avail.y <= 1.0:
		label.add_theme_font_size_override("font_size", max_size)
		return
	for font_size in range(max_size, min_size - 1, -1):
		if font.get_multiline_string_size(label.text, HORIZONTAL_ALIGNMENT_CENTER, avail.x, font_size).y <= avail.y:
			label.add_theme_font_size_override("font_size", font_size)
			return
	label.add_theme_font_size_override("font_size", min_size)

func set_hand_order(order: int):
	normal_z_index = order
	z_index = normal_z_index

# Highlights a card whose inspiration (영감) is active and shows the reduced cost.
func set_inspired_state(is_inspired: bool, effective_cost: int):
	_bind_nodes()
	cost_label.text = str(effective_cost)
	if is_inspired:
		cost_label.add_theme_color_override("font_color", Color(0.55, 1.0, 0.85))
	else:
		cost_label.remove_theme_color_override("font_color")
	_ensure_inspired_glow()
	inspired_glow.visible = is_inspired

func _ensure_inspired_glow():
	if inspired_glow != null:
		return
	inspired_glow = Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.85, 0.4, 0.0)
	style.border_color = Color(1.0, 0.85, 0.4, 0.95)
	style.set_border_width_all(3)
	style.set_corner_radius_all(6)
	inspired_glow.add_theme_stylebox_override("panel", style)
	inspired_glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	inspired_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inspired_glow.visible = false
	visual_root.add_child(inspired_glow)

func set_rest_rotation(degrees: float):
	rest_rotation_degrees = degrees
	if not is_dragging:
		rotation_degrees = degrees

func set_inactive_offset(target_position: Vector2):
	if is_dragging:
		return
	inactive_offset = target_position
	if inactive_tween != null:
		inactive_tween.kill()
	inactive_tween = create_tween()
	inactive_tween.tween_property(visual_root, "position", inactive_offset, settings.tween_time)

func set_targeting_anchor(center_position: Vector2):
	if not is_dragging or is_targeting_mode:
		return
	is_targeting_mode = true
	z_as_relative = false
	z_index = 1000
	if hover_tween != null:
		hover_tween.kill()
	top_level = true
	rotation_degrees = 0.0
	global_position = center_position - size * 0.5
	visual_root.position = Vector2.ZERO
	visual_root.scale = Vector2.ONE

func _on_mouse_entered():
	if is_disabled or is_dragging or inactive_offset != Vector2.ZERO:
		return
	z_index = 100 + normal_z_index
	_tween_visual(inactive_offset + settings.hover_offset, settings.hover_scale, 0.0)
	_set_body_expanded(true)

func _on_mouse_exited():
	if is_dragging:
		return
	z_index = normal_z_index
	_tween_visual(inactive_offset, Vector2.ONE, rest_rotation_degrees)
	_set_body_expanded(false)

func _input(event: InputEvent):
	if not is_dragging:
		return
	if event is InputEventMouseMotion:
		if not is_targeting_mode:
			visual_root.global_position = event.position - drag_offset
		card_drag_moved.emit(card_index, event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		var drop_position: Vector2 = event.position
		_end_drag()
		card_dropped.emit(card_index, drop_position)

func _on_click_area_gui_input(event: InputEvent):
	if is_disabled:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_start_drag(get_global_mouse_position())

func _bind_nodes():
	if visual_root != null:
		return
	visual_root = %VisualRoot
	art = %ArtRect
	type_strip = %TypeStrip
	cost_label = %CostLabel
	name_label = %NameLabel
	keyword_label = %KeywordLabel
	type_label = %TypeLabel
	body_label = %BodyLabel
	click_area = %ClickArea

func _apply_type_style(card_type: StringName):
	var accent := Color(0.55, 0.95, 1.0, 1.0)
	match card_type:
		&"attack":
			accent = Color(1.0, 0.32, 0.24, 1.0)
		&"enhance":
			accent = Color(0.58, 1.0, 0.72, 1.0)
		_:
			accent = Color(0.48, 0.86, 1.0, 1.0)
	if type_strip != null:
		type_strip.color = accent
	if type_label != null:
		type_label.add_theme_color_override("font_color", accent.lightened(0.18))

func _type_text(card_type: StringName) -> String:
	match card_type:
		&"attack":
			return "공격"
		&"enhance":
			return "강화"
		_:
			return "기술"

func _keyword_text(card: CardData) -> String:
	var labels: Array[String] = []
	if not card.keywords.is_empty():
		for keyword in card.keywords:
			labels.append(String(keyword))
	if not card.inspiration.is_empty():
		labels.append("영감")
	if labels.is_empty():
		labels.append(_type_text(card.card_type))
	return " / ".join(labels)

func _tween_visual(target_position: Vector2, target_scale: Vector2, target_rotation: float):
	if hover_tween != null:
		hover_tween.kill()
	hover_tween = create_tween()
	hover_tween.set_parallel(true)
	hover_tween.tween_property(visual_root, "position", target_position, settings.tween_time)
	hover_tween.tween_property(visual_root, "scale", target_scale, settings.tween_time)
	hover_tween.tween_property(self, "rotation_degrees", target_rotation, settings.tween_time)

func _reset_visual():
	if hover_tween != null:
		hover_tween.kill()
	is_targeting_mode = false
	inactive_offset = Vector2.ZERO
	visual_root.position = Vector2.ZERO
	visual_root.scale = Vector2.ONE

func _start_drag(screen_position: Vector2):
	if hover_tween != null:
		hover_tween.kill()
	# Straighten the card upright before dragging so it scales up unrotated.
	drag_start_rotation = rest_rotation_degrees
	rotation_degrees = 0.0
	var grabbed_local_position: Vector2 = visual_root.get_global_transform().affine_inverse() * screen_position
	is_dragging = true
	is_targeting_mode = false
	z_as_relative = false
	z_index = 1000
	drag_start_global_position = visual_root.global_position
	visual_root.scale = settings.drag_scale
	var grabbed_screen_position: Vector2 = visual_root.get_global_transform() * grabbed_local_position
	visual_root.global_position += screen_position - grabbed_screen_position
	drag_offset = screen_position - visual_root.global_position
	_set_body_expanded(true)
	card_drag_started.emit(card_index)
	card_drag_moved.emit(card_index, screen_position)
	get_viewport().set_input_as_handled()

func _end_drag():
	is_dragging = false
	is_targeting_mode = false
	top_level = false
	rotation_degrees = drag_start_rotation
	z_as_relative = true
	z_index = normal_z_index
	visual_root.global_position = drag_start_global_position
	_reset_visual()
	_set_body_expanded(false)
