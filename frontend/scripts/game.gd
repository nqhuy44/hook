extends Node2D

var entity_script = preload("res://scripts/entity.gd")
var projectile_script = preload("res://scripts/projectile.gd")
# var hud_script = preload("res://scripts/hud.gd") # Potential cycle/fail point

var entities = {} # id -> Node2D
var projectiles = [] # list of Node2D
var my_id = ""
var camera: Camera2D
var hud_node: CanvasLayer

var server_updates = []
const RENDER_DELAY = 100 # ms (matches JS)

func _ready():
	NetworkManager.packet_received.connect(_on_packet)
	my_id = NetworkManager.my_id
	print("Game Started. My ID: ", my_id)
	
	# Setup Camera
	camera = Camera2D.new()
	camera.zoom = Vector2(1.4, 1.4) 
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 10.0
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	# Set Limits instead of manual clamp
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = 1600
	camera.limit_bottom = 900
	add_child(camera)
	camera.make_current()
	
	# Setup HUD (Lazy Load)
	var hud_script = load("res://scripts/hud.gd")
	if hud_script:
		hud_node = CanvasLayer.new()
		hud_node.set_script(hud_script)
		add_child(hud_node)
	else:
		printerr("FAILED TO LOAD HUD SCRIPT")
	
	# Setup Background (Static)
	z_index = 0

func _draw():
	# ==========================================================================
	# 1. FLAT FLOOR (Pastel Green / Beige)
	# ==========================================================================
	var map_rect = Rect2(0, 0, 1600, 900)
	var col_floor = Color("#A8D5BA") # Soft Pastel Green
	var col_grid = Color(1, 1, 1, 0.3)
	
	# Fill
	draw_rect(map_rect, col_floor)
	
	# Grid Lines
	var step = 100
	for x in range(0, 1601, step):
		draw_line(Vector2(x, 0), Vector2(x, 900), col_grid, 2.0)
	for y in range(0, 901, step):
		draw_line(Vector2(0, y), Vector2(1600, y), col_grid, 2.0)
		
	# Random Decor (Grass / Pebbles)
	# Use deterministic hash based on grid cells
	var decor_count = 50
	var seed_val = 12345
	for i in range(decor_count):
		var dx = (hash(seed_val + i) % 1600)
		var dy = (hash(seed_val + i * 2) % 900)
		
		# River Check (Don't draw in river)
		if dx > 720 and dx < 720+160: continue
		
		var type = hash(i) % 2
		if type == 0:
			# Grass Tuft (3 short lines)
			var g_pos = Vector2(dx, dy)
			var g_col = Color(0.1, 0.4, 0.1, 0.4)
			draw_line(g_pos, g_pos + Vector2(-3, -5), g_col, 2.0)
			draw_line(g_pos, g_pos + Vector2(0, -6), g_col, 2.0)
			draw_line(g_pos, g_pos + Vector2(3, -5), g_col, 2.0)
		else:
			# Pebble
			draw_circle(Vector2(dx, dy), 4, Color(0.5, 0.5, 0.5, 0.5))

	# ==========================================================================
	# 2. THE RIVER (Death Zone - Flat Blue)
	# ==========================================================================
	var rx = 720.0
	var rw = 160.0
	var river_rect = Rect2(rx, 0, rw, 900)
	var col_river = Color("#5DADE2") # Flat Deep Blue
	
	draw_rect(river_rect, col_river)
	
	# Flowing Waves
	var time = Time.get_ticks_msec() / 1000.0
	for i in range(8):
		var wave_y = (int(time * 50 + i * 120) % 900)
		var wave_center = Vector2(rx + rw/2, wave_y)
		_draw_wave(wave_center, 40, Color(1, 1, 1, 0.3))
		
	# Dashed Borders
	_draw_dashed_line(Vector2(rx, 0), Vector2(rx, 900), Color.WHITE, 4.0)
	_draw_dashed_line(Vector2(rx+rw, 0), Vector2(rx+rw, 900), Color.WHITE, 4.0)
	
	# ==========================================================================
	# 3. VECTOR FENCE (Walls)
	# ==========================================================================
	var wall_col = Color("#2c3e50") # Dark vector color
	var barrier_col = Color(1, 1, 1, 0.1)
	
	# Pillars
	for x in range(0, 1601, 200):
		draw_circle(Vector2(x, 0), 10, wall_col)
		draw_circle(Vector2(x, 900), 10, wall_col)
		# Connect with barrier
		if x < 1600:
			draw_rect(Rect2(x, -5, 200, 10), barrier_col)
			draw_rect(Rect2(x, 895, 200, 10), barrier_col)
			
	for y in range(0, 901, 200):
		draw_circle(Vector2(0, y), 10, wall_col)
		draw_circle(Vector2(1600, y), 10, wall_col)
		if y < 900:
			draw_rect(Rect2(-5, y, 10, 200), barrier_col)
			draw_rect(Rect2(1595, y, 10, 200), barrier_col)

	# Draw Chains for projectiles
	for p_node in projectiles:
		if is_instance_valid(p_node) and entities.has(p_node.from_id):
			var owner_node = entities[p_node.from_id]
			draw_line(owner_node.position, p_node.position, Color("#bdc3c7"), 3.0)

