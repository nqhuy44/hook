extends Node

var menu_script = preload("res://scripts/menu.gd")
var lobby_script = preload("res://scripts/lobby.gd")
var game_script = preload("res://scripts/game.gd")
var current_node = null

# State passed to lobby
var current_room_code = ""
var is_host = false

func _ready():
	NetworkManager.connected_to_server.connect(_on_connected)
	NetworkManager.connection_closed.connect(_on_disconnected)
	NetworkManager.packet_received.connect(_on_packet)
	
	# Start connection
	NetworkManager.connect_to_server()
	show_menu()

func _on_connected():
	pass

func _on_disconnected():
	show_menu() # Reset to menu on disconnect

func show_menu():
	if current_node:
		current_node.queue_free()
	current_node = Control.new()
	current_node.set_script(menu_script)
	current_node.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(current_node)

func show_lobby():
	if current_node:
		current_node.queue_free()
	
	current_node = Control.new()
	current_node.set_script(lobby_script)
	current_node.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(current_node)
	
	# Pass data
	if current_node.get("room_code_label"):
		current_node.room_code_label.text = "Room Code: " + current_room_code
	if is_host and current_node.get("start_button"):
		current_node.start_button.show()

func start_game():
	if current_node:
		current_node.queue_free()
	
	current_node = Node2D.new()
	current_node.set_script(game_script)
	add_child(current_node)

func _on_packet(type, payload):
	print("Main received packet: ", type)
	if type == "room_joined":
		print("Transitioning to Lobby...")
		current_room_code = payload.get("code")
		is_host = payload.get("is_host")
		var pid = payload.get("id")
		NetworkManager.my_id = pid
		
		show_lobby()
		
	elif type == "game_started":
		start_game()
