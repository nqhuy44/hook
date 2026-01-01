extends Control

# UI References
var room_code_label: Label
var radiant_grid: VBoxContainer
var dire_grid: VBoxContainer
var start_button: Button
var avatar_grid: HFlowContainer # Using Flow for nice wrapping if needed, or Grid

# Preview Refs
var preview_avatar: Control
var preview_topdown: Control
var preview_name_label: Label

# Chat Refs
var chat_log: RichTextLabel
var chat_input: LineEdit

# Scripts
const AnimalRendererScript = preload("res://scripts/heroes/animal_renderer.gd")
const AvatarRendererScript = preload("res://scripts/ui/avatar_renderer.gd")

# State
var available_skins = []
var selected_avatar = "duck"
var particles = []

# Style Config - Kurzgesagt Palette
const COL_BG = Color("#181825") # Deep Space
const COL_PANEL_BG = Color("#2E3440") # Dark Slate
const COL_PANEL_LIGHT = Color("#3B4252") # Lighter Slate
const COL_ACCENT_TEAL = Color("#88C0D0")
const COL_ACCENT_ORANGE = Color("#D08770")
const COL_TEXT_WHITE = Color("#ECEFF4")
const COL_TEXT_MUTED = Color("#D8DEE9")
const RADIANT_TINT = Color("#A3BE8C") # Soft Green
const DIRE_TINT = Color("#BF616A") # Soft Red

func _ready():
	NetworkManager.packet_received.connect(_on_packet)
	
	# 1. Background
	var bg = ColorRect.new()
	bg.color = COL_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# Particles
	var p_layer = Control.new()
	p_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	p_layer.draw.connect(_draw_particles.bind(p_layer))
	add_child(p_layer)
	_init_particles()
	set_process(true)
	
	# 2. Main Layout Root
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 15)
	margin.add_child(main_vbox)
	
	# ==========================================================================
	# HEADER (Room Pill)
	# ==========================================================================
	var header_hbox = HBoxContainer.new()
	main_vbox.add_child(header_hbox)
	
	var room_pill = PanelContainer.new()
	var pill_style = _create_style_box(COL_ACCENT_TEAL, 20)
	room_pill.add_theme_stylebox_override("panel", pill_style)
	header_hbox.add_child(room_pill)
	
	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left", 25)
	m.add_theme_constant_override("margin_right", 25)
	m.add_theme_constant_override("margin_top", 10)
	m.add_theme_constant_override("margin_bottom", 10)
	room_pill.add_child(m)
	
	room_code_label = Label.new()
	room_code_label.text = "ROOM: ???"
	room_code_label.add_theme_color_override("font_color", COL_BG) # Dark text on bright pill
	room_code_label.add_theme_font_size_override("font_size", 20)
	room_code_label.add_theme_constant_override("font_outline_size", 0) 
	# Bold font simulation if possible, usually just default bold
	m.add_child(room_code_label)
	
	# ==========================================================================
	# TWO-COLUMN CONTENT
	# ==========================================================================
	var content_hbox = HBoxContainer.new()
	content_hbox.size_flags_vertical = SIZE_EXPAND_FILL
	content_hbox.add_theme_constant_override("separation", 20)
	main_vbox.add_child(content_hbox)
	
	# --------------------------------------------------------------------------
	# A. LEFT PANEL (Game Setup - 75%)
	# --------------------------------------------------------------------------
	var left_panel = VBoxContainer.new()
	left_panel.size_flags_horizontal = SIZE_EXPAND_FILL
	left_panel.size_flags_stretch_ratio = 0.75
	left_panel.add_theme_constant_override("separation", 20)
	content_hbox.add_child(left_panel)
	
	# A1. UPPER SECTION (Character & Skills)
	_build_upper_section(left_panel)
	
	# A2. LOWER SECTION (Teams & Actions)
	_build_lower_section(left_panel)
	
	# --------------------------------------------------------------------------
	# B. RIGHT PANEL (Chat - 25%)
	# --------------------------------------------------------------------------
	var right_panel = PanelContainer.new()
	right_panel.size_flags_horizontal = SIZE_EXPAND_FILL
	right_panel.size_flags_stretch_ratio = 0.25
	right_panel.add_theme_stylebox_override("panel", _create_style_box(COL_PANEL_LIGHT, 12))
	content_hbox.add_child(right_panel)
	
	_build_chat_ui(right_panel)
	
	# Init Data
	available_skins = SkinRegistry.get_all_skins()
	_populate_skin_grid()
	_select_avatar(available_skins[0].id)

