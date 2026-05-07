extends CharacterBody2D

@export var speed := 180.0
@export var attack_action: StringName = &"ui_accept"
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var is_attacking := false

func _ready():
	anim.animation_finished.connect(_on_animation_finished)
	anim.play("Idle")

func _physics_process(_delta):
	if Input.is_action_just_pressed(attack_action) and not is_attacking:
		_start_attack()

	if is_attacking:
		velocity = Vector2.ZERO
		move_and_slide()
		return

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

func _start_attack():
	is_attacking = true
	velocity = Vector2.ZERO
	anim.play("Attack")

func _on_animation_finished():
	if anim.animation == "Attack":
		is_attacking = false
