extends Node2D

# One combat enemy's runtime state (spawned node + its combat data).
class CombatEnemy:
	var node: Node2D
	var sprite: CanvasItem
	var data: MonsterData
	var intents: Array = []
	var intent_index := 0
	var hp := 0
	var block := 0
	var status_bar: EnemyStatusBar
	var home_position := Vector2.ZERO
	var dead := false

	func is_alive() -> bool:
		return not dead and hp > 0

	func max_hp() -> int:
		return data.stats.max_hp

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
const CRIT_COLOR := Color(1.0, 0.5, 0.1)
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
const CHARACTER_CARDS_PATH := "res://data/generated/character_cards.json"
const MAP_SCENE_PATH := "res://scenes/map/map_screen.tscn"

@onready var heroine: CharacterBody2D = $Heroine
@onready var camera: Camera2D = $Camera2D
@onready var monster_spawn: Marker2D = $MonsterSpawn

var draw_pile: Array[CardData] = []
var discard_pile: Array[CardData] = []
var hand: Array[CardData] = []
var battle_log: Array[String] = []
var enemies: Array = []
var targeted_enemy: CombatEnemy = null
var player_hp := 0
var player_block := 0
var energy := 0
# Temporary +% bonus to Tsuki's attack-card damage for the current turn.
var _attack_damage_bonus_percent := 0
# 빙점 칼날(강화) passive: playing an inspired card deals bonus AoE this combat.
var _inspired_play_passive := false
var card_library: Dictionary = {}
var turn_number := 1
# Shared enemy action counter: all living enemies act together when it hits 0.
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
var draw_animation_card_index := -1

func _run_state() -> Node:
	return get_node_or_null("/root/RunState")

func _ready():
	card_library = _load_card_library()
	_setup_scene()
	_setup_enemies(_get_encounter_datas())
	_build_ui()
	_start_battle()

func _load_card_library() -> Dictionary:
	var library: Dictionary = {}
	var file := FileAccess.open(CHARACTER_CARDS_PATH, FileAccess.READ)
	if file == null:
		return library
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not (parsed is Array):
		return library
	for entry in parsed:
		var card := CardData.new()
		card.id = String(entry.get("id", ""))
		card.display_name = String(entry.get("display_name", ""))
		card.cost = int(entry.get("cost", 0))
		card.text = String(entry.get("text", ""))
		card.card_type = StringName(String(entry.get("card_type", "skill")))
		card.effects = entry.get("effects", [])
		var keywords: Variant = entry.get("keywords", [])
		card.keywords = keywords if keywords is Array else []
		var inspiration: Variant = entry.get("inspiration", [])
		card.inspiration = inspiration if inspiration is Array else []
		card.requires_target = _derive_requires_target(card.effects)
		library[card.id] = card
	return library

func _derive_requires_target(effects: Array) -> bool:
	for effect in effects:
		if String(effect.get("type", "")) == "damage" and String(effect.get("target", "enemy")) == "enemy":
			return true
	return false

func _setup_scene():
	player_home_position = heroine.global_position
	if is_instance_valid(camera):
		camera.enabled = true
		camera.position_smoothing_enabled = true
		camera.position_smoothing_speed = 6.0
	if heroine.has_method("set_movement_enabled"):
		heroine.call("set_movement_enabled", false)

func _setup_enemies(datas: Array):
	for enemy in enemies:
		if is_instance_valid(enemy.node):
			enemy.node.queue_free()
	enemies.clear()
	var count := datas.size()
	for i in range(count):
		var data: MonsterData = datas[i]
		var enemy := CombatEnemy.new()
		enemy.data = data
		enemy.intents = data.intents.duplicate()
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
	if data == ABYSSAL_CROWN_GUARDIAN_DATA:
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
	turn_number = 1
	battle_over = false
	battle_won = false
	combat_sequence_active = false
	_inspired_play_passive = false
	selected_card_index = -1
	is_card_play_lifted = false
	is_targeting_active = false
	targeted_enemy = null
	draw_animation_card_index = -1
	end_turn_button.visible = true
	restart_button.visible = false
	restart_button.text = "Restart Battle"
	heroine.global_position = player_home_position
	if heroine.has_method("reset_combat_state"):
		heroine.call("reset_combat_state", player_hp, PLAYER_STATS.max_hp)
	for enemy in enemies:
		enemy.hp = enemy.max_hp()
		enemy.block = 0
		enemy.intent_index = 0
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
	_start_player_turn(true)

