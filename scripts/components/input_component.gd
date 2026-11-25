@icon("res://assets/icons/StreamlineController1.svg")
class_name InputComponent extends Node
## This is the component that handles the players input and then relays that to the player states in the [StateMachine]

## Signal emitted to the player states
## whenever a player performs an attack.
signal attack_input_signal(height, range, direction, special)

## Signal emitted to the player states
## whenever a player performs a defensive move
## such as blocking, dodging or ducking.
signal defense_input_signal(move)

## The time in seconds an action will be stored/buffered for before being cleared away
@export var buffer_time : float = 0.3

## The amount of time in seconds a block has to be
## within an incoming attack for the balck to be considered a parry.
@export var parry_window : float = 0.1

## The timer used to set the duration of how long it stores the unhandled inputs
var input_buffer_timer: Timer = null

## Timer that gets started when the player blocks and is then checked to see if it's still running to determine if it was a parry or not.
var parry_timer: Timer = null

## Variable that stores the unhandled input
var unhandled_input = null

## Variable that stores if the player is holding down the left button.
var holding_left : bool = false

## Variable that stores if the player is holding down the right button.
var holding_right : bool = false

## Variable that stores if the player can perform any inputs.
var allow_inputs : bool = false

## Stores the actions and if they are currently being pressed or not.
var action_dictionary : Dictionary[String, bool] = {
	"up" : false,
	"down" : false,
	"left" : false,
	"right" : false,
	"block" : false,
	"block_upper" : false,
	"block_lower" : false,
	"star_punch" : false,
	"left_punch" : false,
	"right_punch" : false,
}
## A duplicate of [member action_dictionary] that is basically used to check if an action
## was JUST pressed/released and isnt being held down.
var stored_dictionary : Dictionary[String, bool] = {}

## Just stores the names of the different punches depending of if the player is holding up or not.
var punch_dictionary : Dictionary[bool, Array] = {
	false : ["left_low_punch", "right_low_punch", "star_punch_lower"],
	true : ["left_high_punch", "right_high_punch", "star_punch_upper"],
}

var run_stored_input : bool = false

func _ready() -> void:
	# Creates a new input buffer Timer on ready
	input_buffer_timer = TimerCreator.create_timer_and_add_as_child("InputBufferTimer", true, buffer_time, false, self)
	input_buffer_timer.timeout.connect(_on_input_buffer_timer_timeout)
	
	# Creates the parry timer
	parry_timer = TimerCreator.create_timer_and_add_as_child("ParryTimer", true, parry_window, false, self)
	
	FightManager.final_stun_hit_signal.connect(final_stun_hit)
	stored_dictionary = action_dictionary.duplicate()
	return
	
	## Don't allow inputs if it's playing a demo.
	#if DemoRecorder.status == DemoRecorder.RECORD_STATUS_ENUM.PLAYBACK:
		#allow_inputs = false
func _input(event: InputEvent) -> void:
	
	# For readability. Is true if it's currently recording a demo.
	var rec_status : bool = (DemoRecorder.status == DemoRecorder.RECORD_STATUS_ENUM.RECORDING)
	
	# For readability. Is true if the device that gave the input matches the simulated device ID.
	var device_match : bool = (event.device == DemoRecorder.SIMULATED_DEVICE_ID)
	
	# If inputs aren't allowed, don't bother running the rest of the function.
	if allow_inputs == false :
		return
		
	# Don't read inputs if they aren't simulated by the demo playback when playing a demo.
	# Basically, don't read player inputs when in a demo, and don't read demo inputs when recording.
	if rec_status == device_match:
		return
	
	# Loops through each action in the action dictionary.
	for action in action_dictionary:
		
		# Set the action as true in the action dictionary if it was just pressed.
		if Input.is_action_just_pressed(action):
			action_dictionary[action] = true
			#print("INPUT Demo Tick: ", DemoRecorder.tick)
			
		# Set the action as false in the action dictionary if it was just released.
		elif Input.is_action_just_released(action):
			action_dictionary[action] = false
			stored_dictionary[action] = false
			#print("INPUT Demo Tick: ", DemoRecorder.tick)

