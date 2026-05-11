extends Node2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var home_position := Vector2.ZERO
var is_busy := false

func _ready():
	home_position = global_position
	anim.play("Idle")

func play_attack_sequence(target_position: Vector2):
	if is_busy:
		return
	is_busy = true

	var attack_position := target_position + Vector2(120, 0)

	var tween := create_tween()
	tween.tween_property(self, "global_position", attack_position, 0.25)
	tween.tween_callback(func(): anim.play("Attack"))
	tween.tween_interval(0.45)
	tween.tween_property(self, "global_position", home_position, 0.25)
	tween.tween_callback(func():
		anim.play("Idle")
		is_busy = false
	)
