@icon("res://assets/icons/BoxiconsBinocularFilled.svg")

class_name EnemySpectating extends State

## It's the state entered when the [Player] is knocked down and the [Enemy] is watching them.
##
## It is a required state for all [Enemy].

func enter() -> void:
	print_rich("[color=orange]Enemy Entered State: [/color]", self.name)
	FightManager.fighter_got_up_signal.connect(back_to_the_fight)
	FightManager.resume_fighting_signal.connect(transition_to_previous_state)
	FightManager.enemy_ready_status = false

	animation_tree.animation_finished.connect(end_match)
	owner.animation_tree.set("parameters/back_to_the_fight/blend_position", -1)
	anim_state_machine = animation_tree["parameters/playback"]
	
	
func exit() -> void:
	FightManager.fighter_got_up_signal.disconnect(back_to_the_fight)
	FightManager.resume_fighting_signal.disconnect(transition_to_previous_state)

	animation_tree.animation_finished.disconnect(end_match)

func back_to_the_fight() -> void:
	anim_state_machine.travel("back_to_the_fight")

func play_win_animation() -> void:
	await FightManager.fight_is_over_signal

	if anim_state_machine.get_current_node() != "spectating" or anim_state_machine.get_current_node() != "move_to_spectate":

		await animation_tree.animation_finished

	if FightManager.is_fight_over == true:
		anim_state_machine.travel("outro")

func end_match(animation : String) -> void:
	if animation == "outro":
		print("Fight's over for real this time.")
		
func _process(_delta: float) -> void:
	if Engine.is_editor_hint(): # Doesnt run the check round time function when in the editor; only when in-game
		return
	if state_machine.current_state != self:
		return
	if anim_state_machine.get_current_node() == "idle":
		anim_state_machine.travel("move_to_spectate")
	play_win_animation()
	
