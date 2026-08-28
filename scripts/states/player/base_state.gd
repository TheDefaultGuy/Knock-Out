class_name State extends Node

@onready var move_set_anim: AnimationPlayer = %MoveSetAnim
@onready var health_component: HealthComponent = %HealthComponent
@onready var defense_component: DefenseComponent = %DefenseComponent
@onready var attacking_component: AttackingComponent = %AttackingComponent
@onready var animation_tree: AnimationTree = %AnimationTree


@warning_ignore("unused_signal")
signal transition_state


## The Function that will run as soon as the state machine enters the state.
## Can be overwritten by extended state, but still be reliably called by the state machine.
func enter():
	pass
## The Function that will run right before the state machine exits the state.
## Can be overwritten by extended state, but still be reliably called by the state machine.
func exit():
	pass

func _process(_delta: float) -> void:
	pass
	
func transition(current, target_state):
	transition_state.emit(current, target_state)

## Used to go back to the previously interrupted state. Mainly used to return from states like stunned, knocked down, tired or spectating.
func transition_to_previous_state():
	transition_state.emit(self, get_parent().interrupted_state)
	
## Function that transitions from the current state to the stunned state.
func transition_to_stunned():
	transition_state.emit(self, get_parent().stun_state)
	
## Function that transitions from the current state to the knocked down state.
func transition_to_knocked_down():
	transition_state.emit(self, get_parent().knocked_down_state)
	
func transition_to_spectating():
	transition_state.emit(self, get_parent().spectating_state)

func transition_to_tired():
	transition_state.emit(self, get_parent().tired_state)
