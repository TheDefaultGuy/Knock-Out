class_name PlayerState extends Node

@onready var health_component: HealthComponent = %HealthComponent
@onready var defense_component: DefenseComponent = %DefenseComponent
@onready var attacking_component: AttackingComponent = %AttackingComponent
@export var animation_tree: AnimationTree


@warning_ignore("unused_signal")
signal transition_state


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
	
func transition(target_state) -> void:
	transition_state.emit(self, target_state)

	
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
