extends CanvasLayer

signal node_selected(node_id: String)

class MiniMapView:
	extends Control

	const NODE_ATLAS := preload("res://assets/ui/ui_map.png")
	const NODE_RADIUS := 11.0
	const CURRENT_RADIUS := 14.0

	var map_nodes: Array = []
	var current_node_id := ""
	var completed_nodes: Dictionary = {}
	var selectable_ids: Array = []

	func setup(nodes: Array, current_id: String, completed: Dictionary, selectable: Array):
		map_nodes = nodes
		current_node_id = current_id
		completed_nodes = completed
		selectable_ids = selectable
		queue_redraw()

	func _draw():
		var panel_rect := Rect2(Vector2.ZERO, size)
		draw_rect(panel_rect, Color(0.025, 0.055, 0.075, 0.82), true)
		_draw_grid()
		for node_data in map_nodes:
			var from_id := String(node_data["id"])
			var from_pos := _map_position(node_data["pos"])
			for next_id in node_data["next"]:
				var to_data := _find_node(String(next_id))
				if to_data.is_empty():
					continue
				var to_pos := _map_position(to_data["pos"])
				var is_open := completed_nodes.has(from_id) or from_id == current_node_id
				draw_line(from_pos, to_pos, Color(0.55, 0.9, 1.0, 0.62) if is_open else Color(0.38, 0.46, 0.52, 0.38), 2.8, true)
		for node_data in map_nodes:
			_draw_node(node_data)
		draw_rect(panel_rect, Color(0.42, 0.82, 1.0, 0.62), false, 1.5)

	func _draw_grid():
		var step := 34.0
		var grid_color := Color(0.38, 0.78, 0.95, 0.18)
		var offset := -size.y
		while offset < size.x + size.y:
			draw_line(Vector2(offset, 0), Vector2(offset + size.y, size.y), grid_color, 1.0)
			draw_line(Vector2(offset, size.y), Vector2(offset + size.y, 0), grid_color, 1.0)
			offset += step
		var current_data := _find_node(current_node_id)
		if not current_data.is_empty():
			var current_pos := _map_position(current_data["pos"])
			draw_rect(Rect2(Vector2(max(current_pos.x - 30.0, 0.0), 0), Vector2(60.0, size.y)), Color(0.25, 0.78, 1.0, 0.08), true)

	func _draw_node(node_data: Dictionary):
		var node_id := String(node_data["id"])
		var node_type := String(node_data["type"])
		var pos := _map_position(node_data["pos"])
		var radius := CURRENT_RADIUS if node_id == current_node_id else NODE_RADIUS
		var fill := _type_color(node_type)
		if node_id == current_node_id:
			fill = Color(0.7, 1.0, 1.0)
		elif completed_nodes.has(node_id):
			fill = Color(0.5, 0.9, 0.68)
		elif not (node_id in selectable_ids):
			fill = Color(0.3, 0.34, 0.39)
		if node_id == current_node_id or node_id in selectable_ids:
			draw_circle(pos, radius * 2.0, Color(fill.r, fill.g, fill.b, 0.18))
		draw_circle(pos, radius * 1.35, Color(0.02, 0.05, 0.065, 0.82))
		draw_circle(pos, radius * 1.42, fill, false, 1.2)
		var icon_size: Vector2 = Vector2(36, 36) if node_id == current_node_id else Vector2(30, 30)
		var icon_rect: Rect2 = _fit_icon_rect(_get_icon_region(node_type).size, Rect2(pos - icon_size * 0.5, icon_size))
		draw_texture_rect_region(NODE_ATLAS, icon_rect, _get_icon_region(node_type), Color(0.92, 0.98, 1.0, 0.98))
		if node_id == current_node_id:
			draw_circle(pos, 3.0, Color(0.03, 0.12, 0.16, 0.95))

	func _map_position(source: Vector2) -> Vector2:
		var min_pos := Vector2(80, 180)
		var max_pos := Vector2(1160, 520)
		var usable := size - Vector2(28, 24)
		var ratio := Vector2(
			inverse_lerp(min_pos.x, max_pos.x, source.x),
			inverse_lerp(min_pos.y, max_pos.y, source.y)
		)
		return Vector2(14, 12) + Vector2(ratio.x * usable.x, ratio.y * usable.y)

	func _find_node(node_id: String) -> Dictionary:
		for node_data in map_nodes:
			if String(node_data["id"]) == node_id:
				return node_data
		return {}

	func _fit_icon_rect(source_size: Vector2, bounds: Rect2) -> Rect2:
		if source_size.x <= 0.0 or source_size.y <= 0.0:
			return bounds
		var scale: float = min(bounds.size.x / source_size.x, bounds.size.y / source_size.y)
		var draw_size: Vector2 = source_size * scale
		return Rect2(bounds.position + (bounds.size - draw_size) * 0.5, draw_size)

	func _type_color(node_type: String) -> Color:
		match node_type:
			"base_camp":
				return Color(0.55, 0.96, 1.0)
			"battle":
				return Color(0.95, 0.22, 0.38)
			"elite":
				return Color(0.9, 0.58, 0.18)
			"boss":
				return Color(0.72, 0.25, 1.0)
			"event":
				return Color(0.42, 0.8, 0.95)
			"treasure":
				return Color(1.0, 0.72, 0.24)
			"rest":
				return Color(0.42, 0.9, 0.62)
			_:
				return Color(0.62, 0.72, 0.86)

	func _get_icon_region(node_type: String) -> Rect2:
		match node_type:
			"battle":
				return Rect2(78, 54, 190, 246)
			"elite":
				return Rect2(442, 54, 190, 246)
			"boss":
				return Rect2(720, 0, 340, 355)
			"treasure":
				return Rect2(1166, 54, 194, 222)
			"event":
				return Rect2(798, 408, 190, 244)
			"rest":
				return Rect2(1088, 420, 322, 196)
			"base_camp":
				return Rect2(444, 408, 190, 244)
			_:
				return Rect2(444, 408, 190, 244)

