extends Control
class_name CardDissolveVfx

const COLUMNS := 9
const ROWS := 13

var card_center := Vector2.ZERO
var card_size := Vector2(130, 184)
var card_rotation := 0.0
var glow_color := Color(0.45, 0.9, 1.0)
var progress := 0.0
var reverse := false
var phase := 0.0

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_as_relative = false
	z_index = 890
	set_process(true)

func configure(center: Vector2, source_size: Vector2, rotation_degrees: float, color: Color, materialize: bool = false):
	card_center = center
	card_size = source_size
	card_rotation = deg_to_rad(rotation_degrees)
	glow_color = color
	reverse = materialize
	progress = 1.0 if reverse else 0.0
	queue_redraw()

func play(duration: float = 0.24):
	var tween := create_tween()
	if reverse:
		tween.tween_method(_set_progress, 1.0, 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		tween.tween_method(_set_progress, 0.0, 1.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
	queue_free()

func _process(delta: float):
	phase += delta
	queue_redraw()

func _set_progress(value: float):
	progress = value
	queue_redraw()

func _draw():
	var cell_size := Vector2(card_size.x / float(COLUMNS), card_size.y / float(ROWS))
	for row in range(ROWS):
		for column in range(COLUMNS):
			var index := row * COLUMNS + column
			var threshold := _noise01(index)
			var distance_to_edge := absf(threshold - progress)
			if distance_to_edge > 0.16:
				continue
			var local := Vector2(
				(float(column) + 0.5) * cell_size.x - card_size.x * 0.5,
				(float(row) + 0.5) * cell_size.y - card_size.y * 0.5
			)
			var drift_strength := (0.16 - distance_to_edge) / 0.16
			var horizontal_drift := sin(phase * 10.0 + float(index) * 1.7) * 8.0 * drift_strength
			var vertical_drift := (progress if not reverse else 1.0 - progress) * 18.0
			local += Vector2(horizontal_drift, vertical_drift)
			var position := card_center + local.rotated(card_rotation)
			var radius := 1.4 + float(index % 4) * 0.65
			var alpha := clampf(drift_strength * 1.25, 0.0, 1.0)
			draw_circle(position, radius * 2.4, _with_alpha(glow_color, alpha * 0.13))
			draw_circle(position, radius, _with_alpha(glow_color.lightened(0.4), alpha * 0.92))

	var edge_alpha := sin(progress * PI) * 0.7
	if edge_alpha > 0.0:
		var half_size := card_size * 0.5
		var corners := PackedVector2Array([
			card_center + Vector2(-half_size.x, -half_size.y).rotated(card_rotation),
			card_center + Vector2(half_size.x, -half_size.y).rotated(card_rotation),
			card_center + Vector2(half_size.x, half_size.y).rotated(card_rotation),
			card_center + Vector2(-half_size.x, half_size.y).rotated(card_rotation),
			card_center + Vector2(-half_size.x, -half_size.y).rotated(card_rotation),
		])
		draw_polyline(corners, _with_alpha(glow_color.lightened(0.35), edge_alpha * 0.28), 2.0, true)

func _noise01(index: int) -> float:
	return fposmod(sin(float(index) * 12.9898 + 4.1414) * 43758.5453, 1.0)

func _with_alpha(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, alpha)
