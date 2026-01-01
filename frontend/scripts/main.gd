extends Node

var lobby_script = preload("res://scripts/lobby.gd")
var game_script = preload("res://scripts/game.gd")
var current_node = null

func _ready():
	NetworkManager.connected_to_server.connect(_on_connected)
	NetworkManager.connection_closed.connect(_on_disconnected)
	# Start connection
	NetworkManager.connect_to_server()
	
	show_lobby()

func _on_connected():
	pass

func _on_disconnected():
	show_lobby()

func show_lobby():
	if current_node:
		current_node.queue_free()
	
	current_node = Control.new()
	current_node.set_script(lobby_script)
	current_node.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(current_node)
	
	NetworkManager.packet_received.connect(_on_packet)

func start_game():
	if current_node:
		current_node.queue_free()
	
	current_node = Node2D.new()
	current_node.set_script(game_script)
	add_child(current_node)

func _on_packet(type, payload):
	if type == "game_started":
		start_game()
