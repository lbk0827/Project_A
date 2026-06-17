@tool
extends Control

const INGAME_SCENE_PATH := "res://scenes/core/ingame/ingame.tscn"
const MAP_ATLAS := preload("res://assets/ui/UIMap.png")
const NODE_SIZE := Vector2(86, 86)
const BOSS_NODE_SIZE := Vector2(108, 108)
const SELECTABLE_COLOR := Color(1.0, 0.92, 0.52, 1.0)
const COMPLETED_COLOR := Color(0.52, 0.85, 0.72, 1.0)
const LOCKED_COLOR := Color(0.28, 0.3, 0.34, 0.58)
const CURRENT_COLOR := Color(0.55, 0.95, 1.0, 1.0)
const EDGE_COLOR := Color(0.36, 0.82, 0.9, 0.58)
const EDGE_LOCKED_COLOR := Color(0.36, 0.42, 0.48, 0.34)

var map_nodes := [
	{"id": "start", "type": "start", "label": "Start", "pos": Vector2(120, 360), "next": ["battle_1", "event_1"]},
	{"id": "battle_1", "type": "battle", "label": "Battle", "pos": Vector2(310, 255), "next": ["treasure_1", "battle_2"]},
	{"id": "event_1", "type": "event", "label": "Event", "pos": Vector2(310, 465), "next": ["battle_2"]},
	{"id": "treasure_1", "type": "treasure", "label": "Treasure", "pos": Vector2(510, 210), "next": ["elite_1"]},
	{"id": "battle_2", "type": "battle", "label": "Battle", "pos": Vector2(510, 420), "next": ["elite_1", "rest_1"]},
	{"id": "elite_1", "type": "elite", "label": "Elite", "pos": Vector2(725, 280), "next": ["rest_1"]},
	{"id": "rest_1", "type": "rest", "label": "Rest", "pos": Vector2(910, 390), "next": ["boss_1"]},
	{"id": "boss_1", "type": "boss", "label": "Boss", "pos": Vector2(1115, 320), "next": []},
]

var current_node_id := "start"
var node_lookup: Dictionary = {}
var node_buttons: Dictionary = {}
var log_label: Label
var title_label: Label
var enter_battle_button: Button
var selected_combat_node_id := ""

func _ready():
	if size == Vector2.ZERO:
		size = Vector2(1280, 720)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_clear_generated_children()
	node_lookup.clear()
	node_buttons.clear()
	_build_lookup()
	_build_static_ui()
	_build_map_nodes()
	_load_run_state()
	_set_current_node(current_node_id, false)

func _notification(what: int):
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func _draw():
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.07, 0.09, 1.0), true)
	for node_data in map_nodes:
		var from_id: String = node_data["id"]
		var from_pos := _get_node_center(from_id)
		for next_id in node_data["next"]:
			var to_pos := _get_node_center(next_id)
			var is_open := _is_node_completed(from_id) or from_id == current_node_id
			var color := EDGE_COLOR if is_open else EDGE_LOCKED_COLOR
			draw_line(from_pos, to_pos, color, 4.0, true)

func _build_lookup():
	for node_data in map_nodes:
		node_lookup[node_data["id"]] = node_data

func _build_static_ui():
	title_label = Label.new()
	_mark_generated(title_label)
	title_label.text = "Prototype Map"
	title_label.add_theme_font_size_override("font_size", 30)
	title_label.position = Vector2(48, 34)
	title_label.size = Vector2(420, 48)
	add_child(title_label)

	log_label = Label.new()
	_mark_generated(log_label)
	log_label.text = ""
	log_label.add_theme_font_size_override("font_size", 18)
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_label.position = Vector2(48, 620)
	log_label.size = Vector2(760, 70)
	add_child(log_label)

	enter_battle_button = Button.new()
	_mark_generated(enter_battle_button)
	enter_battle_button.text = "Enter Battle"
	enter_battle_button.position = Vector2(1030, 610)
	enter_battle_button.size = Vector2(190, 52)
	enter_battle_button.visible = false
	enter_battle_button.pressed.connect(_on_enter_battle_pressed)
	add_child(enter_battle_button)

	var reset_button := Button.new()
	_mark_generated(reset_button)
	reset_button.text = "Reset Map"
	reset_button.position = Vector2(1030, 42)
	reset_button.size = Vector2(150, 42)
	reset_button.pressed.connect(_on_reset_pressed)
	add_child(reset_button)

