extends Node

signal connected_to_server
signal connection_closed
signal packet_received(type, payload)

var socket: WebSocketPeer
var connected = false

func _ready():
	socket = WebSocketPeer.new()
	# Optional: Increase buffer if packets are large
	socket.inbound_buffer_size = 65535 
	socket.outbound_buffer_size = 65535

func connect_to_server(url: String = "ws://localhost:8080/ws"):
	print("Connecting to %s..." % url)
	var err = socket.connect_to_url(url)
	if err != OK:
		print("Unable to connect")
		set_process(false)
	else:
		connected = false # Wait for OPEN state

func _process(delta):
	socket.poll()
	var state = socket.get_ready_state()
	
	if state == WebSocketPeer.STATE_OPEN:
		if not connected:
			connected = true
			emit_signal("connected_to_server")
			print("Connected!")
			
		while socket.get_available_packet_count():
			var packet = socket.get_packet()
			var packet_text = packet.get_string_from_utf8()
			if packet_text.begins_with("{"): # Simple JSON check
				var json = JSON.new()
				var error = json.parse(packet_text)
				if error == OK:
					var data = json.data
					var type = data.get("type", "")
					emit_signal("packet_received", type, data)
				else:
					print("JSON Parse Error: ", json.get_error_message())
			
	elif state == WebSocketPeer.STATE_CLOSING:
		pass
	elif state == WebSocketPeer.STATE_CLOSED:
		if connected:
			connected = false
			emit_signal("connection_closed")
			print("Connection Closed")

func send_packet(data: Dictionary):
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		var json_str = JSON.stringify(data)
		socket.put_packet(json_str.to_utf8_buffer())

func send_input(type: String, data: Dictionary):
	# Match server expectation: { "type": "input", "payload": { "type": type, ...data... } }
	var payload = data.duplicate()
	payload["type"] = type
	send_packet({
		"type": "input",
		"payload": payload
	})
