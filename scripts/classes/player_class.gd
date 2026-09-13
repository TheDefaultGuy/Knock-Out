@icon("res://assets/icons/RiBoxingFill.svg")
## The base class for all boxers/fighters, including the player.
class_name Player extends Fighter


@onready var input_component: InputComponent = %InputComponent


func _ready() -> void:
	if defense_component == null:
		printerr(self.name, " doesn't have a Defense Component assigned.")
	if attacking_component == null:
		printerr(self.name, " doesn't have an Attacking Component assigned.")
	if health_component == null:
		printerr(self.name, " doesn't have a Health Component assigned.")
	if animation_tree == null:
		printerr(self.name, " doesn't have an Animation Tree assigned.")

	
func ready_to_fight():
	#print("Fighter Class: ", name, " is ready")
	FightManager.player_ready_status = true
	FightManager.fighter_ready_signal.emit()
