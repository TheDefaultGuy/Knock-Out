@icon("res://assets/icons/IntroLoop.svg")
@tool
## This is a template state used by enemy boxers.
##
## In this state, the enemy will first perform an intro animation,
## and then loop another animation or a series of animations over and over until either they or the player are knocked down.
## This should be used to recreate attacks like Bald Bull's Bull Rush, where the enemy won't stop until somebody is knocked down.
##
## This is a template state used by enemy boxers.
## To add it as a state, add it as a child node to the State Machine node in the enemy's scene,
## Then, tweak the exported variables to set it up.
## DO NOT change anything in the actual .gd file, since it'll screw up compatibility HARD.
class_name IntroThenLoops extends EnemyState


#region The Ready, Enter and Exit functions
func _init() -> void:
	state_type = STATE_TYPE_ENUM.NESTED_STATE_MACHINE
	attack_timer_required  = true
	nested_state_machine = preload("uid://bpl60rtp2gv5i")



	if primary_target_state == null and secondary_target_state != null:
		primary_target_state = secondary_target_state
		push_warning(self.name, " Primary target state wasn't set, but used the secondary target state as a fallback.")
	if secondary_target_state == null and primary_target_state != null:
		secondary_target_state = primary_target_state
		push_warning(self.name, " Secondary target state wasn't set, but used the primary target state as a fallback.")
		
func _enter_tree() -> void:
	# Given the nature of this state, these 2 conditions MUST ALWAYS be set and have a target state to transition to.
	primary_condition = STATE_CHANGE_CONDITION.AFTER_PLAYER_KNOCKED_DOWN
	secondary_condition = STATE_CHANGE_CONDITION.AFTER_ENEMY_KNOCKED_DOWN
	
	## Handles showing and hiding applicable exported variables
func _validate_property(property: Dictionary) -> void:
	update_shown_exported_variables(property)


func enter() -> void:
	print_rich("[color=orange]Enemy Entered State: [/color]", self.name)
	
	toggle_important_state_signal_connections()
	
	current_animation_state_machine = animation_tree[str("parameters/",nested_machine_name,"/playback")]

	# Sets the interrupted state in the state machine as itself.
	# That way, if it gets interrupted by another state like stunned, it'll come back to this one.
	get_parent().interrupted_state = self
	
	# Travels to the nested state machine from the Root node
	anim_state_machine.travel(nested_machine_name)
	
	# Connects the attack timer so that the enemy can perform actions.
	attack_timer.timeout.connect(perform_action)
	
	# Starts the attack delay timer so that the enemy can start attacking.
	start_attack_delay_timer()
	
func exit() -> void:
	toggle_important_state_signal_connections()
	attack_timer.timeout.disconnect(perform_action)
#endregion

func perform_action()-> void:
	current_animation_state_machine.travel("attack")
	await animation_tree.animation_finished # Waits for the attack animation to finish before restarting the attack delay timer.
	start_attack_delay_timer()
	
func _process(_delta: float) -> void:
	if Engine.is_editor_hint(): # Doesnt run the check round time function when in the editor; only when in-game
		return
	if get_parent().current_state == self or get_parent().current_state is EnemySpectating:
		animation_tree.set(str("parameters/",nested_machine_name,"/conditions/ko"), Global.player_node.isKnockdown)
	if get_parent().current_state == self:
		check_for_knockdowns()
