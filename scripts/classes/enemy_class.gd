@icon("res://assets/icons/RiBoxingFill.svg")
## The base class for all boxers/fighters, including the player.
class_name Enemy extends Fighter

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

func ready_to_fight() -> void:
	FightManager.enemy_ready_status = true
	FightManager.fighter_ready_signal.emit()
	
