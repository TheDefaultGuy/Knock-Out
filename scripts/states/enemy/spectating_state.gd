@icon("res://assets/icons/BoxiconsBinocularFilled.svg")
## It's the state entered when the player is knocked down.
## This is a required state for enemy boxers.
class_name EnemySpectating extends State


func enter() -> void:
	print_rich("[color=orange]Enemy Entered State: [/color]", self.name)
	FightManager.fighter_got_up_signal.connect(back_to_the_fight)
	FightManager.resume_fighting_signal.connect(transition_to_previous_state)
	FightManager.enemy_ready_status = false
	FightManager.fight_is_over_signal.connect(play_win_animation)
	animation_tree.animation_finished.connect(end_match)

	
func exit() -> void:
	FightManager.fighter_got_up_signal.disconnect(back_to_the_fight)
	FightManager.resume_fighting_signal.disconnect(transition_to_previous_state)
	FightManager.fight_is_over_signal.disconnect(play_win_animation)
	animation_tree.animation_finished.disconnect(end_match)

func back_to_the_fight() -> void:
	anim_state_machine.travel("back_to_the_fight")

func play_win_animation() -> void:
	anim_state_machine.travel("outro")

func end_match(animation : String) -> void:
	if animation == "outro":
		print("Fight's over for real this time.")
		
func _process(_delta: float) -> void:
	if Engine.is_editor_hint(): # Doesnt run the check round time function when in the editor; only when in-game
		return
	if get_parent().current_state != self:
		return
	if anim_state_machine.get_current_node() == "idle":
		anim_state_machine.travel("move_to_spectate")