func _start_player_turn(is_first_turn := false):
	combat_sequence_active = true
	player_block = 0
	energy = PLAYER_STATS.starting_energy
	_attack_damage_bonus_percent = 0
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
	hand.append(_instance_for_hand(draw_pile.pop_back()))
	return true

# Hand cards are per-copy instances so runtime state (inspiration) is not
# shared between duplicate cards of the same id.
func _instance_for_hand(card: CardData) -> CardData:
	var copy: CardData = card.duplicate()
	copy.inspired = false
	return copy

func _discard_hand():
	# Cards with 보존(Retain) stay in hand at end of turn.
	var kept: Array[CardData] = []
	for card in hand:
		if "보존" in card.keywords:
			card.inspired = false
			kept.append(card)
		else:
			discard_pile.append(card)
	hand = kept

func _play_card(index: int, target_enemy: CombatEnemy = null):
	if battle_over or combat_sequence_active or index < 0 or index >= hand.size():
		return

	var card: CardData = hand[index]
	var cost: int = _effective_cost(card)
	if cost > energy:
		_log("Not enough energy for %s." % card.display_name)
		_refresh_ui()
		return

	var is_inspired: bool = card.inspired
	energy -= cost
	hand.remove_at(index)
	# Enhance cards install a lasting effect instead of going to discard.
	if String(card.card_type) != "enhance":
		discard_pile.append(card)
	_log("%s 사용." % card.display_name)

	# Split into enemy-attack effects (played through the attack animation) and
	# instant effects (block/draw/energy applied right away). Passives install
	# a lasting effect rather than resolving now.
	var attack_effects: Array = []
	var instant_effects: Array = []
	for effect in card.effects:
		if String(effect.get("type", "")) == "passive":
			_install_passive(effect)
		elif _is_enemy_damage_effect(effect):
			attack_effects.append(effect.duplicate())
		else:
			instant_effects.append(effect)

	if is_inspired:
		_apply_inspiration(card, attack_effects)
	# 빙점 칼날 passive: playing an inspired card deals bonus AoE.
	if is_inspired and _inspired_play_passive:
		attack_effects.append({ "type": "damage", "percent": 120, "target": "all_enemies" })

	_apply_instant_effects(instant_effects)
	if not attack_effects.is_empty():
		await _play_player_attack_sequence(attack_effects, target_enemy)

	_refresh_ui()
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
		match String(entry.get("type", "")):
			"add_hit":
				var base_hits: Array = attack_effects.duplicate()
				for _i in range(int(entry.get("amount", 0))):
					for effect in base_hits:
						attack_effects.append(effect.duplicate())
			"damage_delta":
				var delta: float = float(entry.get("percent", 0))
				for effect in attack_effects:
					if effect.has("percent"):
						effect["percent"] = int(round(float(effect["percent"]) * (1.0 + delta / 100.0)))

func _install_passive(effect: Dictionary):
	if String(effect.get("trigger", "")) == "on_play_inspired_card":
		_inspired_play_passive = true
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
				_draw_cards_typed(int(effect.get("amount", 0)), String(effect.get("card_type", "")))
			"energy":
				var gain := int(effect.get("amount", 0))
				energy += gain
				_show_popup(_get_player_screen_position(), "+%d EP" % gain, Color(0.5, 0.9, 1.0), 28)
			"buff":
				if String(effect.get("buff", "")) == "attack_damage_up":
					_attack_damage_bonus_percent += int(effect.get("percent", 0))
					_show_popup(_get_player_screen_position(), "공격 강화", Color(1.0, 0.8, 0.3), 24)
			"damage":
				_damage_player(int(effect.get("amount", 0)))
			"activate_inspiration":
				_activate_random_inspiration(int(effect.get("amount", 1)))

