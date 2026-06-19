extends Node2D

const RISE_DISTANCE := 58.0
const DRIFT_DISTANCE := 10.0
const LIFETIME := 0.68

@onready var damage_label: Label = %DamageLabel

func show_damage(amount: int, color := Color.WHITE):
	damage_label.text = str(amount)
	damage_label.add_theme_color_override("font_color", color)
	modulate = Color.WHITE
	scale = Vector2(0.8, 0.8)

	var drift := randf_range(-DRIFT_DISTANCE, DRIFT_DISTANCE)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", position + Vector2(drift, -RISE_DISTANCE), LIFETIME).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, LIFETIME * 0.75).set_delay(LIFETIME * 0.25)
	tween.tween_property(self, "scale", Vector2(1.18, 1.18), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_callback(queue_free)
