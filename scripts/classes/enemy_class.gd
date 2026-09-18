@icon("res://assets/icons/RiBoxingFill.svg")
class_name Enemy extends Fighter

## The class used by enemy fighters/boxers.
##
## It extends from fighter and is its own class to make
## checking between enemy and player easier and to
## avoid having unused variables in the player class.


@warning_ignore("unused_signal")
## Signal emitted when the enemy is confirmed to have been hit by a star punch.
signal hit_by_star_punch_signal

## Whether the fighter is currently stunned.
var is_stunned : bool = false

@onready var instant_ko_component: InstantKOComponent = %InstantKOComponent
@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D

func _ready() -> void:
	if defense_component == null:
		printerr(self.name, " doesn't have a Defense Component assigned.")
	if attacking_component == null:
		printerr(self.name, " doesn't have an Attacking Component assigned.")
	if health_component == null:
		printerr(self.name, " doesn't have a Health Component assigned.")
	if animation_tree == null:
		printerr(self.name, " doesn't have an Animation Tree assigned.")
	if instant_ko_component == null:
		push_warning(self.name, " doesn't have an Instant KO Component assigned")

## Function called by the get_up animations to let functions know that the fighter is ready to fight.
func ready_to_fight() -> void:
	FightManager.enemy_ready_status = true
	FightManager.fighter_ready_signal.emit()
	