# Computed damage of a single attack effect: percent of attack power (or flat
# amount), boosted by this turn's attack buff, then rolled for a critical hit.
func _compute_card_damage(effect: Dictionary) -> Dictionary:
	var base: int
	if effect.has("percent"):
		base = int(round(PLAYER_STATS.attack_power * float(effect["percent"]) / 100.0))
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
		return int(round(PLAYER_STATS.defense_power * float(effect["percent"]) / 100.0))
	return int(effect.get("amount", 0))

func _draw_cards_typed(amount: int, card_type: String):
	if card_type.is_empty():
		_draw_cards(amount)
		return
	for _i in range(amount):
		if not _draw_typed_card(card_type):
			return

func _draw_typed_card(card_type: String) -> bool:
	if hand.size() >= MAX_HAND_SIZE:
		return false
	if draw_pile.is_empty():
		if discard_pile.is_empty():
			return false
		draw_pile = discard_pile.duplicate(true)
		discard_pile.clear()
		draw_pile.shuffle()
	for i in range(draw_pile.size() - 1, -1, -1):
		if String(draw_pile[i].card_type) == card_type:
			hand.append(_instance_for_hand(draw_pile[i]))
			draw_pile.remove_at(i)
			return true
	# No matching type left; draw the top card instead.
	hand.append(_instance_for_hand(draw_pile.pop_back()))
	return true

func _play_player_attack_sequence(damage_effects: Array, target_enemy: CombatEnemy):
	combat_sequence_active = true
	_refresh_ui()
	var focus: CombatEnemy = target_enemy if (target_enemy != null and target_enemy.is_alive()) else _first_alive_enemy()
	await _move_player_to_attack_position(focus)
	_play_heroine_attack(focus)
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
	await _return_player_home()
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

func _face_player_to(enemy: CombatEnemy):
	if not is_instance_valid(heroine) or enemy == null or not is_instance_valid(enemy.node):
		return
	if heroine.has_method("set_facing_direction"):
		heroine.call("set_facing_direction", enemy.node.global_position - heroine.global_position)

func _get_heroine_attack_position(target_position: Vector2) -> Vector2:
	if heroine.has_method("get_attack_position"):
		return heroine.call("get_attack_position", target_position)
	return target_position + Vector2(-120, 0)

func _get_heroine_motion_value(property_name: StringName, fallback: float) -> float:
	var value: Variant = heroine.get(property_name)
	if value is float or value is int:
		return float(value)
	return fallback

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
			_play_enemy_hit(enemy)

	_update_enemy_bar(enemy)
	_check_victory()

func _kill_enemy(enemy: CombatEnemy):
	enemy.dead = true
	if is_instance_valid(enemy.status_bar):
		enemy.status_bar.clear_intent()
	_play_enemy_death(enemy)

func _check_victory():
	if battle_over:
		return
	for enemy in enemies:
		if enemy.is_alive():
			return
	battle_over = true
	battle_won = true
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
	_log("The enemies are defeated.")

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
	# Each living enemy performs its current intent in turn.
	for enemy in enemies:
		if battle_over:
			return
		if not enemy.is_alive() or enemy.intents.is_empty():
			continue
		var intent: EnemyIntentData = enemy.intents[enemy.intent_index]
		match intent.intent_type:
			"attack":
				await _play_enemy_attack_sequence(enemy, intent.amount)
			"block":
				enemy.block += intent.amount
				_show_popup(_enemy_screen_position(enemy), "+%d DEF" % intent.amount, BLOCK_GAIN_COLOR, 28)
				_update_enemy_bar(enemy)
		enemy.intent_index = (enemy.intent_index + 1) % enemy.intents.size()
		_update_enemy_bar(enemy)

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

