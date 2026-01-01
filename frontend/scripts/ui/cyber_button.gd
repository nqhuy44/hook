extends Button
class_name CyberButton

# Config
@export var color_primary: Color = Color("#00f3ff") # Cyan
@export var color_secondary: Color = Color("#ff0055") # Pink
@export var color_bg: Color = Color("#0b0c16")
@export var skew_angle: float = -15.0

# State
var _hovering = false
var _pressed = false
var _anim_offset = Vector2.ZERO

func _ready():
	# Remove default styles
	add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
	
	# Connect signals
	mouse_entered.connect(_on_mouse_enter)
	mouse_exited.connect(_on_mouse_exit)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	
	# Text styling
	add_theme_color_override("font_color", color_primary)
	add_theme_color_override("font_hover_color", Color.WHITE)
	add_theme_color_override("font_pressed_color", Color.BLACK)
	
func _draw():
	var rect = get_rect()
	var w = rect.size.x
	var h = rect.size.y
	
	# Skew calculation (x offset based on y)
	# tan(-15 deg) approx -0.26
	var skew_x = h * tan(deg_to_rad(skew_angle))
	
	# Draw Shadow (Offset)
	if not _pressed:
		var shadow_off = Vector2(4, 4)
		_draw_skewed_rect(Vector2.ZERO + shadow_off, w, h, skew_x, Color.BLACK)
	
	# Draw Main Body
	var body_pos = _anim_offset
	if _pressed: body_pos += Vector2(2, 2)
	
	# Fill
	var fill_col = color_bg
	if _hovering: fill_col = color_primary.darkened(0.7)
	if _pressed: fill_col = color_primary
	
	_draw_skewed_rect(body_pos, w, h, skew_x, fill_col)
	
	# Outline
	var outline_col = color_primary
	if _hovering: outline_col = Color.WHITE
	if _pressed: outline_col = Color.BLACK
	
	_draw_skewed_outline(body_pos, w, h, skew_x, outline_col, 2.0)
	
	# Decoration (Stripes?)
	if _hovering and not _pressed:
		_draw_stripes(body_pos, w, h, skew_x, color_primary)

func _draw_skewed_rect(pos: Vector2, w: float, h: float, skew: float, col: Color):
	# Points: TL, TR, BR, BL
	# TL starts at some offset to allow skewing?
	# Let's center the skew? No, standard top-left anchor.
	# If skew is negative, top is shifted left? Or bottom shifted right?
	# Implementation: Top edge at X, Bottom edge at X - skew
	
	# Let's say skew is the total X displacement from top to bottom.
	# If Skew Angle is -15, top is right, bottom is left?
	# tan(-15) is neg.
	# Let's simply define points.
	
	# To keep content inside, let's just shift the visual rect.
	# We want the text to remain readable, so we don't skew the text, just the bg.
	# We need to ensure the rect covers the hit area roughly.
	
	var offset = abs(skew) # Shift right so we don't draw outside 0
	
	var p1 = pos + Vector2(offset, 0) # TL
	var p2 = pos + Vector2(w + offset, 0) # TR
	var p3 = pos + Vector2(w, h) # BR (Shifted left relative to top?)
	# Wait, if skew is negative (-0.26 * h), then bottom x is top x + skew?
	# Let's try:
	# p3 = p2 + (skew, h) -> No.
	
	# x' = x + y * tan(angle)
	var tan_a = tan(deg_to_rad(skew_angle))
	
	# Origin (0,0) -> (0,0)
	# (w, 0) -> (w, 0)
	# (w, h) -> (w + h*tan, h)
	# (0, h) -> (h*tan, h)
	
	# If angle is -15, tan is negative. Bottom points shift left.
	# To keep it centered or visible, we might want to shift everything right by max skew width if needed.
	var shift_x = 0.0
	if skew_angle < 0:
		shift_x = abs(h * tan_a)
		
	var points = PackedVector2Array([
		pos + Vector2(shift_x, 0),
		pos + Vector2(w + shift_x, 0),
		pos + Vector2(w + shift_x + h * tan_a, h),
		pos + Vector2(shift_x + h * tan_a, h)
	])
	
	draw_colored_polygon(points, col)
	return points

func _draw_skewed_outline(pos: Vector2, w: float, h: float, skew: float, col: Color, width: float):
	var tan_a = tan(deg_to_rad(skew_angle))
	var shift_x = 0.0
	if skew_angle < 0:
		shift_x = abs(h * tan_a)
		
	var points = PackedVector2Array([
		pos + Vector2(shift_x, 0),
		pos + Vector2(w + shift_x, 0),
		pos + Vector2(w + shift_x + h * tan_a, h),
		pos + Vector2(shift_x + h * tan_a, h),
		pos + Vector2(shift_x, 0) # Close loop
	])
	draw_polyline(points, col, width)

func _draw_stripes(pos: Vector2, w: float, h: float, skew: float, col: Color):
	# Draw little Deco lines
	var tan_a = tan(deg_to_rad(skew_angle))
	var shift_x = 0.0
	if skew_angle < 0:
		shift_x = abs(h * tan_a)
		
	# A line at bottom right corner
	var p3 = pos + Vector2(w + shift_x + h * tan_a, h)
	draw_line(p3 + Vector2(-10, 0), p3 + Vector2(-5, -5), col, 2.0)

func _on_mouse_enter():
	_hovering = true
	var t = create_tween()
	t.tween_property(self, "_anim_offset", Vector2(4, -4), 0.1).set_trans(Tween.TRANS_SINE)
	queue_redraw()

func _on_mouse_exit():
	_hovering = false
	var t = create_tween()
	t.tween_property(self, "_anim_offset", Vector2.ZERO, 0.1).set_trans(Tween.TRANS_SINE)
	queue_redraw()

func _on_button_down():
	_pressed = true
	queue_redraw()

func _on_button_up():
	_pressed = false
	queue_redraw()
