extends Node2D

@export var departure_duration := 0.16
@export var arrival_duration := 0.18
@export var ring_color := Color(0.82, 0.96, 1.0, 0.92)
@export var core_color := Color(1.0, 1.0, 1.0, 0.88)
@export var shock_color := Color(0.35, 0.78, 1.0, 0.46)
@export var dust_color := Color(0.88, 0.92, 1.0, 0.26)

var progress := 0.0
var travel_distance := 160.0
var arrival_burst := false

func play_burst(direction: Vector2, distance: float, is_arrival: bool = false):
	if direction.length_squared() <= 0.001:
		direction = Vector2.RIGHT
	rotation = direction.angle()
	travel_distance = max(distance, 90.0)
	arrival_burst = is_arrival
	progress = 0.0
	queue_redraw()

	var tween := create_tween()
	tween.tween_method(_set_progress, 0.0, 1.0, arrival_duration if arrival_burst else departure_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(queue_free)

func _set_progress(value: float):
	progress = value
	queue_redraw()

func _draw():
	var fade: float = 1.0 - progress
	var eased: float = 1.0 - pow(1.0 - progress, 2.0)
	var sign: float = -1.0 if arrival_burst else 1.0
	var trail_length: float = clampf(travel_distance * 0.58, 120.0, 360.0)
	var ring_radius: float = 16.0 + 54.0 * eased
	var ring_width: float = 7.0 + 9.0 * fade

	draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 96, _alpha(ring_color, fade), ring_width, true)
	draw_arc(Vector2.ZERO, ring_radius * 0.62, 0.0, TAU, 72, _alpha(core_color, fade * 0.76), 3.0, true)
	draw_circle(Vector2.ZERO, 10.0 + 18.0 * eased, _alpha(core_color, fade * 0.32))

	var cone_tip: Vector2 = Vector2(sign * trail_length * (0.78 + eased * 0.16), 0.0)
	var cone_back: Vector2 = Vector2(sign * 24.0, 0.0)
	var cone_width: float = 20.0 + 42.0 * fade
	var cone: PackedVector2Array = PackedVector2Array([
		cone_back + Vector2(0, -cone_width),
		cone_tip,
		cone_back + Vector2(0, cone_width),
	])
	draw_colored_polygon(cone, _alpha(shock_color, fade * 0.48))

	for i in range(7):
		var lane: float = float(i - 3)
		var lane_abs: float = absf(lane)
		var y: float = lane * (7.0 + 2.0 * lane_abs)
		var start_x: float = sign * (18.0 + progress * 34.0 + lane_abs * 6.0)
		var end_x: float = sign * (trail_length * (0.55 + 0.08 * float(i % 3)) + progress * 42.0)
		var width: float = maxf(1.4, 5.0 - lane_abs * 0.7)
		var color: Color = _alpha(core_color if i % 2 == 0 else ring_color, fade * (0.74 - lane_abs * 0.08))
		draw_line(Vector2(start_x, y), Vector2(end_x, y * 0.38), color, width, true)

	for i in range(10):
		var angle: float = TAU * float(i) / 10.0 + progress * 0.9
		var radius: float = 20.0 + 84.0 * eased + float(i % 3) * 7.0
		var point: Vector2 = Vector2(cos(angle), sin(angle) * 0.62) * radius
		var particle_radius: float = 2.2 + float(i % 4) * 0.7
		draw_circle(point, particle_radius, _alpha(dust_color, fade * 0.82))

func _alpha(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, clampf(alpha, 0.0, 1.0))