func _play_heroine_attack(enemy: CombatEnemy):
	if heroine.has_method("play_attack_animation"):
		var target_position: Variant = null
		if enemy != null and is_instance_valid(enemy.node):
			target_position = enemy.node.global_position
		heroine.call("play_attack_animation", target_position)

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
		if was_play_lifted:
			await _play_card(index)
		return

	if dropped_on_enemy != null:
		await _play_card(index, dropped_on_enemy)
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
	_update_all_enemy_bars()

	for child in hand_container.get_children():
		child.queue_free()

	for i in range(hand.size()):
		var card: CardData = hand[i]
		var effective_cost: int = _effective_cost(card)
		var card_view: Control = CARD_VIEW_SCENE.instantiate()
		card_view.call("set_card", card, i, battle_over or combat_sequence_active or effective_cost > energy, CARD_HAND_SETTINGS)
		card_view.call("set_inspired_state", card.inspired, effective_cost)
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
		card.call("set_rest_rotation", angle_deg)
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
		var clicked := _enemy_at_screen_position(event.position)
		if clicked != null:
			if battle_ui.call("is_monster_info_visible"):
				battle_ui.call("hide_monster_info")
			else:
				battle_ui.call("show_monster_info", clicked.data.display_name, clicked.intents, clicked.intent_index, enemy_action_count_remaining)
		elif battle_ui.call("is_monster_info_visible"):
			battle_ui.call("hide_monster_info")


func _enemy_at_screen_position(screen_position: Vector2) -> CombatEnemy:
	for enemy in enemies:
		if enemy.is_alive() and screen_position.distance_to(_enemy_screen_position(enemy)) <= MONSTER_DROP_RADIUS:
			return enemy
	return null

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

func _update_player_hp_bar():
	if is_instance_valid(battle_ui):
		battle_ui.call("set_player_status", player_hp, PLAYER_STATS.max_hp, player_block)

func _update_all_enemy_bars():
	for enemy in enemies:
		_update_enemy_bar(enemy)

func _update_enemy_bar(enemy: CombatEnemy):
	if not is_instance_valid(enemy.status_bar):
		return
	enemy.status_bar.set_status(enemy.hp, enemy.max_hp(), enemy.block)
	if battle_over or enemy.dead or enemy.intents.is_empty():
		enemy.status_bar.clear_intent()
		return
	var intent: EnemyIntentData = enemy.intents[enemy.intent_index]
	enemy.status_bar.set_intent(intent.intent_type, intent.amount, enemy_action_count_remaining, intent.display_name)

func _get_enemy_action_count() -> int:
	for enemy in enemies:
		if enemy.is_alive():
			return max(enemy.data.action_count, 1)
	return 1

# Ticks the shared enemy action counter down by one "time unit" (a card played
# or the turn ended). When it reaches zero, every living enemy acts in turn,
# then the counter resets.
func _tick_enemy_action_count():
	if battle_over or _alive_enemies().is_empty():
		return
	enemy_action_count_remaining = max(enemy_action_count_remaining - 1, 0)
	if enemy_action_count_remaining > 0:
		_update_all_enemy_bars()
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
	targeted_enemy = null
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
	targeted_enemy = null
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
	targeted_enemy = _enemy_at_screen_position(screen_position)
	if targeted_enemy != null:
		target_position = _enemy_screen_position(targeted_enemy)
	_apply_targeting_dot_style(targeted_enemy != null)
	var diameter := CARD_HAND_SETTINGS.targeting_dot_radius * 2.0
	targeting_dot.size = Vector2(diameter, diameter)
	targeting_dot.position = target_position - targeting_dot.size * 0.5
	targeting_dot.visible = true

func _enemy_screen_position(enemy: CombatEnemy) -> Vector2:
	if enemy == null or not is_instance_valid(enemy.node):
		return Vector2.ZERO
	return get_viewport().get_canvas_transform() * enemy.node.global_position

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
