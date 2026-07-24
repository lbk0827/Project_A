@tool
extends Resource
class_name MapRouteResource

@export var nodes: Array[MapRouteNodeData] = []

func get_nodes() -> Array:
	var result: Array = []
	for node in nodes:
		if node != null and not node.id.is_empty():
			result.append(node.to_dictionary())
	return result
