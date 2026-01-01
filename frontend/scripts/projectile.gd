extends Node2D

var from_id = ""
var type = "hook"

# Chain Config
const CHAIN_COLOR = Color("#95A5A6") # Metallic Grey
const CHAIN_HIGHLIGHT = Color("#BDC3C7")
const CHAIN_WIDTH = 12.0
const LINK_LENGTH = 15.0
const LINK_SPACING = 5.0

func _draw():
	# 1. FIND OWNER POSITION
	var start_pos = Vector2.ZERO
	# Assuming parent is Game and has 'entities' dictionary
	var parent = get_parent()
	if parent and "entities" in parent and parent.entities.has(from_id):
		# We need position relative to this node
		var owner_node = parent.entities[from_id]
		# Transform global owner pos to local pos
		start_pos = to_local(owner_node.global_position)
	else:
		return # Can't draw chain if no owner found (or just draw head)

	# 2. DRAW CHAIN
	_draw_chain(start_pos, Vector2.ZERO) # Local 0,0 is the hook head

	# 3. DRAW HOOK HEAD (Claw)
	_draw_hook_head()

func _draw_chain(from, to):
	var dist = from.distance_to(to)
	var dir = (to - from).normalized()
	
	var current_dist = 0.0
	while current_dist < dist:
		var link_pos = from + dir * current_dist
		
		# Draw Link (Capsule-ish)
		# We draw a rotated rect/pill
		var angle = dir.angle()
		
		# Alternating links for depth (one flat, one sideways)
		# Simplified: Just draw rounded rects along the line
		
		draw_set_transform(link_pos, angle, Vector2.ONE)
		# Capsule shape
		var rect = Rect2(-LINK_LENGTH/2, -CHAIN_WIDTH/2, LINK_LENGTH, CHAIN_WIDTH)
		draw_rect(rect, CHAIN_COLOR, true) # Darker base
		# Highlight strip
		draw_rect(Rect2(-LINK_LENGTH/2 + 2, -CHAIN_WIDTH/4, LINK_LENGTH - 4, CHAIN_WIDTH/2), CHAIN_HIGHLIGHT, true)
		
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE) # Reset
		
		current_dist += LINK_LENGTH + LINK_SPACING

func _draw_hook_head():
	# Draw a "Claw" shape at 0,0
	var col = Color("#7F8C8D") # Darker Metal
	var tip_col = Color("#ECF0F1") # Sharp Tip
	
	# Left Claw
	var pts_l = PackedVector2Array([
		Vector2(-5, -5), Vector2(5, -10), Vector2(15, -15), Vector2(20, -5), Vector2(10, 5)
	])
	draw_colored_polygon(pts_l, col)
	
	# Right Claw
	var pts_r = PackedVector2Array([
		Vector2(-5, 5), Vector2(5, 10), Vector2(15, 15), Vector2(20, 5), Vector2(10, -5)
	])
	draw_colored_polygon(pts_r, col)
	
	# Central Hub
	draw_circle(Vector2.ZERO, 8, col)
	draw_circle(Vector2.ZERO, 4, tip_col)

func _process(_delta):
	queue_redraw()
