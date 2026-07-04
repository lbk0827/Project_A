extends Node2D

const MAX_HAND_SIZE := 7
const DRAW_CARDS_PER_TURN := 3
const DRAW_CARD_DELAY := 0.12
const DRAW_CARD_ANIMATION_TIME := 0.28
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
const BATTLE_UI_SCENE := preload("res://scenes/ui/battle_ui.tscn")
const CARD_VIEW_SCENE := preload("res://scenes/ui/cards/CardView.tscn")
const DAMAGE_TO_ENEMY_COLOR := Color(1.0, 0.9, 0.4)
const DAMAGE_TO_PLAYER_COLOR := Color(1.0, 0.35, 0.35)
const BLOCK_GAIN_COLOR := Color(0.55, 0.8, 1.0)
const BLOCKED_HIT_COLOR := Color(0.7, 0.75, 0.85)
const CARD_HAND_SETTINGS := preload("res://scenes/ui/cards/CardHandSettings.tres")
const PLAYER_STATS := preload("res://data/player/PlayerStats.tres")
const DEFAULT_MONSTER_DATA := preload("res://data/monsters/MireImp.tres")
const BONE_CRAWLER_DATA := preload("res://data/monsters/BoneCrawler.tres")
const ABYSSAL_CROWN_GUARDIAN_DATA := preload("res://data/monsters/AbyssalCrownGuardian.tres")
const MONSTER_DATA_BY_ID := {
	"mire_imp": DEFAULT_MONSTER_DATA,
	"bone_crawler": BONE_CRAWLER_DATA,
	"abyssal_crown_guardian": ABYSSAL_CROWN_GUARDIAN_DATA,
}
const CARD_SLASH := preload("res://data/cards/Slash.tres")
const CARD_GUARD := preload("res://data/cards/Guard.tres")
const CARD_FOCUS := preload("res://data/cards/Focus.tres")
const CARD_HEAVY_SLASH := preload("res://data/cards/HeavySlash.tres")
const MAP_SCENE_PATH := "res://scenes/map/map_screen.tscn"

@onready var heroine: CharacterBody2D = $Heroine
@onready var camera: Camera2D = $Camera2D
@onready var monster_spawn: Marker2D = $MonsterSpawn

var draw_pile: Array[CardData] = []
var discard_pile: Array[CardData] = []
var hand: Array[CardData] = []
var battle_log: Array[String] = []
var monster_data: MonsterData
var enemy_intents: Array[EnemyIntentData] = []
var monster: Node2D
var monster_sprite: CanvasItem
var enemy_status_bar: EnemyStatusBar
var player_hp := 0
var player_block := 0
var enemy_hp := 0
var enemy_block := 0
var energy := 0
var turn_number := 1
var enemy_intent_index := 0
var enemy_action_count_remaining := 0
var battle_over := false
var battle_won := false
var combat_sequence_active := false
var player_home_position := Vector2.ZERO

var battle_ui: CanvasLayer
var ui_root: Control
var hand_container: Control
var end_turn_button: Button
var restart_button: Button
var targeting_dot: Panel
var targeting_dot_style: StyleBoxFlat
var selected_card_index := -1
var is_card_play_lifted := false
var is_targeting_active := false
var is_monster_targeted := false
var draw_animation_card_index := -1

func _run_state() -> Node:
	return get_node_or_null("/root/RunState")

func _ready():
	_setup_scene()
	_setup_monster(_get_selected_monster_data())
	_build_ui()
	_start_battle()

func _setup_scene():
	player_home_position = heroine.global_position
	if is_instance_valid(camera):
		camera.enabled = true
		camera.position_smoothing_enabled = true
		camera.position_smoothing_speed = 6.0
	if heroine.has_method("set_movement_enabled"):
		heroine.call("set_movement_enabled", false)