func _physics_process(_delta: float) -> void:
	
	# If inputs aren't allowed, don't bother running the rest of the function.
	if allow_inputs == false :
		return
	
	# Sets the value to be used for the block animation blend.
	var blend_vector : Vector2i = Vector2i( \
	int(action_dictionary["block"] or action_dictionary["block_upper"] or action_dictionary["block_lower"]), \
	int((action_dictionary["block"] and action_dictionary["up"]) or action_dictionary["block_upper"])\
	)
	
	owner.animation_tree.set("parameters/neutral/idle/blend_position", blend_vector)
	
	if action_dictionary["left"] == true:
		owner.animation_tree.set("parameters/dodge/dodge_left/dodge_blend_left/blend_position", Global.RangeEnum.LEFT)
	
	elif action_dictionary["right"] == true:
		owner.animation_tree.set("parameters/dodge/dodge_right/dodge_blend_right/blend_position", Global.RangeEnum.RIGHT)
		
	elif action_dictionary["down"] == true:
		owner.animation_tree.set("parameters/dodge/duck/duck_blend/blend_position", -1)
	
	# Sets the conditions of the dodge and duck animations depending on if the player is holding down that button or not.
	owner.animation_tree.set("parameters/dodge/dodge_left/conditions/holding_left", action_dictionary["left"])
	owner.animation_tree.set("parameters/dodge/dodge_right/conditions/holding_right", action_dictionary["right"])
	owner.animation_tree.set("parameters/dodge/duck/conditions/holding_down", action_dictionary["down"])
	
	# Loops through the 3 dodge actions
	for action in ["down", "left", "right"]:
		
		# Checks if the corresponding action is true in the action dictionary.
		if action_dictionary[action] == true and stored_dictionary[action] == false: 
			
			# If it IS true in the action dictionary, then run the perform action function.
			perform_action(action)
			stored_dictionary[action] = true
			return
			
	var block_status : bool = false
	
	# Loops through the 3 block actions
	for action in ["block", "block_upper", "block_lower"]:
		if action_dictionary[action] == true and stored_dictionary[action] == false:
			
			# If any of the block actions have been pressed, then the parry timer will start.
			block_status = true
			stored_dictionary[action] = true
			continue
	
	if block_status == true:
		parry_timer.start()
		
	
	var punch_array : Array[String] = ["left_punch", "right_punch", "star_punch"]
	
	# Loops through the 3 punch actions
	for i in range(punch_array.size()):
		if action_dictionary[punch_array[i]] == true and stored_dictionary[punch_array[i]] == false:
			
			var punch = punch_dictionary[action_dictionary["up"]][i]
			
			# If it IS true in the action dictionary, then run the perform action function.
			perform_action(punch)
			stored_dictionary[punch_array[i]] = true
			return
			
	# If the function to run an unhandled input was called,
	# Then perform the action that correspoonds to the unhandled input.
	if run_stored_input == true:
		perform_action(unhandled_input)
		unhandled_input = null
		run_stored_input = false
	
	# If there's an unhandled input and the input buffer timer hasn't been started, start it.
	if unhandled_input != null and input_buffer_timer.is_stopped() == true:
		input_buffer_timer.start()

## Emits a signal depending on the action that will be used by the player states.
func perform_action(action_name : String):
	
	#print("PHYSICS Demo Tick: ", DemoRecorder.tick)
	
	match action_name:
		"left_low_punch":
			attack_input_signal.emit(Global.HeightEnum.LOW, Global.RangeEnum.LEFT, "left_low_punch")
		"right_low_punch":
			attack_input_signal.emit(Global.HeightEnum.LOW, Global.RangeEnum.RIGHT, "right_low_punch")
		"left_high_punch":
			attack_input_signal.emit(Global.HeightEnum.HIGH, Global.RangeEnum.LEFT, "left_high_punch")
		"right_high_punch":
			attack_input_signal.emit(Global.HeightEnum.HIGH, Global.RangeEnum.RIGHT, "right_high_punch")
		"up":
			defense_input_signal.emit(Global.RangeEnum.NEUTRAL, "up")
		"down": # Ducking to avoid high attacks
			defense_input_signal.emit(Global.RangeEnum.NEUTRAL, "down")
		"left":
			defense_input_signal.emit(Global.RangeEnum.LEFT, "left")
		"right":
			defense_input_signal.emit(Global.RangeEnum.RIGHT, "right")
		"star_punch_lower":
			attack_input_signal.emit(Global.HeightEnum.LOW, Global.RangeEnum.NEUTRAL, "star_punch_lower")
		"star_punch_upper":
			attack_input_signal.emit(Global.HeightEnum.HIGH, Global.RangeEnum.NEUTRAL, "star_punch_upper")
		_:
			printerr("Input Component: Unnaccounted action.")
	return

## Stores the given action to then use it when requested.
func store_unhandled_input(action_name : String): 
	unhandled_input = action_name
	return

## Function called by specific animations.
## Automatically performs the stored unhandled input and then clears it.
func perform_buffered_action():
	if unhandled_input != null:
		run_stored_input = true
		
	return

## When the [member input_buffer_timer] runs out, clear the unhandled input
func _on_input_buffer_timer_timeout() -> void: 
	unhandled_input = null
	return

## Functions called by the dodge animations themselves.
## They reset the dodge blends back to zero.
func reset_blend_positions() -> void:
	owner.animation_tree.set("parameters/dodge_blend_left/blend_position", 0)
	owner.animation_tree.set("parameters/dodge_blend_right/blend_position", 0)
	owner.animation_tree.set("parameters/duck_blend/blend_position", 0)
	return

## This function is used so that players can't attack after the [Enemy] got hit on the last punch allowable of their [StunState].
## This is so that players don't throw another punch that won't land and waste stamina.
func final_stun_hit() -> void:
	
	# Disables inputs
	allow_inputs = false 
	
	# Waits until the enemy finishes the hit animation.
	await Global.enemy_node.animation_tree.animation_finished
	
	# Re-enables inputs after the enemy finishes the hit animation.
	allow_inputs = true 
	return








