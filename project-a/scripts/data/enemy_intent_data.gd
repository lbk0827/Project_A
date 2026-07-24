extends Resource
class_name EnemyIntentData

@export var display_name := ""
@export var intent_type: StringName = &"attack"
# For "attack" intents, amount is a percent of the monster's attack
# (100 = 100%). For "block" intents, amount is a flat shield value.
@export var amount := 0
@export var icon_label := ""
@export_multiline var description := ""
