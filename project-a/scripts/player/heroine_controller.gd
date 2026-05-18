extends CharacterBody2D

@export var speed := 180.0
@export var attack_action: StringName = &"ui_accept"
@export_group("Combat Motion")
@export var attack_offset_from_target := Vector2(-120, 0)
@export var approach_time := 0.35
@export var attack_impact_delay := 0.18
@export var attack_recover_delay := 0.38
@export var return_time := 0.3
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var is_attacking := false
var is_hit_reacting := false
var movement_enabled := true
var hp_ratio := 1.0
var is_dead := false
var hit_recover_time := 0.0

func _ready():
	anim.animation_finished.connect(_on_animation_finished)
	anim.play("Idle")

func _physics_process(delta):
	if is_dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if hit_recover_time > 0.0:
		hit_recover_time = max(0.0, hit_recover_time - delta)
		if hit_recover_time == 0.0 and is_hit_reacting:
			is_hit_reacting = false
			_play_base_animation(Vector2.ZERO)

	if movement_enabled and Input.is_action_just_pressed(attack_action) and not _is_animation_locked():
		_start_attack()

	if not movement_enabled:
		velocity = Vector2.ZERO
		move_and_slide()
		if not _is_animation_locked():
			_play_base_animation(Vector2.ZERO)
		return

	if _is_animation_locked():
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var dir := Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	).normalized()

	velocity = dir * speed
	move_and_slide()

	_play_base_animation(dir)

func set_movement_enabled(enabled: bool):
	movement_enabled = enabled
	if not movement_enabled:
		velocity = Vector2.ZERO
	_play_base_animation(Vector2.ZERO)

func reset_combat_state(current_hp: int, max_hp: int):
	is_attacking = false
	is_hit_reacting = false
	is_dead = false
	hit_recover_time = 0.0
	update_hp_state(current_hp, max_hp)
	anim.play("Idle")

func play_attack_animation():
	if is_dead or not _has_animation("Attack"):
		return
	_start_attack()

func play_run_animation(direction: Vector2):
	if is_dead or _is_animation_locked():
		return
	_play_base_animation(direction.normalized())

func play_idle_animation():
	if is_dead or _is_animation_locked():
		return
	_play_base_animation(Vector2.ZERO)

func set_facing_direction(direction: Vector2):
	if direction.x != 0:
		anim.flip_h = direction.x < 0

func get_attack_position(target_position: Vector2) -> Vector2:
	return target_position + attack_offset_from_target

func play_hit_animation():
	if is_dead or not _has_animation("Hit"):
		return
	is_hit_reacting = true
	hit_recover_time = 0.4
	velocity = Vector2.ZERO
	anim.play("Hit")

func play_dead_animation():
	if is_dead:
		return
	is_dead = true
	is_attacking = false
	is_hit_reacting = false
	hit_recover_time = 0.0
	velocity = Vector2.ZERO
	if _has_animation("Dead"):
		anim.play("Dead")

func update_hp_state(current_hp: int, max_hp: int):
	if max_hp <= 0:
		return
	hp_ratio = clamp(float(current_hp) / float(max_hp), 0.0, 1.0)
	if not _is_animation_locked() and not is_dead:
		_play_base_animation(Vector2.ZERO)

func _play_base_animation(dir: Vector2):
	if is_dead:
		return
	if dir == Vector2.ZERO:
		if hp_ratio <= 0.2 and _has_animation("Sick"):
			anim.play("Sick")
		else:
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
		_play_base_animation(Vector2.ZERO)

func _has_animation(animation_name: StringName) -> bool:
	return anim.sprite_frames != null and anim.sprite_frames.has_animation(animation_name)

func _is_animation_locked() -> bool:
	return is_attacking or is_hit_reacting
