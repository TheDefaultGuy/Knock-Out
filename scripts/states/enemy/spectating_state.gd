@icon("res://assets/icons/BoxiconsBinocularFilled.svg")

class_name EnemySpectating extends State

## It's the state entered when the [Player] is knocked down and the [Enemy] is watching them.
##
## It is a required state for all [Enemy].

@export var move_to_spectate_animation : String = "move_to_spectate"
@export var outro_animation : String = "outro"
@export var return_animation : String = "back_to_the_fight"
@export var spectating_animation : String = "spectating"

func enter() -> void:
	print_rich("[color=orange]Enemy Entered State: [/color]", self.name)
	
	
	FightManager.fighter_got_up_signal.connect(back_to_the_fight)
	
	FightManager.resume_fighting_signal.connect(transition_to_previous_state)
	
	FightManager.enemy_ready_status = false
	
	animation_tree.animation_finished.connect(check_finished_animation)
	
	owner.animation_component.set_animation_1d_blend("back_to_the_fight", -1)


func exit() -> void:
	FightManager.fighter_got_up_signal.disconnect(back_to_the_fight)
	
	FightManager.resume_fighting_signal.disconnect(transition_to_previous_state)
	
	animation_tree.animation_finished.disconnect(check_finished_animation)

func back_to_the_fight() -> void:
	anim_state_machine.travel("from_spectate")

func check_finished_animation(animation : String) -> void:
	
	animation = remove_library_preffix(animation)
	
	match animation:
		outro_animation:
			FightManager.go_to_results_screen_signal.emit()
			print("Fight's over for real this time.")
			return
		
		move_to_spectate_animation:
			if FightManager.is_fight_over == true:
				anim_state_machine.travel(outro_animation)
				return
			
			print("Emitting fighter_can_start_getup_signal")
			FightManager.fighter_can_start_getup_signal.emit()
			return
			
		"left", "right", "from_spectate":
			print("ENEMY READY")
			FightManager.enemy_ready_status = true
			FightManager.fighter_ready_signal.emit()
			return
			
		_:
			if anim_state_machine.get_current_node() == "idle":
				anim_state_machine.travel(move_to_spectate_animation)
				return
