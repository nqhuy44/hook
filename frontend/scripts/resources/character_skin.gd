# res://scripts/resources/character_skin.gd
extends Resource
class_name CharacterSkin

@export_group("Visuals")
@export var texture: Texture2D       # Sprite sheet
@export var portrait: Texture2D      # Portrait Display in HUD
@export var name: String             # Skin name
