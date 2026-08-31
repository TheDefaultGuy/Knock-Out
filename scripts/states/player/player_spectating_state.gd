@icon("res://assets/icons/BoxiconsBinocularFilled.svg")
class_name PlayerSpectatingState extends State



func enter() -> void:
	print_rich("[color=yellow]Player Entered State: [/color]", self.name)
	animation_tree.set("parameters/conditions/spectating", true)
	
	FightManager.fighter_got_up_signal.connect(back_to_fight)
	FightManager.resume_fighting_signal.connect(transition_to_neutral)
	FightManager.player_ready_status = false

func exit() -> void:
	animation_tree.set("parameters/conditions/spectating", false)
	FightManager.fighter_got_up_signal.disconnect(back_to_fight)
	FightManager.resume_fighting_signal.disconnect(transition_to_neutral)


func back_to_fight() -> void:
	anim_state_machine.travel("back_to_the_fight")
	animation_tree.set("parameters/conditions/spectating", false)
	
func ready_to_fight() -> void:
	FightManager.player_ready_status = true
	FightManager.fighter_ready_signal.emit()
	
func perform_attack(_height : int, _direction : int, _action_name : String, _special_move : bool) -> void:
	return
	
func perform_defense(_move : int, _action_name : String) -> void:
	return
