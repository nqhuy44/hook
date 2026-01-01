extends Node

# Dictionary mapping skin_id -> CharacterSkin Resource
var skins = {}
# Data for 20 Animals
const ANIMAL_DATA = [
	# Existing 12
	{"id": "duck", "name": "Psyduck", "type": "Duck", "col": "FFD700", "sec": "FFA500"},
	{"id": "pig", "name": "Baconator", "type": "Pig", "col": "FFB6C1", "sec": "DB7093"},
	{"id": "panda", "name": "Po", "type": "Panda", "col": "FFFFFF", "sec": "000000"},
	{"id": "frog", "name": "Kermit", "type": "Frog", "col": "32CD32", "sec": "006400"},
	{"id": "bear", "name": "Winnie", "type": "Bear", "col": "8B4513", "sec": "D2691E"},
	{"id": "cat", "name": "Meowth", "type": "Cat", "col": "333333", "sec": "CCCCCC"},
	{"id": "rabbit", "name": "Bugs", "type": "Rabbit", "col": "F0F8FF", "sec": "FFC0CB"},
	{"id": "chicken", "name": "Nugget", "type": "Chicken", "col": "FFFFFF", "sec": "FF0000"},
	{"id": "tiger", "name": "Shere Khan", "type": "Tiger", "col": "FFA500", "sec": "000000"},
	{"id": "bee", "name": "Stinger", "type": "Bee", "col": "FFFF00", "sec": "000000"},
	{"id": "elephant", "name": "Dumbo", "type": "Elephant", "col": "A9A9A9", "sec": "808080"},
	{"id": "penguin", "name": "Rico", "type": "Penguin", "col": "1A1A1A", "sec": "FFA500"},
	# New 8
	{"id": "fox", "name": "Firefox", "type": "Fox", "col": "FF4500", "sec": "FFFFFF"},
	{"id": "turtle", "name": "Shelly", "type": "Turtle", "col": "006400", "sec": "8B4513"},
	{"id": "cow", "name": "MooMoo", "type": "Cow", "col": "FFFFFF", "sec": "000000"},
	{"id": "mouse", "name": "Jerry", "type": "Mouse", "col": "808080", "sec": "FFC0CB"},
	{"id": "owl", "name": "Hooters", "type": "Owl", "col": "8B4513", "sec": "FFFFFF"},
	{"id": "ladybug", "name": "Dotty", "type": "Ladybug", "col": "FF0000", "sec": "000000"},
	{"id": "axolotl", "name": "Axo", "type": "Axolotl", "col": "FFC0CB", "sec": "FF0000"},
	{"id": "slime", "name": "Blobby", "type": "Slime", "col": "39FF14", "sec": "000000"} # Alpha handled in init
]

func _ready():
	_load_all_skins()

func _load_all_skins():
	# Generate procedural skins
	for d in ANIMAL_DATA:
		var skin = CharacterSkin.new()
		skin.id = d["id"]
		skin.display_name = d["name"]
		skin.animal_type = d["type"]
		skin.body_color = Color(d["col"])
		if d["id"] == "slime": skin.body_color.a = 0.7
		skin.secondary_color = Color(d["sec"])
		
		# Register
		skins[d["id"]] = skin

	# Aliases for compatibility with old IDs if needed (optional)
	skins["boar"] = skins["pig"]
	skins["wolf"] = skins["cat"] # Fallback
	skins["bot_basic"] = skins["panda"]

func get_skin(id: String) -> CharacterSkin:
	return skins.get(id, skins.get("duck"))

func get_all_skins() -> Array:
	var list = []
	for d in ANIMAL_DATA:
		list.append(skins[d["id"]])
	return list
