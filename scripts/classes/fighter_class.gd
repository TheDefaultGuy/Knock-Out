@icon("res://assets/icons/RiBoxingFill.svg")

@abstract class_name Fighter extends Node2D
## The base class for all boxers/fighters, including the [Player] and [Enemy].


@export var fighter_info : FighterInfo


## Whether the [Fighter] is currently knocked down.
var is_knocked_down : bool = false

## The [DefenseComponent] assigned to the [Fighter].
@onready var defense_component: DefenseComponent = %DefenseComponent

## The [HealthComponent] assigned to the [Fighter].
@onready var health_component: HealthComponent = %HealthComponent

## The [AttackingComponent] assigned to the [Fighter].
@onready var attacking_component: AttackingComponent = %AttackingComponent

## The [AnimationTree] assigned to the [Fighter].
@onready var animation_tree: AnimationTree = %AnimationTree

## The animation state machine inside of the [member animation_tree].
## It's where all of the Animations of the [Fighter] are.
@onready var anim_state_machine: AnimationNodeStateMachinePlayback = animation_tree["parameters/playback"]

## The [StateMachine] assigned to the [Fighter].
@onready var state_machine: StateMachine = %StateMachine
