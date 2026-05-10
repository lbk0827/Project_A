extends Node2D

const MAX_HAND_SIZE := 5
const PLAYER_MAX_HP := 40
const ENEMY_MAX_HP := 44
const STARTING_ENERGY := 3
const CARD_SPACING := -8
const CARD_FAN_DEGREES := 9.0
const CARD_VIEW_SCENE := preload("res://scenes/ui/cards/CardView.tscn")
const CARD_LIBRARY := {
	"slash": {
		"id": "slash",
		"name": "Slash",
		"cost": 1,
		"text": "Deal 6 damage.",
		"type": "attack",
		"amount": 6
	},
	"guard": {
		"id": "guard",
		"name": "Guard",
		"cost": 1,
		"text": "Gain 7 block.",
		"type": "skill",
		"amount": 7
	},
	"focus": {
		"id": "focus",
		"name": "Focus",
		"cost": 0,
		"text": "Draw 1 card. Gain 1 energy.",
		"type": "skill",
		"amount": 1
	},
	"heavy_slash": {
		"id": "heavy_slash",
		"name": "Heavy Slash",
		"cost": 2,
		"text": "Deal 12 damage.",
		"type": "attack",
		"amount": 12
	}
}
const ENEMY_INTENTS := [
	{"name": "Stab", "type": "attack", "amount": 6},
	{"name": "Brace", "type": "block", "amount": 5},
	{"name": "Heavy Blow", "type": "attack", "amount": 9}
]

@onready var heroine: CharacterBody2D = $Heroine
@onready var camera: Camera2D = $Camera2D

var draw_pile: Array[Dictionary] = []
var discard_pile: Array[Dictionary] = []
var hand: Array[Dictionary] = []
var battle_log: Array[String] = []
var player_hp := PLAYER_MAX_HP
var player_block := 0
var enemy_hp := ENEMY_MAX_HP
var enemy_block := 0
var energy := STARTING_ENERGY
var turn_number := 1
var enemy_intent_index := 0
var battle_over := false

var ui_root: Control
var hand_container: HBoxContainer
var end_turn_button: Button
var restart_button: Button

func _ready():
	_setup_scene()
	_build_ui()
	_start_battle()

func _setup_scene():
	if is_instance_valid(camera):
		camera.enabled = true
		camera.position_smoothing_enabled = true
		camera.position_smoothing_speed = 6.0
	if heroine.has_method("set_movement_enabled"):
		heroine.call("set_movement_enabled", false)

func _build_ui():
	var canvas := CanvasLayer.new()
	add_child(canvas)

	ui_root = Control.new()
	ui_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(ui_root)

	hand_container = HBoxContainer.new()
	hand_container.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hand_container.position = Vector2(-365, -200)
	hand_container.custom_minimum_size = Vector2(730, 184)
	hand_container.size = Vector2(730, 184)
	hand_container.alignment = BoxContainer.ALIGNMENT_CENTER
	hand_container.add_theme_constant_override("separation", CARD_SPACING)
	ui_root.add_child(hand_container)

	end_turn_button = Button.new()
	end_turn_button.text = "End Turn"
	end_turn_button.position = Vector2(1080, 630)
	end_turn_button.custom_minimum_size = Vector2(150, 48)
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	ui_root.add_child(end_turn_button)

	restart_button = Button.new()
	restart_button.text = "Restart Battle"
	restart_button.position = Vector2(1040, 575)
	restart_button.custom_minimum_size = Vector2(190, 46)
	restart_button.visible = false
	restart_button.pressed.connect(_on_restart_pressed)
	ui_root.add_child(restart_button)

func _start_battle():
	draw_pile = _build_starter_deck()
	draw_pile.shuffle()
	discard_pile.clear()
	hand.clear()
	battle_log.clear()
	player_hp = PLAYER_MAX_HP
	player_block = 0
	enemy_hp = ENEMY_MAX_HP
	enemy_block = 0
	energy = STARTING_ENERGY
	turn_number = 1
	enemy_intent_index = 0
	battle_over = false
	end_turn_button.visible = true
	restart_button.visible = false
	restart_button.text = "Restart Battle"
	if heroine.has_method("reset_combat_state"):
		heroine.call("reset_combat_state", player_hp, PLAYER_MAX_HP)
	_log("Battle start. Defeat the training enemy.")
	_start_player_turn(true)

