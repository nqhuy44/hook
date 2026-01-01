extends Node

signal connected_to_server
signal connection_closed
signal packet_received(type, payload)

var socket: WebSocketPeer
var connected = false
var my_id = ""

func _ready():
	socket = WebSocketPeer.new()
	# Optional: Increase buffer if packets are large
	socket.inbound_buffer_size = 65535 
	socket.outbound_buffer_size = 65535

func connect_to_server(url: String = ""):
	var final_url = url
	
	if final_url == "":
		if OS.has_feature("web"):
			# Dynamic Web URL based on page origin
			var host = JavaScriptBridge.eval("window.location.host")
			var protocol = JavaScriptBridge.eval("window.location.protocol")
			var ws_proto = "wss://" if protocol == "https:" else "ws://"
			# If using Nginx proxy at /ws, use just /ws
			# If host is localhost:8080 (no nginx), use existing logic? 
			# Assuming Nginx Deployment as per plan:
			final_url = ws_proto + host + "/ws"
			print("Web Deployment detected. Connecting to: ", final_url)
		else:
			# Desktop / Editor default
			final_url = "ws://localhost:8080/ws"
	
	print("Connecting to %s..." % final_url)
	var err = socket.connect_to_url(final_url)
	if err != OK:
		print("Unable to connect")
		set_process(false)
	else:
		connected = false # Wait for OPEN state
		print("WebSocket connecting...")

func _process(_delta):
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
					print("Packet Received: ", type)
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
