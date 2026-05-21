extends Node2D

const MAX_HAND_SIZE := 5
const CARD_SPACING := -8
const CARD_FAN_DEGREES := 9.0
const MONSTER_DROP_RADIUS := 90.0
const BATTLE_UI_SCENE := preload("res://scenes/ui/battle_ui.tscn")
const CARD_VIEW_SCENE := preload("res://scenes/ui/cards/CardView.tscn")
const CARD_HAND_SETTINGS := preload("res://scenes/ui/cards/CardHandSettings.tres")
const PLAYER_STATS := preload("res://data/player/PlayerStats.tres")
const MONSTER_STATS := preload("res://data/monsters/MonsterDummyStats.tres")
const CARD_SLASH := preload("res://data/cards/Slash.tres")
const CARD_GUARD := preload("res://data/cards/Guard.tres")
const CARD_FOCUS := preload("res://data/cards/Focus.tres")
const CARD_HEAVY_SLASH := preload("res://data/cards/HeavySlash.tres")
const INTENT_STAB := preload("res://data/monsters/intents/Stab.tres")
const INTENT_BRACE := preload("res://data/monsters/intents/Brace.tres")
const INTENT_HEAVY_BLOW := preload("res://data/monsters/intents/HeavyBlow.tres")
const ENEMY_INTENTS: Array[EnemyIntentData] = [
	INTENT_STAB,
	INTENT_BRACE,
	INTENT_HEAVY_BLOW
]

@onready var heroine: CharacterBody2D = $Heroine
@onready var camera: Camera2D = $Camera2D
@onready var monster: Node2D = $Monster
@onready var monster_sprite: CanvasItem = $Monster/AnimatedSprite2D

var draw_pile: Array[CardData] = []
var discard_pile: Array[CardData] = []
var hand: Array[CardData] = []
var battle_log: Array[String] = []
var player_hp := 0
var player_block := 0
var enemy_hp := 0
var enemy_block := 0
var energy := 0
var turn_number := 1
var enemy_intent_index := 0
var battle_over := false
var combat_sequence_active := false
var player_home_position := Vector2.ZERO

var battle_ui: CanvasLayer
var ui_root: Control
var hand_container: HBoxContainer
var end_turn_button: Button
var restart_button: Button
var targeting_dot: Panel
var targeting_dot_style: StyleBoxFlat
var selected_card_index := -1
var is_card_play_lifted := false
var is_targeting_active := false
var is_monster_targeted := false

func _ready():
	_setup_scene()
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
	player_hp = PLAYER_STATS.max_hp
	player_block = 0
	enemy_hp = MONSTER_STATS.max_hp
	enemy_block = 0
	energy = PLAYER_STATS.starting_energy
	turn_number = 1
	enemy_intent_index = 0
	battle_over = false
	combat_sequence_active = false
	selected_card_index = -1
	is_card_play_lifted = false
	is_targeting_active = false
	is_monster_targeted = false
	end_turn_button.visible = true
	restart_button.visible = false
	restart_button.text = "Restart Battle"
	heroine.global_position = player_home_position
	if heroine.has_method("reset_combat_state"):
		heroine.call("reset_combat_state", player_hp, PLAYER_STATS.max_hp)
	_reset_monster_visual()
	_log("Battle start. Defeat the training enemy.")
	_start_player_turn(true)

func _start_player_turn(is_first_turn := false):
	player_block = 0
	energy = PLAYER_STATS.starting_energy
	_draw_cards(MAX_HAND_SIZE)
	if not is_first_turn:
		turn_number += 1
	_log("Turn %d. Draw up and spend your energy." % turn_number)
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
		if hand.size() >= MAX_HAND_SIZE:
			return
		if draw_pile.is_empty():
			if discard_pile.is_empty():
				return
			draw_pile = discard_pile.duplicate(true)
			discard_pile.clear()
			draw_pile.shuffle()
			_log("Discard pile reshuffled into draw pile.")
		hand.append(draw_pile.pop_back())

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
			_play_player_attack_sequence(card)
		"heavy_slash":
			_log("Heavy Slash crashes in for 12 damage.")
			_play_player_attack_sequence(card)
		"guard":
			player_block += card.amount
			_log("Guard grants %d block." % card.amount)
		"focus":
			energy += card.amount
			_draw_cards(1)
			_log("Focus draws 1 card and refunds 1 energy.")

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

	if incoming > 0:
		enemy_hp = max(0, enemy_hp - incoming)
		_log("Enemy takes %d damage." % incoming)
		_play_monster_hit()

	if enemy_hp <= 0:
		battle_over = true
		end_turn_button.visible = false
		restart_button.text = "Victory - Restart"
		restart_button.visible = true
		if is_instance_valid(monster_sprite):
			monster_sprite.modulate = Color(0.45, 0.45, 0.45, 0.75)
		_log("The enemy is defeated.")

