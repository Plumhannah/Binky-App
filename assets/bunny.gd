extends Node2D
@export var min_time: float = 2.0
@export var max_time: float = 5.0

# simple one-animation idle poses she can randomly switch between
var anims = ["Idle", "Idle_left", "Idle_right", "Idle_back"]

# played whenever she's being dragged - not part of any random rotation
var pickup_anim = "picked_up"

# custom cursor - drag your carrot PNG into this slot in the Inspector
@export var cursor_texture: Texture2D
@export var cursor_hotspot: Vector2 = Vector2.ZERO

# "activities" are multi-step: an intro animation that plays once,
# then a loop animation that keeps playing until she's double-clicked.
# to add a new one later, just add a new line here - nothing else needs to change.
var activities = {
	"sleep": {"intro": "sleep", "loop": "sleep_breathing"},
	"eating": {"intro": "hay", "loop": "eating_hay"},
}

enum State { AWAKE, IN_ACTIVITY }
var state = State.AWAKE
var current_activity = "" # which activity key she's currently doing, if any

@onready var sprite = $AnimatedSprite2D
@onready var heart_sprite = $HeartSprite
@onready var timer = Timer.new()
@onready var quit_menu = PopupMenu.new()

func _ready():
	add_child(timer)
	add_child(quit_menu)
	timer.timeout.connect(_on_timer_timeout)
	sprite.animation_finished.connect(_on_animation_finished)
	heart_sprite.animation_finished.connect(_on_heart_finished)

	quit_menu.add_item("Quit", 0)
	quit_menu.id_pressed.connect(_on_quit_menu_id_pressed)

	# replace the cursor everywhere over this window with your carrot
	Input.set_custom_mouse_cursor(cursor_texture, Input.CURSOR_ARROW, cursor_hotspot)

	_play_random()

	# snap the window to bottom-right, above the taskbar
	var screen_id = DisplayServer.window_get_current_screen()
	var usable_rect = DisplayServer.screen_get_usable_rect(screen_id)
	var window_size = DisplayServer.window_get_size()
	DisplayServer.window_set_position(usable_rect.position + usable_rect.size - window_size, screen_id)

func _play_random(force_idle_only: bool = false):
	if state != State.AWAKE:
		return
	# combine simple idle poses and activity names into one pool to pick from -
	# unless force_idle_only is true, in which case only simple poses are allowed
	var pool = anims if force_idle_only else anims + activities.keys()
	var choice = pool[randi() % pool.size()]

	if activities.has(choice):
		_start_activity(choice)
		return

	sprite.play(choice)
	timer.wait_time = randf_range(min_time, max_time)
	timer.start()

func _on_timer_timeout():
	_play_random()

func _start_activity(activity_name: String):
	state = State.IN_ACTIVITY
	current_activity = activity_name
	timer.stop() # she won't auto-switch to anything else mid-activity
	sprite.play(activities[activity_name]["intro"])

func _on_animation_finished():
	if state == State.IN_ACTIVITY and sprite.animation == activities[current_activity]["intro"]:
		sprite.play(activities[current_activity]["loop"])

func _end_activity():
	if state != State.IN_ACTIVITY:
		return
	state = State.AWAKE
	current_activity = ""
	_play_random(true) # force a simple idle pose first, no back-to-back activities

func _on_heart_finished():
	heart_sprite.visible = false

# --- quit menu ---

func _show_quit_menu():
	quit_menu.popup(Rect2i(DisplayServer.mouse_get_position(), Vector2i(80, 32)))

func _on_quit_menu_id_pressed(id: int):
	if id == 0:
		get_tree().quit()

# --- input ---

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# show the heart the instant you click, no waiting
			heart_sprite.visible = true
			heart_sprite.play("heart")

			if event.double_click:
				# stop whatever she was doing and show the "being picked up" pose
				state = State.AWAKE
				current_activity = ""
				timer.stop()
				sprite.play(pickup_anim)

				# catches the click at the exact instant it happens,
				# then hands the drag straight to Windows
				DisplayServer.window_start_drag()

				# window_start_drag() finishes once you release the mouse,
				# so this runs right after the drag ends
				_play_random(true) # force a simple idle pose first
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_show_quit_menu()
