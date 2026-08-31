@icon("res://assets/icons/BoxiconsBinocularFilled.svg")
## It's the state entered when the player is knocked down.
## This is a required state for enemy boxers.
class_name EnemySpectatingState extends State


func enter() -> void:
	print_rich("[color=orange]Enemy Entered State: [/color]", self.name)
	anim_state_machine.travel("spectating")
	FightManager.fighter_got_up_signal.connect(back_to_the_fight)
	FightManager.resume_fighting_signal.connect(transition_to_previous_state)
	animation_tree.set("parameters/conditions/spectating", true)
	animation_tree.set("parameters/conditions/stunned", false)
	FightManager.enemy_ready_status = false
	
func exit() -> void:
	animation_tree.set("parameters/conditions/spectating", false)
	FightManager.fighter_got_up_signal.disconnect(back_to_the_fight)
	FightManager.resume_fighting_signal.disconnect(transition_to_previous_state)

func back_to_the_fight() -> void:
	anim_state_machine.travel("back_to_the_fight")
	animation_tree.set("parameters/conditions/spectating", false)
	
