@icon("res://assets/icons/WhhRandom.svg")
@tool
## A state in which the enemy will randomly choose an attack from a given list of attacks.
##
## In this state, the enemy will randomly select between a weighted list of moves.
## You can choose how long the enemy waits until they perform an attack, which attacks, and the likelyhood of the attack
## You can also set conditions to transition to another state if desired.
## To make a new state based on this one, create a new state that inherits this one.
##
## This is a template state used by enemy boxers.
## To add it as a state, add it as a child node to the State Machine node in the enemy's scene,
## Then, tweak the exported variables to set it up.
## DO NOT change anything in the actual .gd file, since it'll screw up compatibility HARD.
class_name RandomizedMoves extends EnemyState

@export_category("🎬 Animations & Moveset")

## What type of moveset is available in this state.
@export var moveset_type := MOVESET_TYPE_ENUM.WEIGHTED_DICTIONARY:
	set(value):
		if moveset_type != value:
			moveset_type = value
			notify_property_list_changed()

## The available animations that can be called by the attack timer in this state stored as a weighted Dictionary.
## The 1st variable or "key" is a string corresponding to the name of the move, and the 2nd variable corresponds to the weight or chance of that move.
@export var moveset_dictionary : Dictionary = {}

## The available animations that can be called by the attack timer in this state stored as an array.
@export var moveset_array : Array[String] = []

## The current index of the moveset array.
## Used so that it can loop back to the start and not look for a value beyond the range of the array
var moveset_index : int = 0

#region The Ready, Enter and Exit functions.
func _init() -> void:
	state_type = STATE_TYPE_ENUM.SIMPLE
	attack_timer_required  = true


func _ready() -> void:
	var moves_arr : Array = []
	
	if moveset_type == MOVESET_TYPE_ENUM.WEIGHTED_DICTIONARY and moveset_dictionary == {} and state_type == STATE_TYPE_ENUM.SIMPLE:
		printerr(self.name, " : Moveset Dictionary does NOT contain any attacks.")
	if moveset_type == MOVESET_TYPE_ENUM.PICK_RANDOM and moveset_array == [] and state_type == STATE_TYPE_ENUM.SIMPLE:
		printerr(self.name, " : Moveset Array does NOT contain any attacks.")
	if moveset_type == MOVESET_TYPE_ENUM.PREDETERMINED_ORDER and moveset_array == [] and state_type == STATE_TYPE_ENUM.SIMPLE:
		printerr(self.name, " : Moveset Array does NOT contain any attacks.")
		
	match moveset_type:
		MOVESET_TYPE_ENUM.WEIGHTED_DICTIONARY:
			moves_arr = moveset_dictionary.keys()
		MOVESET_TYPE_ENUM.PICK_RANDOM:
			moves_arr = moveset_array
		MOVESET_TYPE_ENUM.PREDETERMINED_ORDER:
			moves_arr = moveset_array
			
	parent_state_machine_node = get_parent()
	
	conditions_and_targets_dict = {
		primary_condition: primary_target_state,
		secondary_condition: secondary_target_state,
		tertiary_condition: tertiary_target_state
		}
	
	current_animation_state_machine = anim_state_machine
	

	if STATE_CHANGE_CONDITION.AFTER_TIME_PASSED in conditions_and_targets_dict.keys():
		state_change_timer = create_timer("Wait Timer", true, time_to_wait)
		add_child(state_change_timer)
		
	if attack_timer_required == true: # Creates and adds the attack timer as a child and connects it if it's required for the state.
		attack_timer = create_timer("Attack Delay Timer", false, max_wait_time)
		add_child(attack_timer)
		
	check_for_unassigned_variables()
	
	call_deferred("add_attack_animation_nodes", animation_tree.tree_root, moves_arr)
	
## Handles showing and hiding applicable exported variables
func _validate_property(property: Dictionary) -> void:
	update_shown_exported_variables(property)
	if property.name == "moveset_dictionary" and (moveset_type != MOVESET_TYPE_ENUM.WEIGHTED_DICTIONARY or moveset_type == MOVESET_TYPE_ENUM.NOT_APPLICABLE):
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "moveset_array" and (moveset_type not in [MOVESET_TYPE_ENUM.PICK_RANDOM, MOVESET_TYPE_ENUM.PREDETERMINED_ORDER] or moveset_type == MOVESET_TYPE_ENUM.NOT_APPLICABLE):
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "moveset_dictionary" and (moveset_type != MOVESET_TYPE_ENUM.WEIGHTED_DICTIONARY or moveset_type == MOVESET_TYPE_ENUM.NOT_APPLICABLE):
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "moveset_array" and (moveset_type not in [MOVESET_TYPE_ENUM.PICK_RANDOM, MOVESET_TYPE_ENUM.PREDETERMINED_ORDER] or moveset_type == MOVESET_TYPE_ENUM.NOT_APPLICABLE):
		property.usage = PROPERTY_USAGE_NONE

