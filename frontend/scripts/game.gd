extends Node2D

var entity_script = preload("res://scripts/entity.gd")
var projectile_script = preload("res://scripts/projectile.gd")
var hud_script = preload("res://scripts/hud.gd")

var entities = {} # id -> Node2D
var projectiles = [] # list of Node2D
var my_id = ""
var camera: Camera2D
var hud_node: CanvasLayer

var server_updates = []
const RENDER_DELAY = 100 # ms (matches JS)

func _ready():
	NetworkManager.packet_received.connect(_on_packet)
	
	# Setup Camera
	camera = Camera2D.new()
	add_child(camera)
	camera.make_current()
	
	# Setup HUD
	hud_node = CanvasLayer.new()
	hud_node.set_script(hud_script)
	add_child(hud_node)
	
	# Setup Background (Static)awd
	z_index = 0

func _draw():
	# Draw Map Borders / River (Static for now)
	var rx = 720
	draw_rect(Rect2(rx, 0, 160, 900), Color(0.01, 0.02, 0.04)) # River
	# River Borders
	draw_line(Vector2(rx, 0), Vector2(rx, 900), Color(0, 0.6, 1), 3.0)
	draw_line(Vector2(rx+160, 0), Vector2(rx+160, 900), Color(0, 0.6, 1), 3.0)
	# Map Border
	draw_rect(Rect2(0, 0, 1600, 900), Color(0.2, 0.4, 0.6), false, 10.0)

	# Draw Chains for projectiles
	for p_node in projectiles:
		if is_instance_valid(p_node) and entities.has(p_node.from_id):
			var owner_node = entities[p_node.from_id]
			draw_line(owner_node.position, p_node.position, Color(0.5, 0.5, 0.5), 4.0)

func _process(_delta):
	queue_redraw()
	_handle_interpolation()
	_update_camera()

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		var global_pos = get_global_mouse_position()
		var type = "move"
		if event.button_index == MOUSE_BUTTON_RIGHT:
			# Check logic for attack? For now just move
			type = "move"
			NetworkManager.send_input(type, {"x": global_pos.x, "y": global_pos.y, "targetID": ""})
		elif event.button_index == MOUSE_BUTTON_LEFT:
			# Shooting skill? Not implemented in click usually, unless targeting
			pass

	if event is InputEventKey and event.pressed:
		var k = event.as_text().to_lower()
		var idx = -1
		if k == "q": idx = 0
		elif k == "w": idx = 1
		elif k == "e": idx = 2
		elif k == "r": idx = 3
		
		if idx != -1:
			var global_pos = get_global_mouse_position()
			NetworkManager.send_input("skill", {"skillIdx": idx, "x": global_pos.x, "y": global_pos.y, "targetID": ""})

func _on_packet(type, payload):
	if type == "room_joined":
		my_id = payload.get("id")
	elif type == "game_update" or type == "game_state":
		var state = payload.get("state", payload)
		server_updates.push_back({ "state": state, "time": Time.get_ticks_msec() }) # Local time for diff
		if server_updates.size() > 5:
			server_updates.pop_front()
			
		# Update HUD immediate stuff
		if state.has("score"):
			hud_node.update_stats(state.get("time_remaining", 0), state.get("score", {}))
		if state.has("feed"):
			pass

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
				entities[id].queue_free()
				entities.erase(id)
			continue
			
		if not entities.has(id):
			var aid = data.get("avatar_id", "butcher")
			
			# Use the generic Player scene
			var scene_path = "res://scenes/heroes/player.tscn"
			var e = null
			if ResourceLoader.exists(scene_path):
				var scn = load(scene_path)
				e = scn.instantiate()
				
				# Apply Skin if it's a Player node
				if e.has_method("apply_skin"):
					var skin = SkinRegistry.get_skin(aid)
					if skin:
						e.apply_skin(skin)
						
				# Propagate data to the inner EntityLogic if it exists
				var logic = e.get_node_or_null("EntityLogic")
				if logic:
					logic.setup(data)
				else:
					# Fallback setup if script is on root (legacy)
					if e.has_method("setup"):
						e.setup(data)
			else:
				# Fallback
				e = Node2D.new()
				e.set_script(entity_script)
				e.setup(data)
			
			add_child(e)
			entities[id] = e
		
		# Position Update
		entities[id].position = Vector2(data["pos"]["x"], data["pos"]["y"])
		entities[id].rotation = data.get("rotation", 0)
		
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

func _update_camera():
	if my_id and entities.has(my_id):
		camera.position = entities[my_id].position
		camera.position.x = clamp(camera.position.x, 0, 1600)
		camera.position.y = clamp(camera.position.y, 0, 900)
