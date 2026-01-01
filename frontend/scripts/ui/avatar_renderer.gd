extends Control
class_name AvatarRenderer

# Re-uses the logic from AnimalRenderer to draw in UI
# We can just instance an AnimalRenderer as a child and manage it?
# OR copy the drawing logic?
# Instancing is cleaner to keep DRY. But AnimalRenderer is Node2D.
# UI is Control.
# We can use a SubViewportContainer? Too heavy?
# Or just use the same drawing commands in _draw() with an offset?

# Let's use the same drawing commands by duplicating the script logic?
# No, duplications is bad.
# Let's make AnimalRenderer able to draw on a Control?
# Or easier: Make AvatarRenderer a Node2D that puts itself in the right place? No.

# Best approach:
# Refactor drawing logic into a library? 
# Or just instantiate AnimalRenderer as a child of this Control, 
# and in _draw() of this Control, we call the drawing functions?

# For now, to be fast and robust:
# I will create a simple wrapper that instances AnimalRenderer (Node2D)
# and centers it in this Control.

var renderer: AnimalRenderer
var skin: CharacterSkin
var view_mode = AnimalRenderer.ViewMode.PORTRAIT

func _ready():
	# Clip content
	clip_contents = true
	
	# Add the renderer
	if not renderer:
		renderer = AnimalRenderer.new()
		add_child(renderer)
	
	# If skin was set before ready, apply it now
	if skin:
		_apply_skin()
	
func set_skin(p_skin: CharacterSkin, p_mode = null):
	skin = p_skin
	if p_mode != null:
		view_mode = p_mode
	if renderer:
		_apply_skin()

func _apply_skin():
	if not renderer or not skin: return
	renderer.setup(skin)
	# Set Mode
	renderer.set_view_mode(view_mode)
	
	if view_mode == AnimalRenderer.ViewMode.PORTRAIT:
		renderer.position = size / 2.0
		renderer.scale = Vector2(1.2, 1.2)
	else:
		# Top Down might need different centering/scale
		renderer.position = size / 2.0
		renderer.scale = Vector2(1.0, 1.0) # Normal scale for top down
		
	renderer.queue_redraw()

func _draw():
	# Draw a background for the portrait
	# Maybe different bg for top down?
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.1, 0.1, 0.15))
