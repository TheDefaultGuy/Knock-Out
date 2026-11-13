@icon("res://assets/icons/BoxiconsBinocularFilled.svg")

class_name EnemySpectating extends State
## It's the state entered when the [Player] is knocked down and the [Enemy] is watching them.
##
## It is a required state for all [Enemy].

## The animation the [Enemy] will play once the [Player] enters [PlayerKnockedDown]
@export var move_to_spectate_animation : String = "move_to_spectate"

## The animation the [Enemy] will play when winning the match.
@export var outro_animation : String = "outro"

## The animation the [Enemy] will play once the [Player] recovers from [PlayerKnockedDown]
@export var return_animation : String = "back_to_the_fight"

## The animation the [Enemy] will loop while the [Player] attempts to get up during [PlayerKnockedDown]
@export var spectating_animation : String = "spectating"


func enter() -> void:
	print_rich("[color=orange][b]Enemy Entered State: [/b][/color]", self.name)
	
	FightManager.fighter_got_up_signal.connect(back_to_the_fight)
	
	FightManager.resume_fighting_signal.connect(transition_to_previous_state)
	
	FightManager.enemy_ready_status = false
	
	animation_tree.animation_finished.connect(check_finished_animation)
	
	AnimationManager.set_animation_1d_blend("back_to_the_fight", -1, self)
	
	FightManager.fight_is_over_signal.connect(play_outro_animation)
	
	await animation_tree.animation_finished
	
	anim_state_machine.travel(move_to_spectate_animation)
	
	#AnimationManager.force_play_animation("move_to_spectate", self)

func exit() -> void:
	FightManager.fighter_got_up_signal.disconnect(back_to_the_fight)
	
	FightManager.resume_fighting_signal.disconnect(transition_to_previous_state)
	
	animation_tree.animation_finished.disconnect(check_finished_animation)
	
	FightManager.fight_is_over_signal.disconnect(play_outro_animation)

func back_to_the_fight() -> void:
	anim_state_machine.travel("from_spectate")
	print_rich(str("[color=orange]",self.name,"[/color]:  Traveling to: from_spectate"))

func check_finished_animation(animation : String) -> void:
	
	animation = ArrayStringFormatter.remove_animation_library_preffix(animation)
	
	match animation:
		outro_animation:
			FightManager.go_to_results_screen_signal.emit()
			print_rich("[color=#orange][b]Enemy Spectating State: [/b][/color]Fight's over for real this time.")
			return
		
		move_to_spectate_animation:
			print_rich("[color=#orange][b]Enemy Spectating State: [/b][/color]Emitting fighter_can_start_getup_signal...")
			FightManager.fighter_can_start_getup_signal.emit()
			return
			
		"left", "right", "from_spectate":
			print_rich("[color=#orange][b]Enemy Spectating State: [/b][/color]Enemy is ready to fight.")
			FightManager.enemy_ready_status = true
			FightManager.fighter_ready_signal.emit()
			return

func play_outro_animation() -> void:
		AnimationManager.force_play_animation(outro_animation, self)
