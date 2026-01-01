extends Node2D

const RADIUS = 60.0
const COLOR_BASE = Color.MAGENTA # DEBUG: High Contrast

var is_active = false
var time_accum = 0.0

func _ready():
	z_index = 1 # DEBUG: Draw ON TOP of player
	visible = false
	set_process(false)
	print("RotVisual Ready. Parent: ", get_parent().name)

func toggle(on: bool):
	print("RotVisual Toggled: ", on)
	is_active = on
	visible = on
	set_process(on)
	queue_redraw()

func _process(delta):
	time_accum += delta
	# Force constant redraw to animate pulse
	queue_redraw()

func _draw():
	if not is_active: return
	
	# Pulse calc
	var t = Time.get_ticks_msec() / 1000.0
	var alpha = 0.4 + sin(t * 10.0) * 0.1 # 0.3 to 0.5 (Stronger)
	
	var c_fill = COLOR_BASE
	c_fill.a = alpha
	
	var c_border = COLOR_BASE
	c_border.a = 1.0 # Solid border
	
	# Draw
	draw_circle(Vector2.ZERO, RADIUS, c_fill)
	draw_arc(Vector2.ZERO, RADIUS, 0, TAU, 32, c_border, 3.0)
	# draw_string(ThemeDB.fallback_font, Vector2.ZERO, "AURA", HORIZONTAL_ALIGNMENT_CENTER) # Debug Text
