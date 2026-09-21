@icon("res://assets/icons/RiBoxingFill.svg")
## The base class for all boxers/fighters, including the [Player] and [Enemy].
class_name Fighter extends Node2D

## Whether the [Fighter] is currently knocked down.
@export var isKnockdown : bool = false

#@export_category("Required Gameplay Components")
## The [DefenseComponent] assigned to the [Fighter].
@onready var defense_component: DefenseComponent = %DefenseComponent

## The [HealthComponent] assigned to the [Fighter]/
@onready var health_component: HealthComponent = %HealthComponent

## The [AttackingComponent] assigned to the [Fighter]
@onready var attacking_component: AttackingComponent = %AttackingComponent

## The [AnimationTree] assigned to the [Fighter].
@onready var animation_tree: AnimationTree = %AnimationTree

## The animation state machine inside of the [member animation_tree].
## It's where all of the Animations of the [Fighter] are.
@onready var anim_state_machine: AnimationNodeStateMachinePlayback = animation_tree["parameters/playback"]

@export var fighter_info : FighterInfo

## The [StateMachine] assigned to the [Fighter].
@onready var state_machine: StateMachine = %StateMachine

## Self-explanatory
@export var max_hp : float = 100.0

var can_get_up : bool = false

func start_get_up():
	FightManager.start_ko_count_signal.emit()
	can_get_up = true
	FightManager.fight_is_over_signal.emit()
