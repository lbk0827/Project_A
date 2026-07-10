extends CharacterBody2D

const FX_HEROINE_SLASH_SCENE := preload("res://scenes/vfx/fx_heroine_slash.tscn")
const FX_TSUKI_FIVE_SLASH_SCENE := preload("res://scenes/vfx/fx_tsuki_five_slash.tscn")

@export var speed := 180.0
@export var attack_action: StringName = &"ui_accept"
@export_group("Combat Motion")
@export var attack_offset_from_target := Vector2(-120, 0)
@export var approach_time := 0.35
@export var attack_impact_delay := 0.18
@export var attack_recover_delay := 0.38
@export var return_time := 0.3
@export_group("Attack VFX")
@export var slash_fx_offset := Vector2(-45, -10)
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var is_attacking := false
var is_hit_reacting := false
var movement_enabled := true
var hp_ratio := 1.0
var is_dead := false
var hit_recover_time := 0.0
var attack_sequence_id := 0

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
		if not _is_animation_locked() and anim.animation != "Run":
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
	attack_sequence_id += 1
	is_attacking = false
	is_hit_reacting = false
	is_dead = false
	hit_recover_time = 0.0
	update_hp_state(current_hp, max_hp)
	anim.play("Idle")

func play_attack_animation(target_position: Variant = null):
	if is_dead or not _has_animation("Attack"):
		return
	_start_attack(target_position)

func play_five_slash_animation(target_position: Variant = null):
	if is_dead or not _has_animation("FiveSlash"):
		return
	_start_attack(target_position, &"FiveSlash")

func play_card_animation(animation_name: StringName, target_position: Variant = null):
	if is_dead:
		return
	if animation_name == &"Idle" or animation_name == &"":
		play_idle_animation()
		return
	if not _has_animation(animation_name):
		animation_name = &"Attack" if _has_animation(&"Attack") else &"Idle"
	if animation_name == &"Idle":
		play_idle_animation()
		return
	_start_attack(target_position, animation_name)

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
	attack_sequence_id += 1
	is_hit_reacting = true
	hit_recover_time = 0.4
	velocity = Vector2.ZERO
	anim.play("Hit")

func play_dead_animation():
	if is_dead:
		return
	is_dead = true
	attack_sequence_id += 1
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

func _start_attack(target_position: Variant = null, animation_name: StringName = &"Attack"):
	attack_sequence_id += 1
	is_attacking = true
	velocity = Vector2.ZERO
	anim.play(animation_name)
	if target_position is Vector2:
		_spawn_slash_fx_after_impact(target_position, attack_sequence_id, animation_name)

func _spawn_slash_fx_after_impact(target_position: Vector2, sequence_id: int, animation_name: StringName):
	await get_tree().create_timer(attack_impact_delay).timeout
	if sequence_id != attack_sequence_id or is_dead or not is_attacking:
		return

	var slash_scene := _attack_fx_scene(animation_name)
	if slash_scene == null:
		return
	var slash_fx := slash_scene.instantiate()
	var fx_parent := get_parent()
	if fx_parent == null:
		fx_parent = get_tree().current_scene
	if fx_parent == null:
		return

	fx_parent.add_child(slash_fx)
	slash_fx.global_position = target_position + slash_fx_offset
	slash_fx.scale.x = 1.0 if target_position.x >= global_position.x else -1.0

func _on_animation_finished():
	if is_attacking:
		is_attacking = false
		_play_base_animation(Vector2.ZERO)

func _has_animation(animation_name: StringName) -> bool:
	return anim.sprite_frames != null and anim.sprite_frames.has_animation(animation_name)

func _attack_fx_scene(animation_name: StringName) -> PackedScene:
	match animation_name:
		&"FiveSlash":
			return FX_TSUKI_FIVE_SLASH_SCENE
		_:
			return FX_HEROINE_SLASH_SCENE

func _is_animation_locked() -> bool:
	return is_attacking or is_hit_reacting