func _setup_monster(data: MonsterData):
	monster_data = data
	enemy_intents = data.intents.duplicate()

	if is_instance_valid(monster):
		monster.queue_free()

	monster = data.scene.instantiate()
	monster.name = "Monster"
	add_child(monster)
	monster.global_position = monster_spawn.global_position
	monster_sprite = monster.get_node_or_null("AnimatedSprite2D") as CanvasItem
	_setup_enemy_status_bar()

func _setup_enemy_status_bar():
	if is_instance_valid(enemy_status_bar):
		enemy_status_bar.queue_free()
	enemy_status_bar = EnemyStatusBar.new()
	monster.add_child(enemy_status_bar)
	enemy_status_bar.position = monster_data.hp_bar_offset - EnemyStatusBar.PANEL_SIZE * 0.5

func _get_selected_monster_data() -> MonsterData:
	var run_state := _run_state()
	if run_state != null:
		var monster_id: String = run_state.current_monster_id if "current_monster_id" in run_state else ""
		if not monster_id.is_empty() and MONSTER_DATA_BY_ID.has(monster_id):
			return MONSTER_DATA_BY_ID[monster_id]
	return DEFAULT_MONSTER_DATA

func _build_ui():
	battle_ui = BATTLE_UI_SCENE.instantiate()
	add_child(battle_ui)

	ui_root = battle_ui.get_node("%UIRoot")
	hand_container = battle_ui.get_node("%HandContainer")
	targeting_dot = battle_ui.get_node("%TargetingDot")
	end_turn_button = battle_ui.get_node("%EndTurnButton")
	restart_button = battle_ui.get_node("%RestartButton")

	targeting_dot_style = StyleBoxFlat.new()
	targeting_dot.add_theme_stylebox_override("panel", targeting_dot_style)
	_apply_targeting_dot_style(false)
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	restart_button.pressed.connect(_on_restart_pressed)

func _start_battle():
	draw_pile = _build_starter_deck()
	draw_pile.shuffle()
	discard_pile.clear()
	hand.clear()
	battle_log.clear()
	var run_state := _run_state()
	player_hp = PLAYER_STATS.max_hp
	if run_state != null and run_state.current_hp > 0:
		player_hp = min(run_state.current_hp, PLAYER_STATS.max_hp)
	player_block = 0
	enemy_hp = monster_data.stats.max_hp
	enemy_block = 0
	energy = PLAYER_STATS.starting_energy
	turn_number = 1
	enemy_intent_index = 0
	battle_over = false
	battle_won = false
	combat_sequence_active = false
	selected_card_index = -1
	is_card_play_lifted = false
	is_targeting_active = false
	is_monster_targeted = false
	draw_animation_card_index = -1
	end_turn_button.visible = true
	restart_button.visible = false
	restart_button.text = "Restart Battle"
	heroine.global_position = player_home_position
	if heroine.has_method("reset_combat_state"):
		heroine.call("reset_combat_state", player_hp, PLAYER_STATS.max_hp)
	if monster.has_method("reset_combat_state"):
		monster.call("reset_combat_state")
	_reset_monster_visual()
	if is_instance_valid(enemy_status_bar):
		enemy_status_bar.visible = true
	enemy_action_count_remaining = _get_monster_action_count()
	_update_player_hp_bar()
	_update_enemy_hp_bar()
	_update_enemy_intent()
	_log("Battle start. Defeat %s." % monster_data.display_name)
	_start_player_turn(true)

func _start_player_turn(is_first_turn := false):
	combat_sequence_active = true
	player_block = 0
	energy = PLAYER_STATS.starting_energy
	if not is_first_turn:
		turn_number += 1
	_log("Turn %d. Draw %d cards and spend your energy." % [turn_number, DRAW_CARDS_PER_TURN])
	if is_instance_valid(battle_ui):
		battle_ui.call("show_turn_banner", "PLAYER TURN", Color(0.65, 0.9, 1.0))
	_refresh_ui()
	await _draw_cards_with_animation(DRAW_CARDS_PER_TURN)
	combat_sequence_active = false
	_refresh_ui()

