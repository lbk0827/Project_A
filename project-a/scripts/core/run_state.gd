extends Node

const START_NODE_ID := "BaseCamp"
const STARTING_MAX_HP := 150

var current_node_id := START_NODE_ID
var active_combat_node_id := ""
var current_monster_id := ""
var current_encounter_id := ""
var completed_nodes: Dictionary = {}
var run_cleared := false
var max_hp := STARTING_MAX_HP
var current_hp := STARTING_MAX_HP
var gold := 0
# The run's persistent deck as a list of card ids. Grows via combat rewards and
# carries across battles.
var deck: Array[String] = []

func reset_run():
	current_node_id = START_NODE_ID
	active_combat_node_id = ""
	current_monster_id = ""
	current_encounter_id = ""
	completed_nodes.clear()
	run_cleared = false
	max_hp = STARTING_MAX_HP
	current_hp = max_hp
	gold = 0
	deck = _default_deck()

func get_deck() -> Array[String]:
	if deck.is_empty():
		deck = _default_deck()
	return deck

func add_card_to_deck(card_id: String):
	if not card_id.is_empty():
		get_deck().append(card_id)

func _default_deck() -> Array[String]:
	# Tsuki's starting deck (card id repeated per its copy count).
	var starter: Array[String] = []
	starter.append("CrescentSlash")
	starter.append("CrescentSlash")
	starter.append("FlowGuard")
	starter.append("StanceShift")
	starter.append("AfterimageThrust")
	starter.append("BreathReset")
	starter.append("RuptureCleave")
	starter.append("HalfmoonCombo")
	return starter

func start_combat_node(node_id: String, monster_id := "", encounter_id := ""):
	active_combat_node_id = node_id
	current_monster_id = monster_id
	current_encounter_id = encounter_id

func complete_active_combat_node():
	if active_combat_node_id.is_empty():
		return
	complete_node(active_combat_node_id)
	current_node_id = active_combat_node_id
	if active_combat_node_id == "Boss1":
		run_cleared = true
	active_combat_node_id = ""
	current_monster_id = ""
	current_encounter_id = ""

func complete_node(node_id: String):
	if node_id == START_NODE_ID:
		return
	completed_nodes[node_id] = true

func is_node_completed(node_id: String) -> bool:
	return completed_nodes.has(node_id)

func gain_gold(amount: int):
	gold = max(gold + amount, 0)

func heal(amount: int):
	current_hp = clamp(current_hp + amount, 0, max_hp)