func _build_map_nodes():
	for node_data in map_nodes:
		var button := TextureButton.new()
		_mark_generated(button)
		var node_type: String = node_data["type"]
		var size := BOSS_NODE_SIZE if node_type == "boss" else NODE_SIZE
		button.name = "Node_%s" % node_data["id"]
		button.texture_normal = _make_icon_texture(node_type)
		button.ignore_texture_size = true
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		button.custom_minimum_size = size
		button.size = size
		button.position = node_data["pos"] - size * 0.5
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_on_node_pressed.bind(node_data["id"]))
		add_child(button)
		node_buttons[node_data["id"]] = button

		var label := Label.new()
		_mark_generated(label)
		label.text = node_data["label"]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 13)
		label.position = Vector2(-16, size.y - 2)
		label.size = Vector2(size.x + 32, 22)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(label)

func _on_node_pressed(node_id: String):
	if not _is_selectable(node_id):
		return
	_set_current_node(node_id)

func _set_current_node(node_id: String, complete_previous := true):
	if complete_previous and current_node_id != node_id:
		RunState.complete_node(current_node_id)
	current_node_id = node_id
	RunState.current_node_id = current_node_id

	var node_data: Dictionary = node_lookup[current_node_id]
	var node_type: String = node_data["type"]
	selected_combat_node_id = current_node_id if node_type in ["battle", "elite", "boss"] else ""
	enter_battle_button.visible = not selected_combat_node_id.is_empty()

	if node_type == "boss":
		log_label.text = "Boss node selected. Enter the final battle when ready."
	elif node_type in ["battle", "elite"]:
		log_label.text = "%s node selected. Enter battle when ready." % node_data["label"]
	else:
		log_label.text = "%s node completed. Choose the next connected node." % node_data["label"]
		if node_type != "start":
			RunState.complete_node(current_node_id)

	_update_node_states()
	queue_redraw()

func _update_node_states():
	for node_id in node_buttons:
		var button: TextureButton = node_buttons[node_id]
		button.disabled = not _is_selectable(node_id) and node_id != current_node_id
		if node_id == current_node_id:
			button.modulate = CURRENT_COLOR
		elif _is_node_completed(node_id):
			button.modulate = COMPLETED_COLOR
		elif _is_selectable(node_id):
			button.modulate = SELECTABLE_COLOR
		else:
			button.modulate = LOCKED_COLOR

func _on_enter_battle_pressed():
	if selected_combat_node_id.is_empty():
		return
	if Engine.is_editor_hint():
		return
	var node_data: Dictionary = node_lookup[selected_combat_node_id]
	log_label.text = "Loading %s..." % node_data["label"]
	RunState.start_combat_node(selected_combat_node_id)
	get_tree().change_scene_to_file(INGAME_SCENE_PATH)

func _on_reset_pressed():
	RunState.reset_run()
	selected_combat_node_id = ""
	_set_current_node("start", false)

func _is_selectable(node_id: String) -> bool:
	if node_id == current_node_id:
		return false
	var current_node: Dictionary = node_lookup[current_node_id]
	return node_id in current_node["next"]

func _is_node_completed(node_id: String) -> bool:
	return RunState.is_node_completed(node_id)

func _get_node_center(node_id: String) -> Vector2:
	var node_data: Dictionary = node_lookup[node_id]
	return node_data["pos"]

func _make_icon_texture(node_type: String) -> AtlasTexture:
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
		"start":
			return Rect2(444, 408, 190, 244)
		_:
			return Rect2(444, 408, 190, 244)

func _mark_generated(node: Node):
	node.set_meta("map_screen_generated", true)

func _load_run_state():
	if Engine.is_editor_hint():
		current_node_id = "start"
		return
	if node_lookup.has(RunState.current_node_id):
		current_node_id = RunState.current_node_id
	else:
		current_node_id = "start"

func _clear_generated_children():
	for child in get_children():
		if child.has_meta("map_screen_generated"):
			if Engine.is_editor_hint():
				remove_child(child)
				child.free()
			else:
				child.queue_free()
