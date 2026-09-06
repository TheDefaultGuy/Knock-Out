@icon("res://assets/icons/BoxiconsBinocularFilled.svg")
class_name PlayerSpectating extends State

func enter() -> void:
	print_rich("[color=yellow]Player Entered State: [/color]", self.name)
	animation_tree.set("parameters/conditions/spectating", true)
	
	FightManager.fighter_got_up_signal.connect(back_to_fight)
	FightManager.resume_fighting_signal.connect(transition_to_neutral)
	FightManager.player_ready_status = false
	FightManager.fight_is_over_signal.connect(play_win_animation)
	animation_tree.animation_finished.connect(end_match)
	
func exit() -> void:
	animation_tree.set("parameters/conditions/spectating", false)
	FightManager.fighter_got_up_signal.disconnect(back_to_fight)
	FightManager.resume_fighting_signal.disconnect(transition_to_neutral)
	FightManager.fight_is_over_signal.disconnect(play_win_animation)
	animation_tree.animation_finished.disconnect(end_match)
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
	
func end_match(animation : String) -> void:
	if animation == "outro":
		print("Fight's over for real this time.")
		
func play_win_animation() -> void:
	anim_state_machine.travel("outro")