func _build_starter_deck() -> Array[CardData]:
	var deck: Array[CardData] = []
	for _i in range(4):
		deck.append(CARD_SLASH)
	for _i in range(3):
		deck.append(CARD_GUARD)
	for _i in range(2):
		deck.append(CARD_FOCUS)
	deck.append(CARD_HEAVY_SLASH)
	return deck

func _draw_cards(amount: int):
	for _i in range(amount):
		if not _draw_card_to_hand():
			return

func _draw_cards_with_animation(amount: int):
	for _i in range(amount):
		if not _draw_card_to_hand():
			return
		draw_animation_card_index = hand.size() - 1
		_refresh_ui()
		await _play_draw_card_from_deck(draw_animation_card_index)
		draw_animation_card_index = -1
		_refresh_ui()
		await get_tree().create_timer(DRAW_CARD_DELAY).timeout

func _draw_card_to_hand() -> bool:
	if hand.size() >= MAX_HAND_SIZE:
		return false
	if draw_pile.is_empty():
		if discard_pile.is_empty():
			return false
		draw_pile = discard_pile.duplicate(true)
		discard_pile.clear()
		draw_pile.shuffle()
		_log("Discard pile reshuffled into draw pile.")
	hand.append(draw_pile.pop_back())
	return true

func _discard_hand():
	for card in hand:
		discard_pile.append(card)
	hand.clear()

func _play_card(index: int):
	if battle_over or combat_sequence_active or index < 0 or index >= hand.size():
		return

	var card: CardData = hand[index]
	var cost: int = card.cost
	if cost > energy:
		_log("Not enough energy for %s." % card.display_name)
		_refresh_ui()
		return

	energy -= cost
	hand.remove_at(index)
	discard_pile.append(card)

	match card.id:
		"slash":
			_log("Slash deals 6 damage.")
			await _play_player_attack_sequence(card)
		"heavy_slash":
			_log("Heavy Slash crashes in for 12 damage.")
			await _play_player_attack_sequence(card)
		"guard":
			player_block += card.amount
			_log("Guard grants %d block." % card.amount)
			_show_popup(_get_player_screen_position(), "+%d DEF" % card.amount, BLOCK_GAIN_COLOR, 28)
		"focus":
			energy += card.amount
			_draw_cards(1)
			_log("Focus draws 1 card and refunds 1 energy.")
			_show_popup(_get_player_screen_position(), "+%d EP" % card.amount, Color(0.5, 0.9, 1.0), 28)

	_refresh_ui()
	if not battle_over:
		await _tick_enemy_action_count()
	_refresh_ui()

func _play_player_attack_sequence(card: CardData):
	combat_sequence_active = true
	_refresh_ui()
	await _move_player_to_attack_position()
	_play_heroine_attack()
	await get_tree().create_timer(_get_heroine_motion_value("attack_impact_delay", 0.18)).timeout
	_damage_enemy(card.amount)
	await get_tree().create_timer(_get_heroine_motion_value("attack_recover_delay", 0.38)).timeout
	await _return_player_home()
	combat_sequence_active = false
	_face_player_to_monster()
	if not battle_over and heroine.has_method("play_idle_animation"):
		heroine.call("play_idle_animation")
	_refresh_ui()

func _move_player_to_attack_position():
	if not is_instance_valid(heroine) or not is_instance_valid(monster):
		return

	var attack_position := _get_heroine_attack_position(monster.global_position)
	var direction := attack_position - heroine.global_position
	if heroine.has_method("set_facing_direction"):
		heroine.call("set_facing_direction", direction)
	if heroine.has_method("play_run_animation"):
		heroine.call("play_run_animation", direction)

	var tween := create_tween()
	tween.tween_property(heroine, "global_position", attack_position, _get_heroine_motion_value("approach_time", 0.35))
	await tween.finished

