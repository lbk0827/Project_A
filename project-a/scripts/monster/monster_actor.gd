@tool
extends Node2D

@export_group("Combat Motion")
@export var attack_offset_from_target := Vector2(120, 0)
@export var approach_time := 0.35
@export var attack_impact_delay := 0.2
@export var attack_recover_delay := 0.35
@export var return_time := 0.3
@export var source_faces_left := false

@export_group("Reaction Motion")
@export var hit_flash_color := Color(1.0, 0.28, 0.24)
@export var hit_flash_time := 0.05
@export var hit_recover_time := 0.14
@export var hit_shake_distance := 14.0
@export var death_fade_time := 0.42
@export var death_drop_distance := 18.0
@export var death_scale := Vector2(1.08, 0.9)

@export_group("Combat UI Preview")
@export var hp_bar_offset := Vector2(0, -172):
	set(value):
		hp_bar_offset = value
		_update_editor_combat_ui_preview()
@export var intent_overlay_offset := Vector2(-14, -48):
	set(value):
		intent_overlay_offset = value
		_update_editor_combat_ui_preview()
@export var show_combat_ui_preview := true:
	set(value):
		show_combat_ui_preview = value
		_update_editor_combat_ui_preview()
@export var preview_action_count := 3:
	set(value):
		preview_action_count = max(value, 1)
		_update_editor_combat_ui_preview()
@export var preview_intent_label := "ATK":
	set(value):
		preview_intent_label = value
		_update_editor_combat_ui_preview()

@onready var anim: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")
@onready var reaction_player: AnimationPlayer = get_node_or_null("AnimationPlayer")

var editor_preview_root: Node2D
var editor_preview_hp_bar: Control
var editor_preview_hp_label: Label
var editor_preview_count_label: Label
var editor_preview_intent_label: Label
var home_position := Vector2.ZERO
var home_flip_h := false
var home_anim_position := Vector2.ZERO
var home_anim_scale := Vector2.ONE
var home_anim_rotation := 0.0
var home_anim_modulate := Color.WHITE
var is_busy := false
var hit_tween: Tween
var death_tween: Tween

func _ready():
	if Engine.is_editor_hint():
		_update_editor_combat_ui_preview()
		return

	home_position = global_position
	if not is_instance_valid(anim):
		return
	home_flip_h = anim.flip_h
	home_anim_position = anim.position
	home_anim_scale = anim.scale
	home_anim_rotation = anim.rotation
	home_anim_modulate = anim.modulate
	_ensure_reaction_animations()
	anim.play("Idle")
	play_spawn_animation()

func _process(_delta: float):
	if Engine.is_editor_hint():
		_update_editor_combat_ui_preview()

func reset_combat_state():
	if not is_instance_valid(anim):
		return
	home_position = global_position
	anim.flip_h = home_flip_h
	anim.position = home_anim_position
	anim.scale = home_anim_scale
	anim.rotation = home_anim_rotation
	anim.modulate = home_anim_modulate
	anim.visible = true
	is_busy = false
	_kill_reaction_tweens()
	if is_instance_valid(reaction_player):
		reaction_player.stop()
	play_idle_animation()

func set_facing_direction(direction: Vector2):
	if is_instance_valid(anim) and direction.x != 0:
		anim.flip_h = direction.x > 0 if source_faces_left else direction.x < 0

func get_attack_position(target_position: Vector2) -> Vector2:
	return target_position + attack_offset_from_target

func play_run_animation(direction: Vector2):
	set_facing_direction(direction)
	play_idle_animation()

func play_idle_animation():
	if is_instance_valid(anim) and anim.sprite_frames != null and anim.sprite_frames.has_animation(&"Idle"):
		anim.play("Idle")

func play_attack_animation():
	if is_instance_valid(anim) and anim.sprite_frames != null and anim.sprite_frames.has_animation(&"Attack"):
		anim.frame = 0
		anim.frame_progress = 0.0
		anim.play("Attack")

