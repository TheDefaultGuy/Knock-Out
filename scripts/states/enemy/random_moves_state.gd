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

#var list_of_check_functions : Array[Callable] = []

#region The Ready, Enter and Exit functions.
func _init() -> void:
	state_type = STATE_TYPE_ENUM.SIMPLE
	attack_timer_required  = true

## Handles showing and hiding applicable exported variables
func _validate_property(property: Dictionary) -> void:
	update_shown_exported_variables(property)

func enter() -> void:
	print_rich("[color=orange]Enemy Entered State: [/color]", self.name)
	
	
	# Lets the Animation Tree know that the enemy is neither stunned nor spectating.
	animation_tree.set("parameters/idle/blend_position", 0)
	
	# Connects the enemy knocked down, player knocked down and stun signals.
	toggle_stunned_signal_connections() 
	
	# If the player or the enemy blocks an attack, it resets the attack delay timer
	# This is so that the timer doesn't accidently go off right after a block animation is playing.
	FightManager.successful_block_signal.connect(handle_block)
	
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
	
	toggle_stunned_signal_connections() # Disconnects the enemy knocked down, player knocked down and stun signals.
	
	FightManager.successful_block_signal.disconnect(handle_block)
	
	attack_timer.timeout.disconnect(perform_action)


func _process(_delta: float) -> void:
	if Engine.is_editor_hint(): # Doesnt run the check round time function when in the editor; only when in-game
		return
	if get_parent().current_state == self:
		check_all_assigned_conditions() # Runs all of the check condition functions that apply to this state.

	
#endregion