func _return_player_home():
	if not is_instance_valid(heroine):
		return

	var direction := player_home_position - heroine.global_position
	if heroine.has_method("set_facing_direction"):
		heroine.call("set_facing_direction", direction)
	if heroine.has_method("play_run_animation"):
		heroine.call("play_run_animation", direction)

	var tween := create_tween()
	tween.tween_property(heroine, "global_position", player_home_position, _get_heroine_motion_value("return_time", 0.3))
	await tween.finished

func _face_player_to_monster():
	if not is_instance_valid(heroine) or not is_instance_valid(monster):
		return
	if heroine.has_method("set_facing_direction"):
		heroine.call("set_facing_direction", monster.global_position - heroine.global_position)

func _get_heroine_attack_position(target_position: Vector2) -> Vector2:
	if heroine.has_method("get_attack_position"):
		return heroine.call("get_attack_position", target_position)
	return target_position + Vector2(-120, 0)

func _get_heroine_motion_value(property_name: StringName, fallback: float) -> float:
	var value: Variant = heroine.get(property_name)
	if value is float or value is int:
		return float(value)
	return fallback

func _damage_enemy(amount: int):
	var incoming: int = amount
	if enemy_block > 0:
		var blocked: int = min(enemy_block, incoming)
		enemy_block -= blocked
		incoming -= blocked
		if blocked > 0:
			_log("Enemy blocks %d damage." % blocked)
			_show_popup(_get_monster_screen_position() + Vector2(0, -40), "BLOCK %d" % blocked, BLOCKED_HIT_COLOR, 24)

	var damaged_enemy := false
	if incoming > 0:
		enemy_hp = max(0, enemy_hp - incoming)
		_log("Enemy takes %d damage." % incoming)
		_show_popup(_get_monster_screen_position(), str(incoming), DAMAGE_TO_ENEMY_COLOR, 38)
		_shake_camera(4.0)
		damaged_enemy = true

	if enemy_hp <= 0:
		battle_over = true
		battle_won = true
		_update_enemy_hp_bar()
		if is_instance_valid(enemy_status_bar):
			enemy_status_bar.clear_intent()
		if is_instance_valid(battle_ui):
			battle_ui.call("hide_monster_info")
			battle_ui.call("show_turn_banner", "VICTORY", Color(1.0, 0.85, 0.4))
		end_turn_button.visible = false
		restart_button.text = "Victory - Map"
		restart_button.visible = true
		var run_state := _run_state()
		if run_state != null:
			run_state.current_hp = player_hp
			run_state.complete_active_combat_node()
		_play_monster_death()
		_log("The enemy is defeated.")
	elif damaged_enemy:
		_play_monster_hit()
		_update_enemy_hp_bar()

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
		if is_instance_valid(battle_ui):
			battle_ui.call("hide_monster_info")
			battle_ui.call("show_turn_banner", "DEFEAT", Color(1.0, 0.35, 0.35))
		if heroine.has_method("play_dead_animation"):
			heroine.call("play_dead_animation")
		_log("You have fallen.")

func _enemy_turn():
	if battle_over or enemy_intents.is_empty():
		return

	var intent: EnemyIntentData = enemy_intents[enemy_intent_index]
	match intent.intent_type:
		"attack":
			_log("Enemy uses %s for %d damage." % [intent.display_name, intent.amount])
			await _play_monster_attack_sequence(intent.amount)
		"block":
			enemy_block += intent.amount
			_log("Enemy uses %s and gains %d block." % [intent.display_name, intent.amount])
			_show_popup(_get_monster_screen_position(), "+%d DEF" % intent.amount, BLOCK_GAIN_COLOR, 28)
			_update_enemy_hp_bar()

	enemy_intent_index = (enemy_intent_index + 1) % enemy_intents.size()
	_update_enemy_intent()

