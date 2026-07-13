extends Control

@onready var count_label: Label = %TXT_Count
@onready var visual_root: Control = $VisualRoot
@onready var icon: TextureRect = $VisualRoot/TextureRect

var pulse_tween: Tween

func set_tomb_count(count: int):
	count_label.text = str(max(count, 0))

func get_effect_anchor() -> Vector2:
	return icon.get_global_rect().get_center()

func play_transfer_pulse(tint: Color = Color(0.55, 0.9, 1.0)):
	if pulse_tween != null and pulse_tween.is_valid():
		pulse_tween.kill()
	visual_root.scale = Vector2.ONE
	visual_root.modulate = tint
	pulse_tween = create_tween()
	pulse_tween.tween_property(visual_root, "scale", Vector2(1.16, 1.16), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pulse_tween.parallel().tween_property(visual_root, "modulate", Color.WHITE, 0.16)
	pulse_tween.tween_property(visual_root, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