func _start_player_turn(is_first_turn := false):
	player_block = 0
	energy = STARTING_ENERGY
	_draw_cards(MAX_HAND_SIZE)
	if not is_first_turn:
		turn_number += 1
	_log("Turn %d. Draw up and spend your energy." % turn_number)
	_refresh_ui()

func _build_starter_deck() -> Array[Dictionary]:
	var deck: Array[Dictionary] = []
	for _i in range(4):
		deck.append(_make_card("slash"))
	for _i in range(3):
		deck.append(_make_card("guard"))
	for _i in range(2):
		deck.append(_make_card("focus"))
	deck.append(_make_card("heavy_slash"))
	return deck

func _make_card(card_id: String) -> Dictionary:
	return CARD_LIBRARY[card_id].duplicate(true)

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
	if battle_over or index < 0 or index >= hand.size():
		return

	var card: Dictionary = hand[index]
	var cost: int = card["cost"]
	if cost > energy:
		_log("Not enough energy for %s." % card["name"])
		_refresh_ui()
		return

	energy -= cost
	hand.remove_at(index)
	discard_pile.append(card)

	match card["id"]:
		"slash":
			_log("Slash deals 6 damage.")
			_damage_enemy(card["amount"])
			_play_heroine_attack()
		"heavy_slash":
			_log("Heavy Slash crashes in for 12 damage.")
			_damage_enemy(card["amount"])
			_play_heroine_attack()
		"guard":
			player_block += card["amount"]
			_log("Guard grants %d block." % card["amount"])
		"focus":
			energy += card["amount"]
			_draw_cards(1)
			_log("Focus draws 1 card and refunds 1 energy.")

	_refresh_ui()

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

	if enemy_hp <= 0:
		battle_over = true
		end_turn_button.visible = false
		restart_button.text = "Victory - Restart"
		restart_button.visible = true
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
		heroine.call("update_hp_state", player_hp, PLAYER_MAX_HP)

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

	var intent: Dictionary = ENEMY_INTENTS[enemy_intent_index]
	match intent["type"]:
		"attack":
			_log("Enemy uses %s for %d damage." % [intent["name"], intent["amount"]])
			_damage_player(intent["amount"])
		"block":
			enemy_block += intent["amount"]
			_log("Enemy uses %s and gains %d block." % [intent["name"], intent["amount"]])

	enemy_intent_index = (enemy_intent_index + 1) % ENEMY_INTENTS.size()

func _play_heroine_attack():
	if heroine.has_method("play_attack_animation"):
		heroine.call("play_attack_animation")

func _play_heroine_hit():
	if heroine.has_method("play_hit_animation"):
		heroine.call("play_hit_animation")

func _on_card_pressed(index: int):
	_play_card(index)

func _on_end_turn_pressed():
	if battle_over:
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
	end_turn_button.disabled = battle_over

	for child in hand_container.get_children():
		child.queue_free()

	for i in range(hand.size()):
		var card: Dictionary = hand[i]
		var card_view: Control = CARD_VIEW_SCENE.instantiate()
		card_view.call("set_card", card, i, battle_over or card["cost"] > energy)
		card_view.call("set_hand_order", i)
		card_view.rotation_degrees = _get_card_rotation(i, hand.size())
		card_view.connect("card_pressed", Callable(self, "_on_card_pressed"))
		hand_container.add_child(card_view)

func _log(message: String):
	battle_log.append(message)

func _get_card_rotation(index: int, count: int) -> float:
	if count <= 1:
		return 0.0
	var hand_center := float(count - 1) * 0.5
	return (float(index) - hand_center) / hand_center * CARD_FAN_DEGREES
