extends Control

signal card_pressed(index: int)

const ATTACK_FRAME := preload("res://scenes/ui/cards/CardFrame_Attack.tres")
const SKILL_FRAME := preload("res://scenes/ui/cards/CardFrame_Skill.tres")
const NORMAL_MODULATE := Color.WHITE
const DISABLED_MODULATE := Color(0.58, 0.58, 0.58, 0.92)
const HOVER_OFFSET := Vector2(0, -24)
const HOVER_SCALE := Vector2(1.08, 1.08)
const TWEEN_TIME := 0.1

var visual_root: Control
var frame: TextureRect
var cost_label: Label
var name_label: Label
var body_label: Label
var click_area: Button

var card_index := -1
var is_disabled := false
var normal_z_index := 0
var hover_tween: Tween

func _ready():
	_bind_nodes()
	if not click_area.pressed.is_connected(_on_click_area_pressed):
		click_area.pressed.connect(_on_click_area_pressed)
	if not click_area.mouse_entered.is_connected(_on_mouse_entered):
		click_area.mouse_entered.connect(_on_mouse_entered)
	if not click_area.mouse_exited.is_connected(_on_mouse_exited):
		click_area.mouse_exited.connect(_on_mouse_exited)

func set_card(card: Dictionary, index: int, disabled: bool):
	_bind_nodes()
	card_index = index
	is_disabled = disabled
	frame.texture = ATTACK_FRAME if card.get("type", "") == "attack" else SKILL_FRAME
	cost_label.text = str(card.get("cost", 0))
	name_label.text = str(card.get("name", ""))
	body_label.text = str(card.get("text", ""))
	click_area.disabled = disabled
	modulate = DISABLED_MODULATE if disabled else NORMAL_MODULATE
	_reset_visual()

func set_hand_order(order: int):
	normal_z_index = order
	z_index = normal_z_index

func _on_click_area_pressed():
	card_pressed.emit(card_index)

func _on_mouse_entered():
	if is_disabled:
		return
	z_index = 100 + normal_z_index
	_tween_visual(HOVER_OFFSET, HOVER_SCALE)

func _on_mouse_exited():
	z_index = normal_z_index
	_tween_visual(Vector2.ZERO, Vector2.ONE)

func _bind_nodes():
	if frame != null:
		return
	visual_root = %VisualRoot
	frame = %Frame
	cost_label = %CostLabel
	name_label = %NameLabel
	body_label = %BodyLabel
	click_area = %ClickArea

func _tween_visual(target_position: Vector2, target_scale: Vector2):
	if hover_tween != null:
		hover_tween.kill()
	hover_tween = create_tween()
	hover_tween.set_parallel(true)
	hover_tween.tween_property(visual_root, "position", target_position, TWEEN_TIME)
	hover_tween.tween_property(visual_root, "scale", target_scale, TWEEN_TIME)

func _reset_visual():
	if hover_tween != null:
		hover_tween.kill()
	visual_root.position = Vector2.ZERO
	visual_root.scale = Vector2.ONE
