extends Node2D
class_name MoonSlashVfx

@export var moon_radius := 92.0
@export var reveal_time := 0.18
@export var shatter_time := 0.38

@onready var sprite_sheet: Sprite2D = $SpriteSheet

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
	sprite_sheet.frame = 0
	modulate.a = 0.0
	scale = Vector2(0.35, 0.35)
	queue_redraw()

func reveal():
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, reveal_time)
	tween.tween_property(self, "scale", Vector2.ONE, reveal_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_animate_sheet_frames(0, 3, reveal_time)
	await tween.finished

func apply_slash(hit_index: int):
	active_slash = clamp(hit_index, 0, SLASH_PATHS.size() - 1)
	slash_stage = max(slash_stage, active_slash + 1)
	sprite_sheet.frame = 4 + active_slash
	flash_alpha = 1.0
	queue_redraw()
	var tween := create_tween()
	tween.tween_method(_set_flash_alpha, 1.0, 0.0, 0.16)

func shatter():
	is_shattered = true
	queue_redraw()
	_animate_sheet_frames(9, 15, shatter_time)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_method(_set_shatter_progress, 0.0, 1.0, shatter_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, shatter_time).set_delay(shatter_time * 0.45)
	await tween.finished
	queue_free()

func _animate_sheet_frames(start_frame: int, end_frame: int, duration: float):
	var frame_count: int = max(end_frame - start_frame + 1, 1)
	var frame_time: float = max(duration / float(frame_count), 0.001)
	for frame_index in range(start_frame, end_frame + 1):
		if not is_instance_valid(sprite_sheet):
			return
		sprite_sheet.frame = frame_index
		await get_tree().create_timer(frame_time).timeout

func _set_flash_alpha(value: float):
	flash_alpha = value
	queue_redraw()

func _set_shatter_progress(value: float):
	shatter_progress = value
	queue_redraw()

func _draw():
	if not is_shattered:
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
		var color := Color(0.72 + 0.03 * (i % 2), 0.91, 1.0, (1.0 - shatter_progress) * 0.38)
		draw_colored_polygon(rotated, color)
		draw_polyline(rotated, Color(0.9, 1.0, 1.0, 0.8), 2.0, true)
