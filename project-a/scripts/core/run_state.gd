extends Node

const START_NODE_ID := "start"
const STARTING_MAX_HP := 40

var current_node_id := START_NODE_ID
var active_combat_node_id := ""
var completed_nodes: Dictionary = {}
var run_cleared := false
var max_hp := STARTING_MAX_HP
var current_hp := STARTING_MAX_HP
var gold := 0

func reset_run():
	current_node_id = START_NODE_ID
	active_combat_node_id = ""
	completed_nodes.clear()
	run_cleared = false
	max_hp = STARTING_MAX_HP
	current_hp = max_hp
	gold = 0

func start_combat_node(node_id: String):
	active_combat_node_id = node_id

func complete_active_combat_node():
	if active_combat_node_id.is_empty():
		return
	complete_node(active_combat_node_id)
	current_node_id = active_combat_node_id
	if active_combat_node_id == "boss_1":
		run_cleared = true
	active_combat_node_id = ""

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
