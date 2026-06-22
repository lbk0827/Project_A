extends Resource
class_name MonsterData

@export var id := ""
@export var display_name := ""
@export var stats: CombatantStats
@export var scene: PackedScene
@export var intents: Array[EnemyIntentData] = []
@export var action_count := 3
@export var hp_bar_offset := Vector2(0, -172)
@export var intent_overlay_offset := Vector2(-14, -48)
