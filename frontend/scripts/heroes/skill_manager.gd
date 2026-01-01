extends Node
class_name SkillManager

# Array of active skill nodes
var skills: Array[Node] = [null, null] # Max 2

@onready var player = get_parent()

func _ready():
	# Initialize empty inputs
	pass

func setup_skills(skill_nodes: Array):
	# Clear existing
	for s in skills:
		if s: s.queue_free()
	
	skills = []
	for i in range(2): # Strictly 2
		if i < skill_nodes.size():
			var s = skill_nodes[i]
			add_child(s)
			s.owner_player = player
			skills.append(s)
		else:
			skills.append(null)

func _process(delta):
	# Handle Inputs
	if Input.is_action_just_pressed("skill_q"):
		try_cast(0)
	elif Input.is_action_just_pressed("skill_w"):
		try_cast(1)
	# Removed Skill E

func try_cast(idx: int):
	if idx < 0 or idx >= skills.size(): return
	var skill = skills[idx]
	if skill and skill.turn_condition():
		skill.cast()

# Helper for HUD to get cooldowns etc
func get_skill_state(idx: int):
	if idx < 0 or idx >= skills.size(): return {}
	var s = skills[idx]
	if not s: return {}
	return s.get_state()
