extends Node2D
class_name MoonSlashVfx

@export var moon_radius := 92.0
@export var reveal_time := 0.18
@export var shatter_time := 0.38

@onready var moon: Sprite2D = $Moon

var slash_stage := 0
var active_slash := -1
var flash_alpha := 0.0
var shatter_progress := 0.0
var is_shattered := false

const SLASH_PATHS := [
	[Vector2(-78, -42), Vector2(72, 30)],
	[Vector2(-72, 46), Vector2(76, -24)],
	[Vector2(-22, -86), Vector2(18, 82)],
	[Vector2(-84, 2), Vector2(78, 52)],
	[Vector2(-60, -68), Vector2(58, 70)],
]

var shard_polygons: Array[PackedVector2Array] = [
	PackedVector2Array([Vector2(-82, -58), Vector2(-18, -86), Vector2(-8, -12), Vector2(-70, -4)]),
	PackedVector2Array([Vector2(-18, -86), Vector2(70, -54), Vector2(24, -6), Vector2(-8, -12)]),
	PackedVector2Array([Vector2(70, -54), Vector2(88, 18), Vector2(22, 22), Vector2(24, -6)]),
	PackedVector2Array([Vector2(88, 18), Vector2(52, 76), Vector2(8, 34), Vector2(22, 22)]),
	PackedVector2Array([Vector2(52, 76), Vector2(-34, 84), Vector2(-8, 32), Vector2(8, 34)]),
	PackedVector2Array([Vector2(-34, 84), Vector2(-88, 24), Vector2(-24, 6), Vector2(-8, 32)]),
	PackedVector2Array([Vector2(-88, 24), Vector2(-82, -58), Vector2(-8, -12), Vector2(-24, 6)]),
	PackedVector2Array([Vector2(-24, 6), Vector2(-8, -12), Vector2(24, -6), Vector2(22, 22), Vector2(8, 34), Vector2(-8, 32)]),
]

func _ready():
	modulate.a = 0.0
	scale = Vector2(0.35, 0.35)
	queue_redraw()

func reveal():
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, reveal_time)
	tween.tween_property(self, "scale", Vector2.ONE, reveal_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished

func apply_slash(hit_index: int):
	active_slash = clamp(hit_index, 0, SLASH_PATHS.size() - 1)
	slash_stage = max(slash_stage, active_slash + 1)
	flash_alpha = 1.0
	queue_redraw()
	var tween := create_tween()
	tween.tween_method(_set_flash_alpha, 1.0, 0.0, 0.16)

func shatter():
	is_shattered = true
	moon.visible = false
	queue_redraw()
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_method(_set_shatter_progress, 0.0, 1.0, shatter_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, shatter_time).set_delay(shatter_time * 0.45)
	await tween.finished
	queue_free()

func _set_flash_alpha(value: float):
	flash_alpha = value
	queue_redraw()

func _set_shatter_progress(value: float):
	shatter_progress = value
	queue_redraw()

func _draw():
	if not is_shattered:
		draw_circle(Vector2.ZERO, moon_radius + 16.0, Color(0.25, 0.85, 1.0, 0.08))
		draw_arc(Vector2.ZERO, moon_radius + 5.0, 0.0, TAU, 80, Color(0.72, 0.96, 1.0, 0.72), 3.0, true)
		for i in range(min(slash_stage, SLASH_PATHS.size())):
			var path: Array = SLASH_PATHS[i]
			var slash_start: Vector2 = path[0]
			var slash_end: Vector2 = path[1]
			draw_line(slash_start, slash_end, Color(0.03, 0.16, 0.3, 0.95), 7.0, true)
			draw_line(slash_start, slash_end, Color(0.82, 0.98, 1.0, 0.88), 2.0, true)
			var middle: Vector2 = slash_start.lerp(slash_end, 0.5)
			var normal: Vector2 = (slash_end - slash_start).normalized().orthogonal()
			draw_line(middle, middle + normal * (12.0 + i * 2.0), Color(0.16, 0.42, 0.62, 0.9), 3.0, true)
		if active_slash >= 0 and flash_alpha > 0.0:
			var active: Array = SLASH_PATHS[active_slash]
			draw_line(active[0] * 1.28, active[1] * 1.28, Color(0.85, 1.0, 1.0, flash_alpha), 13.0, true)
			draw_circle(Vector2.ZERO, moon_radius * 0.55, Color(0.75, 0.98, 1.0, flash_alpha * 0.16))
		return

	for i in range(shard_polygons.size()):
		var direction := Vector2.from_angle(TAU * float(i) / float(shard_polygons.size()))
		var offset := direction * (18.0 + 58.0 * shatter_progress)
		var rotated := PackedVector2Array()
		for point in shard_polygons[i]:
			rotated.append(point.rotated(direction.angle() * shatter_progress * 0.16) + offset)
		var color := Color(0.72 + 0.03 * (i % 2), 0.91, 1.0, 1.0 - shatter_progress * 0.45)
		draw_colored_polygon(rotated, color)
		draw_polyline(rotated, Color(0.9, 1.0, 1.0, 0.8), 2.0, true)