func _process(delta):
	# Particles
	for p in particles:
		p.y -= p.speed * delta
		if p.y < -50:
			p.y = get_viewport_rect().size.y + 50
			p.x = randf() * get_viewport_rect().size.x
	queue_redraw()
	
	# Pulse Start
	if start_button and start_button.visible:
		var t = Time.get_ticks_msec() / 200.0
		var s = 1.0 + sin(t) * 0.02
		start_button.scale = Vector2(s, s)

# ==============================================================================
# UI BUILDERS
# ==============================================================================

func _build_upper_section(parent):
	var main_hbox = HBoxContainer.new()
	main_hbox.size_flags_vertical = SIZE_EXPAND_FILL
	main_hbox.size_flags_stretch_ratio = 0.4 # Takes about 40% height of left side? Or just fixed height
	main_hbox.custom_minimum_size.y = 220
	main_hbox.add_theme_constant_override("separation", 20)
	parent.add_child(main_hbox)
	
	# Left: Character Info (Portrait)
	var info_panel = PanelContainer.new()
	info_panel.custom_minimum_size.x = 240
	info_panel.add_theme_stylebox_override("panel", _create_style_box(COL_PANEL_BG, 12))
	main_hbox.add_child(info_panel)
	
	var info_vbox = VBoxContainer.new()
	info_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	# info_panel.get_node("Margin").add_child(info_vbox) - Error: Margin doesn't exist yet
	
	# Create margin manually
	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_top", 10)
	m.add_theme_constant_override("margin_bottom", 10)
	info_panel.add_child(m)
	m.add_child(info_vbox)
	
	preview_avatar = AvatarRendererScript.new()
	preview_avatar.custom_minimum_size = Vector2(100, 100)
	info_vbox.add_child(preview_avatar)
	
	preview_name_label = Label.new()
	preview_name_label.text = "UNKNOWN"
	preview_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_name_label.add_theme_font_size_override("font_size", 24)
	preview_name_label.add_theme_color_override("font_color", COL_TEXT_WHITE)
	info_vbox.add_child(preview_name_label)
	
	preview_topdown = AvatarRendererScript.new()
	preview_topdown.custom_minimum_size = Vector2(50, 50)
	info_vbox.add_child(preview_topdown)
	
	# Right: Skins Grid
	var grid_panel = PanelContainer.new()
	grid_panel.size_flags_horizontal = SIZE_EXPAND_FILL
	grid_panel.add_theme_stylebox_override("panel", _create_style_box(COL_PANEL_BG, 12))
	main_hbox.add_child(grid_panel)
	
	var gm = MarginContainer.new()
	gm.add_theme_constant_override("margin_left", 15)
	gm.add_theme_constant_override("margin_right", 15)
	gm.add_theme_constant_override("margin_top", 15)
	gm.add_theme_constant_override("margin_bottom", 15)
	grid_panel.add_child(gm)
	
	var scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	gm.add_child(scroll)
	
	avatar_grid = HFlowContainer.new() # Flow for wrapping
	avatar_grid.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll.add_child(avatar_grid)

func _build_lower_section(parent):
	var main_vbox = VBoxContainer.new()
	main_vbox.size_flags_vertical = SIZE_EXPAND_FILL
	main_vbox.add_theme_constant_override("separation", 15)
	parent.add_child(main_vbox)
	
	# Teams HBox
	var teams_hbox = HBoxContainer.new()
	teams_hbox.size_flags_vertical = SIZE_EXPAND_FILL
	teams_hbox.add_theme_constant_override("separation", 20)
	main_vbox.add_child(teams_hbox)
	
	# Radiant Column
	radiant_grid = _create_team_column(teams_hbox, "TEAM RADIANT", RADIANT_TINT)
	
	# Dire Column
	dire_grid = _create_team_column(teams_hbox, "TEAM DIRE", DIRE_TINT)
	
	# Footer Actions
	var footer_hbox = HBoxContainer.new()
	footer_hbox.custom_minimum_size.y = 60
	footer_hbox.alignment = BoxContainer.ALIGNMENT_END
	footer_hbox.add_theme_constant_override("separation", 20)
	main_vbox.add_child(footer_hbox)
	
	var btn_switch = Button.new()
	btn_switch.text = "SWITCH TEAM"
	btn_switch.custom_minimum_size = Vector2(150, 50)
	_apply_button_style(btn_switch, Color(0,0,0,0), COL_TEXT_WHITE)
	btn_switch.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn_switch.pressed.connect(_on_switch_team)
	footer_hbox.add_child(btn_switch)
	
	start_button = Button.new()
	start_button.text = "START GAME"
	start_button.custom_minimum_size = Vector2(200, 50)
	start_button.pivot_offset = Vector2(100, 25)
	_apply_button_style(start_button, COL_ACCENT_ORANGE, COL_TEXT_WHITE)
	start_button.pressed.connect(_on_start_game)
	start_button.hide()
	footer_hbox.add_child(start_button)

