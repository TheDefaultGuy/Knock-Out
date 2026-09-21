@icon("res://assets/icons/BoxiconsBinocularFilled.svg")
class_name PlayerSpectating extends State

## The state the player is in when the enemy is knocked down.

#func _process(_delta: float) -> void:
	#if state_machine.current_state == self:
		#play_win_animation()

func enter() -> void:
	print_rich("[color=yellow]Player Entered State: [/color]", self.name)
	animation_tree.set("parameters/conditions/spectating", true)
	
	FightManager.fighter_got_up_signal.connect(back_to_fight)
	FightManager.resume_fighting_signal.connect(transition_to_neutral)
	

	animation_tree.animation_finished.connect(check_finished_animation)
	
	FightManager.fight_is_over_signal.connect(play_win_animation)
	
func exit() -> void:
	animation_tree.set("parameters/conditions/spectating", false)
	
	FightManager.fighter_got_up_signal.disconnect(back_to_fight)
	FightManager.resume_fighting_signal.disconnect(transition_to_neutral)

	animation_tree.animation_finished.disconnect(check_finished_animation)

func back_to_fight() -> void:
	animation_tree.set("parameters/conditions/spectating", false)
	anim_state_machine.travel("back_to_the_fight")
	
	
func check_finished_animation(animation : String) -> void:
	match animation:
		"back_to_the_fight":
			FightManager.player_ready_status = true
			print("PLAYER READY")
			FightManager.fighter_ready_signal.emit()
		"outro":
			print("Fight's over for real this time.")


func play_win_animation() -> void:
	if FightManager.is_fight_over == true:
		anim_state_machine.travel("outro")
