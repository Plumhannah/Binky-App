extends Node2D
 
@export var min_time: float = 2.0
@export var max_time: float = 5.0
 
var anims = ["Idle", "Idle_left", "Idle_right", "Idle_back"]
 
@onready var sprite = $AnimatedSprite2D
@onready var timer = Timer.new()
 
func _ready():
	add_child(timer)
	timer.timeout.connect(_on_timer_timeout)
	_play_random()
 
	# snap the window to bottom-right, above the taskbar
	var screen_id = DisplayServer.window_get_current_screen()
	var usable_rect = DisplayServer.screen_get_usable_rect(screen_id)
	var window_size = DisplayServer.window_get_size()
	DisplayServer.window_set_position(usable_rect.position + usable_rect.size - window_size, screen_id)
 
func _play_random():
	sprite.play(anims.pick_random())
	timer.wait_time = randf_range(min_time, max_time)
	timer.start()
 
func _on_timer_timeout():
	_play_random()
 
func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and event.double_click:
			# catches the click at the exact instant it happens,
			# then hands the drag straight to Windows
			DisplayServer.window_start_drag()