const BattleMapOverlayRoute := preload("res://scripts/map/map_route_data.gd")
const MAP_ATLAS := preload("res://assets/ui/ui_map.png")
const MAX_CHOICES := 3

var ui_root: Control
var scrim: ColorRect
var minimap_panel: Panel
var minimap_view: MiniMapView
var status_label: Label
var choice_container: VBoxContainer
var expanded_map: Panel
var expanded_map_view: MiniMapView
var expand_button: Button
var current_node_id := ""
var notice_text := ""
var is_committing_choice := false

func _ready():
	layer = 20
	_build_ui()
	visible = false

func show_for_run(message := ""):
	notice_text = message
	is_committing_choice = false
	visible = true
	_refresh()
	_play_appear()

func _run_state() -> Node:
	return get_node_or_null("/root/RunState")

func _build_ui():
	ui_root = Control.new()
	ui_root.name = "UIRoot"
	ui_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(ui_root)

	scrim = ColorRect.new()
	scrim.name = "Scrim"
	scrim.color = Color(0.01, 0.015, 0.025, 0.28)
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(scrim)

	_build_minimap_panel()
	_build_choice_panel()
	_build_expanded_map()

func _build_minimap_panel():
	minimap_panel = Panel.new()
	minimap_panel.name = "MiniMapPanel"
	minimap_panel.position = Vector2(18, 466)
	minimap_panel.size = Vector2(372, 222)
	minimap_panel.z_index = 20
	minimap_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.04, 0.08, 0.11, 0.82), Color(0.38, 0.86, 1.0, 0.62), 8))
	ui_root.add_child(minimap_panel)

	var title := Label.new()
	title.text = "ROUTE"
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", Color(0.72, 0.9, 1.0, 0.95))
	title.position = Vector2(14, 8)
	title.size = Vector2(120, 20)
	minimap_panel.add_child(title)

	expand_button = Button.new()
	expand_button.text = "+"
	expand_button.focus_mode = Control.FOCUS_NONE
	expand_button.position = Vector2(334, 8)
	expand_button.size = Vector2(24, 24)
	expand_button.pressed.connect(_on_expand_pressed)
	minimap_panel.add_child(expand_button)

	minimap_view = MiniMapView.new()
	minimap_view.position = Vector2(14, 34)
	minimap_view.size = Vector2(344, 142)
	minimap_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	minimap_panel.add_child(minimap_view)

	status_label = Label.new()
	status_label.add_theme_font_size_override("font_size", 13)
	status_label.add_theme_color_override("font_color", Color(0.9, 0.96, 1.0, 0.92))
	status_label.position = Vector2(14, 184)
	status_label.size = Vector2(344, 26)
	minimap_panel.add_child(status_label)

