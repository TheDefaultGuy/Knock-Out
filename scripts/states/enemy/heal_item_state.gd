@icon("res://assets/icons/PinheadPillBottleWithGreekCross.svg")
@tool

class_name ItemHeal extends EnemyState

## A state in which the enemy will attempt to heal with an item,
## similar to Doc Louis with his chocolate and Soda Popinski with his "Soda".
##
## In this state, the enemy will first perform an intro animation,
## and then play a number of consecutive attacks, equal to the number of attacks given.
## Then, it will change state depending on if the player was knocked out, or survived.
##
## This is a template state used by enemy boxers.
## To add it as a state, add it as a child node to the State Machine node in the enemy's scene,
## Then, tweak the exported variables to set it up.
## DO NOT change anything in the actual .gd file, since it'll screw up compatibility HARD.


#region The Ready, Enter and Exit functions
func _init() -> void:
	state_type = STATE_TYPE_ENUM.NESTED_STATE_MACHINE
	attack_timer_required  = false
	nested_state_machine = preload("uid://dt6b8hv77b0dh")
	
	# Given the nature of this state, these 2 conditions MUST ALWAYS be enabled and have corresponding target states.
	primary_condition = STATE_CHANGE_CONDITION.AFTER_COMPLETION
	secondary_condition = STATE_CHANGE_CONDITION.STATE_INTERRUPTED
	
	if secondary_target_state == null and primary_target_state != null:
		secondary_target_state = primary_target_state
		printerr(self.name, " does NOT have secondary target state set, but has used the primary target state as a fallback.")
		
func _enter_tree() -> void:
	# Given the nature of this state, these 2 conditions MUST ALWAYS be enabled and have corresponding target states.
	primary_condition = STATE_CHANGE_CONDITION.AFTER_COMPLETION
	secondary_condition = STATE_CHANGE_CONDITION.STATE_INTERRUPTED

func _process(_delta: float) -> void:
	if Engine.is_editor_hint(): # Doesnt run the check round time function when in the editor; only when in-game
		return
	if get_parent().current_state == self:
		check_all_assigned_conditions() # Runs all of the check condition functions that apply to this state.

func enter() -> void:
	print_rich("[color=orange]Enemy Entered State: [/color]", self.name)

	anim_state_machine.travel(nested_machine_name)
	
	current_animation_state_machine = animation_tree[str("parameters/",nested_machine_name,"/playback")]
	
	#defense_component.upper_damage_multiplier = 0.0
	#defense_component.lower_damage_multiplier = 0.0
	
	FightManager.succesful_hit_signal.connect(change_to_failed_state)
	
	toggle_stunned_signal_connections()
	
	# Sets the hit animation and state machine in the defense component as the hit animation in the state machine.
	# This is because the defense component is the one responsible for playing the hit animation
	defense_component.current_hit_animation = "item_hit"
	defense_component.current_anim_state_machine = current_animation_state_machine


## Handles showing and hiding applicable exported variables
func _validate_property(property: Dictionary) -> void:
	update_shown_exported_variables(property)
	
func exit() -> void:
	toggle_stunned_signal_connections()
	
	FightManager.succesful_hit_signal.disconnect(change_to_failed_state)
	
	# Resets the hit animation and state machine in the defense component back to the default hit animation.
	defense_component.reset_current_animations()
	interruption_status = false

#endregion

## If the player got hit, then the interrupted state will be set to the failed healed state.
func change_to_failed_state() -> void:
	interruption_status = true
