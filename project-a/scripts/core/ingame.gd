extends Node2D

# One combat enemy's runtime state (spawned node + its combat data).
class CombatEnemy:
	var node: Node2D
	var sprite: CanvasItem
	var data: MonsterData
	var intents: Array = []
	var intent_index := 0
	var ai_enabled := false
	var ai_pattern_id := ""
	var ai_step_id := ""
	var ai_current_action: Dictionary = {}
	var ai_action_count_remaining := 1
	var ai_next_count_delta := 0
	var ai_attack_bonus_percent := 0
	var ai_triggered_rules: Dictionary = {}
	var hp := 0
	var block := 0
	var status_bar: EnemyStatusBar
	var home_position := Vector2.ZERO
	var dead := false

	func is_alive() -> bool:
		return not dead and hp > 0

	func max_hp() -> int:
		return data.stats.max_hp

class RouteWipeView:
	extends Control

	const SLANT := 180.0
	const SOFT_BAND := 96.0

	func _draw():
		var wipe_size: Vector2 = size
		var main := PackedVector2Array([
			Vector2.ZERO,
			Vector2(wipe_size.x - SLANT, 0.0),
			Vector2(wipe_size.x, wipe_size.y),
			Vector2(0.0, wipe_size.y),
		])
		draw_colored_polygon(main, Color(0.0, 0.0, 0.0, 1.0))

		var soft := PackedVector2Array([
			Vector2(wipe_size.x - SLANT, 0.0),
			Vector2(wipe_size.x - SLANT + SOFT_BAND, 0.0),
			Vector2(wipe_size.x + SOFT_BAND, wipe_size.y),
			Vector2(wipe_size.x, wipe_size.y),
		])
		draw_colored_polygon(soft, Color(0.0, 0.0, 0.0, 0.48))

		var edge := PackedVector2Array([
			Vector2(wipe_size.x - SLANT - 10.0, 0.0),
			Vector2(wipe_size.x - SLANT + 10.0, 0.0),
			Vector2(wipe_size.x + 10.0, wipe_size.y),
			Vector2(wipe_size.x - 10.0, wipe_size.y),
		])
		draw_colored_polygon(edge, Color(0.12, 0.18, 0.22, 0.36))

const MAX_HAND_SIZE := 7
const DRAW_CARDS_PER_TURN := 3
const DRAW_CARD_DELAY := 0.07
const DRAW_TRANSFER_TIME := 0.38
const DRAW_CARD_ANIMATION_TIME := 0.24
const DRAW_ENTRY_OFFSET := Vector2(0, 105)
const DISCARD_STAGGER := 0.055
const DISCARD_TRANSFER_TIME := 0.44
const CARD_SPACING := -8
# Hand cards are laid out on a circular arc around a pivot far below the screen,
# so the fan reads as a convex (dome) arch with the middle card highest.
const HAND_ARC_PIVOT := Vector2(640, 1368)
const HAND_ARC_RADIUS := 680.0
const HAND_CARD_ANGLE_STEP := 9.5
const CARD_BOTTOM_PIVOT := Vector2(65, 184)
const HAND_TOP_Y := 468.0
const HAND_CENTER_SCREEN := Vector2(640, 560)
const MONSTER_DROP_RADIUS := 90.0
const RP_MONSTER_CLICK_RADIUS := 150.0
const BATTLE_UI_SCENE := preload("res://scenes/ui/battle_ui.tscn")
const BATTLE_MAP_OVERLAY_SCENE := preload("res://scenes/ui/battle_map_overlay.tscn")
const CARD_VIEW_SCENE := preload("res://scenes/ui/cards/CardView.tscn")
const CARD_PREVIEW_SCENE := preload("res://scenes/ui/cards/CardViewLarge.tscn")
const CARD_TRANSFER_VFX := preload("res://scripts/vfx/card_transfer_vfx.gd")
const CARD_DISSOLVE_VFX := preload("res://scripts/vfx/card_dissolve_vfx.gd")
const MOON_SLASH_VFX_SCENE := preload("res://scenes/vfx/fx_tsuki_moon_slash.tscn")
const SONIC_BOOM_VFX_SCENE := preload("res://scenes/vfx/fx_sonic_boom.tscn")
const MapRouteData := preload("res://scripts/map/map_route_data.gd")
const DAMAGE_TO_ENEMY_COLOR := Color(1.0, 0.9, 0.4)
const CRIT_COLOR := Color(1.0, 0.5, 0.1)
const DAMAGE_TO_PLAYER_COLOR := Color(1.0, 0.35, 0.35)
const BLOCK_GAIN_COLOR := Color(0.55, 0.8, 1.0)
const BLOCKED_HIT_COLOR := Color(0.7, 0.75, 0.85)
const STANCE_MOON_SHADOW := "월영"
const STANCE_CLEAVING_MOON := "참월"
const ENEMY_DEATH_CLEANUP_PADDING := 0.08
const CARD_HAND_SETTINGS := preload("res://scenes/ui/cards/CardHandSettings.tres")
const PLAYER_STATS := preload("res://data/player/PlayerStats.tres")
const BASE_CAMP_STAGE_TEXTURE := preload("res://assets/stage/base_camp.png")
const COMBAT_STAGE_TEXTURE := preload("res://assets/stage/stage_1.png")
const DEFAULT_MONSTER_DATA := preload("res://data/monsters/MireImp.tres")
const BONE_CRAWLER_DATA := preload("res://data/monsters/BoneCrawler.tres")
const BOG_STALKER_DATA := preload("res://data/monsters/BogStalker.tres")
const GRAVEBOUND_CRAWLER_DATA := preload("res://data/monsters/GraveboundCrawler.tres")
const FROST_REVENANT_DATA := preload("res://data/monsters/FrostRevenant.tres")
const CROWN_ACOLYTE_DATA := preload("res://data/monsters/CrownAcolyte.tres")
const ABYSSAL_CROWN_GUARDIAN_DATA := preload("res://data/monsters/AbyssalCrownGuardian.tres")
const MONSTER_DATA_BY_ID := {
	"mire_imp": DEFAULT_MONSTER_DATA,
	"bone_crawler": BONE_CRAWLER_DATA,
	"bog_stalker": BOG_STALKER_DATA,
	"gravebound_crawler": GRAVEBOUND_CRAWLER_DATA,
	"frost_revenant": FROST_REVENANT_DATA,
	"crown_acolyte": CROWN_ACOLYTE_DATA,
	"abyssal_crown_guardian": ABYSSAL_CROWN_GUARDIAN_DATA,
}
const CHARACTER_CARDS_PATH := "res://data/generated/character_cards.json"
const CARD_EFFECT_ROWS_PATH := "res://data/generated/card_effect_rows.json"
const CHARACTER_RP_SETTINGS_PATH := "res://data/generated/character_rp_settings.json"
const CHARACTER_RP_SKILLS_PATH := "res://data/generated/character_rp_skills.json"
const MONSTER_AI_MONSTERS_PATH := "res://data/generated/monster_ai_monsters.json"
const MONSTER_AI_STATS_PATH := "res://data/generated/monster_ai_stats.json"
const MONSTER_AI_ACTIONS_PATH := "res://data/generated/monster_ai_actions.json"
const MONSTER_AI_PATTERNS_PATH := "res://data/generated/monster_ai_patterns.json"
const MONSTER_AI_RULES_PATH := "res://data/generated/monster_ai_rules.json"
const MAP_SCENE_PATH := "res://scenes/map/map_screen.tscn"
const ROUTE_WIPE_OVERSCAN := 96.0

@onready var heroine: CharacterBody2D = $Heroine
@onready var camera: Camera2D = $Camera2D
@onready var monster_spawn: Marker2D = $MonsterSpawn
@onready var background: TextureRect = $BackgroundLayer/Background

var draw_pile: Array[CardData] = []
var discard_pile: Array[CardData] = []
var hand: Array[CardData] = []
var battle_log: Array[String] = []
var enemies: Array = []
var targeted_enemy: CombatEnemy = null
var selected_info_enemy: CombatEnemy = null
var player_hp := 0
var player_block := 0
var energy := 0
var rage_point := 0.0
var rp_settings: Dictionary = {}
var rp_skill: Dictionary = {}
var monster_ai_monsters: Dictionary = {}
var monster_ai_stats: Dictionary = {}
var monster_ai_actions: Dictionary = {}
var monster_ai_pattern_steps: Dictionary = {}
var monster_ai_rules_by_monster: Dictionary = {}
var rp_skill_selected := false
var current_stance := STANCE_MOON_SHADOW
var stance_changed_this_turn := false
# Temporary +% bonus to Tsuki's attack-card damage for the current turn.
var _attack_damage_bonus_percent := 0
# Passive effects installed by enhance cards for this combat.
var _inspired_play_passive_effects: Array = []
var card_library: Dictionary = {}
var turn_number := 1
# Shared enemy action counter: all living enemies act together when it hits 0.
var enemy_action_count_remaining := 0
var battle_over := false
var battle_won := false
var combat_sequence_active := false
var route_selection_mode := false
var player_home_position := Vector2.ZERO

var battle_ui: CanvasLayer
var battle_map_overlay: CanvasLayer
var route_transition_layer: CanvasLayer
var route_transition_rect: RouteWipeView
var ui_root: Control
var hand_container: Control
var end_turn_button: Button
var restart_button: Button
var targeting_dot: Panel
var targeting_dot_style: StyleBoxFlat
var selected_card_index := -1
var is_card_play_lifted := false
var is_targeting_active := false
var stance_badge: Panel
var stance_badge_label: Label
var stance_badge_suppressed := false
var draw_animation_card_indices: Array[int] = []
var reshuffle_animation_pending := false
var card_preview_large: Control

func _run_state() -> Node:
	return get_node_or_null("/root/RunState")

func _ready():
	card_library = _load_card_library()
	rp_settings = _load_character_table_entry(CHARACTER_RP_SETTINGS_PATH, "tsuki")
	rp_skill = _load_character_table_entry(CHARACTER_RP_SKILLS_PATH, "tsuki")
	_load_monster_ai_tables()
	_setup_scene()
	_build_ui()
	if _has_active_combat():
		_enter_combat_mode()
	else:
		_enter_route_selection_mode()

func _process(_delta: float):
	if route_selection_mode:
		if is_instance_valid(stance_badge):
			stance_badge.visible = false
		return
	_update_stance_badge()

func _load_card_library() -> Dictionary:
	var library: Dictionary = {}
	var effect_rows_by_card := _load_card_effect_rows()
	var file := FileAccess.open(CHARACTER_CARDS_PATH, FileAccess.READ)
	if file == null:
		return library
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not (parsed is Array):
		return library
	var card_id_counts: Dictionary = {}
	for entry in parsed:
		if entry is Dictionary:
			var entry_id := String(entry.get("id", ""))
			card_id_counts[entry_id] = int(card_id_counts.get(entry_id, 0)) + 1
	for entry in parsed:
		var card := CardData.new()
		card.id = String(entry.get("id", ""))
		card.character = String(entry.get("character", ""))
		card.display_name = String(entry.get("display_name", ""))
		card.cost = int(entry.get("cost", 0))
		var key := _card_key(card.character, card.id)
		var effect_rows: Array = effect_rows_by_card.get(key, [])
		card.text = _build_card_text(entry, effect_rows)
		card.card_type = StringName(String(entry.get("card_type", "skill")))
		card.motion_animation = StringName(String(entry.get("motion_animation", _default_card_motion_animation(card.card_type))))
		card.effects = _build_card_effects(entry, effect_rows)
		card.stance_effects = _build_card_stance_effects(entry, effect_rows)
		var keywords: Variant = entry.get("keywords", [])
		card.keywords = keywords if keywords is Array else []
		card.inspiration = _build_card_inspiration(entry, effect_rows)
		card.requires_target = _derive_requires_target(card.effects)
		library[key] = card
		if int(card_id_counts.get(card.id, 0)) == 1:
			library[card.id] = card
	return library

func _load_card_effect_rows() -> Dictionary:
	var rows_by_card: Dictionary = {}
	var file := FileAccess.open(CARD_EFFECT_ROWS_PATH, FileAccess.READ)
	if file == null:
		return rows_by_card
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not (parsed is Array):
		return rows_by_card
	for row in parsed:
		if not (row is Dictionary):
			continue
		var key := String(row.get("card_key", ""))
		if key.is_empty():
			key = _card_key(String(row.get("character", "")), String(row.get("card_id", "")))
		if key == "/":
			continue
		var rows: Array = rows_by_card.get(key, [])
		rows.append(row)
		rows_by_card[key] = rows
	return rows_by_card

func _load_table_array(path: String) -> Array:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return []
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if parsed is Array else []

func _index_table_by_id(rows: Array, id_field: String) -> Dictionary:
	var indexed: Dictionary = {}
	for row in rows:
		if not (row is Dictionary):
			continue
		var id := str(row.get(id_field, ""))
		if not id.is_empty():
			indexed[id] = row
	return indexed

