extends Resource
class_name CardData

@export var id := ""
@export var display_name := ""
@export var cost := 0
@export_multiline var text := ""
@export var card_type: StringName = &"skill"
@export var requires_target := false
@export var amount := 0
