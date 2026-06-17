extends Node

const START_NODE_ID := "start"

var current_node_id := START_NODE_ID
var active_combat_node_id := ""
var completed_nodes: Dictionary = {}

func reset_run():
	current_node_id = START_NODE_ID
	active_combat_node_id = ""
	completed_nodes.clear()

func start_combat_node(node_id: String):
	active_combat_node_id = node_id

func complete_active_combat_node():
	if active_combat_node_id.is_empty():
		return
	complete_node(active_combat_node_id)
	current_node_id = active_combat_node_id
	active_combat_node_id = ""

func complete_node(node_id: String):
	if node_id == START_NODE_ID:
		return
	completed_nodes[node_id] = true

func is_node_completed(node_id: String) -> bool:
	return completed_nodes.has(node_id)
