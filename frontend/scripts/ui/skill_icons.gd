extends Control
class_name SkillIconRenderer

var icon_type = "hook"
const ICON_COLOR = Color("#ECEFF4") # Bright White/Grey

func set_icon(type):
	icon_type = type
	queue_redraw()

func _draw():
	var center = size / 2.0
	var scale_factor = size.x / 100.0 # Normalize to ~100px canvas
	
	draw_set_transform(center, 0, Vector2(scale_factor, scale_factor))
	
	match icon_type:
		"hook":
			_draw_anchor()
		"rot":
			_draw_biohazard()
		"bite":
			_draw_teeth()
			
func _draw_anchor():
	var col = ICON_COLOR
	# Shank
	draw_rect(Rect2(-5, -30, 10, 50), col)
	# Ring
	draw_arc(Vector2(0, -35), 8, 0, TAU, 32, col, 4.0)
	# Arms
	draw_arc(Vector2(0, 0), 25, 0, PI, 32, col, 8.0)
	# Flukes (Arrow tips)
	var arrow_l = PackedVector2Array([Vector2(-25, 0), Vector2(-35, -10), Vector2(-15, -10)])
	draw_colored_polygon(arrow_l, col)
	var arrow_r = PackedVector2Array([Vector2(25, 0), Vector2(35, -10), Vector2(15, -10)])
	draw_colored_polygon(arrow_r, col)

func _draw_biohazard():
	var col = ICON_COLOR
	# Central Circle
	draw_circle(Vector2.ZERO, 6, col)
	# Three Lobes
	for i in range(3):
		var angle = i * (TAU / 3.0) - PI/2
		var offset = Vector2(cos(angle), sin(angle)) * 15
		draw_circle(offset, 12, col)
		draw_circle(offset, 8, Color.TRANSPARENT) # Cutout simulated? No, masked usually.
		# Simple approximation using arc
		# draw_arc(offset, 10, 0, TAU, 32, col, 6.0)
	
	# Rings
	draw_arc(Vector2.ZERO, 25, 0, TAU, 64, col, 4.0)

func _draw_teeth():
	var col = ICON_COLOR
	# Upper Jaw
	var pts_upper = PackedVector2Array([
		Vector2(-30, -10), Vector2(-15, 5), Vector2(0, -5), Vector2(15, 5), Vector2(30, -10),
		Vector2(20, -20), Vector2(-20, -20)
	])
	draw_colored_polygon(pts_upper, col)
	
	# Lower Jaw
	var pts_lower = PackedVector2Array([
		Vector2(-30, 15), Vector2(-15, 0), Vector2(0, 10), Vector2(15, 0), Vector2(30, 15),
		Vector2(20, 25), Vector2(-20, 25)
	])
	draw_colored_polygon(pts_lower, col)
