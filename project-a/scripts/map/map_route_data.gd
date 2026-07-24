@tool
extends RefCounted

const DEFAULT_ROUTE: MapRouteResource = preload("res://data/map/DefaultRoute.tres")
const DEFAULT_NEXT_IDS := {
	"BaseCamp": ["Battle1", "Event1"],
	"Battle1": ["Treasure1", "Battle2"],
	"Event1": ["Battle2"],
	"Treasure1": ["Elite1"],
	"Battle2": ["Elite1", "Rest1"],
	"Elite1": ["Rest1"],
	"Rest1": ["Boss1"],
}

static func get_nodes() -> Array:
	var nodes: Array = []
	for route_node in DEFAULT_ROUTE.nodes:
		if route_node == null or route_node.id.is_empty():
			continue
		var node_data := route_node.to_dictionary()
		var normalized_node: Dictionary = node_data.duplicate(true)
		_apply_default_next_ids(normalized_node)
		nodes.append(normalized_node)
	return nodes

static func build_lookup() -> Dictionary:
	var lookup: Dictionary = {}
	for node_data in get_nodes():
		lookup[node_data["id"]] = node_data.duplicate(true)
	return lookup

static func get_node(node_id: String) -> Dictionary:
	for node_data in get_nodes():
		if String(node_data["id"]) == node_id:
			return node_data.duplicate(true)
	return {}

static func get_next_nodes(node_id: String) -> Array:
	var lookup := build_lookup()
	if not lookup.has(node_id):
		return []
	var nodes: Array = []
	for next_id in lookup[node_id]["next"]:
		if lookup.has(next_id):
			nodes.append(lookup[next_id].duplicate(true))
	return nodes

static func _apply_default_next_ids(node_data: Dictionary):
	var node_id := String(node_data.get("id", ""))
	if not DEFAULT_NEXT_IDS.has(node_id):
		return
	var next_ids: Array = node_data.get("next", [])
	if not next_ids.is_empty():
		return
	node_data["next"] = DEFAULT_NEXT_IDS[node_id].duplicate()

static func is_result_node(node_id: String) -> bool:
	var node_data := get_node(node_id)
	return String(node_data.get("type", "")) in ["Event", "Treasure", "Rest"]

static func is_combat_node(node_id: String) -> bool:
	var node_data := get_node(node_id)
	return String(node_data.get("type", "")) in ["Battle", "Elite", "Boss"]

static func get_type_title(node_type: String) -> String:
	match node_type:
		"BaseCamp":
			return "BASE"
		"Battle":
			return "BATTLE"
		"Elite":
			return "ELITE"
		"Boss":
			return "BOSS"
		"Event":
			return "EVENT"
		"Treasure":
			return "TREASURE"
		"Rest":
			return "REST"
		_:
			return "NODE"

static func get_type_description(node_type: String) -> String:
	match node_type:
		"BaseCamp":
			return "Safe starting point. Choose the next route."
		"Battle":
			return "Standard encounter. Win to open the next route."
		"Elite":
			return "Hard encounter with stronger rewards later."
		"Boss":
			return "Final encounter of this prototype route."
		"Event":
			return "Resolve a small anomaly and gain gold for now."
		"Treasure":
			return "Open a cache and gain prototype gold."
		"Rest":
			return "Recover before the next fight."
		_:
			return "Continue along the selected route."

static func get_type_color(node_type: String) -> Color:
	match node_type:
		"BaseCamp":
			return Color(0.55, 0.96, 1.0)
		"Battle":
			return Color(0.95, 0.22, 0.38)
		"Elite":
			return Color(0.9, 0.58, 0.18)
		"Boss":
			return Color(0.72, 0.25, 1.0)
		"Event":
			return Color(0.42, 0.8, 0.95)
		"Treasure":
			return Color(1.0, 0.72, 0.24)
		"Rest":
			return Color(0.42, 0.9, 0.62)
		_:
			return Color(0.62, 0.72, 0.86)

static func apply_result_node_effect(run_state: Node, node_type: String) -> String:
	if run_state == null:
		return "Route updated."
	match node_type:
		"Event":
			run_state.gain_gold(10)
			return "Event resolved. Gained 10 gold."
		"Treasure":
			run_state.gain_gold(50)
			return "Treasure opened. Gained 50 gold."
		"Rest":
			var before_hp := int(run_state.current_hp)
			run_state.heal(12)
			return "Rested. Recovered %d HP." % (int(run_state.current_hp) - before_hp)
		_:
			return "Route updated."

static func get_result_text(node_type: String) -> String:
	match node_type:
		"Event":
			return "An unstable anomaly flickers nearby. Event choices will be connected here later."
		"Treasure":
			return "A sealed cache waits on the path. Reward selection will be connected here later."
		"Rest":
			return "The party catches its breath. Healing and upgrade choices will be connected here later."
		_:
			return "This node has been resolved."
