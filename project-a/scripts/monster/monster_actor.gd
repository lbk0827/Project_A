extends Node2D

@export_group("Combat Motion")
@export var attack_offset_from_target := Vector2(120, 0)
@export var approach_time := 0.35
@export var attack_impact_delay := 0.2
@export var attack_recover_delay := 0.35
@export var return_time := 0.3

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var home_position := Vector2.ZERO
var home_flip_h := false
var is_busy := false

func _ready():
	home_position = global_position
	home_flip_h = anim.flip_h
	anim.play("Idle")

func reset_combat_state():
	home_position = global_position
	anim.flip_h = home_flip_h
	is_busy = false
	play_idle_animation()

func set_facing_direction(direction: Vector2):
	if direction.x != 0:
		anim.flip_h = direction.x < 0

func get_attack_position(target_position: Vector2) -> Vector2:
	return target_position + attack_offset_from_target

func play_run_animation(direction: Vector2):
	set_facing_direction(direction)
	play_idle_animation()

func play_idle_animation():
	if anim.sprite_frames != null and anim.sprite_frames.has_animation(&"Idle"):
		anim.play("Idle")

func play_attack_animation():
	if anim.sprite_frames != null and anim.sprite_frames.has_animation(&"Attack"):
		anim.frame = 0
		anim.frame_progress = 0.0
		anim.play("Attack")

func restore_home_facing():
	anim.flip_h = home_flip_h

func get_attack_animation_duration() -> float:
	if anim.sprite_frames == null or not anim.sprite_frames.has_animation(&"Attack"):
		return attack_impact_delay + attack_recover_delay
	var frame_count := anim.sprite_frames.get_frame_count(&"Attack")
	var speed := anim.sprite_frames.get_animation_speed(&"Attack")
	if speed <= 0.0:
		return attack_impact_delay + attack_recover_delay
	return float(frame_count) / speed

func play_attack_sequence(target_position: Vector2):
	if is_busy:
		return
	is_busy = true

	var attack_position := get_attack_position(target_position)

	var tween := create_tween()
	tween.tween_property(self, "global_position", attack_position, approach_time)
	tween.tween_callback(play_attack_animation)
	tween.tween_interval(get_attack_animation_duration())
	tween.tween_property(self, "global_position", home_position, return_time)
	tween.tween_callback(func():
		restore_home_facing()
		play_idle_animation()
		is_busy = false
	)
