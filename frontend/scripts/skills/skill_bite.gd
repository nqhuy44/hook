extends Node

var owner_player: Node

const MANA_COST = 0
const COOLDOWN = 1.5
const DAMAGE = 80
const RANGE = 30.0 # Very close 30px

var current_cd = 0.0

func _process(delta):
	if current_cd > 0:
		current_cd -= delta

func turn_condition() -> bool:
	return current_cd <= 0

func cast():
	# Strict Static Logic
	current_cd = COOLDOWN
	
	# Targeting
	var game = owner_player.get_parent()
	if not game or not "entities" in game: return
	
	var my_pos = owner_player.global_position
	var my_facing = Vector2.RIGHT.rotated(owner_player.rotation)
	
	var best_target = null
	var min_dist = RANGE
	
	# Using entities loop as unreliable strictly on groups yet
	for pid in game.entities:
		if pid == NetworkManager.my_id: continue
		var p = game.entities[pid]
		
		# 1. Distance Check
		var vec_to = p.global_position - my_pos
		var dist = vec_to.length()
		
		if dist <= RANGE:
			# 2. Facing Check (Dot Product)
			# Normalize vec_to
			var dir_to = vec_to.normalized()
			var dot = my_facing.dot(dir_to)
			
			# Dot > 0 means within 180 deg front. Dot > 0.5 means within 60 deg cone.
			if dot > 0.5:
				if dist < min_dist:
					min_dist = dist
					best_target = p
					
	if best_target:
		print("BITE HIT: ", best_target.name)
		# Spawn Visuals
		var vfx = game.get_node_or_null("VFXManager")
		if vfx:
			vfx.trigger_bite(best_target.global_position, randf() * TAU)
			vfx.spawn_damage_number(best_target.global_position, DAMAGE)
	else:
		print("BITE MISS")

func get_state():
	return {
		"cd": current_cd,
		"max_cd": COOLDOWN,
		"name": "Bite"
	}