#func _physics_process(_delta: float) -> void:
	#
	#
	##print("Demo Tick: ", DemoRecorder.tick)
	#
	## If inputs aren't allowed, don't bother running the rest of the function.
	#if allow_inputs == false :
		#return
	#
	## Sets the value to be used for the block animation blend.
	#var blend_vector : Vector2i = Vector2i( \
	#int(Input.is_action_pressed("block") or Input.is_action_pressed("block_upper") or Input.is_action_pressed("block_lower")), \
	#int((Input.is_action_pressed("block") and Input.is_action_pressed("up")) or Input.is_action_pressed("block_upper"))\
	#)
	#
	#owner.animation_tree.set("parameters/neutral/idle/blend_position", blend_vector)
	#
	#if Input.is_action_pressed("left"):
		#owner.animation_tree.set("parameters/dodge/dodge_left/dodge_blend_left/blend_position", Global.RangeEnum.LEFT)
	#
	#elif Input.is_action_pressed("right"):
		#owner.animation_tree.set("parameters/dodge/dodge_right/dodge_blend_right/blend_position", Global.RangeEnum.RIGHT)
		#
	#elif Input.is_action_pressed("down"):
		#owner.animation_tree.set("parameters/dodge/duck/duck_blend/blend_position", -1)
	#
	## Sets the conditions of the dodge and duck animations depending on if the player is holding down that button or not.
	#owner.animation_tree.set("parameters/dodge/dodge_left/conditions/holding_left", Input.is_action_pressed("left"))
	#owner.animation_tree.set("parameters/dodge/dodge_right/conditions/holding_right", Input.is_action_pressed("right"))
	#owner.animation_tree.set("parameters/dodge/duck/conditions/holding_down", Input.is_action_pressed("down"))
	#
	## Ducking to avoid high attacks
	#if Input.is_action_just_pressed("down"): 
		#perform_action("down")
		#return
	#
	## Left Dodge
	#elif Input.is_action_just_pressed("left"):
		#perform_action("left")
		#return
	#
	## Right Dodge
	#elif Input.is_action_just_pressed("right"):
		#perform_action("right")
		#return
	#
	## Starts the parry timer if any of the block buttons are pressed.
	#if Input.is_action_just_pressed("block") or Input.is_action_just_pressed("block_upper") or Input.is_action_just_pressed("block_lower"):
		#parry_timer.start()
		#
	## If the player is NOT holding the Up button, check the low punches.
	#if Input.is_action_pressed("up") == false:
		#
		#if Input.is_action_just_pressed("left_punch"):
			#perform_action("left_low_punch")
			#return
			#
		#elif Input.is_action_just_pressed("right_punch"):
			#perform_action("right_low_punch")
			#return
			#
		#elif Input.is_action_just_pressed("star_punch"):
			#perform_action("star_punch_lower")
			#return
			#
	## If the player is already holding the Up button check the high punches
	#elif Input.is_action_pressed("up") == true:
		#
		#if Input.is_action_just_pressed("left_punch"):
			#perform_action("left_high_punch")
			#return
			#
		#elif Input.is_action_just_pressed("right_punch"):
			#perform_action("right_high_punch")
			#return
			#
		#elif Input.is_action_just_pressed("star_punch"):
			#perform_action("star_punch_upper")
			#return
#
### Emits a signal depending on the action that will be used by the player states.
#func perform_action(action_name : String):
	#match action_name:
		#"left_low_punch":
			#attack_input_signal.emit(Global.HeightEnum.LOW, Global.RangeEnum.LEFT, "left_low_punch")
		#"right_low_punch":
			#attack_input_signal.emit(Global.HeightEnum.LOW, Global.RangeEnum.RIGHT, "right_low_punch")
		#"left_high_punch":
			#attack_input_signal.emit(Global.HeightEnum.HIGH, Global.RangeEnum.LEFT, "left_high_punch")
		#"right_high_punch":
			#attack_input_signal.emit(Global.HeightEnum.HIGH, Global.RangeEnum.RIGHT, "right_high_punch")
		#"up":
			#defense_input_signal.emit(Global.RangeEnum.NEUTRAL, "up")
		#"down": # Ducking to avoid high attacks
			#defense_input_signal.emit(Global.RangeEnum.NEUTRAL, "down")
		#"left":
			#defense_input_signal.emit(Global.RangeEnum.LEFT, "left")
		#"right":
			#defense_input_signal.emit(Global.RangeEnum.RIGHT, "right")
		#"star_punch_lower":
			#attack_input_signal.emit(Global.HeightEnum.LOW, Global.RangeEnum.NEUTRAL, "star_punch_lower")
		#"star_punch_upper":
			#attack_input_signal.emit(Global.HeightEnum.HIGH, Global.RangeEnum.NEUTRAL, "star_punch_upper")
		#_:
			#printerr("Input Component: Unnaccounted action.")
	#return
