@icon("res://assets/icons/WhhRandom.svg")
@tool
## This is a template state used by enemy boxers.
##
## In this state, the enemy will randomly select between a weighted list of moves.
## You can choose how long the enemy waits until they perform an attack, which attacks, and the likelyhood of the attack
## You can also set conditions to transition to another state if desired.
## To make a new state based on this one, create a new state that inherits this one.
class_name RandomizedMovesState extends State

@onready var anim_state_machine = animation_tree["parameters/playback"]

#region Exported Variables and function that handles which variables to show
@export_category("🎬 Animations & Moveset")
## The available moves in this state.
## The 1st variable or "key" is a string corresponding to the name of the move, and the 2nd variable corresponds to the weight or chance of that move.
@export var moveset : Dictionary[String, float]
## The idling animation that will play in this state.
@export var idle_animation : String = "idle"



enum ATTACK_DELAY{
	## Chooses a float value between the minimum and maximum wait time.
	FLOAT,
	
	## Randomly chooses from an array of predetermined values.
	PREDETERMINED
}
## Enum that stores all of the possible state change conditions.
enum STATE_CHANGE_CONDITION{
	## The enemy will change to the target state AT the specified ROUND time.
	AT_ROUND_TIME,
	
	## The enemy will change to the target state after they've been knocked down.
	AFTER_ENEMY_KNOCKED_DOWN,
	
	## The enemy will change to the target state after the player has been knocked down.
	AFTER_PLAYER_KNOCKED_DOWN,
	
	## The enemy will change to the target state AFTER the specified amount of time has elapsed.
	## Different to At Round Time since this can happen at different points in the round.
	AFTER_TIME_PASSED,
	
	## The enemy will change to the target state once the player is in the tired state.
	AFTER_PLAYER_TIRED,
	
	## The enemy will never change from this state.
	DO_NOT_CHANGE
}

## What to do when either the player or the enemy blocks an attack.
enum BLOCK_BEHAVIOR{
	## When a block occurs, it momentarily pauses the attack delay timer and then resumes after the block animation has finished.
	PAUSE_TIMER,
	## When a block occurs, it fully resets the attack delay timer. This can cause potential indefinite stalling.
	RESET_TIMER
}



@export_category("⏱ Attack Delays")
## What to do when an attack is blocked when in this state.
@export var block_behavior := BLOCK_BEHAVIOR.PAUSE_TIMER
## A Multipurpose timer that can be used by various states.
@export var general_timer : Timer
## How the delay between each attack is handled.
@export var attack_delay_type := ATTACK_DELAY.FLOAT: 
	set(value):
		attack_delay_type = value
		notify_property_list_changed()
		
## The minimum amount of time (in seconds) the enemy will wait before randomly choosing a move.
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var min_wait_time : float = 1.0
## The maximum amount of time (in seconds) the enemy will wait before randomly choosing a move.
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var max_wait_time : float = 3.0

@export_custom(PROPERTY_HINT_NONE, "suffix:s") var attack_delay_array : Array[float]

@export_category("⇄ State Changing Conditions")
## The primary condition for changing state and the first one being checked.
##
## If the condition is met, it will transition to the primary target state.
## If it's not, it will check the secondary condition.
@export var primary_condition := STATE_CHANGE_CONDITION.AT_ROUND_TIME: 
	set(value):
		primary_condition = value
		notify_property_list_changed()
	
## The secondary condition for changing state and the second one being checked.
##
## If the condition is met, it will transition to the secondary target state.
@export var secondary_condition := STATE_CHANGE_CONDITION.DO_NOT_CHANGE:
	set(value2):
		secondary_condition = value2
		notify_property_list_changed()
		
## The state the enemy will transition to after the primary condition is met.
@export var primary_target_state : State
## The state the enemy will transition to after the secondary condition is met.
@export var secondary_target_state : State
## The time in the round (in seconds) where the enemy changes to the target state.
@export_range(10.0, 180.0, 1.0, "suffix:s") var target_round_time : float
## The amount of time the enemy waits (in seconds) before changing to the target state.
@export_range(1.0, 90.0, 1.0, "suffix:s") var time_to_wait : float
## Timer used to transition to the target state.
@export var wait_timer : Timer



