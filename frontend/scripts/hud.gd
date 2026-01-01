extends CanvasLayer

# UI References
var score_label_1: Label
var score_label_2: Label
var time_label: Label
var hp_bar: ProgressBar
var mana_bar: ProgressBar
var skill_slots = [] # Array of Dicts
var feed_container: VBoxContainer
var portrait_avatar: Control
var death_overlay: Control
var death_timer_lbl: Label

# Data State
var my_stats = {}
var current_avatar_id = ""

# Scripts
const AnimalRendererScript = preload("res://scripts/heroes/animal_renderer.gd")
const AvatarRendererScript = preload("res://scripts/ui/avatar_renderer.gd")
# const SkillIconScript = preload("res://scripts/ui/skill_icons.gd") # Lazy load instead to avoid parsing issues?

# Style Config
const COL_HP_BG = Color("#1E5631")
const COL_HP_FG = Color("#2ECC71") # Bright Green
const COL_MANA_BG = Color("#154360")
const COL_MANA_FG = Color("#3498DB") # Bright Blue
const COL_SKILL_BG = Color("#3B4252") # Slate
const COL_PANEL_DARK = Color("#2E3440")
const COL_TEXT_WHITE = Color("#FFFFFF")

func _ready():
	# 1. Main Control
	var root = Control.new()
	root.name = "MainControl"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	
	# 2. Top Scoreboard
	_build_death_screen()
	

	
	_build_scoreboard(root)
	
	# 3. Bottom Cluster (Portrait - Vitals - Skills)
	_build_bottom_cluster(root)
	
	# 4. Kill Feed
	_build_kill_feed(root)

func _build_death_screen():
	death_overlay = Control.new()
	death_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	death_overlay.visible = false
	death_overlay.z_index = 100 # On top of everything
	add_child(death_overlay)
	
	# Grey Overlay
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.4) # Semi-transparent grey
	death_overlay.add_child(bg)
	
	# Center Info
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	death_overlay.add_child(center)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	center.add_child(vbox)
	
	var lbl = Label.new()
	lbl.text = "YOU DIED"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_text_style(lbl, 64, Color("#BF616A"), true) # Red
	vbox.add_child(lbl)
	
	var sub = Label.new()
	sub.text = "Respawning in..."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_text_style(sub, 24, Color.WHITE, true)
	vbox.add_child(sub)
	
	death_timer_lbl = Label.new()
	death_timer_lbl.text = "10"
	death_timer_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_text_style(death_timer_lbl, 48, Color.WHITE, true)
	vbox.add_child(death_timer_lbl)

func show_death_screen(time: float):
	death_overlay.visible = true
	death_timer_lbl.text = str(int(time))
	var t = create_tween()
	t.tween_method(func(val): death_timer_lbl.text = str(int(val)), time, 0.0, time)

func hide_death_screen():
	death_overlay.visible = false

# ==============================================================================
# UI BUILDERS
# ==============================================================================

func _build_scoreboard(parent):
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	panel.offset_left = 300 # Centering logic usually via HBox or Anchors
	panel.offset_right = -300
	# Better: Anchor Top Center
	panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.position.y = 20 # Margin top
	panel.custom_minimum_size = Vector2(400, 60)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var style = StyleBoxFlat.new()
	style.bg_color = COL_PANEL_DARK
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.corner_radius_bottom_right = 20
	style.corner_radius_bottom_left = 20
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 30)
	panel.add_child(hbox)
	
	# Radiant Score
	score_label_1 = Label.new()
	score_label_1.text = "0"
	_apply_text_style(score_label_1, 32, Color("#A3BE8C"))
	hbox.add_child(score_label_1)
	
	# Timer
	time_label = Label.new()
	time_label.text = "00:00"
	_apply_text_style(time_label, 24, Color.WHITE)
	hbox.add_child(time_label)
	
	# Dire Score
	score_label_2 = Label.new()
	score_label_2.text = "0"
	_apply_text_style(score_label_2, 32, Color("#BF616A"))
	hbox.add_child(score_label_2)

