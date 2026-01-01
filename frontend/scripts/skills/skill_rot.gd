extends Node

var owner_player: Node

const MANA_COST = 0
const COOLDOWN = 0.5 # Toggle cooldown
const DAMAGE_TICK = 0.5
const DMG_ENEMY = 120
const DMG_SELF = 70
const RADIUS = 50 # Strictly 50

var is_active = false
var current_cd = 0.0
var tick_timer = 0.0

func _process(delta):
	if current_cd > 0:
		current_cd -= delta
		
	if is_active:
		tick_timer += delta
		if tick_timer >= DAMAGE_TICK:
			tick_timer = 0.0
			_perform_tick()

func turn_condition() -> bool:
	if current_cd > 0: return false
	return true

func cast():
	# Toggle
	is_active = !is_active
	current_cd = COOLDOWN
	
	print("Rot Toggled: ", is_active)
	
	# Update Visuals via Node
	if owner_player and owner_player.has_node("RotVisual"):
		owner_player.get_node("RotVisual").toggle(is_active)
	
	# Send input to server (if networked)
	# owner_player.send_skill_input("rot_toggle", is_active)

func _perform_tick():
	# Local Logic / Prediction
	var game = owner_player.get_parent()
	if not game or not "entities" in game: return
	
	# Self Damage Indication
	var vfx = game.get_node_or_null("VFXManager")
	var my_pos = owner_player.global_position
	
	if vfx:
		vfx.spawn_damage_number(my_pos + Vector2(randf_range(-10,10), -40), DMG_SELF, Color.RED)
	
	# Enemy Damage
	for pid in game.entities:
		if pid == NetworkManager.my_id: continue
		var p = game.entities[pid]
		if my_pos.distance_to(p.global_position) <= RADIUS:
			if vfx:
				vfx.spawn_damage_number(p.global_position, DMG_ENEMY, Color("#A3BE8C"))

func get_state():
	return {
		"cd": current_cd,
		"max_cd": COOLDOWN,
		"active": is_active,
		"name": "Rot"
	}
