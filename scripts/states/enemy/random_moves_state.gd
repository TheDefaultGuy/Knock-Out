@tool
@icon("res://assets/icons/WhhRandom.svg")
class_name RandomizedMoves extends EnemyState

## A state in which the [Enemy] will randomly choose an attack from a given list of attacks.
##
## In this state, the [Enemy] will randomly select an attack from the given list.
## You can choose how long the enemy waits until they perform an attack, which attacks, and the likelyhood of the attack
## You can also set conditions to transition to another state if desired.
## To make a new state based on this one, create a new state that inherits this one. [br]
##
## This is a template [EnemyState] used by [Enemy] boxers.
## To add it as a [State], add it as a child node to the [StateMachine] node in the enemy's scene.
## Then, tweak the exported variables to set it up how you'd like.
## DO NOT change anything in the actual .gd file, since it'll mess up compatibility.


#@export var condictionary : Dictionary[EnemyState.StateChangeConditionEnum, StateChangeConditions]
#@export var condarray : Array[StateChangeConditions] 
#
#@export var condictionaryNodepath : Dictionary[NodePath, StateChangeConditions]
#
#


func _process(_delta: float) -> void:
	if Engine.is_editor_hint(): # Only Runs the function in-game and not the editor
		return
	if state_machine.current_state == self:
		#print(attack_timer.time_left)
		#print(list_of_check_functions)
		check_all_assigned_conditions() # Runs all of the check condition functions that apply to this state.

func override_conditions_and_state_parameters() -> void:
	state_type = StateTypeEnum.SIMPLE
	attack_timer_required = true
