extends Control
class_name HandRail

# Foreground "hand tray" drawn above the cards. Its top edge is a convex arch
# (a dome: high in the middle, dropping toward the sides) that mirrors the
# card fan's lower silhouette, so the fanned cards tuck behind it evenly. The
# energy number sits at the center; the bright top edge is the arch line.

const SAMPLES := 48

@export var edge_center_y := 18.0
@export var edge_side_y := 50.0
@export var fill_top := Color(0.07, 0.1, 0.16, 0.82)
@export var fill_bottom := Color(0.02, 0.03, 0.06, 0.97)
@export var line_color := Color(0.55, 0.82, 1.0, 0.62)

func _draw():
	var w := size.x
	var h := size.y
	var top := PackedVector2Array()
	for s in range(SAMPLES + 1):
		var t := float(s) / float(SAMPLES)
		top.append(Vector2(t * w, _edge_y(t)))

	var poly := PackedVector2Array()
	var cols := PackedColorArray()
	for p in top:
		poly.append(p)
		cols.append(fill_top)
	poly.append(Vector2(w, h))
	cols.append(fill_bottom)
	poly.append(Vector2(0, h))
	cols.append(fill_bottom)
	draw_polygon(poly, cols)

	# Glow underlay + crisp line along the arched top edge.
	draw_polyline(top, Color(line_color.r, line_color.g, line_color.b, line_color.a * 0.35), 5.0, true)
	draw_polyline(top, line_color, 2.0, true)

func _edge_y(t: float) -> float:
	var d := (t - 0.5) * 2.0
	return edge_center_y + (edge_side_y - edge_center_y) * d * d
