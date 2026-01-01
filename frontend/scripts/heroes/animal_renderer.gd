extends Node2D
class_name AnimalRenderer

# Enums
enum ViewMode { TOP_DOWN, PORTRAIT }

# State
var skin: CharacterSkin
var view_mode: ViewMode = ViewMode.TOP_DOWN
var body_color: Color
var secondary_color: Color
var eye_color: Color = Color.BLACK
# Kurzgesagt Style Config
const OUTLINE_COLOR = Color("#2c3e50")
const OUTLINE_WIDTH = 3.0
const SHADOW_COLOR = Color(0, 0, 0, 0.2)
const HIGHLIGHT_COLOR = Color(1, 1, 1, 0.3)
const BODY_RADIUS = 35.0

func setup(p_skin: CharacterSkin):
	skin = p_skin
	if skin:
		body_color = skin.body_color
		secondary_color = skin.secondary_color
		eye_color = Color.BLACK # Fixed for this style usually
	else:
		body_color = Color.WHITE
		secondary_color = Color.GRAY
	queue_redraw()

func set_view_mode(mode: ViewMode):
	view_mode = mode
	queue_redraw()

func _draw():
	if not skin: return
	
	# Scale down slightly for TopDown to fit collisions
	var s = 1.0 if view_mode == ViewMode.PORTRAIT else 0.9
	draw_set_transform(Vector2.ZERO, 0, Vector2(s, s))
	
	_draw_animal_body()
	_draw_features(skin.id)
	_draw_eyes()

# ==============================================================================
# BASE SHAPES
# ==============================================================================
func _draw_animal_body():
	# 0. Directional Indicator (Top Down Only)
	if view_mode == ViewMode.TOP_DOWN:
		var cone_col = Color(1, 1, 1, 0.15)
		var cone_pts = PackedVector2Array([
			Vector2(0, 0),
			Vector2(BODY_RADIUS + 20, -15),
			Vector2(BODY_RADIUS + 25, 0),
			Vector2(BODY_RADIUS + 20, 15)
		])
		draw_colored_polygon(cone_pts, cone_col)

	# 1. Main Body Circle
	draw_circle(Vector2.ZERO, BODY_RADIUS, body_color)
	
	# 2. Rim Light (Top Left Arc) - keep stylistic
	draw_arc(Vector2(-5, -5), BODY_RADIUS - 5, PI, 1.5 * PI, 32, HIGHLIGHT_COLOR, 4.0)
	
	# 3. Shadow Crescent (Bottom Right)
	draw_arc(Vector2(5, 5), BODY_RADIUS - 5, 0, 0.5 * PI, 32, SHADOW_COLOR, 8.0)
	
	# 4. Thick Outline
	draw_arc(Vector2.ZERO, BODY_RADIUS, 0, TAU, 64, OUTLINE_COLOR, OUTLINE_WIDTH)

func _draw_eyes():
	var eye_offset_x = 10.0
	var eye_offset_y = -5.0
	
	# If Top Down, shift eyes forward (+X) to denote facing
	if view_mode == ViewMode.TOP_DOWN:
		eye_offset_x = 10.0 # Wide spacing
		# Shift both eyes to the Right (+X)
		# Eyes at (15, -10) and (15, 10)?
		# Let's say center of face is +15 X.
		
		# Right Eye (Side)
		draw_circle(Vector2(12, 10), 4, eye_color)
		# Left Eye (Side)
		draw_circle(Vector2(12, -10), 4, eye_color)
	else:
		# Portrait (Centered)
		var eye_radius = 4.0
		# Left Eye
		draw_circle(Vector2(-eye_offset_x, eye_offset_y), eye_radius, eye_color)
		# Right Eye
		draw_circle(Vector2(eye_offset_x, eye_offset_y), eye_radius, eye_color)

