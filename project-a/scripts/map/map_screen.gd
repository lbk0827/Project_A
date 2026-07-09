@tool
extends Control

const INGAME_SCENE_PATH := "res://scenes/core/ingame/ingame.tscn"
const MAP_ATLAS := preload("res://assets/ui/ui_map.png")
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
	{"id": "battle_1", "type": "battle", "label": "Battle", "monster_id": "bog_stalker", "pos": Vector2(310, 255), "next": ["treasure_1", "battle_2"]},
	{"id": "event_1", "type": "event", "label": "Event", "pos": Vector2(310, 465), "next": ["battle_2"]},
	{"id": "treasure_1", "type": "treasure", "label": "Treasure", "pos": Vector2(510, 210), "next": ["elite_1"]},
	{"id": "battle_2", "type": "battle", "label": "Battle", "monster_id": "gravebound_crawler", "pos": Vector2(510, 420), "next": ["elite_1", "rest_1"]},
	{"id": "elite_1", "type": "elite", "label": "Elite", "monster_id": "frost_revenant", "pos": Vector2(725, 280), "next": ["rest_1"]},
	{"id": "rest_1", "type": "rest", "label": "Rest", "pos": Vector2(910, 390), "next": ["boss_1"]},
	{"id": "boss_1", "type": "boss", "label": "Boss", "monster_id": "abyssal_crown_guardian", "pos": Vector2(1115, 320), "next": []},
]

var current_node_id := "start"
var node_lookup: Dictionary = {}
var node_buttons: Dictionary = {}
var log_label: Label
var title_label: Label
var run_status_label: Label
var enter_battle_button: Button
var result_panel: PanelContainer
var result_title_label: Label
var result_body_label: Label
var continue_node_button: Button
var selected_combat_node_id := ""

func _run_state() -> Node:
	return get_node_or_null("/root/RunState")

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

	run_status_label = Label.new()
	_mark_generated(run_status_label)
	run_status_label.add_theme_font_size_override("font_size", 18)
	run_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	run_status_label.position = Vector2(730, 42)
	run_status_label.size = Vector2(270, 34)
	add_child(run_status_label)

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
	enter_battle_button.z_index = 40
	enter_battle_button.pressed.connect(_on_enter_battle_pressed)
	add_child(enter_battle_button)

	var reset_button := Button.new()
	_mark_generated(reset_button)
	reset_button.text = "Reset Map"
	reset_button.position = Vector2(1030, 42)
	reset_button.size = Vector2(150, 42)
	reset_button.z_index = 40
	reset_button.pressed.connect(_on_reset_pressed)
	add_child(reset_button)

	_build_result_panel()

func _build_result_panel():
	result_panel = PanelContainer.new()
	_mark_generated(result_panel)
	result_panel.visible = false
	result_panel.position = Vector2(840, 190)
	result_panel.size = Vector2(340, 250)
	result_panel.z_index = 50
	add_child(result_panel)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.12, 0.16, 0.96)
	style.border_color = Color(0.75, 0.67, 0.42, 1.0)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	result_panel.add_theme_stylebox_override("panel", style)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	result_panel.add_child(content)

	result_title_label = Label.new()
	result_title_label.add_theme_font_size_override("font_size", 22)
	content.add_child(result_title_label)

	result_body_label = Label.new()
	result_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_body_label.add_theme_font_size_override("font_size", 15)
	result_body_label.custom_minimum_size = Vector2(300, 118)
	content.add_child(result_body_label)

	continue_node_button = Button.new()
	continue_node_button.text = "Continue"
	continue_node_button.custom_minimum_size = Vector2(160, 42)
	continue_node_button.pressed.connect(_on_continue_node_pressed)
	content.add_child(continue_node_button)

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
	var run_state := _run_state()
	if run_state == null:
		return
	if complete_previous and current_node_id != node_id:
		run_state.complete_node(current_node_id)
	current_node_id = node_id
	run_state.current_node_id = current_node_id
	_hide_node_result()

	var node_data: Dictionary = node_lookup[current_node_id]
	var node_type: String = node_data["type"]
	var is_unresolved_combat := _is_combat_node(current_node_id) and not _is_node_completed(current_node_id)
	var is_unresolved_result := _is_result_node(current_node_id) and not _is_node_completed(current_node_id)
	selected_combat_node_id = current_node_id if is_unresolved_combat else ""
	enter_battle_button.visible = not selected_combat_node_id.is_empty()

	if run_state.run_cleared:
		log_label.text = "Run cleared. Reset the map to start another prototype run."
	elif _is_combat_node(current_node_id) and _is_node_completed(current_node_id):
		log_label.text = "%s cleared. Choose the next connected node." % node_data["label"]
	elif is_unresolved_result:
		log_label.text = "%s node resolved. Confirm the result to continue." % node_data["label"]
		_show_node_result(node_data)
	elif node_type == "boss":
		log_label.text = "Boss node selected. Enter the final battle when ready."
	elif node_type in ["battle", "elite"]:
		log_label.text = "%s node selected. Enter battle when ready." % node_data["label"]
	else:
		log_label.text = "%s node completed. Choose the next connected node." % node_data["label"]

	_update_node_states()
	_update_run_status()
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
	var run_state := _run_state()
	if run_state == null:
		return
	var node_data: Dictionary = node_lookup[selected_combat_node_id]
	log_label.text = "Loading %s..." % node_data["label"]
	run_state.start_combat_node(selected_combat_node_id, node_data.get("monster_id", "mire_imp"))
	get_tree().change_scene_to_file(INGAME_SCENE_PATH)

