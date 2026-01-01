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
	z_index = 200 # Ensure drawn on top of everything including AnimalRenderer
	id = data.get("id", "")
	entity_name = data.get("name", "Unknown")
	team = data.get("team", 1)
	radius = data.get("radius", 20)
	var hex = data.get("color", "#ffffff")
	color = Color(hex)
	max_hp = data.get("max_hp", 100)
	current_hp = data.get("hp", 100)
	avatar_id = data.get("avatar_id", "butcher")
	# position = Vector2(data.get("pos", {}).get("x", 0), data.get("pos", {}).get("y", 0))
	# rotation = data.get("rotation", 0)

func update_state(data):
	# Position and Rotation are handled by the Game loop interpolation, 
	# but we need to update HP and other stats here.
	current_hp = data.get("hp", current_hp)
	max_hp = data.get("max_hp", max_hp)
	if data.has("color"): color = Color(data.get("color"))
	queue_redraw()

func _draw():
	# If we are just a logic node (parent handles visuals), skip body draw
	if get_parent().has_method("apply_skin"): # Heuristic: Parent is Player.tscn
		_draw_info()
		return

	# Draw Circle Body
	draw_circle(Vector2.ZERO, radius, color)
	
	# Draw Direction Indicator
	var dir_point = Vector2(radius * 1.2, 0)
	draw_line(Vector2.ZERO, dir_point, Color(1, 1, 1, 0.5), 2.0)
	
	_draw_info()

func _process(_delta):
	# Redraw every frame to handle rotation updates
	queue_redraw()

func _draw_info():
	# Reset transform to be upright
	draw_set_transform(Vector2.ZERO, -global_rotation, Vector2.ONE)
	
	var font = ThemeDB.fallback_font
	var font_size = 16 # Bold font if possible, standard is fine with outline
	var text_pos = Vector2(-50, -radius - 35)
	
	# NAME (Floating Text Style)
	# Heavy White Outline (Contrast)
	draw_string_outline(font, text_pos + Vector2(0, 14), entity_name, HORIZONTAL_ALIGNMENT_CENTER, 100, font_size, 4, Color.WHITE)
	# Black/Dark Text
	draw_string(font, text_pos + Vector2(0, 14), entity_name, HORIZONTAL_ALIGNMENT_CENTER, 100, font_size, Color.BLACK)
	
	# HP BAR (Slim & Clean)
	var bar_w = 60
	var bar_h = 6
	var bar_pos = Vector2(-bar_w / 2.0, -radius - 15)
	
	# Background (Dark Grey)
	draw_rect(Rect2(bar_pos, Vector2(bar_w, bar_h)), Color("#2E3440"))
	
	# Fill (Bright Green/Red)
	var pct = clamp(float(current_hp) / float(max_hp), 0.0, 1.0)
	var fill_color = Color("#2ECC71") if team == 1 else Color("#E74C3C")
	draw_rect(Rect2(bar_pos, Vector2(bar_w * pct, bar_h)), fill_color)
