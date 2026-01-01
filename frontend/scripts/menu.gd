extends Control

# Data State
var name_edit: LineEdit
var code_edit: LineEdit
var decor_items = []

# Config
const COL_BG = Color("#2C3E50") # Navy Blue
const COL_YELLOW = Color("#F1C40F") # Vibrant Yellow
const COL_WHITE = Color("#ECF0F1")
const COL_PLANET_1 = Color("#E67E22")
const COL_PLANET_2 = Color("#27AE60")
const COL_STARS = Color(1, 1, 1, 0.5)

func _ready():
	# 1. Background
	var bg = ColorRect.new()
	bg.color = COL_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# 2. Space Decor (Behind UI)
	var decor_layer = Control.new()
	decor_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	decor_layer.draw.connect(_draw_space_decor.bind(decor_layer))
	add_child(decor_layer)
	_init_decor()
	
	# 3. UI Container (Center)
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(400, 0)
	vbox.add_theme_constant_override("separation", 25)
	center.add_child(vbox)
	
	# 4. Logo
	var title = Label.new()
	title.text = "HooK"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", COL_WHITE)
	title.add_theme_color_override("font_shadow_color", Color(0,0,0,0.2))
	title.add_theme_constant_override("shadow_offset_y", 6)
	title.add_theme_constant_override("shadow_outline_size", 0)
	vbox.add_child(title)
	
	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size.y = 20
	vbox.add_child(spacer)
	
	# 5. Inputs
	vbox.add_child(_create_label("OPERATOR NAME"))
	name_edit = _create_pill_input("Codename")
	vbox.add_child(name_edit)
	
	vbox.add_child(_create_label("ROOM CODE"))
	code_edit = _create_pill_input("######")
	vbox.add_child(code_edit)
	
	vbox.add_child(Control.new()) # Spacer
	
	# 6. Buttons
	var btn_play = _create_pill_button("Create", COL_YELLOW, true)
	btn_play.pressed.connect(_on_create_game)
	vbox.add_child(btn_play)
	
	var btn_join = _create_pill_button("Join", COL_WHITE, false)
	btn_join.pressed.connect(_on_join_game)
	vbox.add_child(btn_join)
	
	set_process(true)

func _process(delta):
	# Rotate Decor
	for item in decor_items:
		item.angle += item.speed * delta
	queue_redraw()

# ==============================================================================
# DECOR
# ==============================================================================
func _init_decor():
	# Planets
	decor_items.append({
		"type": "planet", "pos": Vector2(150, 150), "r": 80, "col": COL_PLANET_1, 
		"ring": true, "angle": 0.0, "speed": 0.2
	})
	decor_items.append({
		"type": "planet", "pos": Vector2(1700, 800), "r": 120, "col": COL_PLANET_2, 
		"ring": false, "angle": 0.0, "speed": -0.1
	})
	# Stars
	for i in range(50):
		decor_items.append({
			"type": "star", 
			"pos": Vector2(randf() * 1920, randf() * 1080), 
			"r": randf_range(1, 3), 
			"angle": 0, "speed": 0
		})

func _draw_space_decor(control: Control):
	for item in decor_items:
		if item.type == "planet":
			# Draw Planet
			control.draw_circle(item.pos, item.r, item.col)
			# Shadow (Crescent)
			control.draw_arc(item.pos + Vector2(item.r*0.2, item.r*0.2), item.r*0.9, 0, PI/2, 32, Color(0,0,0,0.1), item.r*0.2)
			
			if item.get("ring"):
				# Draw Ring (Ellipse logic is hard in pure draw, sim with line)
				var ring_col = Color(1, 1, 1, 0.2)
				var ring_w = item.r * 2.5
				# Draw simple line for ring?
				control.draw_line(item.pos - Vector2(ring_w/2, 0).rotated(0.5), item.pos + Vector2(ring_w/2, 0).rotated(0.5), ring_col, 8.0)
				
		elif item.type == "star":
			control.draw_circle(item.pos, item.r, COL_STARS)

# ==============================================================================
# UI HELPERS
# ==============================================================================
func _create_label(text):
	var l = Label.new()
	l.text = text
	l.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	l.add_theme_font_size_override("font_size", 12)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

func _create_pill_input(placeholder):
	var le = LineEdit.new()
	le.placeholder_text = placeholder
	le.alignment = HORIZONTAL_ALIGNMENT_CENTER
	le.custom_minimum_size.y = 50
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.1) # Translucent White
	style.corner_radius_top_left = 25
	style.corner_radius_top_right = 25
	style.corner_radius_bottom_right = 25
	style.corner_radius_bottom_left = 25
	style.content_margin_left = 20
	style.content_margin_right = 20
	
	le.add_theme_stylebox_override("normal", style)
	le.add_theme_stylebox_override("focus", style) # Keep same
	le.add_theme_color_override("font_color", COL_WHITE)
	le.add_theme_color_override("font_placeholder_color", Color(1, 1, 1, 0.3))
	
	return le

func _create_pill_button(text, bg_col, is_dark_text):
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, 60)
	btn.pivot_offset = Vector2(200, 30) # Approx center for scale
	
	var style = StyleBoxFlat.new()
	style.bg_color = bg_col
	style.corner_radius_top_left = 30
	style.corner_radius_top_right = 30
	style.corner_radius_bottom_right = 30
	style.corner_radius_bottom_left = 30
	style.shadow_color = Color(0,0,0,0.2)
	style.shadow_size = 0
	style.shadow_offset = Vector2(0, 4) # Drop shadow
	
	var hover = style.duplicate()
	# Can't animate scale here easily, will handle signal
	
	var pressed = style.duplicate()
	pressed.shadow_offset = Vector2(0, 2)
	pressed.bg_color = bg_col.darkened(0.1)
	
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	
	var txt_col = Color("#2C3E50") if is_dark_text else COL_BG
	if not is_dark_text: txt_col = COL_BG # Force dark text on white/yellow usually looks best or check contrast
	if bg_col == COL_WHITE: txt_col = COL_BG
	
	btn.add_theme_color_override("font_color", txt_col)
	btn.add_theme_color_override("font_hover_color", txt_col)
	btn.add_theme_color_override("font_pressed_color", txt_col)
	btn.add_theme_font_size_override("font_size", 18)
	
	# Bounce
	btn.mouse_entered.connect(func(): 
		var t = create_tween()
		t.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.1)
	)
	btn.mouse_exited.connect(func():
		var t = create_tween()
		t.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1)
	)
	
	return btn

# ==============================================================================
# LOGIC
# ==============================================================================
func _on_create_game():
	var p_name = name_edit.text.strip_edges()
	if p_name == "": 
		p_name = "Agent-" + str(randi() % 1000)
	NetworkManager.send_packet({"type": "create_room", "payload": {"name": p_name, "avatar_id": "duck"}})

func _on_join_game():
	var p_name = name_edit.text.strip_edges()
	var code = code_edit.text.strip_edges()
	if p_name == "" or code == "": return
	NetworkManager.send_packet({"type": "join_room", "payload": {"code": code, "name": p_name, "avatar_id": "duck"}})
