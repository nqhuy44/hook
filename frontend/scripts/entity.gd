extends Node2D

var id = ""
var entity_name = ""
var team = 1
var radius = 20
var color = Color.WHITE
var current_hp = 100
var max_hp = 100
var avatar_id = "butcher"
var target_pos = Vector2() # For smoothing if needed

func setup(data):
	id = data.get("id", "")
	entity_name = data.get("name", "Unknown")
	team = data.get("team", 1)
	radius = data.get("radius", 20)
	var hex = data.get("color", "#ffffff")
	color = Color(hex)
	max_hp = data.get("max_hp", 100)
	current_hp = data.get("hp", 100)
	avatar_id = data.get("avatar_id", "butcher")
	position = Vector2(data.get("pos", {}).get("x", 0), data.get("pos", {}).get("y", 0))
	rotation = data.get("rotation", 0)

func update_state(data):
	# Position and Rotation are handled by the Game loop interpolation, 
	# but we need to update HP and other stats here.
	current_hp = data.get("hp", current_hp)
	max_hp = data.get("max_hp", max_hp)
	if data.has("color"): color = Color(data.get("color"))
	queue_redraw()

func _draw():
	# If we have child nodes (loaded from scene), we might not want to draw the default circle
	# Assume that if 'Body' node exists, we don't draw the circle
	if has_node("Body"):
		# Just draw info overlays
		_draw_info()
		return

	# Draw Circle Body
	draw_circle(Vector2.ZERO, radius, color)
	
	# Draw Direction Indicator
	var dir_point = Vector2(radius * 1.2, 0)
	draw_line(Vector2.ZERO, dir_point, Color(1, 1, 1, 0.5), 2.0)
	
	_draw_info()

func _draw_info():
	# Draw Name
	var font = ThemeDB.fallback_font
	var font_size = 16
	var text_pos = Vector2(-40, -radius - 25)
	draw_string(font, text_pos, entity_name, HORIZONTAL_ALIGNMENT_CENTER, 80, font_size)
	
	# Draw HP Bar
	var bar_w = 60
	var bar_h = 6
	var bar_pos = Vector2(-bar_w/2, -radius - 15)
	# BG
	draw_rect(Rect2(bar_pos, Vector2(bar_w, bar_h)), Color.BLACK)
	# Fill
	var pct = clamp(float(current_hp) / float(max_hp), 0.0, 1.0)
	var fill_color = Color.GREEN if team == 1 else Color.RED # Simplified logic, ideally relative to 'me'
	draw_rect(Rect2(bar_pos, Vector2(bar_w * pct, bar_h)), fill_color)
