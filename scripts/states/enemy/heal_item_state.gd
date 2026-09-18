@icon("res://assets/icons/PinheadPillBottleWithGreekCross.svg")
@tool

class_name ItemHeal extends EnemyState

## A state in which the enemy will attempt to heal with an item,
## similar to Doc Louis with his chocolate and Soda Popinski with his "Soda".
##
## In this state, the enemy will first perform an intro animation,
## and then play a number of consecutive attacks, equal to the number of attacks given.
## Then, it will change state depending on if the player was knocked out, or survived.[br]
##
## This is a template [EnemyState] used by [Enemy] boxers.
## To add it as a [State], add it as a child node to the [StateMachine] node in the enemy's scene.
## Then, tweak the exported variables to set it up how you'd like.
## DO NOT change anything in the actual .gd file, since it'll mess up compatibility.


#region The Ready, Enter and Exit functions
func _init() -> void:
	state_type = STATE_TYPE_ENUM.NESTED_STATE_MACHINE
	attack_timer_required  = false
	nested_state_machine = preload("uid://dt6b8hv77b0dh")
	
	block_behavior = BLOCK_BEHAVIOR_ENUM.NOT_APPLICABLE
	
	# Given the nature of this state, these 2 conditions MUST ALWAYS be enabled and have corresponding target states.
	primary_condition = STATE_CHANGE_CONDITION.AFTER_COMPLETION
	secondary_condition = STATE_CHANGE_CONDITION.STATE_INTERRUPTED
	
	if secondary_target_state == null and primary_target_state != null:
		secondary_target_state = primary_target_state
		printerr(self.name, " does NOT have secondary target state set, but has used the primary target state as a fallback.")
		

func enter() -> void:
	super() # Runs the base EnemyState enter function and then runs everything below.
	
	FightManager.succesful_hit_signal.connect(change_to_failed_state)
	
	# Sets the hit animation and state machine in the defense component as the hit animation in the state machine.
	# This is because the defense component is the one responsible for playing the hit animation
	defense_component.current_hit_animation = "item_hit"
	defense_component.current_anim_state_machine = current_animation_state_machine

func exit() -> void:
	super() # Runs the base EnemyState exit function and then runs everything below.
	
	FightManager.succesful_hit_signal.disconnect(change_to_failed_state)
	interruption_status = false

#endregion

## If the player got hit, then the interrupted state will be set to the failed healed state.
func change_to_failed_state() -> void:
	interruption_status = true
