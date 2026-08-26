@icon("res://assets/icons/RiBoxingFill.svg")
## The base class for all boxers/fighters, including the player.
class_name Fighter extends Node2D

@export_category("Required Gameplay Components")
@export var defense_component: DefenseComponent
@export var attacking_component: AttackingComponent
@export var health_component: HealthComponent

@export var move_set_anim: AnimationPlayer
@export var animation_tree: AnimationTree
@onready var anim_state_machine = animation_tree["parameters/playback"]
@export var fighter_info : FighterInfo

## Self-explanatory
@export var max_hp : float = 100.0

@export_group("Fighter Variables")
## Whether the fighter is currently knocked down.
@export var isKnockdown : bool = false
## Whether the fighter is currently dodging.
@export var isDodging : bool = false
## Whether the fighter is currently attacking.
@export var isAttacking : bool = false
## Whether the fighter is currently hit/playing the hit animation.
@export var isHit : bool = false
## Whether the fighter is the player themselves.
@export var isPlayer : bool = false


func _ready() -> void:
	if defense_component == null:
		printerr(self.name, " doesn't have a Defense Component Assigned.")
	if attacking_component == null:
		printerr(self.name, " doesn't have an Attacking Component Assigned.")
	if health_component == null:
		printerr(self.name, " doesn't have a Health Component Assigned.")
	if move_set_anim == null:
		printerr(self.name, " doesn't have a Move Set Animation Player Assigned.")
	if animation_tree == null:
		printerr(self.name, " doesn't have an Animation Tree Assigned.")
	#if isPlayer == false and :

func start_get_up():
	FightManager.start_get_up_signal.emit()
		
func ready_to_fight():
	print(name, "ready")
	FightManager.fighter_ready_signal.emit()
	if isPlayer == true:
		FightManager.player_ready_status = true
	elif isPlayer == false:
		FightManager.enemy_ready_status = true
	
func emit_got_up_signal():
	print("Fart")
	FightManager.fighter_got_up_signal.emit()