func _build_choice_panel():
	var panel := Panel.new()
	panel.name = "ChoicePanel"
	panel.position = Vector2(744, 64)
	panel.size = Vector2(510, 590)
	panel.z_index = 30
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.02, 0.026, 0.038, 0.18), Color(0.45, 0.76, 0.92, 0.0), 4))
	ui_root.add_child(panel)

	var title := Label.new()
	title.text = "NEXT ROUTE"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.9, 0.97, 1.0))
	title.add_theme_color_override("font_outline_color", Color(0.02, 0.05, 0.08, 0.92))
	title.add_theme_constant_override("outline_size", 5)
	title.position = Vector2(42, 16)
	title.size = Vector2(280, 36)
	panel.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Choose one connected node."
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.82, 0.92, 0.9))
	subtitle.position = Vector2(44, 52)
	subtitle.size = Vector2(280, 22)
	panel.add_child(subtitle)

	choice_container = VBoxContainer.new()
	choice_container.position = Vector2(36, 96)
	choice_container.size = Vector2(450, 464)
	choice_container.add_theme_constant_override("separation", 28)
	panel.add_child(choice_container)

func _build_expanded_map():
	expanded_map = Panel.new()
	expanded_map.name = "ExpandedMap"
	expanded_map.visible = false
	expanded_map.position = Vector2(170, 98)
	expanded_map.size = Vector2(640, 390)
	expanded_map.z_index = 80
	expanded_map.add_theme_stylebox_override("panel", _panel_style(Color(0.035, 0.065, 0.085, 0.95), Color(0.5, 0.9, 1.0, 0.72), 8))
	ui_root.add_child(expanded_map)

	var title := Label.new()
	title.text = "ROUTE MAP"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.86, 0.96, 1.0))
	title.position = Vector2(22, 16)
	title.size = Vector2(220, 30)
	expanded_map.add_child(title)

	var close_button := Button.new()
	close_button.text = "X"
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.position = Vector2(590, 14)
	close_button.size = Vector2(32, 32)
	close_button.pressed.connect(func(): expanded_map.visible = false)
	expanded_map.add_child(close_button)

	expanded_map_view = MiniMapView.new()
	expanded_map_view.position = Vector2(22, 58)
	expanded_map_view.size = Vector2(596, 302)
	expanded_map_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	expanded_map.add_child(expanded_map_view)

func _refresh():
	var run_state := _run_state()
	if run_state == null:
		return
	current_node_id = String(run_state.current_node_id)
	var nodes := BattleMapOverlayRoute.get_nodes()
	var next_nodes := BattleMapOverlayRoute.get_next_nodes(current_node_id)
	var selectable_ids: Array = []
	for node_data in next_nodes:
		selectable_ids.append(String(node_data["id"]))
	minimap_view.setup(nodes, current_node_id, run_state.completed_nodes, selectable_ids)
	expanded_map_view.setup(nodes, current_node_id, run_state.completed_nodes, selectable_ids)
	status_label.text = _status_text(run_state, next_nodes.size())
	_rebuild_choices(next_nodes)

func _status_text(run_state: Node, choice_count: int) -> String:
	if not notice_text.is_empty():
		return notice_text
	if run_state.run_cleared:
		return "Run cleared. Prototype route complete."
	return "HP %d/%d   Gold %d   Paths %d" % [run_state.current_hp, run_state.max_hp, run_state.gold, choice_count]

func _rebuild_choices(next_nodes: Array):
	for child in choice_container.get_children():
		child.queue_free()
	if next_nodes.is_empty():
		choice_container.add_child(_make_route_done_label())
		return
	for i in range(min(next_nodes.size(), MAX_CHOICES)):
		choice_container.add_child(_make_choice_card(next_nodes[i], i))

func _make_route_done_label() -> Label:
	var label := Label.new()
	label.text = "No connected route remains."
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0, 0.9))
	label.custom_minimum_size = Vector2(360, 64)
	return label