func _on_reset_pressed():
	var run_state := _run_state()
	if run_state != null:
		run_state.reset_run()
	selected_combat_node_id = ""
	_hide_node_result()
	_set_current_node("start", false)

func _on_continue_node_pressed():
	if not _is_result_node(current_node_id):
		return
	var run_state := _run_state()
	if run_state == null:
		return
	var node_data: Dictionary = node_lookup[current_node_id]
	var result_text := _apply_result_node_effect(node_data["type"])
	run_state.complete_node(current_node_id)
	_hide_node_result()
	log_label.text = "%s completed. %s" % [node_data["label"], result_text]
	_update_node_states()
	_update_run_status()
	queue_redraw()

func _is_selectable(node_id: String) -> bool:
	var run_state := _run_state()
	if run_state == null:
		return false
	if run_state.run_cleared:
		return false
	if node_id == current_node_id:
		return false
	if _is_result_node(current_node_id) and not _is_node_completed(current_node_id):
		return false
	if _is_combat_node(current_node_id) and not _is_node_completed(current_node_id):
		return false
	var current_node: Dictionary = node_lookup[current_node_id]
	return node_id in current_node["next"]

func _is_result_node(node_id: String) -> bool:
	if not node_lookup.has(node_id):
		return false
	var node_data: Dictionary = node_lookup[node_id]
	return node_data["type"] in ["event", "treasure", "rest"]

func _is_combat_node(node_id: String) -> bool:
	if not node_lookup.has(node_id):
		return false
	var node_data: Dictionary = node_lookup[node_id]
	return node_data["type"] in ["battle", "elite", "boss"]

func _is_node_completed(node_id: String) -> bool:
	var run_state := _run_state()
	return run_state != null and run_state.is_node_completed(node_id)

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

func _show_node_result(node_data: Dictionary):
	if result_panel == null:
		return
	var node_type: String = node_data["type"]
	result_title_label.text = node_data["label"]
	result_body_label.text = _get_result_text(node_type)
	result_panel.visible = true

func _hide_node_result():
	if result_panel != null:
		result_panel.visible = false

func _update_run_status():
	if run_status_label == null:
		return
	var run_state := _run_state()
	if run_state == null:
		run_status_label.text = "HP --/--   Gold --"
		return
	run_status_label.text = "HP %d/%d   Gold %d" % [run_state.current_hp, run_state.max_hp, run_state.gold]

func _apply_result_node_effect(node_type: String) -> String:
	var run_state := _run_state()
	if run_state == null:
		return "Choose the next node."
	match node_type:
		"event":
			run_state.gain_gold(10)
			return "Gained 10 gold. Choose the next node."
		"treasure":
			run_state.gain_gold(50)
			return "Gained 50 gold. Choose the next node."
		"rest":
			var before_hp := int(run_state.current_hp)
			run_state.heal(12)
			return "Recovered %d HP. Choose the next node." % (int(run_state.current_hp) - before_hp)
		_:
			return "Choose the next node."

func _get_result_text(node_type: String) -> String:
	match node_type:
		"event":
			return "An unstable anomaly flickers nearby. Event choices will be connected here later."
		"treasure":
			return "A sealed chest waits on the path. Reward selection will be connected here later."
		"rest":
			return "The party catches its breath. Healing and upgrade choices will be connected here later."
		_:
			return "This node has been resolved."

func _load_run_state():
	if Engine.is_editor_hint():
		current_node_id = "start"
		return
	var run_state := _run_state()
	if run_state != null and node_lookup.has(run_state.current_node_id):
		current_node_id = run_state.current_node_id
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
