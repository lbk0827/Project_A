@tool
extends Resource
class_name MapRouteNodeData

@export var id := ""
@export var type := "battle"
@export var label := ""
@export var monster_id := ""
@export var encounter_id := ""
@export var position := Vector2.ZERO
@export var next_ids: PackedStringArray = []

func to_dictionary() -> Dictionary:
	var data := {
		"id": id,
		"type": type,
		"label": label,
		"pos": position,
		"next": Array(next_ids),
	}
	if not monster_id.is_empty():
		data["MonsterId"] = monster_id
	if not encounter_id.is_empty():
		data["EncounterId"] = encounter_id
	return data
