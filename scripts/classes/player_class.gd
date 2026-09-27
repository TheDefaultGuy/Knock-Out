@icon("res://assets/icons/RiBoxingFill.svg")
class_name Player extends Fighter
## The class that is the actual playable player character.
##
## It extends from [Fighter] and is its own class to make
## checking between [Enemy] and [Player] easier and to
## avoid having unused variables in the [Player] class.


@onready var input_component: InputComponent = %InputComponent


func _ready() -> void:
	if defense_component == null and self.get_script() != Fighter:
		printerr(self.name, " doesn't have a Defense Component assigned.")
	if attacking_component == null and self.get_script() != Fighter:
		printerr(self.name, " doesn't have an Attacking Component assigned.")
	if health_component == null and self.get_script() != Fighter:
		printerr(self.name, " doesn't have a Health Component assigned.")
	if animation_tree == null and self.get_script() != Fighter:
		printerr(self.name, " doesn't have an Animation Tree assigned.")
	else:
		animation_tree.process_priority = -1 # Sets the process priority of the Animation tree lower so that it RUNS BEFORE other nodes in the tree. 