func _load_monster_ai_tables():
	monster_ai_monsters = _index_table_by_id(_load_table_array(MONSTER_AI_MONSTERS_PATH), "monster_id")
	monster_ai_stats = _index_table_by_id(_load_table_array(MONSTER_AI_STATS_PATH), "stats_id")
	monster_ai_actions = _index_table_by_id(_load_table_array(MONSTER_AI_ACTIONS_PATH), "action_id")
	monster_ai_pattern_steps.clear()
	for row in _load_table_array(MONSTER_AI_PATTERNS_PATH):
		if not (row is Dictionary):
			continue
		var pattern_id := str(row.get("pattern_id", ""))
		var step_id := str(row.get("step_id", ""))
		if pattern_id.is_empty() or step_id.is_empty():
			continue
		var steps: Dictionary = monster_ai_pattern_steps.get(pattern_id, {})
		steps[step_id] = row
		monster_ai_pattern_steps[pattern_id] = steps
	monster_ai_rules_by_monster.clear()
	for row in _load_table_array(MONSTER_AI_RULES_PATH):
		if not (row is Dictionary):
			continue
		var monster_id := str(row.get("monster_id", ""))
		if monster_id.is_empty():
			continue
		var rules: Array = monster_ai_rules_by_monster.get(monster_id, [])
		rules.append(row)
		monster_ai_rules_by_monster[monster_id] = rules

func _card_key(character: String, card_id: String) -> String:
	return "%s/%s" % [character, card_id]

func _build_card_text(entry: Dictionary, effect_rows: Array) -> String:
	var template := String(entry.get("text_template", entry.get("text", "")))
	var values := _card_text_values(entry, effect_rows)
	for index in values:
		template = template.replace("{%s}" % index, values[index])
	return template

func _card_text_values(entry: Dictionary, effect_rows: Array) -> Dictionary:
	var values: Dictionary = {}
	for row in effect_rows:
		if not _has_table_value(row, "text_arg_index"):
			continue
		var arg_index := int(row["text_arg_index"])
		var value: Variant = null
		if _has_table_value(row, "percent"):
			value = row["percent"]
		elif _has_table_value(row, "amount"):
			value = row["amount"]
		elif _has_table_value(row, "duration_turns"):
			value = row["duration_turns"]
		if value != null:
			values[str(arg_index)] = _format_table_value(value)
	if values.is_empty():
		for field in ["damage_percent", "shield_percent", "draw_amount", "buff_percent", "buff_duration_turns"]:
			if _has_table_value(entry, field):
				values[str(values.size())] = _format_table_value(entry[field])
	return values

func _format_table_value(value: Variant) -> String:
	var number := float(value)
	number = absf(number)
	if is_equal_approx(number, round(number)):
		return str(int(round(number)))
	return str(number)

func _build_card_effects(entry: Dictionary, effect_rows: Array) -> Array:
	var existing: Variant = entry.get("effects", null)
	if existing is Array:
		return existing
	var effects: Array = []
	for row in effect_rows:
		var trigger := String(row.get("trigger", "on_play"))
		if trigger == "on_play":
			effects.append(_effect_from_row(row))
		elif trigger != "on_inspiration" and trigger != "on_stance" and trigger != "text_only":
			effects.append({
				"type": "passive",
				"trigger": trigger,
				"effect": _effect_from_row(row),
			})
	return effects

func _build_card_stance_effects(entry: Dictionary, effect_rows: Array) -> Dictionary:
	var existing: Variant = entry.get("stance_effects", null)
	if existing is Dictionary:
		return existing
	var stance_effects: Dictionary = {}
	for row in effect_rows:
		if String(row.get("trigger", "")) != "on_stance":
			continue
		var stance := String(row.get("stance", ""))
		if stance.is_empty():
			continue
		var effects: Array = stance_effects.get(stance, [])
		effects.append(_effect_from_row(row))
		stance_effects[stance] = effects
	return stance_effects

func _build_card_inspiration(entry: Dictionary, effect_rows: Array) -> Array:
	var existing: Variant = entry.get("inspiration", null)
	if existing is Array:
		return existing
	var inspiration: Array = []
	for row in effect_rows:
		if String(row.get("trigger", "")) == "on_inspiration":
			inspiration.append(_effect_from_row(row))
	return inspiration

func _effect_from_row(row: Dictionary) -> Dictionary:
	var effect := {
		"type": String(row.get("effect_type", "")),
	}
	for field in ["target", "card_type", "buff", "scope", "condition"]:
		if _has_table_value(row, field):
			effect[field] = String(row[field])
	for field in ["percent", "amount", "duration_turns"]:
		if _has_table_value(row, field):
			effect[field] = int(row[field])
	if effect["type"] == "add_card_to_hand" and effect.has("scope"):
		effect["card_id"] = effect["scope"]
	return effect

func _has_table_value(entry: Dictionary, field: String) -> bool:
	if not entry.has(field):
		return false
	var value: Variant = entry[field]
	if value == null:
		return false
	return not (value is String and String(value).is_empty())

func _load_character_table_entry(path: String, character_id: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("Unable to load character table: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not (parsed is Array):
		push_warning("Character table is not an array: %s" % path)
		return {}
	for entry in parsed:
		if entry is Dictionary and String(entry.get("character", "")) == character_id:
			return entry.duplicate(true)
	return {}

func _derive_requires_target(effects: Array) -> bool:
	for effect in effects:
		if String(effect.get("type", "")) != "damage":
			continue
		var target := String(effect.get("target", "enemy"))
		if target == "enemy" or target == "all_enemies":
			return true
	return false

func _default_card_motion_animation(card_type: StringName) -> String:
	return "Attack" if String(card_type) == "attack" else "Idle"

func _setup_scene():
	player_home_position = heroine.global_position
	if is_instance_valid(camera):
		camera.enabled = true
		camera.position_smoothing_enabled = true
		camera.position_smoothing_speed = 6.0
	if heroine.has_method("set_movement_enabled"):
		heroine.call("set_movement_enabled", false)

func _has_active_combat() -> bool:
	var run_state := _run_state()
	return run_state != null and not String(run_state.active_combat_node_id).is_empty()

func _set_stage_background(texture: Texture2D):
	if is_instance_valid(background):
		background.texture = texture

func _enter_route_selection_mode(message := ""):
	var was_route_selection := route_selection_mode
	route_selection_mode = true
	battle_over = false
	battle_won = false
	combat_sequence_active = false
	rp_skill_selected = false
	_clear_enemies()
	if not was_route_selection:
		_set_stage_background(BASE_CAMP_STAGE_TEXTURE if _is_base_camp_route() else COMBAT_STAGE_TEXTURE)
	_reset_camera_view()
	heroine.global_position = player_home_position
	if heroine.has_method("play_idle_animation"):
		heroine.call("play_idle_animation")
	if is_instance_valid(battle_ui):
		battle_ui.visible = true
		battle_ui.call("set_route_selection_mode", true)
		_update_route_player_status()
	_show_battle_map_overlay(message)

func _enter_combat_mode():
	route_selection_mode = false
	_set_stage_background(COMBAT_STAGE_TEXTURE)
	_reset_camera_view()
	if is_instance_valid(battle_map_overlay):
		battle_map_overlay.visible = false
	if is_instance_valid(battle_ui):
		battle_ui.visible = true
		battle_ui.call("set_route_selection_mode", false)
	_setup_enemies(_get_encounter_datas())
	_start_battle()

func _is_base_camp_route() -> bool:
	var run_state := _run_state()
	return run_state == null or String(run_state.current_node_id) == String(run_state.START_NODE_ID)

func _reset_camera_view():
	if not is_instance_valid(camera):
		return
	camera.offset = Vector2.ZERO
	camera.zoom = Vector2.ONE

func _prepare_route_wipe(start_x: float):
	if not is_instance_valid(route_transition_layer) or not is_instance_valid(route_transition_rect):
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	route_transition_layer.visible = true
	route_transition_rect.size = Vector2(viewport_size.x + ROUTE_WIPE_OVERSCAN * 2.0 + RouteWipeView.SLANT + RouteWipeView.SOFT_BAND, viewport_size.y)
	route_transition_rect.position = Vector2(start_x, 0.0)
	route_transition_rect.modulate = Color(1, 1, 1, 1)
	route_transition_rect.queue_redraw()

func _play_route_wipe_cover():
	if not is_instance_valid(route_transition_rect):
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	var wipe_width: float = viewport_size.x + ROUTE_WIPE_OVERSCAN * 2.0 + RouteWipeView.SLANT + RouteWipeView.SOFT_BAND
	_prepare_route_wipe(-wipe_width)
	var tween := create_tween()
	tween.tween_property(route_transition_rect, "position:x", -ROUTE_WIPE_OVERSCAN, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

func _play_route_wipe_reveal():
	if not is_instance_valid(route_transition_rect):
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	var tween := create_tween()
	tween.tween_property(route_transition_rect, "position:x", viewport_size.x + ROUTE_WIPE_OVERSCAN, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	if is_instance_valid(route_transition_layer):
		route_transition_layer.visible = false

func _setup_enemies(datas: Array):
	_clear_enemies()
	var count := datas.size()
	for i in range(count):
		var data: MonsterData = datas[i]
		var enemy := CombatEnemy.new()
		enemy.data = data
		enemy.intents = data.intents.duplicate()
		_setup_enemy_ai(enemy)
		enemy.node = data.scene.instantiate()
		enemy.node.name = "Monster%d" % i
		add_child(enemy.node)
		enemy.home_position = _enemy_spawn_position(i, count)
		enemy.node.global_position = enemy.home_position
		if "home_position" in enemy.node:
			enemy.node.home_position = enemy.home_position
		enemy.sprite = enemy.node.get_node_or_null("AnimatedSprite2D") as CanvasItem
		enemy.status_bar = EnemyStatusBar.new()
		enemy.node.add_child(enemy.status_bar)
		enemy.status_bar.position = data.hp_bar_offset - EnemyStatusBar.PANEL_SIZE * 0.5
		enemies.append(enemy)

func _setup_enemy_ai(enemy: CombatEnemy):
	var monster_id := enemy.data.id
	if not monster_ai_monsters.has(monster_id):
		return
	var monster_row: Dictionary = monster_ai_monsters[monster_id]
	var pattern_id := str(monster_row.get("default_pattern_id", ""))
	if pattern_id.is_empty() or not monster_ai_pattern_steps.has(pattern_id):
		return
	enemy.ai_enabled = true
	enemy.ai_pattern_id = pattern_id
	enemy.ai_step_id = "start"
	_set_enemy_ai_step(enemy, enemy.ai_step_id, null, false)

func _set_enemy_ai_step(enemy: CombatEnemy, step_id: String, count_override: Variant = null, apply_rules := true):
	var pattern_steps: Dictionary = monster_ai_pattern_steps.get(enemy.ai_pattern_id, {})
	if not pattern_steps.has(step_id):
		step_id = "start"
	if not pattern_steps.has(step_id):
		enemy.ai_enabled = false
		return
	var step: Dictionary = pattern_steps[step_id]
	var action_id := str(step.get("action_id", ""))
	if not monster_ai_actions.has(action_id):
		enemy.ai_enabled = false
		return
	enemy.ai_step_id = step_id
	enemy.ai_current_action = monster_ai_actions[action_id]
	if count_override != null:
		enemy.ai_action_count_remaining = max(int(count_override), 1)
	else:
		enemy.ai_action_count_remaining = max(int(step.get("action_count", 1)), 1)
	if apply_rules:
		_apply_enemy_ai_rules(enemy)

func _advance_enemy_ai_step(enemy: CombatEnemy):
	var pattern_steps: Dictionary = monster_ai_pattern_steps.get(enemy.ai_pattern_id, {})
	var step: Dictionary = pattern_steps.get(enemy.ai_step_id, {})
	var next_step_id := str(step.get("next_step_id", "start"))
	_set_enemy_ai_step(enemy, next_step_id)
	if enemy.ai_next_count_delta != 0:
		enemy.ai_action_count_remaining = max(enemy.ai_action_count_remaining + enemy.ai_next_count_delta, 1)
		enemy.ai_next_count_delta = 0

func _apply_enemy_ai_rules(enemy: CombatEnemy):
	if not enemy.ai_enabled:
		return
	var monster_id := enemy.data.id
	var rules: Array = monster_ai_rules_by_monster.get(monster_id, [])
	var selected_rule: Dictionary = {}
	var selected_priority := -999999
	for rule in rules:
		if not (rule is Dictionary):
			continue
		var rule_id := str(rule.get("rule_id", ""))
		if bool(rule.get("once", false)) and enemy.ai_triggered_rules.has(rule_id):
			continue
		if not _enemy_ai_rule_matches(enemy, rule):
			continue
		var priority := int(rule.get("priority", 0))
		if priority > selected_priority:
			selected_rule = rule
			selected_priority = priority
	if selected_rule.is_empty():
		return
	var selected_rule_id := str(selected_rule.get("rule_id", ""))
	if bool(selected_rule.get("once", false)):
		enemy.ai_triggered_rules[selected_rule_id] = true
	var set_pattern_id := str(selected_rule.get("set_pattern_id", ""))
	if not set_pattern_id.is_empty() and monster_ai_pattern_steps.has(set_pattern_id):
		enemy.ai_pattern_id = set_pattern_id
	var count_override: Variant = selected_rule.get("action_count_override", null)
	_set_enemy_ai_step(enemy, str(selected_rule.get("set_step_id", "start")), count_override, false)

func _enemy_ai_rule_matches(enemy: CombatEnemy, rule: Dictionary) -> bool:
	var trigger_type := str(rule.get("trigger_type", ""))
	match trigger_type:
		"hp_below":
			var threshold := float(rule.get("trigger_value", 0))
			var ratio := float(enemy.hp) / float(max(enemy.max_hp(), 1)) * 100.0
			return ratio <= threshold
	return false

func _clear_enemies():
	_clear_selected_monster_info()
	for enemy in enemies:
		if is_instance_valid(enemy.node):
			enemy.node.queue_free()
	enemies.clear()

func _enemy_spawn_position(index: int, count: int) -> Vector2:
	var base := monster_spawn.global_position
	if count <= 1:
		return base
	var spacing := 210.0
	var offset := (float(index) - float(count - 1) * 0.5) * spacing
	return base + Vector2(offset, 0.0)

func _get_encounter_datas() -> Array:
	var data := DEFAULT_MONSTER_DATA
	var run_state := _run_state()
	if run_state != null:
		var monster_id: String = run_state.current_monster_id if "current_monster_id" in run_state else ""
		if not monster_id.is_empty() and MONSTER_DATA_BY_ID.has(monster_id):
			data = MONSTER_DATA_BY_ID[monster_id]
	# Placeholder encounter groups: boss fights solo, others spawn two enemies.
	if data == ABYSSAL_CROWN_GUARDIAN_DATA or data == FROST_REVENANT_DATA or data == CROWN_ACOLYTE_DATA:
		return [data]
	return [data, data]

func _alive_enemies() -> Array:
	var alive: Array = []
	for enemy in enemies:
		if enemy.is_alive():
			alive.append(enemy)
	return alive

func _first_alive_enemy() -> CombatEnemy:
	for enemy in enemies:
		if enemy.is_alive():
			return enemy
	return null

func _build_ui():
	battle_ui = BATTLE_UI_SCENE.instantiate()
	add_child(battle_ui)
	_build_route_transition()

	ui_root = battle_ui.get_node("%UIRoot")
	hand_container = battle_ui.get_node("%HandContainer")
	targeting_dot = battle_ui.get_node("%TargetingDot")
	end_turn_button = battle_ui.get_node("%EndTurnButton")
	restart_button = battle_ui.get_node("%RestartButton")
	_build_stance_badge()

	targeting_dot_style = StyleBoxFlat.new()
	targeting_dot.add_theme_stylebox_override("panel", targeting_dot_style)
	_apply_targeting_dot_style(false)
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	battle_ui.connect("rp_skill_requested", Callable(self, "_on_rp_skill_requested"))
	battle_ui.connect("rp_skill_cancelled", Callable(self, "_on_rp_skill_cancelled"))
	battle_ui.connect("monster_info_close_requested", Callable(self, "_clear_selected_monster_info"))

func _build_stance_badge():
	if not is_instance_valid(ui_root) or is_instance_valid(stance_badge):
		return
	stance_badge = Panel.new()
	stance_badge.name = "TsukiStanceBadge"
	stance_badge.custom_minimum_size = Vector2(92, 30)
	stance_badge.size = Vector2(92, 30)
	stance_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stance_badge.z_as_relative = false
	stance_badge.z_index = 550

	stance_badge_label = Label.new()
	stance_badge_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	stance_badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stance_badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stance_badge_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stance_badge_label.add_theme_font_size_override("font_size", 16)
	stance_badge_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.92))
	stance_badge_label.add_theme_constant_override("outline_size", 4)
	stance_badge.add_child(stance_badge_label)
	ui_root.add_child(stance_badge)
	_update_stance_badge()

func _update_stance_badge():
	if not is_instance_valid(stance_badge) or not is_instance_valid(stance_badge_label):
		return
	stance_badge.visible = is_instance_valid(heroine) and not battle_over and not route_selection_mode and not stance_badge_suppressed
	if not stance_badge.visible:
		return

	stance_badge_label.text = current_stance
	var style := StyleBoxFlat.new()
	if current_stance == STANCE_CLEAVING_MOON:
		style.bg_color = Color(0.34, 0.08, 0.03, 0.86)
		style.border_color = Color(1.0, 0.57, 0.24, 0.98)
		stance_badge_label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.46, 1.0))
	else:
		style.bg_color = Color(0.03, 0.12, 0.22, 0.86)
		style.border_color = Color(0.48, 0.87, 1.0, 0.98)
		stance_badge_label.add_theme_color_override("font_color", Color(0.68, 0.92, 1.0, 1.0))
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	stance_badge.add_theme_stylebox_override("panel", style)

	var screen_position := heroine.get_global_transform_with_canvas().origin
	stance_badge.global_position = screen_position + Vector2(-46, -146)