func _build_bottom_cluster(parent):
	# Container for the cluster anchored Bottom Center
	var container = HBoxContainer.new()
	container.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	container.grow_vertical = Control.GROW_DIRECTION_BEGIN # Grow Up
	container.grow_horizontal = Control.GROW_DIRECTION_BOTH
	container.position.y -= 20 # Margin Bottom
	container.add_theme_constant_override("separation", 10) # Tight packing
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(container)
	
	# A. PORTRAIT (Left)
	var portrait_wrap = Control.new()
	portrait_wrap.custom_minimum_size = Vector2(110, 110)
	portrait_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(portrait_wrap)
	
	var mask = Panel.new()
	mask.set_anchors_preset(Control.PRESET_FULL_RECT)
	mask.clip_children = Control.CLIP_CHILDREN_ONLY
	var s_circ = StyleBoxFlat.new()
	s_circ.set_corner_radius_all(55)
	s_circ.bg_color = Color.WHITE
	mask.add_theme_stylebox_override("panel", s_circ)
	portrait_wrap.add_child(mask)
	
	portrait_avatar = AvatarRendererScript.new()
	portrait_avatar.set_anchors_preset(Control.PRESET_FULL_RECT)
	mask.add_child(portrait_avatar)
	
	# B. VITALS (Center)
	var vitals_vbox = VBoxContainer.new()
	vitals_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vitals_vbox.custom_minimum_size.x = 300
	vitals_vbox.add_theme_constant_override("separation", 5)
	container.add_child(vitals_vbox)
	
	# Health
	hp_bar = ProgressBar.new()
	hp_bar.custom_minimum_size.y = 40
	hp_bar.show_percentage = false
	hp_bar.add_theme_stylebox_override("background", _create_bar_style(COL_HP_BG))
	hp_bar.add_theme_stylebox_override("fill", _create_bar_style(COL_HP_FG))
	vitals_vbox.add_child(hp_bar)
	
	var hp_lbl = Label.new()
	hp_lbl.name = "Label"
	hp_lbl.text = "0 / 0"
	hp_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_apply_text_style(hp_lbl, 16, Color.WHITE)
	hp_bar.add_child(hp_lbl)
	
	# Mana
	mana_bar = ProgressBar.new()
	mana_bar.custom_minimum_size.y = 20
	mana_bar.show_percentage = false
	mana_bar.add_theme_stylebox_override("background", _create_bar_style(COL_MANA_BG))
	mana_bar.add_theme_stylebox_override("fill", _create_bar_style(COL_MANA_FG))
	vitals_vbox.add_child(mana_bar)
	
	# C. SKILLS (Right)
	var skills_hbox = HBoxContainer.new()
	skills_hbox.add_theme_constant_override("separation", 20)
	container.add_child(skills_hbox)
	
	var skill_definitions = [
		{"key": "Q", "icon": "hook", "name": "HOOK"},
		{"key": "W", "icon": "rot", "name": "ROT"}
	]
	
	for i in range(2):
		var def = skill_definitions[i]
		
	for i in range(2):
		var def = skill_definitions[i]
		
		# 1. ROOT PANEL (Background, Border, Clipping)
		var panel = PanelContainer.new()
		panel.custom_minimum_size = Vector2(110, 110)
		# panel.clip_children = Control.CLIP_CHILDREN_AND_DRAW # Ensure content is clipped to rounded corners
		# Note: CLIP_CHILDREN_ONLY hides the parent panel background, so use AND_DRAW or handle BG inside.
		# Godot 4: CLIP_CHILDREN_ONLY means parent is mask. 
		# If we want the BG visible + mask, we might need a separate mask node or accept square corners for now if stylebox radius works.
		# Let's rely on Stylebox for visual, and just overlay properly.
		
		var s_panel = StyleBoxFlat.new()
		s_panel.bg_color = Color("#0f172a") # Deep Indigo
		s_panel.border_width_left = 4
		s_panel.border_width_top = 4
		s_panel.border_width_right = 4
		s_panel.border_width_bottom = 4
		s_panel.border_color = Color("#22d3ee") # Cyan
		s_panel.set_corner_radius_all(16)
		panel.add_theme_stylebox_override("panel", s_panel)
		skills_hbox.add_child(panel)
		
		# 2. LAYERS CONTROL (Inside PanelMargins)
		# Panel adds border padding automatically, so we might need a margin container 
		# OR just add Control as child which fills available space (inside border).
		var layers = Control.new()
		layers.set_anchors_preset(Control.PRESET_FULL_RECT)
		layers.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(layers)
		
		# LAYER A: ICON (Bottom)
		var icon_ctrl = load("res://scripts/ui/skill_icons.gd").new()
		icon_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
		# Add small margin to not touch border
		icon_ctrl.offset_left = 6
		icon_ctrl.offset_top = 6
		icon_ctrl.offset_right = -6
		icon_ctrl.offset_bottom = -6
		icon_ctrl.set_icon(def["icon"])
		layers.add_child(icon_ctrl)
		
		# LAYER B: COOLDOWN OVERLAY (Middle)
		var cd_overlay = TextureProgressBar.new()
		cd_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		# Match icon margin
		cd_overlay.offset_left = 6
		cd_overlay.offset_top = 6
		cd_overlay.offset_right = -6
		cd_overlay.offset_bottom = -6
		
		cd_overlay.fill_mode = TextureProgressBar.FILL_COUNTER_CLOCKWISE
		cd_overlay.tint_progress = Color(0, 0, 0, 0.85) # Dark dim
		
		# Create solid white texture for the progress fill
		var g = GradientTexture2D.new()
		g.width = 100
		g.height = 100
		g.fill = GradientTexture2D.FILL_SQUARE
		g.gradient = Gradient.new()
		g.gradient.set_color(0, Color.WHITE)
		g.gradient.set_color(1, Color.WHITE)
		cd_overlay.texture_progress = g
		layers.add_child(cd_overlay)
		
		# LAYER C: LABELS (Top)
		# C1. Hotkey
		var hk = Label.new()
		hk.text = def["key"]
		hk.position = Vector2(10, 6)
		_apply_text_style(hk, 18, Color("#22d3ee"), true)
		layers.add_child(hk)
		
		# C2. Name
		var nm = Label.new()
		nm.text = def["name"]
		nm.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nm.position.y = -8
		# Manually apply style for outlined big text
		var nm_set = LabelSettings.new()
		nm_set.font_size = 14
		nm_set.font_color = Color.WHITE
		nm_set.outline_size = 4
		nm_set.outline_color = Color.BLACK
		nm.label_settings = nm_set
		layers.add_child(nm)
		
		# C3. Timer
		var cd_lbl = Label.new()
		cd_lbl.set_anchors_preset(Control.PRESET_CENTER)
		_apply_text_style(cd_lbl, 28, Color("#f97316"), true)
		layers.add_child(cd_lbl)
		
		skill_slots.append({
			"node": panel, 
			"style": s_panel,
			"icon": icon_ctrl,
			"cd_lbl": cd_lbl,
			"cd_bar": cd_overlay,
			"key": def["key"]
		})

