extends Control
class_name CardTransferVfx

var start_point := Vector2.ZERO
var end_point := Vector2.ZERO
var control_point := Vector2.ZERO
var glow_color := Color(0.45, 0.9, 1.0)
var progress := 0.0
var burst_progress := 0.0
var phase := 0.0

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_as_relative = false
	z_index = 900
	set_process(true)

func configure(from: Vector2, to: Vector2, color: Color, arc_height: float = 150.0):
	start_point = from
	end_point = to
	glow_color = color
	var midpoint: Vector2 = (from + to) * 0.5
	var direction: Vector2 = to - from
	var perpendicular: Vector2 = Vector2(-direction.y, direction.x).normalized()
	var side: float = -1.0 if from.x < to.x else 1.0
	control_point = midpoint + Vector2(0.0, -arc_height) + perpendicular * 38.0 * side
	queue_redraw()

func play(duration: float = 0.42):
	var travel_tween := create_tween()
	travel_tween.tween_method(_set_progress, 0.0, 1.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await travel_tween.finished
	var burst_tween := create_tween()
	burst_tween.tween_method(_set_burst_progress, 0.0, 1.0, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await burst_tween.finished
	queue_free()

func _process(delta: float):
	phase += delta
	queue_redraw()

func _set_progress(value: float):
	progress = value
	queue_redraw()

func _set_burst_progress(value: float):
	burst_progress = value
	queue_redraw()

func _draw():
	var direction: Vector2 = end_point - start_point
	var perpendicular: Vector2 = Vector2(-direction.y, direction.x).normalized()
	for lane in range(3):
		var lane_progress: float = clampf(progress - float(lane) * 0.035, 0.0, 1.0)
		if lane_progress <= 0.0:
			continue
		var trail_start: float = maxf(lane_progress - 0.24, 0.0)
		var points := PackedVector2Array()
		for step in range(13):
			var t: float = lerpf(trail_start, lane_progress, float(step) / 12.0)
			var lane_wave: float = sin(t * PI) * (float(lane) - 1.0) * 7.0
			points.append(_bezier(t) + perpendicular * lane_wave)
		var lane_alpha: float = 0.28 - float(lane) * 0.045
		draw_polyline(points, _with_alpha(glow_color, lane_alpha), 9.0 - float(lane) * 1.5, true)
		draw_polyline(points, _with_alpha(glow_color.lightened(0.3), 0.78), 2.4, true)
		var head: Vector2 = points[points.size() - 1]
		draw_circle(head, 15.0 - float(lane) * 2.0, _with_alpha(glow_color, 0.12))
		draw_circle(head, 5.5 - float(lane), _with_alpha(glow_color.lightened(0.45), 0.94))

	for i in range(8):
		var spark_t: float = progress - 0.025 - float(i) * 0.026
		if spark_t <= 0.0:
			continue
		var sway: float = sin(phase * 11.0 + float(i) * 2.3) * (8.0 + float(i % 3) * 3.0)
		var spark: Vector2 = _bezier(clampf(spark_t, 0.0, 1.0)) + perpendicular * sway
		var radius: float = 1.5 + float(i % 3)
		draw_circle(spark, radius, _with_alpha(glow_color.lightened(0.35), 0.72))

	if burst_progress > 0.0:
		var fade: float = 1.0 - burst_progress
		draw_circle(end_point, 24.0 * fade + 5.0, _with_alpha(glow_color, 0.18 * fade))
		draw_arc(end_point, 8.0 + burst_progress * 28.0, 0.0, TAU, 32, _with_alpha(glow_color.lightened(0.35), 0.78 * fade), 2.0, true)

func _bezier(t: float) -> Vector2:
	var inverse: float = 1.0 - t
	return inverse * inverse * start_point + 2.0 * inverse * t * control_point + t * t * end_point

func _with_alpha(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, alpha)