func _set_stance_badge_suppressed(suppressed: bool):
	stance_badge_suppressed = suppressed
	_update_stance_badge()

func _build_route_transition():
	route_transition_layer = CanvasLayer.new()
	route_transition_layer.name = "RouteTransitionLayer"
	route_transition_layer.layer = 95
	route_transition_layer.visible = false
	add_child(route_transition_layer)

	route_transition_rect = RouteWipeView.new()
	route_transition_rect.name = "RouteWipe"
	route_transition_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	route_transition_layer.add_child(route_transition_rect)

func _start_battle():
	route_selection_mode = false
	draw_pile = _build_deck()
	draw_pile.shuffle()
	discard_pile.clear()
	hand.clear()
	battle_log.clear()
	var run_state := _run_state()
	player_hp = PLAYER_STATS.max_hp
	if run_state != null and run_state.current_hp > 0:
		player_hp = min(run_state.current_hp, PLAYER_STATS.max_hp)
	player_block = 0
	energy = PLAYER_STATS.starting_energy
	rage_point = clamp(float(rp_settings.get("starting_rp", 0.0)), 0.0, _max_rp())
	stance_changed_this_turn = false
	turn_number = 1
	battle_over = false
	battle_won = false
	combat_sequence_active = false
	rp_skill_selected = false
	_inspired_play_passive_effects.clear()
	selected_card_index = -1
	is_card_play_lifted = false
	is_targeting_active = false
	targeted_enemy = null
	selected_info_enemy = null
	draw_animation_card_indices.clear()
	reshuffle_animation_pending = false
	end_turn_button.visible = true
	restart_button.visible = false
	restart_button.text = "Restart Battle"
	heroine.global_position = player_home_position
	if heroine.has_method("reset_combat_state"):
		heroine.call("reset_combat_state", player_hp, PLAYER_STATS.max_hp)
	if heroine.has_method("set_facing_direction"):
		heroine.call("set_facing_direction", Vector2.RIGHT)
	for enemy in enemies:
		enemy.hp = enemy.max_hp()
		enemy.block = 0
		enemy.intent_index = 0
		enemy.ai_next_count_delta = 0
		enemy.ai_attack_bonus_percent = 0
		enemy.ai_triggered_rules.clear()
		if enemy.ai_enabled:
			_set_enemy_ai_step(enemy, "start")
		enemy.dead = false
		enemy.node.global_position = enemy.home_position
		if is_instance_valid(enemy.node) and enemy.node.has_method("reset_combat_state"):
			enemy.node.call("reset_combat_state")
		if is_instance_valid(enemy.sprite):
			enemy.sprite.modulate = Color.WHITE
		if is_instance_valid(enemy.status_bar):
			enemy.status_bar.visible = true
	enemy_action_count_remaining = _get_enemy_action_count()
	_update_player_hp_bar()
	_update_all_enemy_bars()
	_log("Battle start. Defeat the enemies.")
	if is_instance_valid(battle_ui):
		battle_ui.call("show_turn_banner", "BATTLE START", Color(0.72, 0.95, 1.0))
		await get_tree().create_timer(0.65).timeout
	_start_player_turn(true)

func _start_player_turn(is_first_turn := false):
	combat_sequence_active = true
	player_block = 0
	energy = PLAYER_STATS.starting_energy
	_attack_damage_bonus_percent = 0
	stance_changed_this_turn = false
	if not is_first_turn:
		turn_number += 1
	_log("Turn %d. Draw %d cards and spend your energy." % [turn_number, DRAW_CARDS_PER_TURN])
	if is_instance_valid(battle_ui):
		battle_ui.call("show_turn_banner", "PLAYER TURN", Color(0.65, 0.9, 1.0))
	_refresh_ui()
	await _draw_cards_with_animation(DRAW_CARDS_PER_TURN)
	combat_sequence_active = false
	_refresh_ui()

func _build_deck() -> Array[CardData]:
	var deck: Array[CardData] = []
	var run_state := _run_state()
	if run_state != null:
		for card_id in run_state.get_deck():
			if card_library.has(card_id):
				deck.append(card_library[card_id])
	if deck.is_empty():
		# Fallback when the scene is run directly without a RunState deck:
		# one of every card in the library.
		for card_id in card_library:
			deck.append(card_library[card_id])
	return deck

func _draw_cards_with_animation(amount: int):
	var drawn_indices: Array[int] = []
	for _i in range(amount):
		if not _draw_card_to_hand():
			break
		drawn_indices.append(hand.size() - 1)
	await _animate_draw_indices(drawn_indices)

func _animate_draw_indices(drawn_indices: Array[int]):
	if reshuffle_animation_pending:
		await _play_reshuffle_animation()
	if drawn_indices.is_empty():
		return
	draw_animation_card_indices = drawn_indices.duplicate()
	_refresh_ui()
	for i in range(drawn_indices.size()):
		_play_draw_card_from_deck(drawn_indices[i], float(i) * DRAW_CARD_DELAY)
	var total_time := DRAW_TRANSFER_TIME + DRAW_CARD_ANIMATION_TIME + float(drawn_indices.size() - 1) * DRAW_CARD_DELAY + 0.05
	await get_tree().create_timer(total_time).timeout
	draw_animation_card_indices.clear()
	_refresh_ui()

func _draw_card_to_hand() -> bool:
	if hand.size() >= MAX_HAND_SIZE:
		return false
	if draw_pile.is_empty():
		if discard_pile.is_empty():
			return false
		draw_pile = discard_pile.duplicate(true)
		discard_pile.clear()
		draw_pile.shuffle()
		reshuffle_animation_pending = true
		_log("Discard pile reshuffled into draw pile.")
	hand.append(_instance_for_hand(draw_pile.pop_back()))
	return true

# Hand cards are per-copy instances so runtime state (inspiration) is not
# shared between duplicate cards of the same id.
func _instance_for_hand(card: CardData) -> CardData:
	var copy: CardData = card.duplicate()
	copy.inspired = false
	return copy

func _discard_hand() -> Array[CardData]:
	# Cards with 보존(Retain) stay in hand at end of turn.
	var kept: Array[CardData] = []
	var discarded: Array[CardData] = []
	for card in hand:
		if "보존" in card.keywords:
			card.inspired = false
			kept.append(card)
		else:
			discarded.append(card)
	hand = kept
	return discarded

func _play_card(index: int, target_enemy: CombatEnemy = null):
	if battle_over or combat_sequence_active or index < 0 or index >= hand.size():
		return

	var card: CardData = hand[index]
	var cost: int = _effective_cost(card)
	if cost > energy:
		_log("Not enough energy for %s." % card.display_name)
		_refresh_ui()
		return

	var transition_proxy := _create_card_transition_proxy(index, card)
	combat_sequence_active = true
	var is_inspired: bool = card.inspired
	energy -= cost
	_gain_rp(float(cost) * float(rp_settings.get("rp_per_action_point", 0.0)), "ACTION")
	hand.remove_at(index)
	# Enhance cards install a lasting effect instead of going to discard.
	var moves_to_tomb := String(card.card_type) != "enhance"
	_log("%s 사용." % card.display_name)

	_refresh_ui()

	# Split into enemy-attack effects (played through the attack animation) and
	# instant effects (block/draw/energy applied right away). Passives install
	# a lasting effect rather than resolving now.
	var attack_effects: Array = []
	var attack_modifiers: Array = []
	var instant_effects: Array = []
	var card_effects := card.effects.duplicate(true)
	card_effects.append_array(_stance_effects_for(card))
	for effect in card_effects:
		if String(effect.get("type", "")) == "passive":
			_install_passive(effect)
		elif _is_attack_modifier_effect(effect):
			attack_modifiers.append(effect.duplicate())
		elif _is_enemy_damage_effect(effect):
			attack_effects.append(effect.duplicate())
		else:
			instant_effects.append(effect)

	if is_inspired:
		_apply_inspiration(card, attack_effects)
	for modifier in attack_modifiers:
		_apply_attack_modifier(modifier, attack_effects)
	if is_inspired:
		for passive_effect in _inspired_play_passive_effects:
			attack_effects.append(passive_effect.duplicate())

	await _apply_instant_effects(instant_effects)
	if not attack_effects.is_empty():
		await _play_player_attack_sequence(attack_effects, target_enemy, card.motion_animation)
	else:
		_play_heroine_card_motion(card.motion_animation)
	combat_sequence_active = true
	if moves_to_tomb:
		await _play_discard_proxy(transition_proxy, card)
	elif is_instance_valid(transition_proxy):
		await _fade_consumed_proxy(transition_proxy)

	_refresh_ui()
	combat_sequence_active = false
	if not battle_over:
		await _tick_enemy_action_count()
	_refresh_ui()