func _play_monster_attack_sequence(amount: int):
	combat_sequence_active = true
	_refresh_ui()
	await _move_monster_to_attack_position()
	_play_monster_attack()
	var attack_duration: float = _get_monster_attack_duration()
	var attack_impact_delay: float = min(_get_monster_motion_value("attack_impact_delay", 0.2), attack_duration)
	await get_tree().create_timer(attack_impact_delay).timeout
	_damage_player(amount)
	await get_tree().create_timer(max(attack_duration - attack_impact_delay, 0.0)).timeout
	await _return_monster_home()
	combat_sequence_active = false
	if not battle_over and monster.has_method("play_idle_animation"):
		if monster.has_method("restore_home_facing"):
			monster.call("restore_home_facing")
		monster.call("play_idle_animation")
	_refresh_ui()

func _move_monster_to_attack_position():
	if not is_instance_valid(monster) or not is_instance_valid(heroine):
		return

	var attack_position := _get_monster_attack_position(heroine.global_position)
	var direction := attack_position - monster.global_position
	if monster.has_method("set_facing_direction"):
		monster.call("set_facing_direction", direction)
	if monster.has_method("play_run_animation"):
		monster.call("play_run_animation", direction)

	var tween := create_tween()
	tween.tween_property(monster, "global_position", attack_position, _get_monster_motion_value("approach_time", 0.35))
	await tween.finished

func _return_monster_home():
	if not is_instance_valid(monster):
		return

	var target_position: Vector2 = monster.home_position if "home_position" in monster else monster.global_position
	var direction := target_position - monster.global_position
	if monster.has_method("set_facing_direction"):
		monster.call("set_facing_direction", direction)
	if monster.has_method("play_run_animation"):
		monster.call("play_run_animation", direction)

	var tween := create_tween()
	tween.tween_property(monster, "global_position", target_position, _get_monster_motion_value("return_time", 0.3))
	await tween.finished
	if monster.has_method("restore_home_facing"):
		monster.call("restore_home_facing")

func _get_monster_attack_position(target_position: Vector2) -> Vector2:
	if monster.has_method("get_attack_position"):
		return monster.call("get_attack_position", target_position)
	return target_position + Vector2(120, 0)

func _get_monster_motion_value(property_name: StringName, fallback: float) -> float:
	var value: Variant = monster.get(property_name)
	if value is float or value is int:
		return float(value)
	return fallback

func _get_monster_attack_duration() -> float:
	if monster.has_method("get_attack_animation_duration"):
		return monster.call("get_attack_animation_duration")
	return _get_monster_motion_value("attack_impact_delay", 0.2) + _get_monster_motion_value("attack_recover_delay", 0.35)

func _play_monster_attack():
	if monster.has_method("play_attack_animation"):
		monster.call("play_attack_animation")

func _play_heroine_attack():
	if heroine.has_method("play_attack_animation"):
		var target_position: Variant = null
		if is_instance_valid(monster):
			target_position = monster.global_position
		heroine.call("play_attack_animation", target_position)

func _play_heroine_hit():
	if heroine.has_method("play_hit_animation"):
		heroine.call("play_hit_animation")

func _on_card_dropped(index: int, screen_position: Vector2):
	if battle_over or combat_sequence_active or index < 0 or index >= hand.size():
		return

	var card: CardData = hand[index]
	var was_play_lifted := is_card_play_lifted
	var was_monster_targeted := is_monster_targeted
	_reset_hand_drag_state()
	if not card.requires_target:
		if was_play_lifted:
			await _play_card(index)
		return

	if was_monster_targeted:
		await _play_card(index)
	else:
		_log("%s needs a target." % card.display_name)
		_refresh_ui()

