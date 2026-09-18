class_name State extends Node

@warning_ignore("unused_signal")
## Signal called by the states when they want to transition out.
## First ar
signal transition_state(current_state, target_state)

@onready var health_component: HealthComponent = %HealthComponent

@onready var defense_component: DefenseComponent = %DefenseComponent

@onready var attacking_component: AttackingComponent = %AttackingComponent

@onready var animation_tree: AnimationTree = %AnimationTree

@onready var state_machine: StateMachine = %StateMachine

## The default/root animation state machine in the animation tree.
@onready var anim_state_machine = animation_tree["parameters/playback"]

## The Function that will run as soon as the state machine enters the state.
## Can be overwritten by extended state, but still be reliably called by the state machine.
func enter() -> void:
	pass
	
## The Function that will run right before the state machine exits the state.
## Can be overwritten by extended state, but still be reliably called by the state machine.
func exit() -> void:
	pass

#region Transition functions
func transition(target_state) -> void:
	transition_state.emit(self, target_state)

## Used to go back to the previously interrupted state. Mainly used to return from states like stunned, knocked down, tired or spectating.
func transition_to_previous_state() -> void:
	transition_state.emit(self, state_machine.interrupted_state)
	
## Function that transitions from the current state to the stunned state.
## Only used by the Enemy.
func transition_to_stunned() -> void:
	transition_state.emit(self, state_machine.stun_state)
	
## Function that transitions from the current state to the knocked down state.
## Used by both enemy and player
func transition_to_knocked_down() -> void:
	transition_state.emit(self, state_machine.knocked_down_state)
	
func transition_to_spectating() -> void:
	transition_state.emit(self, state_machine.spectating_state)
	
## Function that transitions from the current state to the tired state.
## Only used by the player.
func transition_to_tired() -> void:
	transition_state.emit(self, state_machine.tired_state)

## Function that transitions from the current state to the neutral state.
## Only used by the player.
func transition_to_neutral() -> void:
	transition_state.emit(self, state_machine.neutral_state)
#endregion