## Handles showing and hiding applicable exported variables
func _validate_property(property: Dictionary) -> void: 
	if property.name == "target_round_time" and primary_condition != STATE_CHANGE_CONDITION.AT_ROUND_TIME and secondary_condition != STATE_CHANGE_CONDITION.AT_ROUND_TIME :
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "time_to_wait" and primary_condition != STATE_CHANGE_CONDITION.AFTER_TIME_PASSED and secondary_condition != STATE_CHANGE_CONDITION.AFTER_TIME_PASSED :
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "min_wait_time" and attack_delay_type != ATTACK_DELAY.FLOAT :
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "max_wait_time" and attack_delay_type != ATTACK_DELAY.FLOAT :
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "attack_delay_array" and attack_delay_type != ATTACK_DELAY.PREDETERMINED :
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "wait_timer" and primary_condition != STATE_CHANGE_CONDITION.AFTER_TIME_PASSED and secondary_condition != STATE_CHANGE_CONDITION.AFTER_TIME_PASSED :
		property.usage = PROPERTY_USAGE_NONE
#endregion

func _ready() -> void:
	if general_timer == null:
		printerr(self.name, " : General Timer not set.")
	
	if wait_timer != null:
		wait_timer.wait_time = time_to_wait
		wait_timer.one_shot = true
#region The enter and exit functions.
func enter():
	print_rich("[color=orange]Enemy Entered State: [/color]", self.name)
	
	# Lets the Animation Tree now that the enemy is neither stunned nor spectating.
	animation_tree.set("parameters/conditions/stunned", false)
	animation_tree.set("parameters/conditions/spectating", false)
	
	start_attack_delay_timer()
	general_timer.timeout.connect(perform_action)
	anim_state_machine.travel(idle_animation)
	
	# Sets the interrupted state in the state machine as itself.
	# That way, if it gets interrupted by another state like stunned, it'll come back to this one.
	get_parent().interrupted_state = self 
	
	FightManager.player_knocked_down_signal.connect(transition_to_spectating)
	FightManager.enemy_knocked_down_signal.connect(transition_to_knocked_down)
	
	FightManager.player_knocked_down_signal.connect(check_state_change_condition.bind(FightManager.player_knocked_down_signal.get_name()))
	FightManager.enemy_knocked_down_signal.connect(check_state_change_condition.bind(FightManager.player_knocked_down_signal.get_name()))
	FightManager.no_stamina_signal.connect(check_state_change_condition.bind(FightManager.player_knocked_down_signal.get_name()))
	
	# If the player or the enemy blocks an attack, it resets the attack delay timer
	# This is so that the timer doesn't accidently go off right after a block animation is playing.
	FightManager.succesful_block_signal.connect(handle_block)
	
	if wait_timer != null:
		wait_timer.start()
		wait_timer.timeout.connect(_on_wait_timer_timeout)
	defense_component.stunned_signal.connect(transition_to_stunned)
	
	if primary_target_state == null and primary_condition != STATE_CHANGE_CONDITION.DO_NOT_CHANGE:
		printerr(self.name, " : Primary Target State not set.")
	if secondary_target_state == null and secondary_condition != STATE_CHANGE_CONDITION.DO_NOT_CHANGE:
		push_warning(self.name, " : Secondary Target State not set.")
	if animation_tree == null:
		printerr(self.name, " : Animation tree not set.")
	if primary_condition == STATE_CHANGE_CONDITION.AFTER_TIME_PASSED or secondary_condition == STATE_CHANGE_CONDITION.AFTER_TIME_PASSED:
		if wait_timer == null:
			printerr(self.name, " : Wait Timer not set.")
	pass
func exit():
	general_timer.timeout.disconnect(perform_action)
	FightManager.player_knocked_down_signal.disconnect(transition_to_spectating)
	FightManager.enemy_knocked_down_signal.disconnect(transition_to_knocked_down)
	defense_component.stunned_signal.disconnect(transition_to_stunned)
	FightManager.player_knocked_down_signal.disconnect(check_state_change_condition)
	FightManager.enemy_knocked_down_signal.disconnect(check_state_change_condition)
	FightManager.no_stamina_signal.disconnect(check_state_change_condition)
	FightManager.succesful_block_signal.disconnect(handle_block)
	
	general_timer.stop()
	
	if wait_timer != null: # Shenanigans to pause the wait timer when transitioning to another scene.
		wait_timer.stop()
		if wait_timer.time_left <= 0:
			wait_timer.wait_time = time_to_wait
		else:
			wait_timer.wait_time = wait_timer.time_left
		wait_timer.timeout.disconnect(_on_wait_timer_timeout)
	pass