func enter() -> void:
	print_rich("[color=orange]Enemy Entered State: [/color]", self.name)
	
	# Lets the Animation Tree know that the enemy is neither stunned nor spectating.
	animation_tree.set("parameters/idle/blend_position", 0)
	
	# Connects the enemy knocked down, player knocked down and stun signals.
	toggle_important_state_signal_connections() 
	
	# If the player or the enemy blocks an attack, it resets the attack delay timer
	# This is so that the timer doesn't accidently go off right after a block animation is playing.
	FightManager.succesful_block_signal.connect(handle_block)
	
	attack_timer.timeout.connect(perform_action)

	
	# Sets the interrupted state in the state machine as itself.
	# That way, if it gets interrupted by another state like stunned, it'll come back to this one.
	get_parent().interrupted_state = self 
	
	# Starts the attack delay timer so that the enemy can start attacking.
	start_attack_delay_timer()
	
	# Toggles the state change timer.
	# If it stopped or wasn't started, then it starts it.
	# If it was already started, the it toggles pause.
	toggle_state_change_timer()
	
func exit() -> void:
	attack_timer.stop() # Full on stops the attack timer since it's leaving the state.
	toggle_state_change_timer()
	
	toggle_important_state_signal_connections() # Disconnects the enemy knocked down, player knocked down and stun signals.
	
	FightManager.succesful_block_signal.disconnect(handle_block)
	
	attack_timer.timeout.disconnect(perform_action)
	

	
func _process(_delta: float) -> void:
	if Engine.is_editor_hint(): # Doesnt run the check round time function when in the editor; only when in-game
		return
	if get_parent().current_state == self:
		check_round_time()
		check_player_stamina()
		check_time_has_passed()
		check_enemy_health()
		check_for_knockdowns()
		#print("STATE CHANGE TIME LEFT: ", state_change_timer.time_left)
	
#endregion


## Performs an action, animation or attack after the attack timer has finished.
func perform_action() -> void:
	match moveset_type:
		MOVESET_TYPE_ENUM.WEIGHTED_DICTIONARY:
			current_animation_state_machine.travel(get_weighted_choice(moveset_dictionary))
			
			await animation_tree.animation_finished # Waits for the attack animation to finish before restarting the attack delay timer.
			start_attack_delay_timer() # Resets the attack delay timer after attacking
			return
		MOVESET_TYPE_ENUM.PICK_RANDOM:
			if moveset_array.size() == 1: # If theres only 1 move in the array, just choose it.
				current_animation_state_machine.travel(moveset_array[0])
				await animation_tree.animation_finished # Waits for the attack animation to finish before restarting the attack delay timer.
				start_attack_delay_timer() # Resets the attack delay timer after attacking
				return
				
			current_animation_state_machine.travel(moveset_array.pick_random())
			await animation_tree.animation_finished # Waits for the attack animation to finish before restarting the attack delay timer.
			start_attack_delay_timer() # Resets the attack delay timer after attacking
			return
			
		MOVESET_TYPE_ENUM.PREDETERMINED_ORDER:
			if moveset_array.size() == 1: # If theres only 1 move in the array, just choose it.
				current_animation_state_machine.travel(moveset_array[0])
				await animation_tree.animation_finished # Waits for the attack animation to finish before restarting the attack delay timer.
				start_attack_delay_timer() # Resets the attack delay timer after attacking
				return
				
			moveset_index = (moveset_index + 1) % moveset_array.size() # Wraps back to 0 if it reaches the end.
			current_animation_state_machine.travel(moveset_array[moveset_index])
			await animation_tree.animation_finished # Waits for the attack animation to finish before restarting the attack delay timer.
			start_attack_delay_timer() # Resets the attack delay timer after attacking
			return
		_:
			printerr(self.name ," Fallback condition on the perform action function.")

## Does the weight calculation and chooses a random move from the move set dictionary
func get_weighted_choice(weight_dict: Dictionary) -> String:
	
	# Calculates the sum of all weights
	var total_weight : float = 0.0
	
	for weight in weight_dict.values():
		total_weight += weight
	
	# Picks a random number between 0 and the total weight
	var random_value : float = randf_range(0.0, total_weight)
	
	# Goes through the dictionary to find which bracket the roll falls into
	for attack in weight_dict:
		var weight : float = weight_dict[attack]
		
		if random_value < weight:
			return attack # The chosen attack.
			
		random_value -= weight # Shrink the remaining roll value
	
	return str(weight_dict.keys().back()) # Fallback edge case
