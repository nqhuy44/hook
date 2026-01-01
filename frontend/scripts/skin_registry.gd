extends Node

# Dictionary mapping skin_id -> CharacterSkin Resource
var skins = {}

func _ready():
	_load_all_skins()

func _load_all_skins():
	# For now, manually load or scan directory
	# Let's manually register the defaults we know
	#register_skin("butcher", "res://resources/skins/butcher.tres")
	#register_skin("tech", "res://resources/skins/tech.tres")
	register_skin("bot_basic", "res://resources/skins/bot_basic.tres")
	# Add others as needed or scan directory

func register_skin(id: String, path: String):
	if ResourceLoader.exists(path):
		skins[id] = load(path)
	else:
		print("Warning: Skin resource not found: ", path)

func get_skin(id: String) -> CharacterSkin:
	return skins.get(id, skins.get("butcher")) # Fallback
