@icon("res://assets/icons/RiBoxingFill.svg")
## The base class for all boxers/fighters, including the player.
class_name Fighter extends Node2D

## Whether the fighter is currently knocked down.
@export var isKnockdown : bool = false

#@export_category("Required Gameplay Components")
@onready var defense_component: DefenseComponent = %DefenseComponent
@onready var health_component: HealthComponent = %HealthComponent
@onready var attacking_component: AttackingComponent = %AttackingComponent
@onready var animation_tree: AnimationTree = %AnimationTree
@onready var anim_state_machine = animation_tree["parameters/playback"]

@export var fighter_info : FighterInfo
@onready var state_machine: StateMachine = %StateMachine

## Self-explanatory
@export var max_hp : float = 100.0

var can_get_up : bool = false

func start_get_up():
	FightManager.start_ko_count_signal.emit()
	can_get_up = true
	FightManager.fight_is_over_signal.emit()
