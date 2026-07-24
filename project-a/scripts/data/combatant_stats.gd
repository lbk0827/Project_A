extends Resource
class_name CombatantStats

@export var id := ""
@export var display_name := ""
@export var max_hp := 1
@export var attack := 0
@export var defense := 0
@export var starting_energy := 0
# Critical hit chance as a 0.0..1.0 fraction (0.03 = 3%).
@export var crit_rate := 0.0
# Damage multiplier applied on a critical hit (1.25 = +25%).
@export var crit_damage := 1.0
