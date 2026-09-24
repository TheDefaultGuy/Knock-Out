@icon("res://assets/icons/StreamlineSleepSolid.svg")
class_name PlayerKnockedDown extends State

## The state in which the player has no health/is knocked down.
##
## The player can't attack, dodge, block or dodge.
## They can only attempt to get up by pressing attack buttons.

## Curve used to determine the [member get_up_decay_rate] by using the [member FightManager.player_ko_count].
## The more the [Player] has been knocked down, the harder it is to recover.
@export var get_up_difficulty_curve : Curve

## Value from 0.0 to the [param get_up_threshold] that determines how far the player is to recovering from a knockout and getting up.
@export var get_up_progress : float = 0.0

## How much does each button press increase the [param get_up_progress]
## Basically, how large is each step to get up.
@export var get_up_step_value : float = 10.0 

## How many units per second does the [param get_up_progress] decrease by.
## Basically, how hard it is to get up.
@export var base_decay_rate : float = 50.0

## The target value the player has to reach to recover from being knocked down.
@export var get_up_threshold : float = 100.0

@onready var input_component: InputComponent = %InputComponent

var get_up_decay_rate : float = 50.0

func _process(delta: float) -> void:
	if state_machine.current_state != self :
		return
	
	if owner.is_knocked_down == false : # Dont run if the player is no longer knocked down.
		return
	
	if FightManager.is_fight_over == false :
		get_up_progress = clampf(get_up_progress - get_up_decay_rate * delta, 0.0 , 110.0)
		animation_tree.set("parameters/get_up_blend/blend_position", get_up_progress)
		
		# When the get up progress reaches 100 or the get_up_threshold, the player succesfully gets back up.
		if get_up_progress >= get_up_threshold: 
			
			# Plays the get up animation
			animation_tree.set("parameters/conditions/gotup", true)
			
			# Resets HP and also emits tha the fighter is ready.
			health_component.reset_hp()
	return

func enter() -> void:
	print_rich("[color=yellow]Player Entered State: [/color]", self.name)
	
	animation_tree.set("parameters/conditions/gotup", false)
	
	get_up_progress = 0.0 # Resets getup progress to zero when entering
	
	# Waits until the enemy emits the signal so that the player can start getting up.
	await FightManager.fighter_can_start_getup_signal 
	
	# Starts the KO Timer as soon as the player can attempt to get up.
	FightManager.start_ko_count_signal.emit()
	
	animation_tree.animation_finished.connect(check_finished_animation)
	input_component.attack_input_signal.connect(perform_attack)
	
	FightManager.resume_fighting_signal.connect(transition_to_neutral)
	
	get_up_decay_rate = base_decay_rate * get_up_difficulty_curve.sample(float(FightManager.player_ko_count))

func exit() -> void:
	get_up_progress = 0.0
	input_component.attack_input_signal.disconnect(perform_attack)
	FightManager.resume_fighting_signal.disconnect(transition_to_neutral)
	animation_tree.animation_finished.disconnect(check_finished_animation)
	

func check_finished_animation(animation : String) -> void:
	if animation.contains("back_to_the_fight_2") == true :
		FightManager.player_ready_status = true
		print("PLAYER READY")
		FightManager.fighter_ready_signal.emit()

## When an attack input is Given by the [InputComponent], increase the [member get_up_progress].
func perform_attack(_height : int, _direction : int, _action_name : String):
	if FightManager.is_fight_over == false:
		get_up_progress += get_up_step_value
		