# ==============================================================================
# FEATURES BY ID
# ==============================================================================
func _draw_features(id):
	match id:
		"duck":
			var col = Color("#FFA500")
			if view_mode == ViewMode.TOP_DOWN:
				# Front: Shift Bill Forward (+X)
				draw_set_transform(Vector2(20, 0), 0, Vector2.ONE)
				_draw_bill(col)
				draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
				
				# Back: Hair Tufts (Psyduck style)
				var hair_col = Color.BLACK
				draw_line(Vector2(-28, -5), Vector2(-40, -10), hair_col, 2.5)
				draw_line(Vector2(-28, 0), Vector2(-45, 0), hair_col, 2.5)
				draw_line(Vector2(-28, 5), Vector2(-40, 10), hair_col, 2.5)
			else:
				# Portrait
				_draw_bill(col)
				# Center tufts?
				var hair_col = Color.BLACK
				draw_line(Vector2(0, -32), Vector2(0, -42), hair_col, 2.0)
				draw_line(Vector2(-5, -30), Vector2(-8, -38), hair_col, 2.0)
				draw_line(Vector2(5, -30), Vector2(8, -38), hair_col, 2.0)

# ... (rest of match cases unchanged, I will trust the user to keep them or I can include context)
# Ideally I should use a smaller chunk if possible, but matching indentation is key.
# I will just replace the "duck" case range if possible, but previous context was full function.
# The tool view showed line 80 starts _draw_features.

		"pig":
			_draw_snout(secondary_color)
			_draw_ears_round(secondary_color)
		"tiger":
			_draw_ears_pointed(body_color)
			_draw_stripes(Color.BLACK)
		"panda":
			_draw_ears_round(Color.BLACK)
			_draw_eye_patches()
		"frog":
			_draw_frog_eyes()
		"bear":
			_draw_ears_round(body_color)
			_draw_muzzle(secondary_color)
		"rabbit":
			_draw_ears_long(body_color)
		"cat":
			_draw_ears_pointed(body_color)
			_draw_whiskers()
		"chicken":
			_draw_comb_and_beak()
		"bee":
			_draw_bee_stripes()
			_draw_wings()
		"elephant":
			_draw_ears_fan()
			_draw_trunk()
		"penguin":
			_draw_belly_white()
			_draw_bill(Color("#FFA500"))
		"fox":
			_draw_ears_pointed(body_color)
			_draw_beard_white()
		"turtle":
			# Shell pattern on back? Usually visible in top down.
			_draw_hex_pattern()
		"cow":
			_draw_ears_round(body_color)
			_draw_splotches()
		"mouse":
			_draw_ears_large_round(body_color)
			_draw_snout_small()
		"owl":
			_draw_ears_tuft()
			_draw_eye_circles_white()
			_draw_beak_small()
		"ladybug":
			_draw_spots()
			_draw_antennae()
		"axolotl":
			_draw_gills() # Pink branches
		"slime":
			# Translucent drawn in registry color, add nucleus
			draw_circle(Vector2.ZERO, 12, secondary_color) # Nucleus

# ==============================================================================
# HELPER COMPONENTS
# ==============================================================================

func _draw_bill(col):
	# Rounded rectangle beak
	# Centered at (0,0) of local transform
	var rect = Rect2(-4, -6, 12, 12) # Shorter, Wavier?
	# Original: Rect2(-8, 2, 16, 10) -> This was very offset Y?
	# Let's align centering.
	rect = Rect2(-5, -8, 14, 16)
	draw_rect(rect, col)
	draw_rect(rect, OUTLINE_COLOR, false, OUTLINE_WIDTH)

func _draw_snout(col):
	draw_circle(Vector2.ZERO, 10, col)
	draw_circle(Vector2.ZERO, 10, OUTLINE_COLOR, false, OUTLINE_WIDTH)
	# Nostrils
	draw_circle(Vector2(-3, 2), 2, Color(0,0,0,0.5))
	draw_circle(Vector2(3, 2), 2, Color(0,0,0,0.5))