func _create_team_column(parent, title, tint_col):
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = SIZE_EXPAND_FILL
	# Tinted background panel
	var bg = COL_PANEL_BG.lerp(tint_col, 0.1)
	panel.add_theme_stylebox_override("panel", _create_style_box(bg, 12))
	parent.add_child(panel)
	
	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left", 10)
	m.add_theme_constant_override("margin_right", 10)
	m.add_theme_constant_override("margin_top", 10)
	m.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(m)
	
	var vbox = VBoxContainer.new()
	m.add_child(vbox)
	
	var lbl = Label.new()
	lbl.text = title
	lbl.add_theme_color_override("font_color", tint_col.lightened(0.2))
	lbl.add_theme_font_size_override("font_size", 14)
	vbox.add_child(lbl)
	vbox.add_child(HSeparator.new())
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)
	
	var list = VBoxContainer.new()
	list.size_flags_horizontal = SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 5)
	scroll.add_child(list)
	
	return list

func _build_chat_ui(parent):
	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left", 10)
	m.add_theme_constant_override("margin_right", 10)
	m.add_theme_constant_override("margin_top", 10)
	m.add_theme_constant_override("margin_bottom", 10)
	parent.add_child(m)
	
	var vbox = VBoxContainer.new()
	m.add_child(vbox)
	
	var lbl = Label.new()
	lbl.text = "COMMS LINK"
	lbl.add_theme_color_override("font_color", COL_ACCENT_TEAL)
	vbox.add_child(lbl)
	
	chat_log = RichTextLabel.new()
	chat_log.size_flags_vertical = SIZE_EXPAND_FILL
	chat_log.scroll_following = true
	chat_log.bbcode_enabled = true
	chat_log.add_theme_color_override("default_color", COL_TEXT_WHITE)
	vbox.add_child(chat_log)
	
	var input_hbox = HBoxContainer.new()
	vbox.add_child(input_hbox)
	
	chat_input = LineEdit.new()
	chat_input.size_flags_horizontal = SIZE_EXPAND_FILL
	chat_input.placeholder_text = "Type..."
	var style = _create_style_box(Color("#4C566A"), 8)
	chat_input.add_theme_stylebox_override("normal", style)
	chat_input.add_theme_stylebox_override("focus", style)
	chat_input.add_theme_color_override("font_color", COL_TEXT_WHITE)
	chat_input.text_submitted.connect(_on_chat_submit)
	input_hbox.add_child(chat_input)
	
	var btn_send = Button.new()
	btn_send.text = ">"
	_apply_button_style(btn_send, COL_ACCENT_TEAL, COL_BG)
	btn_send.custom_minimum_size.x = 40
	btn_send.pressed.connect(func(): _on_chat_submit(chat_input.text))
	input_hbox.add_child(btn_send)

# ==============================================================================
# HELPERS
# ==============================================================================

func _create_style_box(bg_col, rad):
	var s = StyleBoxFlat.new()
	s.bg_color = bg_col
	s.corner_radius_top_left = rad
	s.corner_radius_top_right = rad
	s.corner_radius_bottom_right = rad
	s.corner_radius_bottom_left = rad
	return s

func _apply_button_style(btn, bg_col, txt_col):
	var norm = _create_style_box(bg_col, 10)
	if bg_col.a == 0: # Transparent
		norm.border_width_bottom = 0
	
	var hov = norm.duplicate()
	if bg_col.a > 0:
		hov.bg_color = bg_col.lightened(0.1)
	else:
		hov.bg_color = Color(1,1,1,0.1)
		
	btn.add_theme_stylebox_override("normal", norm)
	btn.add_theme_stylebox_override("hover", hov)
	btn.add_theme_stylebox_override("pressed", hov)
	btn.add_theme_color_override("font_color", txt_col)
	btn.add_theme_color_override("font_hover_color", txt_col)

