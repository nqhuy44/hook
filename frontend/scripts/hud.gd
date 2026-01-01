extends CanvasLayer

var time_label: Label
var score_label: Label
var feed_container: VBoxContainer

func _ready():
	var root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	
	# Timer
	time_label = Label.new()
	time_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	time_label.position.y += 20
	time_label.add_theme_font_size_override("font_size", 32)
	root.add_child(time_label)
	
	# Score
	score_label = Label.new()
	score_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.position.y += 60
	root.add_child(score_label)
	
	# Kill Feed
	feed_container = VBoxContainer.new()
	feed_container.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	feed_container.position -= Vector2(300, -20)
	feed_container.custom_minimum_size = Vector2(280, 0)
	root.add_child(feed_container)

func update_stats(time_left, score_dict):
	var m = floor(time_left / 60)
	var s = int(time_left) % 60
	time_label.text = "%02d:%02d" % [m, s]
	
	var s1 = score_dict.get("1", 0)
	var s2 = score_dict.get("2", 0)
	score_label.text = "Radiant: %d   Dire: %d" % [s1, s2]

func add_feed_item(text):
	var l = Label.new()
	l.text = text
	l.add_theme_color_override("font_color", Color.YELLOW)
	feed_container.add_child(l)
	# Remove after 5s
	await get_tree().create_timer(5.0).timeout
	if is_instance_valid(l):
		l.queue_free()
