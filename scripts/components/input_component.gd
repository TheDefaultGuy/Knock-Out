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
@export var final_stun_hit_attack_cooldown : float = 0.6

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


func _ready() -> void:
	# Creates a new input buffer Timer on ready
	input_buffer_timer = TimerCreator.create_timer("InputBufferTimer", true, buffer_time, false)
	input_buffer_timer.timeout.connect(_on_input_buffer_timer_timeout)
	add_child(input_buffer_timer)
	
	# Creates the parry timer
	parry_timer = TimerCreator.create_timer("ParryTimer", true, parry_window, false)
	add_child(parry_timer)
	
	FightManager.final_stun_hit_signal.connect(final_stun_hit)

func _process(_delta: float) -> void:
	
	# If inputs aren't allowed, don't bother running the rest of the function.
	if allow_inputs == false :
		return
	
	
	# Sets the value to be used for the block animation blend.
	var blend_vector : Vector2i = Vector2i( \
	int(Input.is_action_pressed("block") or Input.is_action_pressed("block_upper") or Input.is_action_pressed("block_lower")), \
	int((Input.is_action_pressed("block") and Input.is_action_pressed("up")) or Input.is_action_pressed("block_upper"))\
	)
	
	owner.animation_tree.set("parameters/neutral/idle/blend_position", blend_vector)
	
	if Input.is_action_pressed("left"):
		owner.animation_tree.set("parameters/dodge/dodge_left/dodge_blend_left/blend_position", Global.RangeEnum.LEFT)
	
	elif Input.is_action_pressed("right"):
		owner.animation_tree.set("parameters/dodge/dodge_right/dodge_blend_right/blend_position", Global.RangeEnum.RIGHT)
		
	elif Input.is_action_pressed("down"):
		owner.animation_tree.set("parameters/dodge/duck/duck_blend/blend_position", -1)
	
	# Sets the conditions of the dodge and duck animations depending on if the player is holding down that button or not.
	owner.animation_tree.set("parameters/dodge/dodge_left/conditions/holding_left", Input.is_action_pressed("left"))
	owner.animation_tree.set("parameters/dodge/dodge_right/conditions/holding_right", Input.is_action_pressed("right"))
	owner.animation_tree.set("parameters/dodge/duck/conditions/holding_down", Input.is_action_pressed("down"))

func _input(_event: InputEvent) -> void:
	if allow_inputs == false:
		return
	
	# Ducking to avoid high attacks
	if Input.is_action_just_pressed("down"): 
		perform_action("down")
	
	# Left Dodge
	elif Input.is_action_just_pressed("left"):
		perform_action("left")
	
	# Right Dodge
	elif Input.is_action_just_pressed("right"):
		perform_action("right")
	
	# Starts the parry timer if any of the block buttons are pressed.
	if Input.is_action_just_pressed("block") or Input.is_action_just_pressed("block_upper") or Input.is_action_just_pressed("block_lower"):
		parry_timer.start()
		
	# If the player is NOT holding the Up button, check the low punches.
	if Input.is_action_pressed("up") == false:
		
		if Input.is_action_just_pressed("left_punch"):
			perform_action("left_low_punch")
		elif Input.is_action_just_pressed("right_punch"):
			perform_action("right_low_punch")
			
		elif Input.is_action_just_pressed("star_punch"):
			perform_action("star_punch_lower")
			
	# If the player is already holding the Up button check the high punches
	elif Input.is_action_pressed("up") == true:
		
		if Input.is_action_just_pressed("left_punch"):
			perform_action("left_high_punch")
		elif Input.is_action_just_pressed("right_punch"):
			perform_action("right_high_punch")
			
		elif Input.is_action_just_pressed("star_punch"):
			perform_action("star_punch_upper")

## Emits a signal depending on the action that will be used by the player states.
func perform_action(action_name : String):
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
	input_buffer_timer.start()
	return

## Function called by specific animations.
## Automatically performs the stored unhandled input and then clears it.
func perform_buffered_action():
	if unhandled_input != null:
		perform_action(unhandled_input)
		unhandled_input = null
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
	
	allow_inputs = false # Disables inputs
	
	# Waits momentarily
	await get_tree().create_timer(final_stun_hit_attack_cooldown).timeout
	
	allow_inputs = true # Re-enables inputs after time is up/
	return
