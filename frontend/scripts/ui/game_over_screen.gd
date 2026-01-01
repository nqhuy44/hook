extends CanvasLayer

var bg_rect: ColorRect
var content_box: VBoxContainer
var winner_label: Label
var return_btn: Button

func _ready():
	# 0. ROOT CONFIG
	layer = 128
	
	# 1. BACKGROUND (Full Rect)
	bg_rect = ColorRect.new()
	bg_rect.name = "Background"
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_rect.color = Color(0, 0, 0, 0.9) # Default Black
	add_child(bg_rect)
	
	# 2. CENTER CONTAINER
	var center = CenterContainer.new()
	center.name = "CenterHolder"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	
	# 3. CONTENT BOX
	content_box = VBoxContainer.new()
	content_box.name = "Content"
	content_box.alignment = BoxContainer.ALIGNMENT_CENTER
	content_box.add_theme_constant_override("separation", 30)
	# Pivot center for scaling
	content_box.pivot_offset = Vector2(0, 0) # Calculated later or ignored if using tweens differently
	center.add_child(content_box)
	
	# 4A. WINNER LABEL
	winner_label = Label.new()
	winner_label.name = "WinnerLabel"
	winner_label.text = "GAME OVER"
	winner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	var lbl_settings = LabelSettings.new()
	lbl_settings.font_size = 64
	lbl_settings.font_color = Color.WHITE
	lbl_settings.outline_size = 8
	lbl_settings.outline_color = Color.BLACK
	winner_label.label_settings = lbl_settings
	content_box.add_child(winner_label)
	
	# 4B. RETURN BUTTON
	return_btn = Button.new()
	return_btn.name = "ReturnButton"
	return_btn.text = "RETURN TO MENU"
	return_btn.custom_minimum_size = Vector2(250, 60)
	
	var s_btn = StyleBoxFlat.new()
	s_btn.bg_color = Color("#ECF0F1") # White/Grey
	s_btn.set_corner_radius_all(12)
	s_btn.content_margin_top = 10
	s_btn.content_margin_bottom = 10
	
	var s_hover = s_btn.duplicate()
	s_hover.bg_color = Color.WHITE
	
	return_btn.add_theme_stylebox_override("normal", s_btn)
	return_btn.add_theme_stylebox_override("hover", s_hover)
	return_btn.add_theme_stylebox_override("pressed", s_btn)
	return_btn.add_theme_color_override("font_color", Color.BLACK)
	return_btn.add_theme_color_override("font_hover_color", Color.BLACK)
	return_btn.add_theme_color_override("font_pressed_color", Color("#2C3E50"))
	return_btn.add_theme_font_size_override("font_size", 24)
	
	content_box.add_child(return_btn)
	
	return_btn.pressed.connect(_on_return_pressed)
	
	# Initial Scale 0
	content_box.scale = Vector2.ZERO

func setup(winner_info):
	# Handle input: winner_info could be String ("RADIANT") or Int ID
	var team_name = "DRAW"
	
	if typeof(winner_info) == TYPE_STRING:
		team_name = winner_info
	elif typeof(winner_info) == TYPE_INT or typeof(winner_info) == TYPE_FLOAT:
		if int(winner_info) == 1: team_name = "RADIANT"
		elif int(winner_info) == 2: team_name = "DIRE"
		
	winner_label.text = team_name + " VICTORY"
	if team_name == "DRAW": winner_label.text = "GAME DRAW"
	
	var target_col = Color("#34495E") # Default
	if team_name == "RADIANT":
		target_col = Color("#1abc9c") # Deep Teal
	elif team_name == "DIRE":
		target_col = Color("#e74c3c") # Vibrant Red
		
	target_col.a = 0.9
	
	# Animations
	var t = create_tween()
	
	# Background Color Fade
	t.tween_property(bg_rect, "color", target_col, 0.5)
	
	# Content Pop Up (Elastic)
	# Need waiting for layout? Call deferred?
	# Using center pivot for scaling effect
	
	# Trick: CenterContainer keeps it centered, but scaling might look weird if pivot is top-left.
	# We should set pivot to center of size. But size is not calculated yet.
	# Workaround: Animate Modulate or simple scale from 0.
	# Or force update.
	# ensure_control_rect() ?
	
	t.parallel().tween_property(content_box, "scale", Vector2.ONE, 0.8).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func _on_return_pressed():
	if NetworkManager.socket:
		NetworkManager.socket.close()
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