func _on_end_turn_pressed():
	if battle_over or combat_sequence_active:
		return
	combat_sequence_active = true
	_discard_hand()
	_refresh_ui()
	combat_sequence_active = false
	await _tick_enemy_action_count()
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
	end_turn_button.disabled = battle_over or combat_sequence_active
	_reset_hand_drag_state()
	if is_instance_valid(battle_ui):
		battle_ui.call("set_energy", energy, PLAYER_STATS.starting_energy)
		battle_ui.call("set_hand_count", hand.size(), MAX_HAND_SIZE)
		battle_ui.call("set_deck_count", draw_pile.size())
		battle_ui.call("set_tomb_count", discard_pile.size())
		battle_ui.call("set_turn", turn_number)
	_update_player_hp_bar()
	_update_enemy_hp_bar()

	for child in hand_container.get_children():
		child.queue_free()

	for i in range(hand.size()):
		var card: CardData = hand[i]
		var card_view: Control = CARD_VIEW_SCENE.instantiate()
		card_view.call("set_card", card, i, battle_over or combat_sequence_active or card.cost > energy, CARD_HAND_SETTINGS)
		card_view.call("set_hand_order", i)
		card_view.connect("card_drag_started", Callable(self, "_on_card_drag_started"))
		card_view.connect("card_drag_moved", Callable(self, "_on_card_drag_moved"))
		card_view.connect("card_dropped", Callable(self, "_on_card_dropped"))
		hand_container.add_child(card_view)
		if i == draw_animation_card_index:
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
		card.rotation_degrees = angle_deg
		card.position = bottom_center - CARD_BOTTOM_PIVOT