var last_input_time = 0
const INPUT_RATE = 50 # ms
var is_moving = false
var local_feed_count = 0
var last_feed_msg = ""

func _process(_delta):
	queue_redraw()
	_handle_interpolation()
	# Camera is now parented to player, no manual update needed
	_handle_input_loop()

func _handle_input_loop():
	var now = Time.get_ticks_msec()
	if now - last_input_time < INPUT_RATE:
		return
		
	# Stop Command
	if Input.is_physical_key_pressed(KEY_S):
		# Explicit Stop
		NetworkManager.send_input("stop", {})
		last_input_time = now
		return # Stop processing movement

	# Keyboard Movement
	var input_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if input_vector != Vector2.ZERO:
		is_moving = true
		# Calculate a target point in the direction of input relative to our character
		if my_id and entities.has(my_id):
			var my_pos = entities[my_id].position
			var target = my_pos + (input_vector.normalized() * 200) # Aim ahead
			
			# Instant visual rotation for responsiveness (Snapped to 16-way)
			entities[my_id].rotation = snapped(input_vector.angle(), PI / 8.0)
			
			NetworkManager.send_input("move", {
				"x": target.x, 
				"y": target.y, 
				"targetID": ""
			})
			last_input_time = now
	elif is_moving:
		# Stopped moving just now
		is_moving = false
		NetworkManager.send_input("stop", {})
		last_input_time = now

func _input(event):
	# Skill Input (QWER)
	if event is InputEventKey and event.pressed:
		var k = event.as_text().to_lower()
		var idx = -1
		if k == "q": idx = 0
		elif k == "w": idx = 1
		elif k == "e": idx = 2
		elif k == "r": idx = 3
		
		if idx != -1:
			# Use facing direction for skill instead of mouse
			if my_id and entities.has(my_id):
				var p = entities[my_id]
				# Calculate target point based on current rotation
				var direction = Vector2.RIGHT.rotated(p.rotation)
				var target = p.position + (direction * 400) # Range of hook?
				
				NetworkManager.send_input("skill", {"skillIdx": idx, "x": target.x, "y": target.y, "targetID": ""})

func _on_packet(type, payload):
	if type == "room_joined":
		# Usually handled in lobby, but if we reconnect mid-game?
		my_id = payload.get("id")
		NetworkManager.my_id = my_id
	elif type == "game_over":
		var winner = payload.get("winner", "DRAW")
		print("GAME OVER! Winner: ", winner)
		
		var go_script = load("res://scripts/ui/game_over_screen.gd")
		if go_script:
			var screen = go_script.new()
			# Add to HUD node (Layer 100 usually) or Main Canvas
			if hud_node:
				hud_node.add_child(screen)
			else:
				add_child(screen)
			screen.setup(winner)
			
	elif type == "game_update" or type == "game_state":
		var state = payload.get("state", payload)
		server_updates.push_back({ "state": state, "time": Time.get_ticks_msec() }) # Local time for diff
		if server_updates.size() > 5:
			server_updates.pop_front()
			
		# Update HUD immediate stuff
		if state.has("score"):
			hud_node.update_stats(state.get("time_remaining", 0), state.get("score", {}))
			
		# Update Local Player HUD
		if my_id and state.get("entities", {}).has(my_id):
			hud_node.update_player_status(state["entities"][my_id])
		
		# Update Feed
		var feed = state.get("feed", [])
		if feed.size() > 0:
			print("Packet Feed Data: ", feed) # DEBUG
			var last_msg = feed[-1]
			# Store the last processed message string to dedupe
			if last_msg != last_feed_msg:
				# Find where our last known matches
				var start_idx = 0
				for i in range(feed.size() - 1, -1, -1):
					if feed[i] == last_feed_msg:
						start_idx = i + 1
						break
				
				# Add everything from start_idx
				for i in range(start_idx, feed.size()):
					hud_node.add_feed_item(feed[i])
					
				last_feed_msg = last_msg
				
func _handle_interpolation():
	var now = Time.get_ticks_msec()
	var render_time = now - RENDER_DELAY
	
	# Find two frames
	var u1 = null
	var u2 = null
	for i in range(server_updates.size() - 1):
		if server_updates[i].time <= render_time and server_updates[i+1].time >= render_time:
			u1 = server_updates[i]
			u2 = server_updates[i+1]
			break
	
	var target_state = null
	if u1 and u2:
		var total = float(u2.time - u1.time)
		var elapsed = float(render_time - u1.time)
		var t = elapsed / total
		target_state = _interpolate_state(u1.state, u2.state, t)
	elif server_updates.size() > 0:
		target_state = server_updates[-1].state
	
	if target_state:
		_apply_state(target_state)