func _make_choice_card(node_data: Dictionary, order: int) -> Button:
	var node_id := String(node_data["id"])
	var node_type := String(node_data["type"])
	var accent := BattleMapOverlayRoute.get_type_color(node_type)
	var button := Button.new()
	button.name = "Choice_%s" % node_id
	button.custom_minimum_size = Vector2(450, 118)
	button.focus_mode = Control.FOCUS_NONE
	button.text = ""
	button.clip_contents = false
	button.add_theme_stylebox_override("normal", _panel_style(Color(0.025, 0.045, 0.055, 0.68), Color(accent.r, accent.g, accent.b, 0.38), 6))
	button.add_theme_stylebox_override("hover", _panel_style(Color(0.055, 0.09, 0.105, 0.82), Color(accent.r, accent.g, accent.b, 0.82), 6))
	button.add_theme_stylebox_override("pressed", _panel_style(Color(0.02, 0.05, 0.07, 0.92), accent.darkened(0.15), 6))
	button.pressed.connect(func(): _commit_choice(node_id, button))

	var icon_back := Panel.new()
	icon_back.position = Vector2(18, 16)
	icon_back.size = Vector2(86, 86)
	icon_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_back.add_theme_stylebox_override("panel", _panel_style(Color(0.02, 0.035, 0.045, 0.78), Color(accent.r, accent.g, accent.b, 0.62), 6))
	button.add_child(icon_back)

	var icon := TextureRect.new()
	icon.texture = _make_node_texture(node_type)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	icon.position = Vector2(24, 22)
	icon.size = Vector2(74, 74)
	icon.modulate = Color(0.95, 1.0, 1.0, 0.98)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(icon)

	var index_label := Label.new()
	index_label.text = "0%d" % (order + 1)
	index_label.add_theme_font_size_override("font_size", 13)
	index_label.add_theme_color_override("font_color", Color(0.75, 0.9, 1.0, 0.78))
	index_label.position = Vector2(122, 18)
	index_label.size = Vector2(42, 24)
	index_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(index_label)

	var type_label := Label.new()
	type_label.text = BattleMapOverlayRoute.get_type_title(node_type)
	type_label.add_theme_font_size_override("font_size", 13)
	type_label.add_theme_color_override("font_color", accent.lightened(0.25))
	type_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.75))
	type_label.add_theme_constant_override("outline_size", 3)
	type_label.position = Vector2(168, 18)
	type_label.size = Vector2(180, 22)
	type_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(type_label)

	var name_label := Label.new()
	name_label.text = String(node_data.get("label", "Node"))
	name_label.add_theme_font_size_override("font_size", 25)
	name_label.add_theme_color_override("font_color", Color(0.96, 0.99, 1.0))
	name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.72))
	name_label.add_theme_constant_override("outline_size", 4)
	name_label.position = Vector2(122, 42)
	name_label.size = Vector2(286, 34)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(name_label)

	var body_label := Label.new()
	body_label.text = BattleMapOverlayRoute.get_type_description(node_type)
	body_label.add_theme_font_size_override("font_size", 12)
	body_label.add_theme_color_override("font_color", Color(0.77, 0.86, 0.92, 0.92))
	body_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.62))
	body_label.add_theme_constant_override("outline_size", 3)
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.position = Vector2(122, 78)
	body_label.size = Vector2(286, 34)
	body_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(body_label)
	return button

func _make_node_texture(node_type: String) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = MAP_ATLAS
	texture.region = _get_icon_region(node_type)
	return texture

func _get_icon_region(node_type: String) -> Rect2:
	match node_type:
		"battle":
			return Rect2(78, 54, 190, 246)
		"elite":
			return Rect2(442, 54, 190, 246)
		"boss":
			return Rect2(720, 0, 340, 355)
		"treasure":
			return Rect2(1166, 54, 194, 222)
		"event":
			return Rect2(798, 408, 190, 244)
		"rest":
			return Rect2(1088, 420, 322, 196)
		"base_camp":
			return Rect2(444, 408, 190, 244)
		_:
			return Rect2(444, 408, 190, 244)

func _panel_style(fill: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 0.0
	style.content_margin_right = 0.0
	style.content_margin_top = 0.0
	style.content_margin_bottom = 0.0
	return style

func _play_appear():
	ui_root.modulate = Color(1, 1, 1, 0)
	var tween := create_tween()
	tween.tween_property(ui_root, "modulate:a", 1.0, 0.18)

func _on_expand_pressed():
	expanded_map.visible = not expanded_map.visible
	if expanded_map.visible:
		expanded_map_view.queue_redraw()

func _commit_choice(node_id: String, button: Button):
	if is_committing_choice:
		return
	is_committing_choice = true
	_set_choice_buttons_disabled(true)
	expanded_map.visible = false
	button.z_index = 100
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(button, "scale", Vector2(1.06, 1.06), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "modulate", Color(1.35, 1.25, 0.75, 1.0), 0.16)
	tween.set_parallel(false)
	tween.tween_interval(0.18)
	tween.tween_property(ui_root, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func():
		visible = false
		node_selected.emit(node_id)
	)

func _set_choice_buttons_disabled(disabled: bool):
	for child in choice_container.get_children():
		if child is Button:
			child.disabled = disabled
