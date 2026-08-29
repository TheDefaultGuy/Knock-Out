@icon("res://assets/icons/BoxiconsBinocularFilled.svg")
class_name PlayerSpectatingState extends State

@onready var anim_state_machine = animation_tree["parameters/playback"]

func enter():
	print_rich("[color=yellow]Player Entered State: [/color]", self.name)
	animation_tree.set("parameters/conditions/spectating", true)
	
	FightManager.fighter_got_up_signal.connect(back_to_fight)
	FightManager.resume_fighting_signal.connect(transition_to_neutral)
	FightManager.player_ready_status = false


func exit():
	animation_tree.set("parameters/conditions/spectating", false)
	FightManager.fighter_got_up_signal.disconnect(back_to_fight)
	FightManager.resume_fighting_signal.disconnect(transition_to_neutral)


func back_to_fight():
	anim_state_machine.travel("back_to_the_fight")
	
func ready_to_fight():
	FightManager.player_ready_status = true
	FightManager.fighter_ready_signal.emit()
	
func perform_attack(_height : int, _direction : int, _action_name : String, _special_move : bool):
	pass
	
func perform_defense(_move : int, _action_name : String):
	pass