# Card cost after inspiration cost reductions (e.g. 훔쳐베기 영감: 비용 1 감소).
func _effective_cost(card: CardData) -> int:
	var cost: int = card.cost
	if card.inspired:
		for entry in card.inspiration:
			if String(entry.get("type", "")) == "cost_delta":
				cost += int(entry.get("amount", 0))
	return max(cost, 0)

# Applies this card's inspiration modifiers to its outgoing attack effects
# (extra hits, per-hit damage change). Cost changes are handled separately.
func _apply_inspiration(card: CardData, attack_effects: Array):
	for entry in card.inspiration:
		_apply_attack_modifier(entry, attack_effects)

func _apply_attack_modifier(entry: Dictionary, attack_effects: Array):
	if not _modifier_condition_met(entry):
		return
	match String(entry.get("type", "")):
		"add_hit":
			var base_hits: Array = []
			for effect in attack_effects:
				if _is_enemy_damage_effect(effect):
					base_hits.append(effect.duplicate())
			for _i in range(int(entry.get("amount", 0))):
				for effect in base_hits:
					attack_effects.append(effect.duplicate())
		"damage_delta":
			var delta: float = float(entry.get("percent", 0))
			for effect in attack_effects:
				if _is_enemy_damage_effect(effect) and effect.has("percent"):
					effect["percent"] = int(round(float(effect["percent"]) * (1.0 + delta / 100.0)))

func _modifier_condition_met(entry: Dictionary) -> bool:
	match String(entry.get("condition", "")):
		"stance_changed_this_turn":
			return stance_changed_this_turn
		_:
			return true

func _is_attack_modifier_effect(effect: Dictionary) -> bool:
	return String(effect.get("type", "")) in ["add_hit", "damage_delta"]

func _stance_effects_for(card: CardData) -> Array:
	var effects: Variant = card.stance_effects.get(current_stance, [])
	if effects is Array:
		return effects.duplicate(true)
	return []

func _toggle_stance():
	current_stance = STANCE_CLEAVING_MOON if current_stance == STANCE_MOON_SHADOW else STANCE_MOON_SHADOW
	stance_changed_this_turn = true
	_show_popup(_get_player_screen_position(), current_stance, Color(0.75, 0.9, 1.0), 28)

func _install_passive(effect: Dictionary):
	if String(effect.get("trigger", "")) == "on_play_inspired_card" and effect.get("effect", null) is Dictionary:
		_inspired_play_passive_effects.append(effect["effect"].duplicate())
		_show_popup(_get_player_screen_position(), "강화 발동", Color(0.6, 0.85, 1.0), 24)

func _activate_random_inspiration(count: int):
	var candidates: Array = []
	for card in hand:
		if not card.inspired and not card.inspiration.is_empty():
			candidates.append(card)
	candidates.shuffle()
	var activated := 0
	for i in range(min(count, candidates.size())):
		candidates[i].inspired = true
		activated += 1
	if activated > 0:
		_show_popup(_get_player_screen_position(), "영감 발동", Color(1.0, 0.85, 0.4), 24)
		_refresh_ui()

func _is_enemy_damage_effect(effect: Dictionary) -> bool:
	return String(effect.get("type", "")) == "damage" and String(effect.get("target", "enemy")) != "self"

func _apply_instant_effects(effects: Array):
	for effect in effects:
		match String(effect.get("type", "")):
			"block", "shield":
				var block_amount := _compute_shield(effect)
				player_block += block_amount
				_show_popup(_get_player_screen_position(), "+%d DEF" % block_amount, BLOCK_GAIN_COLOR, 28)
			"draw":
				await _draw_cards_typed(int(effect.get("amount", 0)), String(effect.get("card_type", "")))
			"energy":
				var gain := int(effect.get("amount", 0))
				energy += gain
				_show_popup(_get_player_screen_position(), "+%d EP" % gain, Color(0.5, 0.9, 1.0), 28)
			"add_card_to_hand":
				_add_card_to_hand(String(effect.get("card_id", "")))
			"buff":
				if String(effect.get("buff", "")) == "attack_damage_up":
					_attack_damage_bonus_percent += int(effect.get("percent", 0))
					_show_popup(_get_player_screen_position(), "공격 강화", Color(1.0, 0.8, 0.3), 24)
			"stance_change":
				_toggle_stance()
			"damage":
				_damage_player(int(effect.get("amount", 0)))
			"activate_inspiration":
				_activate_random_inspiration(int(effect.get("amount", 1)))

func _add_card_to_hand(card_id: String) -> bool:
	if hand.size() >= MAX_HAND_SIZE or card_id.is_empty() or not card_library.has(card_id):
		return false
	hand.append(_instance_for_hand(card_library[card_id]))
	_show_popup(_get_player_screen_position(), "+카드", Color(0.75, 0.9, 1.0), 24)
	_refresh_ui()
	return true

# Computed damage of a single attack effect: percent of attack (or flat
# amount), boosted by this turn's attack buff, then rolled for a critical hit.
func _compute_card_damage(effect: Dictionary) -> Dictionary:
	var base: int
	if effect.has("percent"):
		base = int(round(PLAYER_STATS.attack * float(effect["percent"]) / 100.0))
	else:
		base = int(effect.get("amount", 0))
	if _attack_damage_bonus_percent != 0:
		base = int(round(base * (1.0 + float(_attack_damage_bonus_percent) / 100.0)))
	var is_crit := randf() < PLAYER_STATS.crit_rate
	if is_crit:
		base = int(round(base * PLAYER_STATS.crit_damage))
	return {"amount": base, "crit": is_crit}

func _compute_shield(effect: Dictionary) -> int:
	if effect.has("percent"):
		return int(round(PLAYER_STATS.defense * float(effect["percent"]) / 100.0))
	return int(effect.get("amount", 0))

func _max_rp() -> float:
	return max(float(rp_settings.get("max_rp", 0.0)), 0.0)

func _rp_skill_cost() -> float:
	return max(float(rp_skill.get("rp_cost", 0.0)), 0.0)

func _gain_rp(amount: float, reason: String = ""):
	if amount <= 0.0 or _max_rp() <= 0.0:
		return
	var previous := rage_point
	rage_point = clamp(rage_point + amount, 0.0, _max_rp())
	var gained := rage_point - previous
	if gained <= 0.0:
		return
	var label := "+%s RP" % _format_rp_value(gained)
	if not reason.is_empty():
		label += "  %s" % reason
	_show_popup(_get_player_screen_position() + Vector2(-120, 20), label, Color(0.45, 0.9, 1.0), 24)

func _format_rp_value(value: float) -> String:
	if is_equal_approx(value, round(value)):
		return str(int(round(value)))
	return ("%.2f" % value).trim_suffix("0")

func _on_rp_skill_requested():
	if route_selection_mode or battle_over or combat_sequence_active or rp_skill_selected:
		return
	if rp_skill.is_empty() or rage_point + 0.001 < _rp_skill_cost():
		return
	_reset_hand_drag_state()
	_clear_selected_monster_info()
	rp_skill_selected = true
	_refresh_enemy_selection_visuals()
	_refresh_ui()

func _on_rp_skill_cancelled():
	if not rp_skill_selected:
		return
	rp_skill_selected = false
	_refresh_enemy_selection_visuals()
	if is_instance_valid(battle_ui):
		battle_ui.call("clear_rp_targeting")
	_refresh_ui()

func _execute_rp_skill():
	if route_selection_mode or battle_over or combat_sequence_active or not rp_skill_selected:
		return
	if rage_point + 0.001 < _rp_skill_cost() or _alive_enemies().is_empty():
		_on_rp_skill_cancelled()
		return

	combat_sequence_active = true
	rp_skill_selected = false
	_refresh_enemy_selection_visuals()
	rage_point = max(rage_point - _rp_skill_cost(), 0.0)
	if is_instance_valid(battle_ui):
		battle_ui.call("clear_rp_targeting")
	_refresh_ui()

	if is_instance_valid(battle_ui):
		await battle_ui.call("play_rp_cutin", float(rp_skill.get("cutin_hold_seconds", 1.0)))

	var targets: Array = _alive_enemies()
	_set_stance_badge_suppressed(true)
	await _move_player_to_moon_slash_position(targets)
	if heroine.has_method("play_card_animation"):
		heroine.call("play_card_animation", StringName(String(rp_skill.get("motion_animation", "MoonSlash"))))

	var moon_vfx: Array = []
	for enemy in targets:
		if not is_instance_valid(enemy.node):
			continue
		var vfx := MOON_SLASH_VFX_SCENE.instantiate()
		add_child(vfx)
		vfx.global_position = enemy.node.global_position + Vector2(0, -34)
		moon_vfx.append(vfx)
		vfx.call("reveal")
	await get_tree().create_timer(0.2).timeout

	var damage_percent := float(rp_skill.get("damage_percent", 0.0))
	var hit_count: int = max(int(rp_skill.get("hit_count", 5)), 1)
	for hit_index in range(hit_count):
		for vfx in moon_vfx:
			if is_instance_valid(vfx):
				vfx.call("apply_slash", hit_index)
		await get_tree().create_timer(0.075).timeout
		var hit := _compute_card_damage({"percent": damage_percent})
		for enemy in targets:
			if enemy.is_alive():
				_damage_enemy(enemy, int(hit["amount"]), bool(hit["crit"]))
		await get_tree().create_timer(0.105).timeout

	for vfx in moon_vfx:
		if is_instance_valid(vfx):
			vfx.call("shatter")
	await get_tree().create_timer(0.4).timeout
	await _return_player_home()
	_set_stance_badge_suppressed(false)
	combat_sequence_active = false
	_face_player_to(_first_alive_enemy())
	if not battle_over and heroine.has_method("play_idle_animation"):
		heroine.call("play_idle_animation")
	_refresh_ui()

func _move_player_to_moon_slash_position(targets: Array):
	if not is_instance_valid(heroine):
		return
	var center := camera.get_screen_center_position() if is_instance_valid(camera) else Vector2.ZERO
	var skill_position := Vector2(center.x - 36.0, player_home_position.y)
	var focus_position := skill_position + Vector2.RIGHT
	if not targets.is_empty() and is_instance_valid(targets[0].node):
		focus_position = targets[0].node.global_position
	var direction := focus_position - heroine.global_position
	if heroine.has_method("set_facing_direction"):
		heroine.call("set_facing_direction", direction)
	if heroine.has_method("play_run_animation"):
		heroine.call("play_run_animation", direction.normalized())
	await _dash_actor_with_sonic_boom(heroine, skill_position, 0.36)
	if heroine.has_method("set_facing_direction"):
		heroine.call("set_facing_direction", focus_position - heroine.global_position)

func _draw_cards_typed(amount: int, card_type: String):
	var drawn_indices: Array[int] = []
	for _i in range(amount):
		var did_draw: bool = _draw_card_to_hand() if card_type.is_empty() else _draw_typed_card(card_type)
		if not did_draw:
			break
		drawn_indices.append(hand.size() - 1)
	await _animate_draw_indices(drawn_indices)

func _draw_typed_card(card_type: String) -> bool:
	if hand.size() >= MAX_HAND_SIZE:
		return false
	if draw_pile.is_empty():
		if discard_pile.is_empty():
			return false
		draw_pile = discard_pile.duplicate(true)
		discard_pile.clear()
		draw_pile.shuffle()
		reshuffle_animation_pending = true
	for i in range(draw_pile.size() - 1, -1, -1):
		if String(draw_pile[i].card_type) == card_type:
			hand.append(_instance_for_hand(draw_pile[i]))
			draw_pile.remove_at(i)
			return true
	# No matching type left; draw the top card instead.
	hand.append(_instance_for_hand(draw_pile.pop_back()))
	return true