func _interpolate_state(s1, s2, t):
	var res = s2.duplicate(true)
	var e1 = s1.get("entities", {})
	var e2 = s2.get("entities", {})
	
	var res_ents = res.get("entities", {})
	
	for id in e2:
		if e1.has(id):
			var p1 = e1[id].get("pos")
			var p2 = e2[id].get("pos")
			var rot1 = e1[id].get("rotation", 0)
			var rot2 = e2[id].get("rotation", 0)
			
			res_ents[id]["pos"]["x"] = lerp(p1.x, p2.x, t)
			res_ents[id]["pos"]["y"] = lerp(p1.y, p2.y, t)
			res_ents[id]["rotation"] = lerp_angle(rot1, rot2, t)
	return res

func _apply_state(state):
	var state_ents = state.get("entities", {})
	
	# 1. Update/Create Entities
	for id in state_ents:
		var data = state_ents[id]
		if data.get("dead"):
			if entities.has(id):
				# CRITICAL FIX: If local player dies, save the camera!
				if id == my_id:
					var p_node = entities[id]
					if camera.get_parent() == p_node:
						camera.reparent(self) # Attach back to Game Root
						
					# Notify HUD
					if hud_node:
						hud_node.show_death_screen(10.0) # Approx respawn time or from data
				
				entities[id].queue_free()
				entities.erase(id)
			continue
			
		if not entities.has(id):
			# Respawn Logic happens here automatically
			# If it's me, hide death screen
			if id == my_id:
				if hud_node:
					hud_node.hide_death_screen()
			var aid = data.get("avatar_id", "butcher")
			
			# Use the generic Player scene
			var scene_path = "res://scenes/heroes/player.tscn"
			var e = null
			var is_scene = false
			
			if ResourceLoader.exists(scene_path):
				var scn = load(scene_path)
				e = scn.instantiate()
				is_scene = true
			else:
				# Fallback
				e = Node2D.new()
				e.set_script(entity_script)
			
			# Add to tree FIRST so @onready works
			add_child(e)
			entities[id] = e
			
			# REPARENT CAMERA if this is me
			if id == my_id:
				if camera.get_parent() != e:
					camera.reparent(e)
					camera.position = Vector2.ZERO # Local to player
			
			if is_scene:
				# Apply Skin if it's a Player node
				if e.has_method("apply_skin"):
					var skin = SkinRegistry.get_skin(aid)
					if skin:
						e.apply_skin(skin)
						
				# Propagate data to the inner EntityLogic if it exists
				var logic_node = e.get_node_or_null("EntityLogic")
				if logic_node:
					logic_node.setup(data)
				else:
					if e.has_method("setup"):
						e.setup(data)
			else:
				e.setup(data)
		
		# Position Update
		entities[id].position = Vector2(data["pos"]["x"], data["pos"]["y"])
		entities[id].rotation = snapped(data.get("rotation", 0), PI / 8.0)
		
		# State Update
		var logic = entities[id].get_node_or_null("EntityLogic")
		if logic:
			logic.update_state(data)
		elif entities[id].has_method("update_state"):
			entities[id].update_state(data)
			
	# 2. Remove Missing
	for id in entities.keys():
		if not state_ents.has(id):
			entities[id].queue_free()
			entities.erase(id)
			
	# 3. Projectiles
	# Clear old
	for p in projectiles:
		p.queue_free()
	projectiles.clear()
	
	var projs_data = state.get("projectiles", [])
	if projs_data:
		for p_data in projs_data:
			var p = Node2D.new()
			p.set_script(projectile_script)
			p.position = Vector2(p_data["pos"]["x"], p_data["pos"]["y"])
			p.rotation = p_data.get("rotation", 0)
			p.from_id = p_data.get("from_id", "")
			add_child(p)
			projectiles.append(p)

# Camera updated via reparenting
# func _update_camera(): removed

# ==============================================================================
# DRAW HELPERS
# ==============================================================================

func _draw_wave(center, width, col):
	# Simple Sin wave segment
	var pts = PackedVector2Array()
	var step = 5
	for i in range(-width/2, width/2 + 1, step):
		var x = i
		var y = sin(i * 0.2) * 5.0
		pts.append(center + Vector2(x, y))
	draw_polyline(pts, col, 2.0)

func _draw_dashed_line(from, to, col, width):
	var dist = from.distance_to(to)
	var dash_len = 20.0
	var gap_len = 10.0
	var current_dist = 0.0
	var dir = (to - from).normalized()
	
	while current_dist < dist:
		var end_dist = min(current_dist + dash_len, dist)
		var p1 = from + dir * current_dist
		var p2 = from + dir * end_dist
		draw_line(p1, p2, col, width)
		current_dist += dash_len + gap_len
