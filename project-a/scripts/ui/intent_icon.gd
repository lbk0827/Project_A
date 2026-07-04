extends Control
class_name IntentIcon

enum Kind { NONE, SWORD, SHIELD }

var kind: int = Kind.NONE
var icon_color := Color(1, 1, 1, 0.98)

func set_icon(new_kind: int, color: Color):
	kind = new_kind
	icon_color = color
	queue_redraw()

func _draw():
	match kind:
		Kind.SWORD:
			_draw_sword()
		Kind.SHIELD:
			_draw_shield()

func _draw_sword():
	# Blade points downward. Coordinates are fractions of the control size.
	var s := size
	var cx := s.x * 0.5
	var edge := icon_color.darkened(0.35)
	var blade_half := s.x * 0.11
	var guard_top := s.y * 0.30
	var blade_bottom := s.y * 0.80
	# Blade body.
	var blade := PackedVector2Array([
		Vector2(cx - blade_half, guard_top),
		Vector2(cx + blade_half, guard_top),
		Vector2(cx + blade_half, blade_bottom),
		Vector2(cx - blade_half, blade_bottom),
	])
	draw_colored_polygon(blade, icon_color)
	# Blade tip.
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - blade_half, blade_bottom),
		Vector2(cx + blade_half, blade_bottom),
		Vector2(cx, s.y * 0.95),
	]), icon_color)
	# Crossguard.
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - s.x * 0.32, guard_top),
		Vector2(cx + s.x * 0.32, guard_top),
		Vector2(cx + s.x * 0.32, guard_top + s.y * 0.10),
		Vector2(cx - s.x * 0.32, guard_top + s.y * 0.10),
	]), icon_color)
	# Grip + pommel above the guard.
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - blade_half * 0.8, s.y * 0.10),
		Vector2(cx + blade_half * 0.8, s.y * 0.10),
		Vector2(cx + blade_half * 0.8, guard_top),
		Vector2(cx - blade_half * 0.8, guard_top),
	]), icon_color)
	draw_line(Vector2(cx, guard_top), Vector2(cx, s.y * 0.9), edge, 1.0, true)

func _draw_shield():
	var s := size
	var shield := PackedVector2Array([
		Vector2(s.x * 0.16, s.y * 0.14),
		Vector2(s.x * 0.84, s.y * 0.14),
		Vector2(s.x * 0.82, s.y * 0.56),
		Vector2(s.x * 0.5, s.y * 0.92),
		Vector2(s.x * 0.18, s.y * 0.56),
	])
	draw_colored_polygon(shield, icon_color)
	# Outline for definition.
	var outline := shield.duplicate()
	outline.append(shield[0])
	draw_polyline(outline, icon_color.darkened(0.4), 1.0, true)
	# Center vertical accent line.
	draw_line(Vector2(s.x * 0.5, s.y * 0.18), Vector2(s.x * 0.5, s.y * 0.82), icon_color.darkened(0.4), 1.0, true)