func _play_player_attack_sequence(damage_effects: Array, target_enemy: CombatEnemy, motion_animation: StringName = &"Attack"):
	combat_sequence_active = true
	_set_stance_badge_suppressed(true)
	_refresh_ui()
	var focus: CombatEnemy = target_enemy if (target_enemy != null and target_enemy.is_alive()) else _first_alive_enemy()
	var moves_to_attack_position := _should_player_move_to_attack_position(motion_animation)
	if moves_to_attack_position:
		await _move_player_to_attack_position(focus)
	else:
		_face_player_to(focus)
	_play_heroine_attack(focus, motion_animation)
	await get_tree().create_timer(_get_heroine_motion_value("attack_impact_delay", 0.18)).timeout
	for effect in damage_effects:
		if battle_over:
			break
		var hit := _compute_card_damage(effect)
		for enemy in _effect_targets(effect, target_enemy):
			if battle_over:
				break
			_damage_enemy(enemy, int(hit["amount"]), bool(hit["crit"]))
	await get_tree().create_timer(_get_heroine_motion_value("attack_recover_delay", 0.38)).timeout
	if moves_to_attack_position:
		await _return_player_home()
	_set_stance_badge_suppressed(false)
	combat_sequence_active = false
	_face_player_to(_first_alive_enemy())
	if not battle_over and heroine.has_method("play_idle_animation"):
		heroine.call("play_idle_animation")
	_refresh_ui()

# Which enemies a damage effect hits: all living for AoE, else the targeted one
# (falling back to the first living enemy).
func _effect_targets(effect: Dictionary, target_enemy: CombatEnemy) -> Array:
	if String(effect.get("target", "enemy")) == "all_enemies":
		return _alive_enemies()
	if target_enemy != null and target_enemy.is_alive():
		return [target_enemy]
	var first := _first_alive_enemy()
	return [first] if first != null else []

func _move_player_to_attack_position(enemy: CombatEnemy):
	if not is_instance_valid(heroine) or enemy == null or not is_instance_valid(enemy.node):
		return

	var attack_position := _get_heroine_attack_position(enemy.node.global_position)
	var direction := attack_position - heroine.global_position
	if heroine.has_method("set_facing_direction"):
		heroine.call("set_facing_direction", direction)
	if heroine.has_method("play_run_animation"):
		heroine.call("play_run_animation", direction)

	await _dash_actor_with_sonic_boom(heroine, attack_position, _get_heroine_motion_value("approach_time", 0.35))

func _return_player_home():
	if not is_instance_valid(heroine):
		return

	var direction := player_home_position - heroine.global_position
	if heroine.has_method("set_facing_direction"):
		heroine.call("set_facing_direction", direction)
	if heroine.has_method("play_run_animation"):
		heroine.call("play_run_animation", direction)

	await _dash_actor_with_sonic_boom(heroine, player_home_position, _get_heroine_motion_value("return_time", 0.3))
	if heroine.has_method("set_facing_direction"):
		heroine.call("set_facing_direction", Vector2.RIGHT)
	if heroine.has_method("play_idle_animation"):
		heroine.call("play_idle_animation")

func _face_player_to(enemy: CombatEnemy):
	if not is_instance_valid(heroine) or enemy == null or not is_instance_valid(enemy.node):
		return
	if heroine.has_method("set_facing_direction"):
		heroine.call("set_facing_direction", enemy.node.global_position - heroine.global_position)

func _get_heroine_attack_position(target_position: Vector2) -> Vector2:
	if heroine.has_method("get_attack_position"):
		return heroine.call("get_attack_position", target_position)
	return target_position + Vector2(-120, 0)

func _should_player_move_to_attack_position(_motion_animation: StringName) -> bool:
	if not is_instance_valid(heroine):
		return true
	if heroine.has_method("should_move_to_attack_position"):
		return bool(heroine.call("should_move_to_attack_position", _motion_animation))
	var value: Variant = heroine.get("move_to_attack_position")
	if value is bool:
		return value
	return true

func _get_heroine_motion_value(property_name: StringName, fallback: float) -> float:
	var value: Variant = heroine.get(property_name)
	if value is float or value is int:
		return float(value)
	return fallback