func _play_draw_card_from_deck(index: int):
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
	proxy_card.z_index = 700 + index
	proxy_card.rotation_degrees = 0.0
	proxy_card.scale = Vector2(0.8, 0.8)
	proxy_card.modulate.a = 1.0

	var source_position := _get_deck_screen_position() - proxy_card.size * 0.5
	var target_position := target_card.global_position
	proxy_card.global_position = source_position

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(proxy_card, "global_position", target_position, DRAW_CARD_ANIMATION_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(proxy_card, "rotation_degrees", target_card.rotation_degrees, DRAW_CARD_ANIMATION_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(proxy_card, "scale", Vector2.ONE, DRAW_CARD_ANIMATION_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished
	proxy_card.queue_free()

func _log(message: String):
	battle_log.append(message)
	if is_instance_valid(battle_ui) and battle_ui.has_method("show_toast"):
		battle_ui.call("show_toast", message)

func _unhandled_input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not is_instance_valid(battle_ui):
			return
		if battle_over or is_targeting_active:
			return
		if _is_monster_drop_position(event.position):
			if battle_ui.call("is_monster_info_visible"):
				battle_ui.call("hide_monster_info")
			else:
				battle_ui.call("show_monster_info", monster_data.display_name, enemy_intents, enemy_intent_index, enemy_action_count_remaining)
		elif battle_ui.call("is_monster_info_visible"):
			battle_ui.call("hide_monster_info")


func _is_monster_drop_position(screen_position: Vector2) -> bool:
	if not is_instance_valid(monster):
		return false
	var monster_screen_position := _get_monster_screen_position()
	return screen_position.distance_to(monster_screen_position) <= MONSTER_DROP_RADIUS

func _play_monster_hit():
	if monster.has_method("play_hit_animation"):
		monster.call("play_hit_animation")
		return
	if is_instance_valid(monster_sprite):
		var hit_tween := create_tween()
		hit_tween.tween_property(monster_sprite, "modulate", Color(1.0, 0.35, 0.35), 0.05)
		hit_tween.tween_property(monster_sprite, "modulate", Color.WHITE, 0.12)

func _play_monster_death():
	if monster.has_method("play_death_animation"):
		monster.call("play_death_animation")
		return
	if is_instance_valid(monster_sprite):
		monster_sprite.modulate = Color(0.45, 0.45, 0.45, 0.75)

func _reset_monster_visual():
	if is_instance_valid(monster_sprite):
		monster_sprite.modulate = Color.WHITE

func _update_player_hp_bar():
	if is_instance_valid(battle_ui):
		battle_ui.call("set_player_status", player_hp, PLAYER_STATS.max_hp, player_block)

func _update_enemy_hp_bar():
	if is_instance_valid(enemy_status_bar):
		enemy_status_bar.set_status(enemy_hp, monster_data.stats.max_hp, enemy_block)

func _update_enemy_intent():
	if not is_instance_valid(enemy_status_bar) or enemy_intents.is_empty():
		return
	if battle_over:
		enemy_status_bar.clear_intent()
		return
	var intent: EnemyIntentData = enemy_intents[enemy_intent_index]
	enemy_status_bar.set_intent(intent.intent_type, intent.amount, enemy_action_count_remaining, intent.display_name)

func _get_monster_action_count() -> int:
	if monster_data == null:
		return 1
	return max(monster_data.action_count, 1)

# Ticks the enemy action counter down by one "time unit" (a card played or the
# turn ended). When it reaches zero the monster performs its telegraphed intent,
# then the counter resets and the intent advances to the next in the cycle.
func _tick_enemy_action_count():
	if battle_over or enemy_intents.is_empty():
		return
	enemy_action_count_remaining = max(enemy_action_count_remaining - 1, 0)
	if enemy_action_count_remaining > 0:
		_update_enemy_intent()
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
		enemy_action_count_remaining = _get_monster_action_count()
	_update_enemy_intent()
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
	selected_card_index = index
	is_card_play_lifted = false
	is_targeting_active = false
	is_monster_targeted = false
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
			_update_targeting_dot(screen_position)
			return
	if should_lift == is_card_play_lifted:
		return
	is_card_play_lifted = should_lift
	_update_inactive_cards(is_card_play_lifted)

func _is_card_play_lifted(screen_position: Vector2) -> bool:
	return screen_position.y <= HAND_TOP_Y - CARD_HAND_SETTINGS.play_lift_threshold

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
	is_monster_targeted = false
	if is_instance_valid(targeting_dot):
		targeting_dot.visible = false
	_update_inactive_cards(false)

func _selected_card_requires_target() -> bool:
	if selected_card_index < 0 or selected_card_index >= hand.size():
		return false
	return hand[selected_card_index].requires_target

func _start_targeting_card(index: int, screen_position: Vector2):
	is_targeting_active = true
	_update_inactive_cards(true)
	var card_view := _get_card_view(index)
	if card_view != null:
		card_view.call("set_targeting_anchor", _get_targeting_card_center())
	_update_targeting_dot(screen_position)

func _get_card_view(index: int) -> Control:
	for child in hand_container.get_children():
		if child is Control and child.card_index == index:
			return child
	return null

func _get_targeting_card_center() -> Vector2:
	return HAND_CENTER_SCREEN + CARD_HAND_SETTINGS.targeting_card_screen_offset

func _update_targeting_dot(screen_position: Vector2):
	if not is_instance_valid(targeting_dot):
		return
	var target_position := screen_position
	is_monster_targeted = _is_monster_drop_position(screen_position)
	if is_monster_targeted:
		target_position = _get_monster_screen_position()
	_apply_targeting_dot_style(is_monster_targeted)
	var diameter := CARD_HAND_SETTINGS.targeting_dot_radius * 2.0
	targeting_dot.size = Vector2(diameter, diameter)
	targeting_dot.position = target_position - targeting_dot.size * 0.5
	targeting_dot.visible = true

func _get_monster_screen_position() -> Vector2:
	if not is_instance_valid(monster):
		return Vector2.ZERO
	return get_viewport().get_canvas_transform() * monster.global_position

func _get_deck_screen_position() -> Vector2:
	if is_instance_valid(battle_ui):
		var deck_hand := battle_ui.get_node_or_null("%DeckHand")
		if deck_hand is Control:
			return deck_hand.get_global_rect().get_center()
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
