@icon("res://assets/icons/RiMovie2Line.svg")

class_name CutSceneState extends State

## This is the state where the enemy and/or player are in during cutscenes (Beginning and end of the fight.)
##
## This state is required and used by both the player and enemies


@export var next_state : State

func _ready() -> void:
	if next_state == null and state_machine.initial_state == self:
		push_error(owner.name, " CutScene State: next state not set")

func enter() -> void:
	print_rich("[color=yellow]",owner.name," Entered State: [/color]", self.name)
	FightManager.start_intro_animation_signal.connect(play_intro)
	FightManager.resume_fighting_signal.connect(transition.bind(self, next_state))
	
	if owner is Player:
		FightManager.player_ready_status = false
	else:
		FightManager.enemy_ready_status = false
	

func exit() -> void:
	FightManager.resume_fighting_signal.disconnect(transition)
	FightManager.start_intro_animation_signal.disconnect(play_intro)
	
func play_intro() -> void:
	anim_state_machine.travel("intro")
	