func play_hit_animation():
	if not is_instance_valid(anim):
		return
	if _play_reaction_animation(&"Hit"):
		return

	_kill_reaction_tweens()
	var shake_direction := -1.0 if anim.flip_h else 1.0
	var shake_offset := Vector2(hit_shake_distance * shake_direction, 0)

	hit_tween = create_tween()
	hit_tween.set_parallel(true)
	hit_tween.tween_property(anim, "modulate", hit_flash_color, hit_flash_time)
	hit_tween.tween_property(anim, "position", home_anim_position + shake_offset, hit_flash_time)
	hit_tween.chain()
	hit_tween.set_parallel(true)
	hit_tween.tween_property(anim, "modulate", home_anim_modulate, hit_recover_time)
	hit_tween.tween_property(anim, "position", home_anim_position, hit_recover_time).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func play_death_animation():
	if not is_instance_valid(anim):
		return
	if _play_reaction_animation(&"Death"):
		return

	_kill_reaction_tweens()
	anim.stop()
	death_tween = create_tween()
	death_tween.set_parallel(true)
	death_tween.tween_property(anim, "modulate", Color(0.45, 0.45, 0.45, 0.22), death_fade_time)
	death_tween.tween_property(anim, "scale", death_scale, death_fade_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	death_tween.tween_property(anim, "position", home_anim_position + Vector2(0, death_drop_distance), death_fade_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func play_spawn_animation():
	_play_reaction_animation(&"Spawn")

func restore_home_facing():
	anim.flip_h = home_flip_h

func get_attack_animation_duration() -> float:
	if not is_instance_valid(anim) or anim.sprite_frames == null or not anim.sprite_frames.has_animation(&"Attack"):
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

func _kill_reaction_tweens():
	if hit_tween != null and hit_tween.is_valid():
		hit_tween.kill()
	if death_tween != null and death_tween.is_valid():
		death_tween.kill()

func _play_reaction_animation(animation_name: StringName) -> bool:
	if not is_instance_valid(reaction_player) or not reaction_player.has_animation(animation_name):
		return false
	_kill_reaction_tweens()
	reaction_player.stop()
	reaction_player.play(animation_name)
	return true

func _ensure_reaction_animations():
	if not is_instance_valid(reaction_player):
		return
	var library := _get_reaction_animation_library()
	if not reaction_player.has_animation(&"Spawn"):
		library.add_animation("Spawn", _create_spawn_animation())
	if not reaction_player.has_animation(&"Hit"):
		library.add_animation("Hit", _create_hit_animation())
	if not reaction_player.has_animation(&"Death"):
		library.add_animation("Death", _create_death_animation())

func _get_reaction_animation_library() -> AnimationLibrary:
	if reaction_player.has_animation_library(""):
		return reaction_player.get_animation_library("")
	var library := AnimationLibrary.new()
	reaction_player.add_animation_library("", library)
	return library

func _create_spawn_animation() -> Animation:
	var reaction := Animation.new()
	reaction.length = 0.18
	_add_value_track(reaction, NodePath("AnimatedSprite2D:modulate"), [
		[0.0, Color(home_anim_modulate.r, home_anim_modulate.g, home_anim_modulate.b, 0.0)],
		[0.18, home_anim_modulate],
	])
	_add_value_track(reaction, NodePath("AnimatedSprite2D:scale"), [
		[0.0, home_anim_scale * 0.92],
		[0.18, home_anim_scale],
	])
	return reaction

func _create_hit_animation() -> Animation:
	var reaction := Animation.new()
	reaction.length = hit_flash_time + hit_recover_time
	_add_value_track(reaction, NodePath("AnimatedSprite2D:modulate"), [
		[0.0, home_anim_modulate],
		[hit_flash_time, hit_flash_color],
		[reaction.length, home_anim_modulate],
	])
	_add_value_track(reaction, NodePath("AnimatedSprite2D:position"), [
		[0.0, home_anim_position],
		[hit_flash_time, home_anim_position + Vector2(-hit_shake_distance, 0)],
		[reaction.length, home_anim_position],
	])
	return reaction

func _create_death_animation() -> Animation:
	var reaction := Animation.new()
	reaction.length = death_fade_time
	_add_value_track(reaction, NodePath("AnimatedSprite2D:modulate"), [
		[0.0, home_anim_modulate],
		[death_fade_time, Color(0.45, 0.45, 0.45, 0.22)],
	])
	_add_value_track(reaction, NodePath("AnimatedSprite2D:scale"), [
		[0.0, home_anim_scale],
		[death_fade_time, death_scale],
	])
	_add_value_track(reaction, NodePath("AnimatedSprite2D:position"), [
		[0.0, home_anim_position],
		[death_fade_time, home_anim_position + Vector2(0, death_drop_distance)],
	])
	return reaction

func _add_value_track(reaction: Animation, track_path: NodePath, keys: Array):
	var track := reaction.add_track(Animation.TYPE_VALUE)
	reaction.track_set_path(track, track_path)
	reaction.track_set_interpolation_type(track, Animation.INTERPOLATION_CUBIC)
	for key in keys:
		reaction.track_insert_key(track, float(key[0]), key[1])

func _update_editor_combat_ui_preview():
	if not Engine.is_editor_hint():
		return
	if not is_inside_tree():
		return
	if not show_combat_ui_preview:
		_remove_editor_combat_ui_preview()
		return

	_ensure_editor_combat_ui_preview()
	editor_preview_root.position = hp_bar_offset
	editor_preview_count_label.text = str(preview_action_count)
	editor_preview_intent_label.text = preview_intent_label

	var intent_origin := intent_overlay_offset
	editor_preview_count_label.get_parent().position = intent_origin
	editor_preview_intent_label.get_parent().position = intent_origin + Vector2(0, 48)

func _ensure_editor_combat_ui_preview():
	if is_instance_valid(editor_preview_root):
		return

	editor_preview_root = Node2D.new()
	editor_preview_root.name = "EditorCombatUIPreview"
	editor_preview_root.set_meta("editor_preview", true)
	add_child(editor_preview_root, false, Node.INTERNAL_MODE_FRONT)

	var hp_root := Control.new()
	hp_root.name = "HpPreview"
	hp_root.size = Vector2(178, 30)
	editor_preview_root.add_child(hp_root)
	editor_preview_hp_bar = hp_root

	var heart := Panel.new()
	heart.position = Vector2(0, 0)
	heart.size = Vector2(30, 30)
	heart.add_theme_stylebox_override("panel", _make_editor_preview_style(Color(0.34, 0.08, 0.1, 0.92), Color(0.95, 0.52, 0.45, 1.0), 3))
	hp_root.add_child(heart)

	var heart_label := Label.new()
	heart_label.text = "HP"
	heart_label.add_theme_font_size_override("font_size", 11)
	heart_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heart_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	heart_label.size = heart.size
	heart.add_child(heart_label)

	var bar := Panel.new()
	bar.position = Vector2(34, 6)
	bar.size = Vector2(144, 18)
	bar.add_theme_stylebox_override("panel", _make_editor_preview_style(Color(0.42, 0.08, 0.1, 0.9), Color(0.95, 0.38, 0.35, 1.0), 2))
	hp_root.add_child(bar)

	editor_preview_hp_label = Label.new()
	editor_preview_hp_label.text = "40 / 40"
	editor_preview_hp_label.add_theme_font_size_override("font_size", 10)
	editor_preview_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	editor_preview_hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	editor_preview_hp_label.size = bar.size
	bar.add_child(editor_preview_hp_label)

	var count_panel := Panel.new()
	count_panel.name = "IntentCountPreview"
	count_panel.size = Vector2(46, 46)
	count_panel.add_theme_stylebox_override("panel", _make_editor_preview_style(Color(0.92, 0.12, 0.36, 0.96), Color(1.0, 0.55, 0.75, 1.0), 8))
	editor_preview_root.add_child(count_panel)

	editor_preview_count_label = Label.new()
	editor_preview_count_label.add_theme_font_size_override("font_size", 24)
	editor_preview_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	editor_preview_count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	editor_preview_count_label.size = count_panel.size
	count_panel.add_child(editor_preview_count_label)

	var intent_panel := Panel.new()
	intent_panel.name = "IntentIconPreview"
	intent_panel.size = Vector2(48, 42)
	intent_panel.add_theme_stylebox_override("panel", _make_editor_preview_style(Color(0.1, 0.16, 0.2, 0.92), Color(0.72, 0.86, 0.9, 0.85), 4))
	editor_preview_root.add_child(intent_panel)

	editor_preview_intent_label = Label.new()
	editor_preview_intent_label.add_theme_font_size_override("font_size", 13)
	editor_preview_intent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	editor_preview_intent_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	editor_preview_intent_label.size = intent_panel.size
	intent_panel.add_child(editor_preview_intent_label)

func _remove_editor_combat_ui_preview():
	if is_instance_valid(editor_preview_root):
		editor_preview_root.queue_free()
	editor_preview_root = null
	editor_preview_hp_bar = null
	editor_preview_hp_label = null
	editor_preview_count_label = null
	editor_preview_intent_label = null

func _make_editor_preview_style(bg_color: Color, border_color: Color, corner_radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	return style
