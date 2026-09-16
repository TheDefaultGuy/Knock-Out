@icon("res://assets/icons/AtIconsComedyMask.svg")
@tool
## This is a template state used by enemy boxers.
## In this state, the enemy will keep looping the same animation, but react to the player's attacks.
## This is used to recreate boxers like Don Flamenco, where they taunt and only attack when attacked at first.
## You can set conditions to transition to another state if desired.
##
## This is a template state used by enemy boxers.
## To add it as a state, add it as a child node to the State Machine node in the enemy's scene,
## Then, tweak the exported variables to set it up.
## DO NOT change anything in the actual .gd file, since it'll screw up compatibility HARD.
class_name TauntAndCounter extends EnemyState

@export var taunt_animation : String = "taunt"
@export var counter_attack : String = "counter_uppercut"

#region The Ready, Enter and Exit functions.
	
func _init() -> void:
	state_type = STATE_TYPE_ENUM.SIMPLE
	attack_timer_required = true

	moveset_array = [taunt_animation, counter_attack]
	moveset_type = MOVESET_TYPE_ENUM.PREDETERMINED_ORDER
	block_behavior = BLOCK_BEHAVIOR_ENUM.NOT_APPLICABLE
	primary_condition = STATE_CHANGE_CONDITION.AFTER_PLAYER_TIRED
	
func _enter_tree() -> void:
	primary_condition = STATE_CHANGE_CONDITION.AFTER_PLAYER_TIRED
	
func _validate_property(property: Dictionary) -> void: 
	update_shown_exported_variables(property)


func enter() -> void: # Blank enter and exit functions that get overridden by each state's own custom enter and exit functions.
	print_rich("[color=orange]Enemy Entered State: [/color]", self.name)

	current_animation_state_machine = animation_tree["parameters/playback"]

	start_attack_delay_timer()
	
	# Sets the interrupted state in the state machine as itself.
	# That way, if it gets interrupted by another state like stunned, it'll come back to this one.
	get_parent().interrupted_state = self 
	
	# Connects the enemy knocked down, player knocked down and stun signals.
	toggle_stunned_signal_connections()
	
	FightManager.successful_block_signal.connect(throw_counter_punch)
	
	# Toggles on the state change timer.
	toggle_state_change_timer()
	
	attack_timer.timeout.connect(perform_action)
	

func exit() -> void:
	attack_timer.timeout.disconnect(perform_action)
		
	toggle_stunned_signal_connections()
	
	FightManager.successful_block_signal.disconnect(throw_counter_punch)

## Waits for the block animation to finish, then does the counter attack.
func throw_counter_punch():
	await animation_tree.animation_finished
	play_attack_start_attack_timer(counter_attack)

## plays the taunt animation
func perform_action() -> void:
	play_attack_start_attack_timer(taunt_animation)

func _process(_delta: float) -> void:
	if Engine.is_editor_hint(): #Doesnt run the check round time function when in the editor; only when in-game
		return
	if get_parent().current_state == self:
		check_all_assigned_conditions() # Runs all of the check condition functions that apply to this state.
		
	#print("Nested current node: ", animation_tree[str("parameters/",nested_machine_name,"/playback")].get_current_node())
#endregion
