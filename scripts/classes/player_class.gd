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
	else:
		animation_tree.process_priority = -1 # Sets the process priority of the Animation tree lower so that it RUNS BEFORE other nodes in the tree. 
