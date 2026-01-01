extends Node2D

var from_id = ""
var type = "hook"

func _draw():
	# Draw Hook Head
	var head_color = Color(0.8, 0.8, 0.8)
	var points = PackedVector2Array([
		Vector2(10, 0), Vector2(-10, 10), Vector2(-5, 0), Vector2(-10, -10)
	])
	draw_colored_polygon(points, head_color)
	
	# Chain is drawn by the Game node or parent because it needs start position 
	# which might be the player's position.
	# Actually, for simplicity, let's draw the chain here if we know where it started.
	# But moving projectiles in Godot are just the head usually.
	# The Game loop in JS drew a line from Owner to Projectile.
	# We can try to find the owner in the parent.

func _process(_delta):
	queue_redraw()