func _damage_player(amount: int):
	var incoming: int = amount
	if player_block > 0:
		var blocked: int = min(player_block, incoming)
		player_block -= blocked
		incoming -= blocked
		if blocked > 0:
			_log("You block %d damage." % blocked)

	if incoming > 0:
		player_hp = max(0, player_hp - incoming)
		_log("You take %d damage." % incoming)
		_play_heroine_hit()

	if heroine.has_method("update_hp_state"):
		heroine.call("update_hp_state", player_hp, PLAYER_STATS.max_hp)

	if player_hp <= 0:
		battle_over = true
		end_turn_button.visible = false
		restart_button.text = "Defeat - Restart"
		restart_button.visible = true
		if heroine.has_method("play_dead_animation"):
			heroine.call("play_dead_animation")
		_log("You have fallen.")

func _enemy_turn():
	if battle_over:
		return

	var intent: EnemyIntentData = ENEMY_INTENTS[enemy_intent_index]
	match intent.intent_type:
		"attack":
			_log("Enemy uses %s for %d damage." % [intent.display_name, intent.amount])
			_damage_player(intent.amount)
		"block":
			enemy_block += intent.amount
			_log("Enemy uses %s and gains %d block." % [intent.display_name, intent.amount])

	enemy_intent_index = (enemy_intent_index + 1) % ENEMY_INTENTS.size()

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
			_play_card(index)
		return

	if was_monster_targeted:
		_play_card(index)
	else:
		_log("%s needs a target." % card.display_name)
		_refresh_ui()

func _on_end_turn_pressed():
	if battle_over or combat_sequence_active:
		return
	_discard_hand()
	_enemy_turn()
	if not battle_over:
		_start_player_turn()
	else:
		_refresh_ui()

func _on_restart_pressed():
	_start_battle()

func _refresh_ui():
	end_turn_button.disabled = battle_over or combat_sequence_active
	_reset_hand_drag_state()
	if is_instance_valid(battle_ui):
		battle_ui.call("set_player_hp", player_hp, PLAYER_STATS.max_hp)
		battle_ui.call("set_deck_count", draw_pile.size())

	for child in hand_container.get_children():
		child.queue_free()

	for i in range(hand.size()):
		var card: CardData = hand[i]
		var card_view: Control = CARD_VIEW_SCENE.instantiate()
		card_view.call("set_card", card, i, battle_over or combat_sequence_active or card.cost > energy, CARD_HAND_SETTINGS)
		card_view.call("set_hand_order", i)
		card_view.rotation_degrees = _get_card_rotation(i, hand.size())
		card_view.connect("card_drag_started", Callable(self, "_on_card_drag_started"))
		card_view.connect("card_drag_moved", Callable(self, "_on_card_drag_moved"))
		card_view.connect("card_dropped", Callable(self, "_on_card_dropped"))
		hand_container.add_child(card_view)

func _log(message: String):
	battle_log.append(message)

func _get_card_rotation(index: int, count: int) -> float:
	if count <= 1:
		return 0.0
	var hand_center := float(count - 1) * 0.5
	return (float(index) - hand_center) / hand_center * CARD_FAN_DEGREES

func _is_monster_drop_position(screen_position: Vector2) -> bool:
	if not is_instance_valid(monster):
		return false
	var monster_screen_position := _get_monster_screen_position()
	return screen_position.distance_to(monster_screen_position) <= MONSTER_DROP_RADIUS

func _play_monster_hit():
	if not is_instance_valid(monster_sprite):
		return
	var hit_tween := create_tween()
	hit_tween.tween_property(monster_sprite, "modulate", Color(1.0, 0.35, 0.35), 0.05)
	hit_tween.tween_property(monster_sprite, "modulate", Color.WHITE, 0.12)

func _reset_monster_visual():
	if is_instance_valid(monster_sprite):
		monster_sprite.modulate = Color.WHITE

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
	if not is_instance_valid(hand_container):
		return false
	var hand_top := hand_container.get_global_rect().position.y
	return screen_position.y <= hand_top - CARD_HAND_SETTINGS.play_lift_threshold

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
	var screen_rect := ui_root.get_global_rect()
	return screen_rect.get_center() + CARD_HAND_SETTINGS.targeting_card_screen_offset

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
