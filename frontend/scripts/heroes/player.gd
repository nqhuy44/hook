# res://scripts/heroes/player.gd
extends CharacterBody2D

@onready var sprite = $Sprite2D

# Call when Spawn character
func apply_skin(skin_resource: CharacterSkin):
	# 1. Change texture of Sprite to texture in Resource
	sprite.texture = skin_resource.texture
	
	# Vì chúng ta đã quy chuẩn Sprite Sheet (ví dụ 4x4),
	# nên AnimationPlayer cũ vẫn hoạt động hoàn hảo!
	
	# (Tùy chọn) Nếu layout ảnh khác nhau, bạn có thể chỉnh lại hframes/vframes
	# sprite.hframes = skin_resource.hframes
