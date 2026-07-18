extends RefCounted

const DEFAULT_ROUTE: MapRouteResource = preload("res://data/map/DefaultRoute.tres")
const DEFAULT_NEXT_IDS := {
	"base_camp": ["battle_1", "event_1"],
	"battle_1": ["treasure_1", "battle_2"],
	"event_1": ["battle_2"],
	"treasure_1": ["elite_1"],
	"battle_2": ["elite_1", "rest_1"],
	"elite_1": ["rest_1"],
	"rest_1": ["boss_1"],
}

static func get_nodes() -> Array:
	var nodes: Array = []
	for node_data in DEFAULT_ROUTE.get_nodes():
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
	return String(node_data.get("type", "")) in ["event", "treasure", "rest"]

static func is_combat_node(node_id: String) -> bool:
	var node_data := get_node(node_id)
	return String(node_data.get("type", "")) in ["battle", "elite", "boss"]

static func get_type_title(node_type: String) -> String:
	match node_type:
		"base_camp":
			return "BASE"
		"battle":
			return "BATTLE"
		"elite":
			return "ELITE"
		"boss":
			return "BOSS"
		"event":
			return "EVENT"
		"treasure":
			return "TREASURE"
		"rest":
			return "REST"
		_:
			return "NODE"

static func get_type_description(node_type: String) -> String:
	match node_type:
		"base_camp":
			return "Safe starting point. Choose the next route."
		"battle":
			return "Standard encounter. Win to open the next route."
		"elite":
			return "Hard encounter with stronger rewards later."
		"boss":
			return "Final encounter of this prototype route."
		"event":
			return "Resolve a small anomaly and gain gold for now."
		"treasure":
			return "Open a cache and gain prototype gold."
		"rest":
			return "Recover before the next fight."
		_:
			return "Continue along the selected route."

static func get_type_color(node_type: String) -> Color:
	match node_type:
		"base_camp":
			return Color(0.55, 0.96, 1.0)
		"battle":
			return Color(0.95, 0.22, 0.38)
		"elite":
			return Color(0.9, 0.58, 0.18)
		"boss":
			return Color(0.72, 0.25, 1.0)
		"event":
			return Color(0.42, 0.8, 0.95)
		"treasure":
			return Color(1.0, 0.72, 0.24)
		"rest":
			return Color(0.42, 0.9, 0.62)
		_:
			return Color(0.62, 0.72, 0.86)

static func apply_result_node_effect(run_state: Node, node_type: String) -> String:
	if run_state == null:
		return "Route updated."
	match node_type:
		"event":
			run_state.gain_gold(10)
			return "Event resolved. Gained 10 gold."
		"treasure":
			run_state.gain_gold(50)
			return "Treasure opened. Gained 50 gold."
		"rest":
			var before_hp := int(run_state.current_hp)
			run_state.heal(12)
			return "Rested. Recovered %d HP." % (int(run_state.current_hp) - before_hp)
		_:
			return "Route updated."

static func get_result_text(node_type: String) -> String:
	match node_type:
		"event":
			return "An unstable anomaly flickers nearby. Event choices will be connected here later."
		"treasure":
			return "A sealed cache waits on the path. Reward selection will be connected here later."
		"rest":
			return "The party catches its breath. Healing and upgrade choices will be connected here later."
		_:
			return "This node has been resolved."
