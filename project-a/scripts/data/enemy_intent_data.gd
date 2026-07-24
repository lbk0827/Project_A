extends Resource
class_name EnemyIntentData

@export var display_name := ""
@export var intent_type: StringName = &"Attack"
# For "Attack" intents, amount is a percent of the monster's attack
# (100 = 100%). For "Block" intents, amount is a flat shield value.
@export var amount := 0
@export var icon_label := ""
@export_multiline var description := ""
