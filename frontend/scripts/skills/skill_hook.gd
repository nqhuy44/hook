extends Node

var owner_player: Node

const MANA_COST = 300
const COOLDOWN = 1.0 # Or handled by server? Assuming client side prediction for now.
const DAMAGE = 400

var current_cd = 0.0

func _process(delta):
	if current_cd > 0:
		current_cd -= delta

func turn_condition() -> bool:
	if current_cd > 0: return false
	# Check Mana via Player
	# if owner_player.mana < MANA_COST: return false
	return true

func cast():
	# Logic to spawn Hook Projectile
	# We rely on Game.gd or NetworkManager to actually spawn the authoritative projectile usually.
	# But for this refactor, let's assume we invoke a method on Player to spawn it or send input.
	print("Casting HOOK")
	
	# In a networked game, we send an Input Packet.
	# owner_player.send_skill_input("hook", get_global_mouse_position())
	
	# For local prediction/logic:
	current_cd = COOLDOWN
	# Invoke local spawn if needed, or wait for server.
	pass

# --- NEW: Wall Collision Handling ---
const WALL_LAYER_BIT = 2

func start_pull(victim: Node2D):
	if victim.has_method("set_collision_mask_value"):
		# Disable collision with Wall Layer (2) to pass through
		victim.set_collision_mask_value(WALL_LAYER_BIT, false)
		
func end_pull(victim: Node2D):
	if victim.has_method("set_collision_mask_value"):
		# Re-enable Wall Collision to trap them
		victim.set_collision_mask_value(WALL_LAYER_BIT, true)

func get_state():
	return {
		"cd": current_cd,
		"max_cd": COOLDOWN,
		"mana": MANA_COST,
		"name": "Hook"
	}
