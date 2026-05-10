extends Node2D

const MAX_HAND_SIZE := 5
const PLAYER_MAX_HP := 40
const ENEMY_MAX_HP := 44
const STARTING_ENERGY := 3
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
var player_status_label: Label
var enemy_status_label: Label
var turn_label: Label
var deck_label: Label
var discard_label: Label
var intent_label: Label
var result_label: Label
var log_label: Label
var hand_container: HBoxContainer
var end_turn_button: Button
var restart_button: Button

func _ready():
	_setup_scene()
	_build_ui()
	_start_battle()

func _process(delta: float):
	if is_instance_valid(camera) and is_instance_valid(heroine):
		camera.global_position = camera.global_position.lerp(heroine.global_position, min(1.0, delta * 8.0))

func _setup_scene():
	heroine.global_position = Vector2(280, 430)
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

	var backdrop := ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.05, 0.06, 0.08, 0.82)
	ui_root.add_child(backdrop)

	player_status_label = _make_label(Vector2(28, 24), Vector2(360, 92), 22)
	ui_root.add_child(player_status_label)

	enemy_status_label = _make_label(Vector2(890, 24), Vector2(340, 92), 22)
	enemy_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ui_root.add_child(enemy_status_label)

	turn_label = _make_label(Vector2(470, 24), Vector2(340, 40), 28)
	turn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui_root.add_child(turn_label)

	intent_label = _make_label(Vector2(820, 118), Vector2(410, 64), 20)
	intent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ui_root.add_child(intent_label)

	deck_label = _make_label(Vector2(28, 118), Vector2(280, 36), 18)
	ui_root.add_child(deck_label)

	discard_label = _make_label(Vector2(28, 150), Vector2(280, 36), 18)
	ui_root.add_child(discard_label)

	log_label = _make_label(Vector2(348, 112), Vector2(584, 180), 18)
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	ui_root.add_child(log_label)

	result_label = _make_label(Vector2(380, 300), Vector2(520, 70), 34)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.visible = false
	ui_root.add_child(result_label)

	hand_container = HBoxContainer.new()
	hand_container.position = Vector2(70, 520)
	hand_container.custom_minimum_size = Vector2(940, 160)
	hand_container.alignment = BoxContainer.ALIGNMENT_CENTER
	hand_container.add_theme_constant_override("separation", 12)
	ui_root.add_child(hand_container)

	end_turn_button = Button.new()
	end_turn_button.text = "End Turn"
	end_turn_button.position = Vector2(1080, 560)
	end_turn_button.custom_minimum_size = Vector2(150, 56)
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	ui_root.add_child(end_turn_button)

	restart_button = Button.new()
	restart_button.text = "Restart Battle"
	restart_button.position = Vector2(1040, 625)
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
	result_label.visible = false
	restart_button.visible = false
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
		result_label.text = "Victory"
		result_label.visible = true
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
		result_label.text = "Defeat"
		result_label.visible = true
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
	player_status_label.text = "Heroine  HP %d/%d  Block %d  Energy %d" % [player_hp, PLAYER_MAX_HP, player_block, energy]
	enemy_status_label.text = "Enemy  HP %d/%d  Block %d" % [enemy_hp, ENEMY_MAX_HP, enemy_block]
	turn_label.text = "Turn %d" % turn_number
	deck_label.text = "Draw Pile: %d" % draw_pile.size()
	discard_label.text = "Discard Pile: %d" % discard_pile.size()

	if battle_over:
		intent_label.text = "Battle finished."
	else:
		var intent: Dictionary = ENEMY_INTENTS[enemy_intent_index]
		if intent["type"] == "attack":
			intent_label.text = "Enemy Intent: %s (%d damage)" % [intent["name"], intent["amount"]]
		else:
			intent_label.text = "Enemy Intent: %s (%d block)" % [intent["name"], intent["amount"]]

	end_turn_button.disabled = battle_over

	for child in hand_container.get_children():
		child.queue_free()

	for i in range(hand.size()):
		var card: Dictionary = hand[i]
		var button := Button.new()
		button.custom_minimum_size = Vector2(170, 150)
		button.text = "%s\nCost %d\n%s" % [card["name"], card["cost"], card["text"]]
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.disabled = battle_over or card["cost"] > energy
		button.pressed.connect(_on_card_pressed.bind(i))
		hand_container.add_child(button)

	log_label.text = "\n".join(battle_log.slice(max(0, battle_log.size() - 6), battle_log.size()))

func _log(message: String):
	battle_log.append(message)

func _make_label(pos: Vector2, size: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.position = pos
	label.custom_minimum_size = size
	label.size = size
	label.add_theme_font_size_override("font_size", font_size)
	return label