func _draw_ears_round(col):
	var pos = Vector2(25, -25)
	# Left
	draw_circle(Vector2(-pos.x, pos.y), 10, col)
	draw_circle(Vector2(-pos.x, pos.y), 10, OUTLINE_COLOR, false, OUTLINE_WIDTH)
	# Right
	draw_circle(pos, 10, col)
	draw_circle(pos, 10, OUTLINE_COLOR, false, OUTLINE_WIDTH)

func _draw_ears_pointed(col):
	var pts_l = PackedVector2Array([Vector2(-20, -20), Vector2(-35, -45), Vector2(-10, -30)])
	draw_colored_polygon(pts_l, col)
	draw_polyline(PackedVector2Array([pts_l[0], pts_l[1], pts_l[2]]), OUTLINE_COLOR, OUTLINE_WIDTH)
	
	var pts_r = PackedVector2Array([Vector2(20, -20), Vector2(35, -45), Vector2(10, -30)])
	draw_colored_polygon(pts_r, col)
	draw_polyline(PackedVector2Array([pts_r[0], pts_r[1], pts_r[2]]), OUTLINE_COLOR, OUTLINE_WIDTH)

func _draw_stripes(col):
	# Simple triangle stripes on sides
	for i in [-1, 1]:
		var p1 = Vector2(i * 35, -10)
		var p2 = Vector2(i * 15, 0)
		var p3 = Vector2(i * 35, 10)
		draw_colored_polygon(PackedVector2Array([p1, p2, p3]), col)

func _draw_eye_patches():
	draw_circle(Vector2(-10, -5), 12, Color.BLACK)
	draw_circle(Vector2(10, -5), 12, Color.BLACK)

func _draw_frog_eyes():
	draw_circle(Vector2(-15, -25), 10, body_color)
	draw_circle(Vector2(-15, -25), 10, OUTLINE_COLOR, false, OUTLINE_WIDTH)
	draw_circle(Vector2(15, -25), 10, body_color)
	draw_circle(Vector2(15, -25), 10, OUTLINE_COLOR, false, OUTLINE_WIDTH)

func _draw_muzzle(col):
	draw_circle(Vector2(0, 5), 12, col)

func _draw_ears_long(col):
	var rect_l = Rect2(-25, -60, 14, 40)
	draw_rect(rect_l, col)
	draw_rect(rect_l, OUTLINE_COLOR, false, OUTLINE_WIDTH)
	
	var rect_r = Rect2(11, -60, 14, 40)
	draw_rect(rect_r, col)
	draw_rect(rect_r, OUTLINE_COLOR, false, OUTLINE_WIDTH)

func _draw_whiskers():
	var col = Color.BLACK
	draw_line(Vector2(-10, 5), Vector2(-40, 0), col, 2.0)
	draw_line(Vector2(-10, 10), Vector2(-40, 15), col, 2.0)
	draw_line(Vector2(10, 5), Vector2(40, 0), col, 2.0)
	draw_line(Vector2(10, 10), Vector2(40, 15), col, 2.0)

func _draw_comb_and_beak():
	# Comb
	draw_circle(Vector2(0, -30), 8, Color.RED)
	draw_circle(Vector2(-10, -25), 6, Color.RED)
	draw_circle(Vector2(10, -25), 6, Color.RED)
	# Beak
	var pts = PackedVector2Array([Vector2(-5, 0), Vector2(5, 0), Vector2(0, 10)])
	draw_colored_polygon(pts, Color.YELLOW)
	draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[0]]), OUTLINE_COLOR, OUTLINE_WIDTH)

func _draw_bee_stripes():
	draw_rect(Rect2(-30, -10, 60, 10), Color.BLACK)
	draw_rect(Rect2(-30, 10, 60, 10), Color.BLACK)

