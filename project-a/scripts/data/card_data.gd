extends Resource
class_name CardData

@export var id := ""
@export var character := ""
@export var display_name := ""
@export var cost := 0
@export_multiline var text := ""
@export var card_type: StringName = &"skill"
@export var requires_target := false
@export var amount := 0
# Data-driven effect list. Each entry is a Dictionary, e.g.
# {"type": "damage", "amount": 6, "target": "enemy"}. Supported types:
# damage, block, draw, energy. Replaces per-id branching in combat.
@export var effects: Array = []
# Keyword tags (보존/유일/영감 등); definitions live in the card_effects table.
@export var keywords: Array = []
# Bonus effects applied when this card's inspiration (영감) is active.
@export var inspiration: Array = []
# Runtime: whether this hand copy's inspiration is currently active.
var inspired := false
