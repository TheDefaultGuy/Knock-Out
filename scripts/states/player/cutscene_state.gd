@icon("res://assets/icons/RiMovie2Line.svg")
## This is the state where the enemy and/or player are in during cutscenes (Beginning and end of the fight.)
##
## This state is required and used by both the player and enemies
class_name CutSceneState extends State

@onready var anim_state_machine = animation_tree["parameters/playback"]

@export var next_state : State

@export_category("Animations")
@export var winning_animation : String
@export var losing_animation : String
@export var intro_animation : String

func enter():
	print_rich("[color=yellow]Player Entered State: [/color]", self.name)
	animation_tree.set("parameters/conditions/spectating", true)
	
	FightManager.fighter_got_up_signal.connect(back_to_fight)
	FightManager.resume_fighting_signal.connect(transition.bind(self, next_state))
	
	
	if get_parent().get_parent().isPlayer == true:
		FightManager.player_ready_status = false
	else:
		FightManager.enemy_ready_status = false
	

func exit():
	animation_tree.set("parameters/conditions/spectating", false)
	FightManager.fighter_got_up_signal.disconnect(back_to_fight)
	FightManager.resume_fighting_signal.disconnect(transition)


func back_to_fight():
	anim_state_machine.travel("back_to_the_fight")
	
func ready_to_fight():
	if get_parent().get_parent().isPlayer == true:
		FightManager.player_ready_status = true
	else:
		FightManager.enemy_ready_status = true
	FightManager.fighter_ready_signal.emit()
	
func perform_attack(_height : int, _direction : int, _action_name : String, _special_move : bool):
	pass
	
func perform_defense(_move : int, _action_name : String):
	pass
