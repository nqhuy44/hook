extends Node2D

# Effect Containers
var rot_particles = [] # {pos, size, life, max_life, col}
var bite_effects = [] # {pos, life, angle}
var impacts = [] # {pos, life, max_life, color}
var popups = [] # {pos, text, life, color, vel}

# Config
const ROT_BUBBLE_RATE = 0.1 # Spawn rate
var rot_timer = 0.0

func _process(delta):
	_update_rot(delta)
	_update_bite(delta)
	_update_impacts(delta)
	_update_popups(delta)
	queue_redraw()

func _draw():
	# 1. Rot Bubbles (Legacy/Global manager style)
	# If we use RotAura.gd locally on player, we might not need this here.
	# But checking `_update_rot`, it spawns into `rot_particles`.
	# We'll keep it for now as a global manager fallback or ensure Player uses RotAura node.
	# Plan said "RotAura.gd (New)... Update VFX Manager".
	# If Players use RotAura.gd, this global logic is redundant but harmless if empty.
	for p in rot_particles:
		var alpha = p.life / p.max_life
		var col = p.col
		col.a = alpha
		draw_circle(p.pos, p.size * (1.0 - alpha * 0.2), col)
		draw_circle(p.pos + Vector2(-p.size*0.3, -p.size*0.3), p.size*0.3, Color(1,1,1, alpha * 0.5))

	# 2. Bite Effects (Spiky Star)
	for b in bite_effects:
		_draw_bite(b)
		
	# 3. Impacts (Hook Pop)
	for i in impacts:
		var progress = 1.0 - (i.life / i.max_life)
		var radius = 10.0 + progress * 50.0
		var alpha = i.life / i.max_life
		var col = i.color
		col.a = alpha
		draw_arc(i.pos, radius, 0, TAU, 32, col, 4.0 * alpha)

	# 4. Popups
	for p in popups:
		var alpha = min(p.life, 1.0)
		var col = p.color
		col.a = alpha
		var font_size = 24
		draw_string(ThemeDB.fallback_font, p.pos, p.text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, col)
		draw_string_outline(ThemeDB.fallback_font, p.pos, p.text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, 4, Color(0,0,0, alpha))

# ... (Updates)
func _update_impacts(delta):
	for i in range(impacts.size() - 1, -1, -1):
		var imp = impacts[i]
		imp.life -= delta
		if imp.life <= 0:
			impacts.remove_at(i)

# ... (Spawners)
func spawn_hook_impact(pos):
	impacts.append({
		"pos": pos,
		"life": 0.3,
		"max_life": 0.3,
		"color": Color.WHITE
	})

# ... (Draw Helpers)
func _draw_bite(b):
	# Spiky Star "Pop"
	var progress = 1.0 - (b.life / 0.3)
	# Elastic scale: Overshoot slightly?
	var scale = sin(progress * PI) # 0 -> 1 -> 0
	if scale < 0: scale = 0
	
	draw_set_transform(b.pos, b.angle, Vector2(scale, scale))
	
	var col = Color.WHITE
	var radius = 40.0
	var points = PackedVector2Array()
	var spikes = 8
	for i in range(spikes * 2):
		var angle = i * PI / spikes
		var r = radius if i % 2 == 0 else radius * 0.4
		points.append(Vector2(cos(angle) * r, sin(angle) * r))
	
	draw_colored_polygon(points, Color("#E74C3C")) # Red Impact
	draw_polyline(points, Color.WHITE, 2.0)
	
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

# ==============================================================================
# UPDATES
# ==============================================================================
func _update_rot(delta):
	# Spawn new bubbles for active players
	# We need access to players. A Hack is to pass list or iterate parent
	var game = get_parent()
	if game and "entities" in game:
		rot_timer -= delta
		if rot_timer <= 0:
			rot_timer = ROT_BUBBLE_RATE
			for pid in game.entities:
				var p = game.entities[pid]
				if p.has_method("set_rot_active") and p.rot_active: # Check flag
					spawn_rot_bubble(p.position)
	
	# Update existing
	for i in range(rot_particles.size() - 1, -1, -1):
		var p = rot_particles[i]
		p.life -= delta
		p.pos.y -= 20 * delta # Float up
		if p.life <= 0:
			rot_particles.remove_at(i)

func _update_bite(delta):
	for i in range(bite_effects.size() - 1, -1, -1):
		var b = bite_effects[i]
		b.life -= delta
		if b.life <= 0:
			bite_effects.remove_at(i)

func _update_popups(delta):
	for i in range(popups.size() - 1, -1, -1):
		var p = popups[i]
		p.life -= delta
		p.pos += p.vel * delta
		p.vel.y += 100 * delta # Gravity
		if p.life <= 0:
			popups.remove_at(i)

# ==============================================================================
# SPAWNERS
# ==============================================================================
func spawn_rot_bubble(pos):
	var offset = Vector2(randf_range(-30, 30), randf_range(-30, 30))
	var col = Color("#2ECC71") if randf() > 0.5 else Color("#F1C40F")
	rot_particles.append({
		"pos": pos + offset,
		"size": randf_range(5, 12),
		"life": 0.8,
		"max_life": 0.8,
		"col": col
	})

func trigger_bite(pos, angle):
	bite_effects.append({
		"pos": pos,
		"angle": angle,
		"life": 0.3
	})

func spawn_damage_number(pos, amount, is_heal=false):
	var col = Color("#E74C3C")
	var text = str(amount)
	if is_heal:
		col = Color("#2ECC71")
		text = "+" + str(amount)
		
	popups.append({
		"pos": pos,
		"text": text,
		"life": 1.0,
		"color": col,
		"vel": Vector2(randf_range(-20, 20), -100) # Jump up
	})

# ==============================================================================
# DRAW HELPERS
# ==============================================================================
# _draw_bite is now handled above in the replaced chunk.
# Wait, the previous tool call replaced the header and _process/_draw, but defined _draw_bite inside the string.
# However, the OLD _draw_bite is at the bottom of the file (lines 122-151).
# I need to remove that old definition to avoid duplication or confusion if I pasted it in the main block.
# Actually, I pasted usage in _draw, but I didn't paste the DEFINITION of _draw_bite in the previous chunk.
# Let's check the previous ReplacementContent.
# It ends with `_draw_bite(b): ... code ...`. 
# So I defined it there.
# I need to DELETE the old `_draw_bite` at the bottom.
