extends Control

var name_edit: LineEdit
var code_edit: LineEdit
var avatar_list: HBoxContainer
var status_label: Label
var selected_avatar = "butcher" # Default

const AVATARS = [
	"butcher", "tech", "nature", "void", "inferno", 
	"glacial", "holy", "shadow", "mecha", "cosmic"
]

func _ready():
	# Background
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.08, 0.12)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(400, 300)
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "HooK"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	vbox.add_child(title)
	
	# Name Input
	name_edit = LineEdit.new()
	name_edit.placeholder_text = "Enter Name"
	vbox.add_child(name_edit)
	
	# Create Room Button
	var create_btn = Button.new()
	create_btn.text = "Create Room"
	create_btn.pressed.connect(_on_create_room)
	vbox.add_child(create_btn)
	
	vbox.add_child(HSeparator.new())
	
	# Join Room Section
	var join_hbox = HBoxContainer.new()
	code_edit = LineEdit.new()
	code_edit.placeholder_text = "Room Code"
	code_edit.size_flags_horizontal = SIZE_EXPAND_FILL
	join_hbox.add_child(code_edit)
	
	var join_btn = Button.new()
	join_btn.text = "Join Room"
	join_btn.pressed.connect(_on_join_room)
	join_hbox.add_child(join_btn)
	
	vbox.add_child(join_hbox)
	
	# Avatar Selector
	var avatar_label = Label.new()
	avatar_label.text = "Select Avatar:"
	vbox.add_child(avatar_label)
	
	avatar_list = HBoxContainer.new()
	avatar_list.alignment = BoxContainer.ALIGNMENT_CENTER
	for av in AVATARS:
		var btn = Button.new()
		btn.text = av.substr(0,1).to_upper()
		btn.custom_minimum_size = Vector2(30, 30)
		btn.toggle_mode = true
		btn.pressed.connect(func(): _select_avatar(av, btn))
		if av == selected_avatar:
			btn.button_pressed = true
		avatar_list.add_child(btn)
	vbox.add_child(avatar_list)
	
	# Status
	status_label = Label.new()
	status_label.text = "Connecting..."
	vbox.add_child(status_label)

	NetworkManager.connected_to_server.connect(func(): status_label.text = "Connected")
	NetworkManager.packet_received.connect(_on_packet)

func _select_avatar(id, btn_ref):
	selected_avatar = id
	for child in avatar_list.get_children():
		child.set_pressed_no_signal(child == btn_ref)
	
	# If in room, send change
	if status_label.text.begins_with("Room:"):
		NetworkManager.send_packet({"type": "change_avatar", "payload": {"avatar_id": id}})

func _on_create_room():
	var name = name_edit.text
	if name == "": name = "Player"
	NetworkManager.send_packet({
		"type": "create_room",
		"payload": {"name": name, "avatar_id": selected_avatar}
	})

func _on_join_room():
	var name = name_edit.text
	if name == "": name = "Player"
	var code = code_edit.text
	NetworkManager.send_packet({
		"type": "join_room",
		"payload": {"code": code, "name": name, "avatar_id": selected_avatar}
	})

func _on_packet(type, payload):
	if type == "room_joined":
		var code = payload.get("code")
		var is_host = payload.get("is_host")
		status_label.text = "Room: " + str(code)
		
		# If host, show Start Button
		if is_host:
			var start_btn = Button.new()
			start_btn.text = "START GAME"
			start_btn.add_theme_color_override("font_color", Color.GREEN)
			start_btn.pressed.connect(func(): NetworkManager.send_packet({"type": "start_game", "payload": {}}))
			get_child(1).add_child(start_btn) # Add to vbox
			
	elif type == "lobby_update":
		var players = payload.get("players", [])
		status_label.text += "\nPlayers: " + str(len(players))
