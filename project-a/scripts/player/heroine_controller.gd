extends CharacterBody2D

@export var speed := 180.0
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(_delta):
	var dir := Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	).normalized()

	velocity = dir * speed
	move_and_slide()

	if dir == Vector2.ZERO:
		anim.play("Idle")
	else:
		anim.play("Run")
		if dir.x != 0:
			anim.flip_h = dir.x < 0