func _draw_wings():
	var col = Color(1, 1, 1, 0.5)
	draw_circle(Vector2(-35, -10), 15, col)
	draw_circle(Vector2(35, -10), 15, col)

func _draw_ears_fan():
	var col = body_color
	draw_circle(Vector2(-35, -10), 20, col)
	draw_circle(Vector2(-35, -10), 20, OUTLINE_COLOR, false, OUTLINE_WIDTH)
	draw_circle(Vector2(35, -10), 20, col)
	draw_circle(Vector2(35, -10), 20, OUTLINE_COLOR, false, OUTLINE_WIDTH)

func _draw_trunk():
	draw_rect(Rect2(-5, 0, 10, 25), body_color)
	draw_rect(Rect2(-5, 0, 10, 25), OUTLINE_COLOR, false, OUTLINE_WIDTH)

func _draw_belly_white():
	draw_circle(Vector2(0, 15), 25, Color.WHITE)

func _draw_beard_white():
	var pts = PackedVector2Array([Vector2(-20, 10), Vector2(20, 10), Vector2(0, 35)])
	draw_colored_polygon(pts, Color.WHITE)

func _draw_hex_pattern():
	# Draw simple hex shape in center
	var r = 15.0
	var pts = []
	for i in range(6):
		var angle = i * PI / 3
		pts.append(Vector2(cos(angle), sin(angle)) * r)
	draw_colored_polygon(PackedVector2Array(pts), Color(0, 0.3, 0))

func _draw_splotches():
	draw_circle(Vector2(-15, 15), 8, Color.BLACK)
	draw_circle(Vector2(20, 0), 10, Color.BLACK)
	draw_circle(Vector2(-5, -25), 6, Color.BLACK)

func _draw_ears_large_round(col):
	draw_circle(Vector2(-30, -25), 18, col)
	draw_circle(Vector2(-30, -25), 18, OUTLINE_COLOR, false, OUTLINE_WIDTH)
	draw_circle(Vector2(30, -25), 18, col)
	draw_circle(Vector2(30, -25), 18, OUTLINE_COLOR, false, OUTLINE_WIDTH)

func _draw_snout_small():
	draw_circle(Vector2(0, 5), 5, Color.BLACK)

func _draw_ears_tuft():
	_draw_ears_pointed(body_color)

func _draw_eye_circles_white():
	draw_circle(Vector2(-12, -5), 14, Color.WHITE)
	draw_circle(Vector2(12, -5), 14, Color.WHITE)

func _draw_beak_small():
	var pts = PackedVector2Array([Vector2(-3, 2), Vector2(3, 2), Vector2(0, 8)])
	draw_colored_polygon(pts, Color.BLACK)

func _draw_spots():
	draw_circle(Vector2(0, 0), 5, Color.BLACK)
	draw_circle(Vector2(-15, 10), 4, Color.BLACK)
	draw_circle(Vector2(15, 10), 4, Color.BLACK)
	draw_circle(Vector2(0, 20), 4, Color.BLACK)
	draw_line(Vector2(0, -35), Vector2(0, 35), Color.BLACK, 2.0)

func _draw_antennae():
	draw_line(Vector2(-5, -30), Vector2(-15, -45), Color.BLACK, 2.0)
	draw_line(Vector2(5, -30), Vector2(15, -45), Color.BLACK, 2.0)

func _draw_gills():
	var col = Color.RED
	draw_line(Vector2(-25, -10), Vector2(-40, -15), col, 3.0)
	draw_line(Vector2(-25, 0), Vector2(-40, 0), col, 3.0)
	draw_line(Vector2(-25, 10), Vector2(-40, 15), col, 3.0)
	
	draw_line(Vector2(25, -10), Vector2(40, -15), col, 3.0)
	draw_line(Vector2(25, 0), Vector2(40, 0), col, 3.0)
	draw_line(Vector2(25, 10), Vector2(40, 15), col, 3.0)
