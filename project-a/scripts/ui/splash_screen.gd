extends Control

const TITLE_SCENE_PATH := "res://scenes/core/main/title_screen.tscn"
const INTRO_TIME := 0.45
const HOLD_TIME := 1.25
const OUTRO_TIME := 0.45

@onready var studio_label: Label = $Center/LogoStack/StudioLabel
@onready var mark_label: Label = $Center/LogoStack/MarkLabel
@onready var line_left: ColorRect = $Center/LogoStack/LineRow/LineLeft
@onready var line_right: ColorRect = $Center/LogoStack/LineRow/LineRight
@onready var fade_rect: ColorRect = $FadeRect

var is_changing_scene := false

func _ready():
	await get_tree().process_frame
	_prepare_style()
	_play_intro()

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel") or (event is InputEventMouseButton and event.pressed):
		_go_to_title()

func _prepare_style():
	studio_label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	mark_label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	line_left.scale.x = 0.0
	line_right.scale.x = 0.0
	line_left.pivot_offset = Vector2(line_left.size.x, line_left.size.y * 0.5)
	line_right.pivot_offset = Vector2(0.0, line_right.size.y * 0.5)
	fade_rect.color = Color(0.015, 0.016, 0.022, 1.0)

func _play_intro():
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(fade_rect, "color:a", 0.0, INTRO_TIME)
	tween.tween_property(studio_label, "modulate:a", 1.0, INTRO_TIME).set_delay(0.1)
	tween.tween_property(mark_label, "modulate:a", 1.0, INTRO_TIME).set_delay(0.22)
	tween.tween_property(line_left, "scale:x", 1.0, INTRO_TIME).set_delay(0.28)
	tween.tween_property(line_right, "scale:x", 1.0, INTRO_TIME).set_delay(0.28)
	tween.set_parallel(false)
	tween.tween_interval(HOLD_TIME)
	tween.tween_callback(_play_outro)

func _play_outro():
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(fade_rect, "color:a", 1.0, OUTRO_TIME)
	tween.tween_property(studio_label, "modulate:a", 0.0, OUTRO_TIME)
	tween.tween_property(mark_label, "modulate:a", 0.0, OUTRO_TIME)
	tween.tween_property(line_left, "scale:x", 0.0, OUTRO_TIME)
	tween.tween_property(line_right, "scale:x", 0.0, OUTRO_TIME)
	tween.set_parallel(false)
	tween.tween_callback(_go_to_title)

func _go_to_title():
	if is_changing_scene:
		return
	is_changing_scene = true
	get_tree().change_scene_to_file(TITLE_SCENE_PATH)
