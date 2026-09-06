class_name State extends Node

@onready var health_component: HealthComponent = %HealthComponent
@onready var defense_component: DefenseComponent = %DefenseComponent
@onready var attacking_component: AttackingComponent = %AttackingComponent
@onready var animation_tree: AnimationTree = %AnimationTree
@onready var anim_state_machine = animation_tree["parameters/playback"]

## Enum that stores all of the possible state change conditions.
enum STATE_CHANGE_CONDITION{
	## The enemy will change to the target state AFTER the specified amount of time has elapsed.
	## Different to At Round Time since this can happen at different points in the round.
	AFTER_TIME_PASSED,
	
	## The enemy will change to the target state AT the specified ROUND time.
	AT_ROUND_TIME,
	
	## The enemy will change to the target state after they've been knocked down.
	AFTER_ENEMY_KNOCKED_DOWN,
	
	## The enemy will change to the target state after the player has been knocked down.
	AFTER_PLAYER_KNOCKED_DOWN,
	
	## The enemy will change to the target state once the player is in the tired state.
	AFTER_PLAYER_TIRED,
	
	## The enemy will change to the target state when their health drops below a given value.
	AFTER_HEALTH_DROPS_BELOW,
	
	## The enemy will change to the target state once the player leaves the tired state.
	AFTER_PLAYER_NOT_TIRED,
	
	## The enemy will change to the target state after entering stun.
	AFTER_STUN,
	
	## The enemy will change to the target state after being hit with a star punch.
	#AFTER_STAR_PUNCH_LANDED,
	
	## The enemy will change to the target state after being hit with a star punch.
	#AFTER_STAR_PUNCH_MISSED,
	
	## The enemy will never change from this state.
	DO_NOT_CHANGE
}

@warning_ignore("unused_signal")
signal transition_state

func _ready() -> void:
	pass
	
## The Function that will run as soon as the state machine enters the state.
## Can be overwritten by extended state, but still be reliably called by the state machine.
func enter() -> void:
	pass
	
## The Function that will run right before the state machine exits the state.
## Can be overwritten by extended state, but still be reliably called by the state machine.
func exit() -> void:
	pass

#func _process(_delta: float) -> void:
	#return

#region Transition functions
func transition(current, target_state) -> void:
	transition_state.emit(current, target_state)

## Used to go back to the previously interrupted state. Mainly used to return from states like stunned, knocked down, tired or spectating.
func transition_to_previous_state() -> void:
	transition_state.emit(self, get_parent().interrupted_state)
	
## Function that transitions from the current state to the stunned state.
func transition_to_stunned() -> void:
	transition_state.emit(self, get_parent().stun_state)
	
## Function that transitions from the current state to the knocked down state.
func transition_to_knocked_down() -> void:
	transition_state.emit(self, get_parent().knocked_down_state)
	
func transition_to_spectating() -> void:
	transition_state.emit(self, get_parent().spectating_state)

func transition_to_tired() -> void:
	transition_state.emit(self, get_parent().tired_state)

## Function that transitions from the current state to the neutral state.
func transition_to_neutral() -> void:
	transition_state.emit(self, get_parent().neutral_state)
#endregion