func _dash_actor_with_sonic_boom(actor: Node2D, target_position: Vector2, requested_duration: float):
	if not is_instance_valid(actor):
		return
	var start_position := actor.global_position
	var direction := target_position - start_position
	var distance := direction.length()
	if distance <= 1.0:
		return
	_spawn_sonic_boom(start_position, direction, distance, false)
	var tween := create_tween()
	tween.tween_property(actor, "global_position", target_position, _sonic_boom_dash_time(requested_duration)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tween.finished
	_spawn_sonic_boom(target_position, direction, distance, true)

func _sonic_boom_dash_time(requested_duration: float) -> float:
	return clampf(requested_duration * 0.42, 0.1, 0.16)

func _spawn_sonic_boom(position: Vector2, direction: Vector2, distance: float, is_arrival: bool):
	var vfx := SONIC_BOOM_VFX_SCENE.instantiate()
	add_child(vfx)
	vfx.global_position = position
	vfx.call("play_burst", direction, distance, is_arrival)

func _damage_enemy(enemy: CombatEnemy, amount: int, is_crit := false):
	if enemy == null or enemy.dead:
		return
	var incoming: int = amount
	if enemy.block > 0:
		var blocked: int = min(enemy.block, incoming)
		enemy.block -= blocked
		incoming -= blocked
		if blocked > 0:
			_show_popup(_enemy_screen_position(enemy) + Vector2(0, -40), "BLOCK %d" % blocked, BLOCKED_HIT_COLOR, 24)

	if incoming > 0:
		enemy.hp = max(0, enemy.hp - incoming)
		var dmg_text := ("%d!" % incoming) if is_crit else str(incoming)
		var dmg_color := CRIT_COLOR if is_crit else DAMAGE_TO_ENEMY_COLOR
		var dmg_size := 52 if is_crit else 38
		_show_popup(_enemy_screen_position(enemy), dmg_text, dmg_color, dmg_size)
		_shake_camera(7.0 if is_crit else 4.0)
		if enemy.hp <= 0:
			_kill_enemy(enemy)
		else:
			if enemy.ai_enabled:
				_apply_enemy_ai_rules(enemy)
			_play_enemy_hit(enemy)

	_update_enemy_bar(enemy)
	_check_victory()

func _kill_enemy(enemy: CombatEnemy):
	enemy.dead = true
	if enemy == selected_info_enemy:
		_clear_selected_monster_info()
	_gain_rp(float(rp_settings.get("rp_per_enemy_kill", 0.0)), "KILL")
	if is_instance_valid(enemy.status_bar):
		enemy.status_bar.clear_intent()
		enemy.status_bar.visible = false
	_play_enemy_death(enemy)
	_remove_enemy_after_death(enemy)

func _check_victory():
	if battle_over:
		return
	for enemy in enemies:
		if enemy.is_alive():
			return
	battle_over = true
	battle_won = true
	_clear_selected_monster_info()
	if is_instance_valid(battle_ui):
		battle_ui.call("show_turn_banner", "VICTORY", Color(1.0, 0.85, 0.4))
	end_turn_button.visible = false
	var run_state := _run_state()
	if run_state != null:
		run_state.current_hp = player_hp
		run_state.complete_active_combat_node()
		if run_state.run_cleared:
			restart_button.text = "Run Cleared - Map"
			restart_button.visible = true
		else:
			_show_route_after_victory("The enemies are defeated.")
	else:
		restart_button.text = "Victory - Map"
		restart_button.visible = true
	_log("The enemies are defeated.")

func _show_route_after_victory(message: String):
	await get_tree().create_timer(0.85).timeout
	if battle_won and not route_selection_mode:
		_enter_route_selection_mode(message)

func _show_battle_map_overlay(message := ""):
	if not is_instance_valid(battle_map_overlay):
		battle_map_overlay = BATTLE_MAP_OVERLAY_SCENE.instantiate()
		add_child(battle_map_overlay)
		battle_map_overlay.connect("node_selected", Callable(self, "_on_map_overlay_node_selected"))
	battle_map_overlay.call("show_for_run", message)

func _on_map_overlay_node_selected(node_id: String):
	var run_state := _run_state()
	if run_state == null:
		return
	var node_data := MapRouteData.get_node(node_id)
	if node_data.is_empty():
		return

	if MapRouteData.is_combat_node(node_id):
		run_state.start_combat_node(node_id, node_data.get("monster_id", "mire_imp"), node_data.get("encounter_id", ""))
		await _play_route_wipe_cover()
		_enter_combat_mode()
		await _play_route_wipe_reveal()
		return

	if MapRouteData.is_result_node(node_id):
		run_state.current_node_id = node_id
		var result_text := MapRouteData.apply_result_node_effect(run_state, String(node_data["type"]))
		run_state.complete_node(node_id)
		await _play_route_wipe_cover()
		_enter_route_selection_mode(result_text)
		await _play_route_wipe_reveal()

func _damage_player(amount: int):
	var incoming: int = amount
	if player_block > 0:
		var blocked: int = min(player_block, incoming)
		player_block -= blocked
		incoming -= blocked
		if blocked > 0:
			_log("You block %d damage." % blocked)
			_show_popup(_get_player_screen_position() + Vector2(0, -40), "BLOCK %d" % blocked, BLOCKED_HIT_COLOR, 24)

	if incoming > 0:
		player_hp = max(0, player_hp - incoming)
		_log("You take %d damage." % incoming)
		_show_popup(_get_player_screen_position(), str(incoming), DAMAGE_TO_PLAYER_COLOR, 38)
		_shake_camera(7.0)
		_play_heroine_hit()

	if heroine.has_method("update_hp_state"):
		heroine.call("update_hp_state", player_hp, PLAYER_STATS.max_hp)
	_update_player_hp_bar()

	if player_hp <= 0:
		battle_over = true
		var run_state := _run_state()
		if run_state != null:
			run_state.current_hp = player_hp
		end_turn_button.visible = false
		restart_button.text = "Defeat - Restart"
		restart_button.visible = true
		_clear_selected_monster_info()
		if is_instance_valid(battle_ui):
			battle_ui.call("show_turn_banner", "DEFEAT", Color(1.0, 0.35, 0.35))
		if heroine.has_method("play_dead_animation"):
			heroine.call("play_dead_animation")
		_log("You have fallen.")

func _enemy_turn():
	# Each living enemy performs its current intent in turn.
	for enemy in enemies:
		if battle_over:
			return
		if not enemy.is_alive():
			continue
		if enemy.ai_enabled:
			if enemy.ai_action_count_remaining > 0 or enemy.ai_current_action.is_empty():
				continue
			await _perform_enemy_ai_action(enemy)
			_advance_enemy_ai_step(enemy)
			_update_enemy_bar(enemy)
			continue
		if enemy.intents.is_empty():
			continue
		var intent: EnemyIntentData = enemy.intents[enemy.intent_index]
		match intent.intent_type:
			"attack":
				await _play_enemy_attack_sequence(enemy, _enemy_attack_damage(enemy, intent))
			"block":
				enemy.block += intent.amount
				_show_popup(_enemy_screen_position(enemy), "+%d DEF" % intent.amount, BLOCK_GAIN_COLOR, 28)
				_update_enemy_bar(enemy)
		enemy.intent_index = (enemy.intent_index + 1) % enemy.intents.size()
		_update_enemy_bar(enemy)

func _perform_enemy_ai_action(enemy: CombatEnemy):
	var action := enemy.ai_current_action
	var action_type := str(action.get("action_type", "skill"))
	match action_type:
		"attack":
			await _play_enemy_attack_sequence(enemy, _enemy_ai_attack_damage(enemy, action))
		"defense", "block":
			var block_amount := _enemy_ai_defense_amount(enemy, action)
			enemy.block += block_amount
			_show_popup(_enemy_screen_position(enemy), "+%d DEF" % block_amount, BLOCK_GAIN_COLOR, 28)
			_update_enemy_bar(enemy)
		"buff":
			var gain: int = max(int(action.get("power_value", 1)), 1)
			enemy.ai_attack_bonus_percent += 20 * gain
			_show_popup(_enemy_screen_position(enemy), "%s +%d" % [str(action.get("display_name", "강화")), gain], BLOCK_GAIN_COLOR, 28)
		"skill":
			if str(action.get("power_type", "")) == "count_delta":
				enemy.ai_next_count_delta += int(action.get("power_value", 0))
			_show_popup(_enemy_screen_position(enemy), str(action.get("display_name", "기술")), Color(0.78, 0.62, 1.0), 28)
		_:
			_show_popup(_enemy_screen_position(enemy), str(action.get("display_name", "기술")), Color(0.78, 0.62, 1.0), 28)

func _enemy_ai_attack_damage(enemy: CombatEnemy, action: Dictionary) -> int:
	var base := _enemy_ai_attack(enemy)
	var percent := int(action.get("power_value", 100))
	var damage := int(round(base * float(percent) / 100.0))
	if enemy.ai_attack_bonus_percent > 0:
		damage = int(round(damage * (1.0 + float(enemy.ai_attack_bonus_percent) / 100.0)))
		enemy.ai_attack_bonus_percent = 0
	return damage

func _enemy_ai_defense_amount(enemy: CombatEnemy, action: Dictionary) -> int:
	var power_type := str(action.get("power_type", "flat"))
	var power_value := int(action.get("power_value", 0))
	if power_type == "defense_percent":
		return int(round(_enemy_ai_defense(enemy) * float(power_value) / 100.0))
	return power_value

# Attack intent damage = the monster's attack scaled by the intent percent.
func _enemy_attack_damage(enemy: CombatEnemy, intent: EnemyIntentData) -> int:
	return int(round(enemy.data.stats.attack * float(intent.amount) / 100.0))

func _play_enemy_attack_sequence(enemy: CombatEnemy, amount: int):
	combat_sequence_active = true
	_refresh_ui()
	await _move_enemy_to_attack_position(enemy)
	_play_enemy_attack(enemy)
	var attack_duration: float = _get_enemy_attack_duration(enemy)
	var attack_impact_delay: float = min(_get_enemy_motion_value(enemy, "attack_impact_delay", 0.2), attack_duration)
	await get_tree().create_timer(attack_impact_delay).timeout
	_damage_player(amount)
	await get_tree().create_timer(max(attack_duration - attack_impact_delay, 0.0)).timeout
	await _return_enemy_home(enemy)
	combat_sequence_active = false
	if not battle_over and is_instance_valid(enemy.node) and enemy.node.has_method("play_idle_animation"):
		if enemy.node.has_method("restore_home_facing"):
			enemy.node.call("restore_home_facing")
		enemy.node.call("play_idle_animation")
	_refresh_ui()

func _move_enemy_to_attack_position(enemy: CombatEnemy):
	if enemy == null or not is_instance_valid(enemy.node) or not is_instance_valid(heroine):
		return
	var attack_position := _get_enemy_attack_position(enemy, heroine.global_position)
	var direction := attack_position - enemy.node.global_position
	if enemy.node.has_method("set_facing_direction"):
		enemy.node.call("set_facing_direction", direction)
	if enemy.node.has_method("play_run_animation"):
		enemy.node.call("play_run_animation", direction)
	var tween := create_tween()
	tween.tween_property(enemy.node, "global_position", attack_position, _get_enemy_motion_value(enemy, "approach_time", 0.35))
	await tween.finished

func _return_enemy_home(enemy: CombatEnemy):
	if enemy == null or not is_instance_valid(enemy.node):
		return
	var target_position: Vector2 = enemy.home_position
	var direction := target_position - enemy.node.global_position
	if enemy.node.has_method("set_facing_direction"):
		enemy.node.call("set_facing_direction", direction)
	if enemy.node.has_method("play_run_animation"):
		enemy.node.call("play_run_animation", direction)
	var tween := create_tween()
	tween.tween_property(enemy.node, "global_position", target_position, _get_enemy_motion_value(enemy, "return_time", 0.3))
	await tween.finished
	if enemy.node.has_method("restore_home_facing"):
		enemy.node.call("restore_home_facing")

func _get_enemy_attack_position(enemy: CombatEnemy, target_position: Vector2) -> Vector2:
	if enemy.node.has_method("get_attack_position"):
		return enemy.node.call("get_attack_position", target_position)
	return target_position + Vector2(120, 0)

func _get_enemy_motion_value(enemy: CombatEnemy, property_name: StringName, fallback: float) -> float:
	var value: Variant = enemy.node.get(property_name)
	if value is float or value is int:
		return float(value)
	return fallback

func _get_enemy_attack_duration(enemy: CombatEnemy) -> float:
	if enemy.node.has_method("get_attack_animation_duration"):
		return enemy.node.call("get_attack_animation_duration")
	return _get_enemy_motion_value(enemy, "attack_impact_delay", 0.2) + _get_enemy_motion_value(enemy, "attack_recover_delay", 0.35)

func _play_enemy_attack(enemy: CombatEnemy):
	if is_instance_valid(enemy.node) and enemy.node.has_method("play_attack_animation"):
		enemy.node.call("play_attack_animation")

func _play_heroine_attack(enemy: CombatEnemy, motion_animation: StringName = &"Attack"):
	var target_position: Variant = null
	if enemy != null and is_instance_valid(enemy.node):
		target_position = enemy.node.global_position
	_play_heroine_card_motion(motion_animation, target_position)

func _play_heroine_card_motion(motion_animation: StringName, target_position: Variant = null):
	if heroine.has_method("play_card_animation"):
		heroine.call("play_card_animation", motion_animation, target_position)
	elif motion_animation == &"Attack" and heroine.has_method("play_attack_animation"):
		heroine.call("play_attack_animation", target_position)
	elif heroine.has_method("play_idle_animation"):
		heroine.call("play_idle_animation")

func _play_heroine_hit():
	if heroine.has_method("play_hit_animation"):
		heroine.call("play_hit_animation")

func _on_card_dropped(index: int, screen_position: Vector2):
	if battle_over or combat_sequence_active or index < 0 or index >= hand.size():
		return

	var card: CardData = hand[index]
	var was_play_lifted := is_card_play_lifted
	var dropped_on_enemy := targeted_enemy
	_reset_hand_drag_state()
	if not card.requires_target:
		if was_play_lifted or _is_non_attack_card_map_drop(card, screen_position):
			await _play_card(index)
		return

	if dropped_on_enemy != null:
		await _play_card(index, dropped_on_enemy)
	else:
		_log("%s needs a target." % card.display_name)
		_refresh_ui()

func _on_end_turn_pressed():
	if route_selection_mode or battle_over or combat_sequence_active:
		return
	_on_rp_skill_cancelled()
	_gain_rp(float(rp_settings.get("rp_per_end_turn", 0.0)), "TURN")
	combat_sequence_active = true
	var pending_transitions: Array = []
	for i in range(hand.size()):
		pending_transitions.append({
			"card": hand[i],
			"proxy": _create_card_transition_proxy(i, hand[i]),
		})
	_discard_hand()
	_refresh_ui()
	var discarded_count := 0
	for entry in pending_transitions:
		var card: CardData = entry["card"]
		var proxy: Control = entry["proxy"]
		if hand.has(card):
			if is_instance_valid(proxy):
				proxy.queue_free()
			continue
		_play_discard_proxy(proxy, card, float(discarded_count) * DISCARD_STAGGER)
		discarded_count += 1
	if discarded_count > 0:
		var discard_time := DISCARD_TRANSFER_TIME + 0.22 + float(discarded_count - 1) * DISCARD_STAGGER
		await get_tree().create_timer(discard_time).timeout
	combat_sequence_active = false
	await _tick_enemy_action_count(true)
	if not battle_over:
		_start_player_turn()
	else:
		_refresh_ui()

func _on_restart_pressed():
	if battle_won:
		get_tree().change_scene_to_file(MAP_SCENE_PATH)
		return
	_start_battle()

func _refresh_ui():
	if route_selection_mode:
		return
	end_turn_button.disabled = battle_over or combat_sequence_active or rp_skill_selected
	_reset_hand_drag_state()
	if is_instance_valid(battle_ui):
		battle_ui.call("set_energy", energy, PLAYER_STATS.starting_energy)
		battle_ui.call("set_hand_count", hand.size(), MAX_HAND_SIZE)
		battle_ui.call("set_deck_count", draw_pile.size())
		battle_ui.call("set_tomb_count", discard_pile.size())
		battle_ui.call("set_turn", turn_number)
		battle_ui.call("set_rp_skill_card", rp_skill)
		battle_ui.call("set_rp_state", rage_point, _max_rp(), _rp_skill_cost(), rp_skill_selected, battle_over or combat_sequence_active)
		if rp_skill_selected:
			var rp_positions: Array = []
			for enemy in _alive_enemies():
				rp_positions.append(_enemy_screen_position(enemy))
			battle_ui.call("set_rp_targeting_positions", rp_positions)
		else:
			battle_ui.call("clear_rp_targeting")
	_update_stance_badge()
	_update_player_hp_bar()
	_update_all_enemy_bars()

	for child in hand_container.get_children():
		child.queue_free()

	for i in range(hand.size()):
		var card: CardData = hand[i]
		var effective_cost: int = _effective_cost(card)
		var card_view: Control = CARD_VIEW_SCENE.instantiate()
		card_view.call("set_card", card, i, battle_over or combat_sequence_active or rp_skill_selected or effective_cost > energy, CARD_HAND_SETTINGS, current_stance)
		card_view.call("set_inspired_state", card.inspired, effective_cost)
		card_view.call("set_hand_order", i)
		card_view.connect("card_drag_started", Callable(self, "_on_card_drag_started"))
		card_view.connect("card_drag_moved", Callable(self, "_on_card_drag_moved"))
		card_view.connect("card_dropped", Callable(self, "_on_card_dropped"))
		hand_container.add_child(card_view)
		if i in draw_animation_card_indices:
			card_view.modulate.a = 0.0

	_layout_hand()

func _layout_hand():
	var cards: Array = []
	for child in hand_container.get_children():
		if child is Control and not child.is_queued_for_deletion():
			cards.append(child)
	var count := cards.size()
	for i in range(count):
		var card: Control = cards[i]
		var angle_deg := (float(i) - float(count - 1) * 0.5) * HAND_CARD_ANGLE_STEP
		var theta := deg_to_rad(angle_deg)
		var bottom_center := HAND_ARC_PIVOT + Vector2(sin(theta), -cos(theta)) * HAND_ARC_RADIUS
		card.pivot_offset = CARD_BOTTOM_PIVOT
		card.call("set_rest_rotation", angle_deg)
		card.position = bottom_center - CARD_BOTTOM_PIVOT

func _play_draw_card_from_deck(index: int, delay: float = 0.0):
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	await get_tree().process_frame
	if index < 0 or index >= hand.size() or not is_instance_valid(ui_root):
		return

	var target_card := _get_card_view(index)
	if target_card == null:
		return

	var card: CardData = hand[index]
	var proxy_card: Control = CARD_VIEW_SCENE.instantiate()
	ui_root.add_child(proxy_card)
	proxy_card.call("set_card", card, index, false, CARD_HAND_SETTINGS)
	proxy_card.call("set_hand_order", 700 + index)
	proxy_card.size = target_card.size
	proxy_card.pivot_offset = target_card.pivot_offset
	proxy_card.z_as_relative = false
	proxy_card.z_index = 120
	proxy_card.rotation_degrees = 0.0
	proxy_card.scale = Vector2(0.78, 0.78)
	proxy_card.modulate.a = 0.0

	var target_position := target_card.global_position
	var target_rotation := target_card.rotation_degrees
	var entry_position := target_position + DRAW_ENTRY_OFFSET
	proxy_card.global_position = entry_position
	var source_position := _get_deck_screen_position()
	var entry_center := entry_position + proxy_card.pivot_offset
	var transfer: Variant = _spawn_card_transfer(source_position, entry_center, _card_transfer_color(card), 120.0)
	transfer.call("play", DRAW_TRANSFER_TIME)
	_pulse_deck()
	await get_tree().create_timer(DRAW_TRANSFER_TIME).timeout
	var materialize: Variant = _spawn_card_dissolve(entry_center, proxy_card.size, 0.0, _card_transfer_color(card), true)
	materialize.call("play", DRAW_CARD_ANIMATION_TIME)
	_raise_draw_proxy(proxy_card, 700 + index, 0.08)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(proxy_card, "global_position", target_position, DRAW_CARD_ANIMATION_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(proxy_card, "rotation_degrees", target_rotation, DRAW_CARD_ANIMATION_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(proxy_card, "scale", Vector2.ONE, DRAW_CARD_ANIMATION_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(proxy_card, "modulate:a", 1.0, DRAW_CARD_ANIMATION_TIME * 0.72).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tween.finished
	proxy_card.queue_free()

func _raise_draw_proxy(proxy_card: Control, target_z: int, delay: float):
	await get_tree().create_timer(delay).timeout
	if is_instance_valid(proxy_card):
		proxy_card.z_index = target_z

func _create_card_transition_proxy(index: int, card: CardData) -> Control:
	var source_card := _get_card_view(index)
	if source_card == null or not is_instance_valid(ui_root):
		return null
	var proxy_card: Control = CARD_VIEW_SCENE.instantiate()
	ui_root.add_child(proxy_card)
	proxy_card.call("set_card", card, index, true, CARD_HAND_SETTINGS, current_stance)
	proxy_card.call("set_inspired_state", card.inspired, _effective_cost(card))
	proxy_card.call("set_hand_order", 800 + index)
	proxy_card.size = source_card.size
	proxy_card.pivot_offset = source_card.pivot_offset
	proxy_card.z_as_relative = false
	proxy_card.z_index = 800 + index
	proxy_card.global_position = source_card.global_position
	proxy_card.rotation_degrees = source_card.rotation_degrees
	proxy_card.scale = source_card.scale
	proxy_card.modulate = Color.WHITE
	proxy_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return proxy_card

func _play_discard_proxy(proxy_card: Control, card: CardData, delay: float = 0.0):
	if not is_instance_valid(proxy_card):
		_complete_card_discard(card, _card_transfer_color(card))
		return
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	if not is_instance_valid(proxy_card):
		_complete_card_discard(card, _card_transfer_color(card))
		return
	var color := _card_transfer_color(card)
	var start_center := proxy_card.global_position + proxy_card.pivot_offset
	var dissolve: Variant = _spawn_card_dissolve(start_center, proxy_card.size, proxy_card.rotation_degrees, color)
	dissolve.call("play", 0.24)
	var fade_tween := create_tween()
	fade_tween.set_parallel(true)
	fade_tween.tween_property(proxy_card, "global_position", proxy_card.global_position + Vector2(0, 34), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fade_tween.tween_property(proxy_card, "scale", Vector2(0.76, 0.76), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fade_tween.tween_property(proxy_card, "modulate", Color(color.r, color.g, color.b, 0.0), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await get_tree().create_timer(0.08).timeout
	var transfer: Variant = _spawn_card_transfer(start_center + Vector2(0, 26), _get_tomb_screen_position(), color, 105.0)
	transfer.call("play", DISCARD_TRANSFER_TIME)
	await get_tree().create_timer(DISCARD_TRANSFER_TIME).timeout
	if is_instance_valid(proxy_card):
		proxy_card.queue_free()
	_complete_card_discard(card, color)

func _complete_card_discard(card: CardData, color: Color):
	if not discard_pile.has(card):
		discard_pile.append(card)
	_refresh_ui()
	_pulse_tomb(color)

func _fade_consumed_proxy(proxy_card: Control):
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(proxy_card, "global_position", proxy_card.global_position + Vector2(0, -42), 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(proxy_card, "scale", Vector2(0.72, 0.72), 0.24)
	tween.tween_property(proxy_card, "modulate:a", 0.0, 0.2)
	await tween.finished
	if is_instance_valid(proxy_card):
		proxy_card.queue_free()

func _spawn_card_transfer(from: Vector2, to: Vector2, color: Color, arc_height: float):
	var transfer = CARD_TRANSFER_VFX.new()
	ui_root.add_child(transfer)
	transfer.call("configure", from, to, color, arc_height)
	return transfer

func _spawn_card_dissolve(center: Vector2, source_size: Vector2, rotation_degrees: float, color: Color, materialize: bool = false):
	var dissolve = CARD_DISSOLVE_VFX.new()
	ui_root.add_child(dissolve)
	dissolve.call("configure", center, source_size, rotation_degrees, color, materialize)
	return dissolve

func _play_reshuffle_animation():
	reshuffle_animation_pending = false
	var source := _get_tomb_screen_position()
	var destination := _get_deck_screen_position()
	var color := Color(0.55, 0.72, 1.0)
	for i in range(4):
		_play_pile_transfer_with_delay(source, destination, color, float(i) * 0.045, 135.0 + float(i) * 9.0)
	await get_tree().create_timer(DISCARD_TRANSFER_TIME + 0.14).timeout
	_pulse_deck()

func _play_pile_transfer_with_delay(from: Vector2, to: Vector2, color: Color, delay: float, arc_height: float):
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	var transfer: Variant = _spawn_card_transfer(from, to, color, arc_height)
	transfer.call("play", DISCARD_TRANSFER_TIME)

func _card_transfer_color(card: CardData) -> Color:
	match String(card.card_type):
		"attack":
			return Color(1.0, 0.35, 0.55)
		"shield":
			return Color(0.4, 0.82, 1.0)
		"enhance":
			return Color(0.82, 0.52, 1.0)
		_:
			return Color(0.45, 0.92, 1.0)

func _pulse_deck():
	if not is_instance_valid(battle_ui):
		return
	var deck_hand := battle_ui.get_node_or_null("%DeckHand")
	if deck_hand != null and deck_hand.has_method("play_transfer_pulse"):
		deck_hand.call("play_transfer_pulse")

func _pulse_tomb(color: Color):
	if not is_instance_valid(battle_ui):
		return
	var deck_tomb := battle_ui.get_node_or_null("%DeckTomb")
	if deck_tomb != null and deck_tomb.has_method("play_transfer_pulse"):
		deck_tomb.call("play_transfer_pulse", color)

func _log(message: String):
	battle_log.append(message)

func _input(event: InputEvent):
	if route_selection_mode or not rp_skill_selected:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_on_rp_skill_cancelled()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var rp_target := _enemy_at_screen_position(event.position, RP_MONSTER_CLICK_RADIUS)
		if rp_target != null:
			get_viewport().set_input_as_handled()
			_execute_rp_skill()

func _unhandled_input(event: InputEvent):
	if route_selection_mode:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not is_instance_valid(battle_ui):
			return
		if rp_skill_selected:
			return
		if battle_over or is_targeting_active:
			return
		if battle_ui.has_method("is_monster_info_point_inside") and battle_ui.call("is_monster_info_point_inside", event.position):
			return
		var clicked := _enemy_at_screen_position(event.position)
		if clicked != null:
			_select_monster_info(clicked)
		elif selected_info_enemy != null:
			_clear_selected_monster_info()


func _enemy_at_screen_position(screen_position: Vector2, radius: float = MONSTER_DROP_RADIUS) -> CombatEnemy:
	for enemy in enemies:
		if not enemy.is_alive():
			continue
		if _enemy_screen_rect(enemy).grow(18.0).has_point(screen_position):
			return enemy
		if screen_position.distance_to(_enemy_screen_position(enemy)) <= radius:
			return enemy
	return null

func _select_monster_info(enemy: CombatEnemy):
	if enemy == null or not enemy.is_alive() or not is_instance_valid(battle_ui):
		return
	if selected_info_enemy != enemy:
		selected_info_enemy = enemy
		_refresh_enemy_selection_visuals()
	battle_ui.call("show_monster_info", enemy.data.display_name, _enemy_info_intents(enemy), _enemy_info_intent_index(enemy), _enemy_display_action_count(enemy), _enemy_ai_attack(enemy))

func _refresh_selected_monster_info():
	if selected_info_enemy != null and selected_info_enemy.is_alive() and is_instance_valid(battle_ui):
		battle_ui.call("show_monster_info", selected_info_enemy.data.display_name, _enemy_info_intents(selected_info_enemy), _enemy_info_intent_index(selected_info_enemy), _enemy_display_action_count(selected_info_enemy), _enemy_ai_attack(selected_info_enemy))

func _clear_selected_monster_info():
	selected_info_enemy = null
	_refresh_enemy_selection_visuals()
	if is_instance_valid(battle_ui) and battle_ui.has_method("hide_monster_info"):
		battle_ui.call("hide_monster_info")

func _set_enemy_selected(enemy: CombatEnemy, selected: bool):
	if enemy != null and is_instance_valid(enemy.node) and enemy.node.has_method("set_selected"):
		enemy.node.call("set_selected", selected)

func _refresh_enemy_selection_visuals():
	var show_all_card_targets: bool = is_targeting_active and targeted_enemy != null and _selected_card_targets_all_enemies()
	for enemy in enemies:
		var should_select: bool = enemy.is_alive() and (rp_skill_selected or show_all_card_targets or enemy == targeted_enemy or enemy == selected_info_enemy)
		_set_enemy_selected(enemy, should_select)

func _play_enemy_hit(enemy: CombatEnemy):
	if is_instance_valid(enemy.node) and enemy.node.has_method("play_hit_animation"):
		enemy.node.call("play_hit_animation")
		return
	if is_instance_valid(enemy.sprite):
		var hit_tween := create_tween()
		hit_tween.tween_property(enemy.sprite, "modulate", Color(1.0, 0.35, 0.35), 0.05)
		hit_tween.tween_property(enemy.sprite, "modulate", Color.WHITE, 0.12)

func _play_enemy_death(enemy: CombatEnemy):
	if is_instance_valid(enemy.node) and enemy.node.has_method("play_death_animation"):
		enemy.node.call("play_death_animation")
		return
	if is_instance_valid(enemy.sprite):
		enemy.sprite.modulate = Color(0.45, 0.45, 0.45, 0.75)

func _remove_enemy_after_death(enemy: CombatEnemy):
	if enemy == null or not is_instance_valid(enemy.node):
		return
	var death_node := enemy.node
	var cleanup_delay := _get_enemy_death_cleanup_delay(enemy)
	await get_tree().create_timer(cleanup_delay).timeout
	if enemy.dead and is_instance_valid(death_node):
		death_node.queue_free()

func _get_enemy_death_cleanup_delay(enemy: CombatEnemy) -> float:
	if enemy != null and is_instance_valid(enemy.node):
		var value: Variant = enemy.node.get("death_fade_time")
		if value is float or value is int:
			return max(float(value) + ENEMY_DEATH_CLEANUP_PADDING, 0.05)
	return 0.5

func _update_player_hp_bar():
	if is_instance_valid(battle_ui):
		battle_ui.call("set_player_status", player_hp, PLAYER_STATS.max_hp, player_block)

func _update_route_player_status():
	var run_state := _run_state()
	var current_hp: int = PLAYER_STATS.max_hp
	if run_state != null and run_state.current_hp > 0:
		current_hp = min(run_state.current_hp, PLAYER_STATS.max_hp)
	player_hp = current_hp
	player_block = 0
	_update_player_hp_bar()

func _update_all_enemy_bars():
	for enemy in enemies:
		_update_enemy_bar(enemy)

func _enemy_ai_stats(enemy: CombatEnemy) -> Dictionary:
	return monster_ai_stats.get(enemy.data.id, {})

func _enemy_ai_attack(enemy: CombatEnemy) -> int:
	var stats: Dictionary = _enemy_ai_stats(enemy)
	if stats.has("attack"):
		return int(stats.get("attack", enemy.data.stats.attack))
	return enemy.data.stats.attack

func _enemy_ai_defense(enemy: CombatEnemy) -> int:
	var stats: Dictionary = _enemy_ai_stats(enemy)
	if stats.has("defense"):
		return int(stats.get("defense", enemy.data.stats.defense))
	return enemy.data.stats.defense

func _enemy_ai_intent_type(action: Dictionary) -> StringName:
	var action_type := str(action.get("action_type", "skill"))
	match action_type:
		"attack":
			return &"attack"
		"defense", "block":
			return &"defense"
	return &"skill"

func _enemy_ai_display_amount(enemy: CombatEnemy, action: Dictionary) -> int:
	var action_type := str(action.get("action_type", "skill"))
	var power_type := str(action.get("power_type", "flat"))
	var power_value := int(action.get("power_value", 0))
	if action_type == "attack":
		return power_value
	if action_type == "defense" or action_type == "block":
		if power_type == "defense_percent":
			return int(round(_enemy_ai_defense(enemy) * float(power_value) / 100.0))
		return power_value
	return abs(power_value)

func _enemy_info_intents(enemy: CombatEnemy) -> Array:
	if not enemy.ai_enabled:
		return enemy.intents
	var result: Array = []
	var pattern_steps: Dictionary = monster_ai_pattern_steps.get(enemy.ai_pattern_id, {})
	var step_id := enemy.ai_step_id
	for _i in range(5):
		if not pattern_steps.has(step_id):
			break
		var step: Dictionary = pattern_steps[step_id]
		var action_id := str(step.get("action_id", ""))
		if not monster_ai_actions.has(action_id):
			break
		var action: Dictionary = monster_ai_actions[action_id]
		var intent := EnemyIntentData.new()
		intent.display_name = str(action.get("display_name", ""))
		intent.intent_type = _enemy_ai_intent_type(action)
		intent.amount = _enemy_ai_display_amount(enemy, action)
		intent.icon_label = str(action.get("icon_label", ""))
		intent.description = str(action.get("description", ""))
		result.append(intent)
		var next_step_id := str(step.get("next_step_id", ""))
		if next_step_id.is_empty() or next_step_id == step_id:
			break
		step_id = next_step_id
	return result

func _enemy_info_intent_index(enemy: CombatEnemy) -> int:
	return 0 if enemy.ai_enabled else enemy.intent_index

func _enemy_display_action_count(enemy: CombatEnemy) -> int:
	return enemy.ai_action_count_remaining if enemy.ai_enabled else enemy_action_count_remaining

func _update_enemy_bar(enemy: CombatEnemy):
	if not is_instance_valid(enemy.status_bar):
		return
	if battle_over or enemy.dead:
		enemy.status_bar.clear_intent()
		enemy.status_bar.visible = false
		return
	enemy.status_bar.set_status(enemy.hp, enemy.max_hp(), enemy.block)
	if enemy.ai_enabled and not enemy.ai_current_action.is_empty():
		enemy.status_bar.set_intent(_enemy_ai_intent_type(enemy.ai_current_action), _enemy_ai_display_amount(enemy, enemy.ai_current_action), enemy.ai_action_count_remaining, str(enemy.ai_current_action.get("display_name", "")))
		return
	if enemy.intents.is_empty():
		enemy.status_bar.clear_intent()
		return
	var intent: EnemyIntentData = enemy.intents[enemy.intent_index]
	enemy.status_bar.set_intent(intent.intent_type, intent.amount, enemy_action_count_remaining, intent.display_name)

func _get_enemy_action_count() -> int:
	for enemy in enemies:
		if enemy.is_alive():
			return max(enemy.data.action_count, 1)
	return 1

func _uses_monster_ai() -> bool:
	for enemy in enemies:
		if enemy.is_alive() and enemy.ai_enabled:
			return true
	return false

# Ticks the shared enemy action counter down when a card is played. End Turn can
# force the shared enemy turn immediately. After enemies act, the counter resets.
func _tick_enemy_action_count(force_enemy_turn := false):
	if battle_over or _alive_enemies().is_empty():
		return
	if _uses_monster_ai():
		for enemy in enemies:
			if not enemy.is_alive() or not enemy.ai_enabled:
				continue
			enemy.ai_action_count_remaining = 0 if force_enemy_turn else max(enemy.ai_action_count_remaining - 1, 0)
		var has_ready_enemy := false
		for enemy in enemies:
			if enemy.is_alive() and enemy.ai_enabled and enemy.ai_action_count_remaining <= 0:
				has_ready_enemy = true
				break
		if not has_ready_enemy:
			_update_all_enemy_bars()
			_refresh_selected_monster_info()
			_refresh_ui()
			return
		combat_sequence_active = true
		if is_instance_valid(battle_ui):
			battle_ui.call("show_turn_banner", "ENEMY TURN", Color(1.0, 0.55, 0.5))
		_refresh_ui()
		await get_tree().create_timer(0.5).timeout
		combat_sequence_active = false
		await _enemy_turn()
		_update_all_enemy_bars()
		_refresh_selected_monster_info()
		_refresh_ui()
		return
	enemy_action_count_remaining = 0 if force_enemy_turn else max(enemy_action_count_remaining - 1, 0)
	if enemy_action_count_remaining > 0:
		_update_all_enemy_bars()
		_refresh_selected_monster_info()
		_refresh_ui()
		return
	combat_sequence_active = true
	if is_instance_valid(battle_ui):
		battle_ui.call("show_turn_banner", "ENEMY TURN", Color(1.0, 0.55, 0.5))
	_refresh_ui()
	await get_tree().create_timer(0.5).timeout
	combat_sequence_active = false
	await _enemy_turn()
	if not battle_over:
		enemy_action_count_remaining = _get_enemy_action_count()
	_update_all_enemy_bars()
	_refresh_selected_monster_info()
	_refresh_ui()

func _show_popup(screen_position: Vector2, text: String, color: Color, font_size: int = 34):
	if is_instance_valid(battle_ui):
		battle_ui.call("show_damage_popup", screen_position, text, color, font_size)

func _get_player_screen_position() -> Vector2:
	if not is_instance_valid(heroine):
		return Vector2.ZERO
	return get_viewport().get_canvas_transform() * (heroine.global_position + Vector2(0, -90))

func _shake_camera(intensity: float):
	if not is_instance_valid(camera):
		return
	var tween := create_tween()
	var steps := 4
	for i in range(steps):
		var strength := intensity * float(steps - i) / float(steps)
		var shake_offset := Vector2(randf_range(-strength, strength), randf_range(-strength, strength))
		tween.tween_property(camera, "offset", shake_offset, 0.04)
	tween.tween_property(camera, "offset", Vector2.ZERO, 0.05)

func _on_card_drag_started(index: int):
	_clear_selected_monster_info()
	selected_card_index = index
	is_card_play_lifted = false
	is_targeting_active = false
	targeted_enemy = null
	_show_large_card_preview(index, get_viewport().get_mouse_position())
	_update_inactive_cards(false)

func _on_card_drag_moved(index: int, screen_position: Vector2):
	if selected_card_index != index:
		return
	var should_lift := _is_card_play_lifted(screen_position)
	if _selected_card_requires_target():
		if should_lift and not is_targeting_active:
			is_card_play_lifted = true
			_start_targeting_card(index, screen_position)
			return
		if is_targeting_active:
			_anchor_large_card_preview(_get_targeting_card_center())
			_update_targeting_dot(screen_position)
			return
	_update_large_card_preview_position(screen_position)
	if should_lift == is_card_play_lifted:
		return
	is_card_play_lifted = should_lift
	_update_inactive_cards(is_card_play_lifted)

func _is_card_play_lifted(screen_position: Vector2) -> bool:
	return screen_position.y <= HAND_TOP_Y - CARD_HAND_SETTINGS.play_lift_threshold

func _is_non_attack_card_map_drop(card: CardData, screen_position: Vector2) -> bool:
	return String(card.card_type) != "attack" and screen_position.y < HAND_TOP_Y

func _update_inactive_cards(should_lower: bool):
	for child in hand_container.get_children():
		if not child is Control:
			continue
		if child.card_index == selected_card_index:
			continue
		var target_position := CARD_HAND_SETTINGS.inactive_hand_offset if should_lower else Vector2.ZERO
		child.call("set_inactive_offset", target_position)

func _reset_hand_drag_state():
	selected_card_index = -1
	is_card_play_lifted = false
	is_targeting_active = false
	targeted_enemy = null
	_refresh_enemy_selection_visuals()
	_hide_large_card_preview()
	if is_instance_valid(targeting_dot):
		targeting_dot.visible = false
	if is_instance_valid(battle_ui) and battle_ui.has_method("clear_rp_targeting"):
		battle_ui.call("clear_rp_targeting")
	_update_inactive_cards(false)

func _selected_card_requires_target() -> bool:
	if selected_card_index < 0 or selected_card_index >= hand.size():
		return false
	return hand[selected_card_index].requires_target

func _selected_card_targets_all_enemies() -> bool:
	if selected_card_index < 0 or selected_card_index >= hand.size():
		return false
	for effect in hand[selected_card_index].effects:
		if String(effect.get("type", "")) == "damage" and String(effect.get("target", "enemy")) == "all_enemies":
			return true
	return false

func _start_targeting_card(index: int, screen_position: Vector2):
	is_targeting_active = true
	_update_inactive_cards(true)
	var card_view := _get_card_view(index)
	if card_view != null:
		card_view.call("set_targeting_anchor", _get_targeting_card_center())
	_anchor_large_card_preview(_get_targeting_card_center())
	_update_targeting_dot(screen_position)

func _show_large_card_preview(index: int, screen_position: Vector2):
	_hide_large_card_preview()
	if index < 0 or index >= hand.size() or not is_instance_valid(ui_root):
		return
	var card: CardData = hand[index]
	card_preview_large = CARD_PREVIEW_SCENE.instantiate()
	card_preview_large.z_as_relative = false
	card_preview_large.z_index = 1050
	card_preview_large.modulate.a = 0.0
	card_preview_large.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(card_preview_large)
	var effective_cost := _effective_cost(card)
	card_preview_large.call("set_card", card, effective_cost, current_stance)
	card_preview_large.call("set_inspired_state", card.inspired, effective_cost)
	_update_large_card_preview_position(screen_position)
	var tween := create_tween()
	tween.tween_property(card_preview_large, "modulate:a", 1.0, 0.08)

func _update_large_card_preview_position(screen_position: Vector2):
	if not is_instance_valid(card_preview_large):
		return
	var preview_size := card_preview_large.size
	var target_position := screen_position - Vector2(preview_size.x * 0.5, preview_size.y * 0.82)
	card_preview_large.global_position = _clamp_preview_position(target_position, preview_size)

func _anchor_large_card_preview(center_position: Vector2):
	if not is_instance_valid(card_preview_large):
		return
	var preview_size := card_preview_large.size
	card_preview_large.global_position = _clamp_preview_position(center_position - preview_size * 0.5, preview_size)

func _clamp_preview_position(position: Vector2, preview_size: Vector2) -> Vector2:
	var viewport_size := get_viewport().get_visible_rect().size
	return Vector2(
		clamp(position.x, 8.0, max(8.0, viewport_size.x - preview_size.x - 8.0)),
		clamp(position.y, 8.0, max(8.0, viewport_size.y - preview_size.y - 8.0))
	)

func _hide_large_card_preview():
	if is_instance_valid(card_preview_large):
		card_preview_large.queue_free()
	card_preview_large = null

func _get_card_view(index: int) -> Control:
	for child in hand_container.get_children():
		if child is Control and child.card_index == index:
			return child
	return null

func _get_targeting_card_center() -> Vector2:
	return HAND_CENTER_SCREEN + CARD_HAND_SETTINGS.targeting_card_screen_offset

func _update_targeting_dot(screen_position: Vector2):
	var target_position := screen_position
	var hovered_enemy := _enemy_at_screen_position(screen_position)
	if targeted_enemy != hovered_enemy:
		targeted_enemy = hovered_enemy
		_refresh_enemy_selection_visuals()
	if targeted_enemy != null:
		target_position = _enemy_screen_position(targeted_enemy)
	if is_instance_valid(targeting_dot):
		targeting_dot.visible = false
	if not is_instance_valid(battle_ui):
		return
	if targeted_enemy != null and _selected_card_targets_all_enemies() and battle_ui.has_method("set_card_targeting_positions"):
		var target_positions: Array = []
		for enemy in _alive_enemies():
			target_positions.append(_enemy_screen_position(enemy))
		battle_ui.call("set_card_targeting_positions", target_positions)
	elif battle_ui.has_method("set_card_targeting_position"):
		battle_ui.call("set_card_targeting_position", target_position, targeted_enemy != null)

func _enemy_screen_position(enemy: CombatEnemy) -> Vector2:
	if enemy == null or not is_instance_valid(enemy.node):
		return Vector2.ZERO
	return get_viewport().get_canvas_transform() * enemy.node.global_position

func _enemy_screen_rect(enemy: CombatEnemy) -> Rect2:
	if enemy == null or not is_instance_valid(enemy.sprite):
		var center := _enemy_screen_position(enemy)
		return Rect2(center - Vector2.ONE * MONSTER_DROP_RADIUS, Vector2.ONE * MONSTER_DROP_RADIUS * 2.0)
	var local_rect := Rect2(Vector2.ZERO, Vector2.ZERO)
	if enemy.sprite is AnimatedSprite2D:
		local_rect = _animated_sprite_local_rect(enemy.sprite as AnimatedSprite2D)
	elif enemy.sprite is Sprite2D:
		local_rect = (enemy.sprite as Sprite2D).get_rect()
	if local_rect.size == Vector2.ZERO:
		var center := _enemy_screen_position(enemy)
		return Rect2(center - Vector2.ONE * MONSTER_DROP_RADIUS, Vector2.ONE * MONSTER_DROP_RADIUS * 2.0)
	var canvas_transform := get_viewport().get_canvas_transform()
	var corners := [
		local_rect.position,
		local_rect.position + Vector2(local_rect.size.x, 0),
		local_rect.position + local_rect.size,
		local_rect.position + Vector2(0, local_rect.size.y),
	]
	var first_point: Vector2 = canvas_transform * (enemy.sprite.global_transform * corners[0])
	var rect := Rect2(first_point, Vector2.ZERO)
	for i in range(1, corners.size()):
		rect = rect.expand(canvas_transform * (enemy.sprite.global_transform * corners[i]))
	return rect

func _animated_sprite_local_rect(sprite: AnimatedSprite2D) -> Rect2:
	if sprite == null or sprite.sprite_frames == null:
		return Rect2(Vector2.ZERO, Vector2.ZERO)
	var texture := sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	if texture == null:
		return Rect2(Vector2.ZERO, Vector2.ZERO)
	var texture_size := texture.get_size()
	var position := sprite.offset
	if sprite.centered:
		position -= texture_size * 0.5
	return Rect2(position, texture_size)

func _get_deck_screen_position() -> Vector2:
	if is_instance_valid(battle_ui):
		var deck_hand := battle_ui.get_node_or_null("%DeckHand")
		if deck_hand is Control:
			if deck_hand.has_method("get_effect_anchor"):
				return deck_hand.call("get_effect_anchor")
			return deck_hand.get_global_rect().get_center()
	return HAND_CENTER_SCREEN

func _get_tomb_screen_position() -> Vector2:
	if is_instance_valid(battle_ui):
		var deck_tomb := battle_ui.get_node_or_null("%DeckTomb")
		if deck_tomb is Control:
			if deck_tomb.has_method("get_effect_anchor"):
				return deck_tomb.call("get_effect_anchor")
			return deck_tomb.get_global_rect().get_center()
	return HAND_CENTER_SCREEN

func _apply_targeting_dot_style(is_targeted: bool):
	if targeting_dot_style == null:
		return
	var radius := int(CARD_HAND_SETTINGS.targeting_dot_radius)
	targeting_dot_style.bg_color = CARD_HAND_SETTINGS.targeting_dot_targeted_color if is_targeted else CARD_HAND_SETTINGS.targeting_dot_color
	targeting_dot_style.border_color = Color(1.0, 0.86, 0.86, 0.92)
	targeting_dot_style.border_width_left = CARD_HAND_SETTINGS.targeting_dot_border_width
	targeting_dot_style.border_width_top = CARD_HAND_SETTINGS.targeting_dot_border_width
	targeting_dot_style.border_width_right = CARD_HAND_SETTINGS.targeting_dot_border_width
	targeting_dot_style.border_width_bottom = CARD_HAND_SETTINGS.targeting_dot_border_width
	targeting_dot_style.corner_radius_top_left = radius
	targeting_dot_style.corner_radius_top_right = radius
	targeting_dot_style.corner_radius_bottom_right = radius
	targeting_dot_style.corner_radius_bottom_left = radius