# API for Toggle State
func update_rot_state(active: bool):
	if skill_slots.size() < 2: return
	var slot = skill_slots[1] # W is index 1
	var style = slot["style"]
	var icon = slot["icon"]
	
	if active:
		# Glow Toxic Green or Orange
		style.border_color = Color("#a3e635") # Toxic Green
		style.bg_color = Color("#0f172a").lerp(Color("#a3e635"), 0.1)
		icon.modulate = Color("#a3e635")
	else:
		# Reset
		style.border_color = Color("#22d3ee") # Cyan
		style.bg_color = Color("#0f172a") # Deep Indigo
		icon.modulate = Color(1, 1, 1, 1)

func update_player_status(data):
	update_health(data.get("hp", 100), data.get("max_hp", 100))
	update_mana(data.get("mana", 100), data.get("max_mana", 100))
	
	var aid = data.get("avatar_id", "")
	if aid != "" and aid != current_avatar_id:
		current_avatar_id = aid
		portrait_avatar.set_skin(SkinRegistry.get_skin(aid), AnimalRendererScript.ViewMode.PORTRAIT)

	# Handle Cooldowns (Q=0, W=1)
	var skills = data.get("skills", [])
	# Limit to how many slots we actually have valid in HUD
	var limit = min(skills.size(), skill_slots.size())
	
	for i in range(limit):
		if i == 1: continue # Skip Rot Timer (Stateless visuals controlled by toggle)
		
		var s_data = skills[i]
		var cd = 0.0
		var max_cd = 1.0
		if typeof(s_data) == TYPE_DICTIONARY:
			cd = float(s_data.get("cooldown", 0))
			max_cd = float(s_data.get("max_cd", 1.0))
			
		var lbl = skill_slots[i]["cd_lbl"]
		var bar = skill_slots[i]["cd_bar"]
		
		if cd > 0:
			lbl.text = "%.1f" % cd
			bar.max_value = max_cd
			bar.value = cd
			bar.visible = true
		else:
			lbl.text = ""
			bar.value = 0
			bar.visible = false
			
	# Rot State (W) usually sent via boolean in skills or separate flag
	# Assuming 'skills[1].active' exists
	if skills.size() > 1 and typeof(skills[1]) == TYPE_DICTIONARY:
		update_rot_state(skills[1].get("active", false))