# ==============================================================================
# LOGIC
# ==============================================================================

func _populate_skin_grid():
	for skin in available_skins:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(60, 60)
		btn.toggle_mode = true
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		
		# Round button style
		var s_norm = _create_style_box(Color(0,0,0,0.2), 30)
		var s_press = _create_style_box(COL_ACCENT_ORANGE, 30)
		
		btn.add_theme_stylebox_override("normal", s_norm)
		btn.add_theme_stylebox_override("pressed", s_press)
		btn.add_theme_stylebox_override("hover", s_press) # Highlight on hover too? Sure
		
		# Icon
		var icon = AvatarRendererScript.new()
		icon.custom_minimum_size = Vector2(40, 40)
		icon.set_skin(skin, AnimalRendererScript.ViewMode.TOP_DOWN)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var c = CenterContainer.new()
		c.set_anchors_preset(Control.PRESET_FULL_RECT)
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.add_child(icon)
		btn.add_child(c)
		
		btn.pressed.connect(func(): _select_avatar(skin.id, btn))
		avatar_grid.add_child(btn)

func _select_avatar(id, btn_ref=null):
	selected_avatar = id
	if btn_ref:
		for b in avatar_grid.get_children():
			b.set_pressed_no_signal(b == btn_ref)
	
	var skin = SkinRegistry.get_skin(id)
	if skin:
		preview_avatar.set_skin(skin, AnimalRendererScript.ViewMode.PORTRAIT)
		preview_topdown.set_skin(skin, AnimalRendererScript.ViewMode.TOP_DOWN)
		preview_name_label.text = skin.display_name.to_upper()
		
	NetworkManager.send_packet({"type": "change_avatar", "payload": {"avatar_id": id}})

func _on_switch_team():
	NetworkManager.send_packet({"type": "switch_team", "payload": {}})

func _on_start_game():
	NetworkManager.send_packet({"type": "start_game", "payload": {}})

func _on_chat_submit(msg: String):
	if msg.strip_edges() == "": return
	chat_input.text = ""
	NetworkManager.send_packet({"type": "chat", "payload": {"message": msg}})

func _on_packet(type, payload):
	if type == "lobby_update":
		_update_lobby_ui(payload)
	elif type == "chat":
		var sender = payload.get("sender", "System")
		var msg = payload.get("message", "")
		var col = "white"
		if sender == "System": col = "gray"
		chat_log.append_text("[color=%s][b]%s:[/b] %s[/color]\n" % [col, sender, msg])

func _update_lobby_ui(data):
	room_code_label.text = "ROOM: " + data.get("code", "???")
	
	# Clear lists
	for c in radiant_grid.get_children(): c.queue_free()
	for c in dire_grid.get_children(): c.queue_free()
	
	var players = data.get("players", [])
	
	for p in players:
		var team = p.get("team", 1)
		var target_list = radiant_grid if team == 1 else dire_grid
		
		_create_player_card(target_list, p)
		
	start_button.visible = true 

func _create_player_card(parent, p_data):
	var card = PanelContainer.new()
	var bg_col = Color(0,0,0,0.2)
	if p_data.get("id") == NetworkManager.my_id:
		bg_col = Color(1, 1, 1, 0.1) # Highlight me
		
	card.add_theme_stylebox_override("panel", _create_style_box(bg_col, 8))
	parent.add_child(card)
	
	var hbox = HBoxContainer.new()
	card.add_child(hbox)
	
	# Icon
	var aid = p_data.get("avatar_id", "duck")
	var av = AvatarRendererScript.new()
	av.custom_minimum_size = Vector2(40, 40)
	av.set_skin(SkinRegistry.get_skin(aid), AnimalRendererScript.ViewMode.TOP_DOWN)
	hbox.add_child(av)
	
	# Name
	var lbl = Label.new()
	lbl.text = " " + p_data.get("name", "Unknown")
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.size_flags_horizontal = SIZE_EXPAND_FILL
	lbl.add_theme_color_override("font_color", COL_TEXT_WHITE)
	hbox.add_child(lbl)

# Particles
func _init_particles():
	for i in range(40):
		particles.append({
			"x": randf() * 1920, "y": randf() * 1080,
			"size": randf_range(2, 4), "speed": randf_range(5, 30)
		})

func _draw_particles(control: Control):
	for p in particles:
		control.draw_rect(Rect2(p.x, p.y, p.size, p.size), Color(1,1,1,0.05))