#endregion

## Starts the attack delay timer using a random time.
##
## This function is called right after performing an attack and after the player or the enemy blocks.
func start_attack_delay_timer():
	if attack_delay_type == ATTACK_DELAY.FLOAT:
		general_timer.start(randf_range(min_wait_time, max_wait_time)) # Starts the timer when entering the state and sets a random wait time.
	elif attack_delay_type == ATTACK_DELAY.PREDETERMINED:
		general_timer.start(attack_delay_array.pick_random())
		
## Function called when a block occurs.
func handle_block():
	if block_behavior == BLOCK_BEHAVIOR.RESET_TIMER:
		start_attack_delay_timer()
	elif block_behavior == BLOCK_BEHAVIOR.PAUSE_TIMER:
		toggle_attack_delay_timer()
		await get_tree().create_timer(0.5).timeout
		toggle_attack_delay_timer()
		
## Pauses and unpauses the attack delay timer.
func toggle_attack_delay_timer():
	general_timer.paused = !general_timer.paused

## Does the weight calculation and chooses a random move from the move set dictionary
func get_weighted_choice(weight_dict: Dictionary):
	# Calculate the total sum of all weights
	var total_weight: float = 0.0
	for weight in weight_dict.values():
		total_weight += weight
	
	# Pick a random number between 0 and the total weight
	var rolled_value: float = randf_range(0.0, total_weight)
	
	# Goes through the dictionary to find which bracket the roll falls into
	for key in weight_dict:
		var weight: float = weight_dict[key]
		if rolled_value < weight:
			return key # Found our item!
		rolled_value -= weight # Shrink the remaining roll value
	
	return weight_dict.keys().back() # Fallback edge case


func perform_action():
	var move = str(get_weighted_choice(moveset)).replace('"', "") # Formats the move name to be usable since it comes with quoation marks for some reason.
	anim_state_machine.travel(move) 
	start_attack_delay_timer()

func _process(_delta: float) -> void:
	if Engine.is_editor_hint(): # Doesnt run the check round time function when in the editor; only when in-game
		return
	check_round_time()
	
## Checks to see if the current round time matches the specified round time to change state.
func check_round_time(): 
	if primary_condition == STATE_CHANGE_CONDITION.AT_ROUND_TIME:
		if FightManager.round_time >= target_round_time:
			transition(self, primary_target_state)
	elif secondary_condition == STATE_CHANGE_CONDITION.AT_ROUND_TIME:
		if FightManager.round_time >= target_round_time:
			transition(self, secondary_target_state)

## Changes to the condition's target state after the waiting time has elapsed.
func _on_wait_timer_timeout():
	if primary_condition == STATE_CHANGE_CONDITION.AFTER_TIME_PASSED:
		transition(self, primary_target_state)
	elif secondary_condition == STATE_CHANGE_CONDITION.AFTER_TIME_PASSED:
		transition(self, secondary_target_state)

## Matches the signal received to the condition and then changes to the state of the matching condition.
func check_state_change_condition(signal_name : StringName):
	match signal_name:
		#STATE_CHANGE_CONDITION.AT_ROUND_TIME:
		"enemy_knocked_down_signal":
			if primary_condition == STATE_CHANGE_CONDITION.AFTER_ENEMY_KNOCKED_DOWN:
				get_parent().interrupted_state = primary_target_state
			elif secondary_condition == STATE_CHANGE_CONDITION.AFTER_ENEMY_KNOCKED_DOWN:
				get_parent().interrupted_state = secondary_target_state
				
		"player_knocked_down_signal":
			if primary_condition == STATE_CHANGE_CONDITION.AFTER_PLAYER_KNOCKED_DOWN:
				get_parent().interrupted_state = primary_target_state
			elif secondary_condition == STATE_CHANGE_CONDITION.AFTER_PLAYER_KNOCKED_DOWN:
				get_parent().interrupted_state = secondary_target_state
				
		"no_stamina_signal":
			if primary_condition == STATE_CHANGE_CONDITION.AFTER_PLAYER_TIRED: 
				transition(self, primary_target_state)
			elif secondary_condition == STATE_CHANGE_CONDITION.AFTER_PLAYER_TIRED:
				transition(self, secondary_target_state)
