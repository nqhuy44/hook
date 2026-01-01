extends Area2D

const DAMAGE_PER_TICK = 50.0 # Total per second actually? User said 50 every 1s.
const TICK_RATE = 1.0

var dmg_timer: Timer

func _ready():
	# Setup Timer
	dmg_timer = Timer.new()
	dmg_timer.wait_time = TICK_RATE
	dmg_timer.one_shot = false
	dmg_timer.timeout.connect(_on_tick_damage)
	add_child(dmg_timer)
	
	# Connect Area
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body is Entity or body.name == "Player": # Adjust type check
		if dmg_timer.is_stopped():
			dmg_timer.start()

func _on_body_exited(body):
	# Check if any valid bodies remain?
	# Simple implementation: If My Player exits, stop.
	if body.name == "Player" or body == get_parent(): # Assuming logic for local player
		dmg_timer.stop()

func _on_tick_damage():
	# Apply damage to all overlapping bodies
	# Logic only if we are authoritative or purely visual
	var bodies = get_overlapping_bodies()
	for b in bodies:
		if b.has_method("take_damage"):
			# In Networked Game, server invalidates this.
			# But complying with request:
			b.take_damage(DAMAGE_PER_TICK, "River")
