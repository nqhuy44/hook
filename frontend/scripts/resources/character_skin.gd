# res://scripts/resources/character_skin.gd
extends Resource
class_name CharacterSkin

@export_group("Visuals")
@export var texture: Texture2D       # Keep for compatibility/UI
@export var portrait: Texture2D      # Portrait Display in HUD
@export var id: String = "duck"
@export var display_name: String = "Duck"

@export_group("Kurzgesagt Visuals")
@export var body_color: Color = Color("FFC0CB") # Pig Pink default
@export var secondary_color: Color = Color("E6A8B1") # Spots/Belly
@export var eye_color: Color = Color.BLACK
@export var scale_modifier: float = 1.0

# Using String for flexibility with 20+ types procedural generation
@export var animal_type: String = "Duck"