func _build_kill_feed(parent):
	var mc = MarginContainer.new()
	# ANCHOR TOP RIGHT
	mc.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	mc.add_theme_constant_override("margin_top", 80) # Below Scoreboard
	mc.add_theme_constant_override("margin_right", 20)
	mc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(mc)
	
	feed_container = VBoxContainer.new()
	feed_container.custom_minimum_size = Vector2(300, 200) # Valid Size
	feed_container.alignment = BoxContainer.ALIGNMENT_BEGIN
	feed_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mc.add_child(feed_container)
	
	# DEBUG: Instant messages to verify visibility
	add_feed_item("Waiting for kills...")

# ==============================================================================
# HELPERS
# ==============================================================================

func _apply_text_style(lbl, size, col, outline: bool = false):
	var settings = LabelSettings.new()
	settings.font_size = size
	settings.font_color = col
	if outline:
		settings.outline_size = 6
		settings.outline_color = Color.BLACK
	else:
		settings.outline_size = 0
	lbl.label_settings = settings

func _create_bar_style(col):
	var s = StyleBoxFlat.new()
	s.bg_color = col
	s.set_corner_radius_all(8)
	return s

# ==============================================================================
# API
# ==============================================================================

func update_score(team_a, team_b):
	score_label_1.text = str(team_a)
	score_label_2.text = str(team_b)

func add_kill_log(killer, victim):
	var pc = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.5)
	style.set_corner_radius_all(8)
	pc.add_theme_stylebox_override("panel", style)
	
	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left", 10)
	m.add_theme_constant_override("margin_right", 10)
	m.add_theme_constant_override("margin_top", 5)
	m.add_theme_constant_override("margin_bottom", 5)
	pc.add_child(m)
	
	var lbl = RichTextLabel.new()
	lbl.bbcode_enabled = true
	lbl.text = "[b]%s[/b] killed [b]%s[/b]" % [killer, victim]
	lbl.fit_content = true
	lbl.scroll_active = false
	m.add_child(lbl)
	
	feed_container.add_child(pc)
	
	# Fade out
	var t = create_tween()
	t.tween_interval(4.0)
	t.tween_property(pc, "modulate:a", 0.0, 1.0)
	t.tween_callback(pc.queue_free)

# Compatibility for Game.gd
func add_feed_item(text):
	# Parse text if it's "A killed B" or just display it
	# For now just display raw text in a new log
	var pc = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.5)
	style.set_corner_radius_all(8)
	pc.add_theme_stylebox_override("panel", style)
	
	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left", 10)
	pc.add_child(m)
	
	var lbl = RichTextLabel.new()
	lbl.bbcode_enabled = true
	lbl.text = text
	lbl.fit_content = true
	lbl.scroll_active = false
	m.add_child(lbl)
	
	feed_container.add_child(pc)
	var t = create_tween()
	t.tween_interval(4.0)
	t.tween_property(pc, "modulate:a", 0.0, 1.0)
	t.tween_callback(pc.queue_free)

func update_health(cur, max_val):
	hp_bar.value = cur
	hp_bar.max_value = max_val
	hp_bar.get_node("Label").text = "%d / %d" % [int(cur), int(max_val)]

func update_mana(cur, max_val):
	mana_bar.value = cur
	mana_bar.max_value = max_val

func update_stats(time, scores):
	# Legacy compat
	var t = int(time)
	time_label.text = "%02d:%02d" % [floor(t/60), t%60]
	# Server sends "1" (Radiant) and "2" (Dire)
	update_score(int(scores.get("1", 0)), int(scores.get("2", 0)))
