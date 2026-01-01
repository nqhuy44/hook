extends CharacterBody2D
class_name Player

@onready var animal_renderer = AnimalRenderer.new()
@onready var skill_manager = SkillManager.new()

const RotAuraScript = preload("res://scripts/vfx/rot_aura_visual.gd")

# Skill Scripts
const SkillHook = preload("res://scripts/skills/skill_hook.gd")
const SkillRot = preload("res://scripts/skills/skill_rot.gd")
# SkillBite Removed

# Skill Constants (Legacy/Ref for now)
const SKILL_HOOK_MANA = 300
const SKILL_HOOK_DMG = 400

const SKILL_ROT_MANA = 0
const SKILL_ROT_DMG_ENEMY = 120
const SKILL_ROT_DMG_SELF = 70
const ROT_TICK_RATE = 0.5

const SKILL_BITE_MANA = 0
const SKILL_BITE_CD = 1.0
const SKILL_BITE_DMG = 80

# State
var rot_active = false

func _ready():
	# Add renderer as child
	add_child(animal_renderer)
	# Add Skill Manager
	add_child(skill_manager)
	
	# Add Rot Aura
	# Check if visual node exists (from Scene) or add it
	if not has_node("RotVisual"):
		var rot_node = RotAuraScript.new()
		rot_node.name = "RotVisual"
		add_child(rot_node)
	
	# Setup Default Skills
	var s1 = SkillHook.new()
	var s2 = SkillRot.new()
	skill_manager.setup_skills([s1, s2])
	
	# Remove old sprite if exists (or hide it)
	if has_node("Sprite2D"):
		$Sprite2D.hide()

# Call when Spawn character
func apply_skin(skin_resource: CharacterSkin):
	print("Applying Skin: ", skin_resource.display_name if skin_resource else "NULL", " Type: ", skin_resource.animal_type if skin_resource else "N/A")
	animal_renderer.setup(skin_resource)

func set_rot_active(active: bool):
	rot_active = active
	if has_node("RotVisual"):
		get_node("RotVisual").toggle(active)

func play_bite_anim():
	# This could trigger a specific animation on the renderer if supported
	pass
