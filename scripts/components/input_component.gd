@icon("res://assets/icons/StreamlineController1.svg")
## This is the component that handles the players input and then relays that to the player states
class_name InputComponent extends Node

var input_buffer_timer: Timer = null
var parry_timer: Timer = null
var unhandled_input = null
var latest_action = null

signal attack_input_signal(height, range, direction, special)
signal defense_input_signal(move)

## Variable that stores if the player is holding fown the left or right button respectively.
var holding_left : bool = false
## Variable that stores if the player is holding fown the left or right button respectively.
var holding_right : bool = false
## Variable that stores if the player can perform any inputs.
var allow_inputs : bool = false
@export var buffer_time : float = 0.3
@export var parry_window : float = 0.15

func _ready() -> void:
	# Creates a new input buffer Timer on ready
	input_buffer_timer = Timer.new()
	input_buffer_timer.one_shot = true
	input_buffer_timer.wait_time = buffer_time
	input_buffer_timer.timeout.connect(_on_input_buffer_timer_timeout)
	add_child(input_buffer_timer)
	
	parry_timer = Timer.new()
	parry_timer.one_shot = true
	parry_timer.wait_time = parry_window
	#parry_timer.timeout.connect(_on_input_buffer_timer_timeout)
	add_child(parry_timer)

func _input(_event: InputEvent) -> void:
	if allow_inputs == false:
		return
	if Input.is_action_just_pressed("dodge"):
		print("pressed dodge")
	
	if Input.is_action_just_pressed("down"): # Ducking to avoid high attacks
		perform_action("down")

	if Input.is_action_just_pressed("left"):
		perform_action("left")

	if Input.is_action_just_pressed("right"):
		perform_action("right")
		
	if Input.is_action_just_pressed("block"):
		parry_timer.start()
		print("block")
		
	if Input.is_action_just_pressed("star_punch") and Input.is_action_pressed("up") == false:
		perform_action("star_punch_lower")
		
	if Input.is_action_just_pressed("star_punch") and Input.is_action_pressed("up") == true:
		perform_action("star_punch_upper")
		
	# If the player is NOT holding the Up button and presses the button to throw a punch, then that's a low punch.
	if Input.is_action_just_pressed("left_punch") and Input.is_action_pressed("up") == false:
		perform_action("left_low_punch")
	if Input.is_action_just_pressed("right_punch") and Input.is_action_pressed("up") == false:
		perform_action("right_low_punch")
		
	# If the player is already holding the Up button and presses the button to throw a punch, then that's a high punch.
	if Input.is_action_pressed("up") == true and Input.is_action_just_pressed("left_punch"):
		perform_action("left_high_punch")

	if Input.is_action_pressed("up") == true and Input.is_action_just_pressed("right_punch"):
		perform_action("right_high_punch")

func _process(_delta: float) -> void:
	if allow_inputs == false:
		return
	
	if Input.is_action_pressed("up") == true and Input.is_action_pressed("block") == true: 
		owner.animation_tree.set("parameters/neutral/idle/blend_position", Vector2i(1, 1))
		
	elif Input.is_action_pressed("up") == false and Input.is_action_pressed("block") == true: 
		owner.animation_tree.set("parameters/neutral/idle/blend_position", Vector2i(1, 0))
		
	elif Input.is_action_pressed("up") == false and Input.is_action_pressed("block") == false: 
		owner.animation_tree.set("parameters/neutral/idle/blend_position", Vector2i(0, 0))
		
	elif Input.is_action_pressed("up") == true and Input.is_action_pressed("block") == false: 
		owner.animation_tree.set("parameters/neutral/idle/blend_position", Vector2i(0, 0))
		
	if Input.is_action_pressed("left") == true: 
		owner.animation_tree.set("parameters/dodge/dodge_left/dodge_blend_left/blend_position", Global.range.LEFT)
		owner.animation_tree.set("parameters/dodge/dodge_left/conditions/holding_left", true)
		
	elif Input.is_action_pressed("left") == false: 
		owner.animation_tree.set("parameters/dodge/dodge_left/conditions/holding_left", false)
		
	if Input.is_action_pressed("right") == true: 
		owner.animation_tree.set("parameters/dodge/dodge_right/dodge_blend_right/blend_position", Global.range.RIGHT)
		owner.animation_tree.set("parameters/dodge/dodge_right/conditions/holding_right", true)
	elif Input.is_action_pressed("right") == false: 
		owner.animation_tree.set("parameters/dodge/dodge_right/conditions/holding_right", false)
		
	if Input.is_action_pressed("down") == true: 
		owner.animation_tree.set("parameters/dodge/duck/duck_blend/blend_position", -1)
		owner.animation_tree.set("parameters/dodge/duck/conditions/holding_down", true)
	elif Input.is_action_pressed("down") == false: 
		owner.animation_tree.set("parameters/dodge/duck/conditions/holding_down", false)

func perform_action(action_name : String):
	match action_name:
		"left_low_punch":
			attack_input_signal.emit(Global.height.LOW, Global.range.LEFT, "left_low_punch", false)
		"right_low_punch":
			attack_input_signal.emit(Global.height.LOW, Global.range.RIGHT, "right_low_punch", false)
		"left_high_punch":
			attack_input_signal.emit(Global.height.HIGH, Global.range.LEFT, "left_high_punch", false)
		"right_high_punch":
			attack_input_signal.emit(Global.height.HIGH, Global.range.RIGHT, "right_high_punch", false)
		"up": # Ducking to avoid high attacks
			defense_input_signal.emit(Global.range.NEUTRAL, "up")
		"down": # Ducking to avoid high attacks
			defense_input_signal.emit(Global.range.NEUTRAL, "down")
		"left":
			defense_input_signal.emit(Global.range.LEFT, "left")
		"right":
			defense_input_signal.emit(Global.range.RIGHT, "right")
		"star_punch_lower":
			attack_input_signal.emit(Global.height.LOW, Global.range.NEUTRAL, "star_punch_lower", true)
		"star_punch_upper":
			attack_input_signal.emit(Global.height.HIGH, Global.range.NEUTRAL, "star_punch_upper", true)
		_:
			printerr("Unnaccounted action.")
	
## Stores the given action to then use it when requested.
func store_unhandled_input(action_name : String): 
	unhandled_input = action_name
	input_buffer_timer.start()
	
## Function called by specific animations.
## Automatically performs the stored unhandled input and then clears it.
func perform_buffered_action():
	if unhandled_input != null:
		perform_action(unhandled_input)
		unhandled_input = null
		
## When the buffer timer runs out, clear the unhandled input
func _on_input_buffer_timer_timeout() -> void: 
	unhandled_input = null
	
func reset_blend_positions() -> void:
	owner.animation_tree.set("parameters/dodge_blend_left/blend_position", 0)
	owner.animation_tree.set("parameters/dodge_blend_right/blend_position", 0)
	owner.animation_tree.set("parameters/duck_blend/blend_position", 0)
