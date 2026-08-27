@icon("res://assets/icons/RiMovie2Line.svg")
## This is the state where the enemy and/or player are in during cutscenes (Beginning and end of the fight.)
##
## This state is required and used by both the player and enemies
class_name CutSceneState extends State

@onready var anim_state_machine = animation_tree["parameters/playback"]

@export var next_state : State

func _ready() -> void:
	if next_state == null:
		printerr(get_parent().get_parent().name, " CutScene State: next state not set")

func enter():
	print_rich("[color=yellow]",get_parent().get_parent().name," Entered State: [/color]", self.name)
	FightManager.start_intro_animation_signal.connect(play_intro)
	FightManager.resume_fighting_signal.connect(transition.bind(self, next_state))
	
	if get_parent().get_parent().isPlayer == true:
		FightManager.player_ready_status = false
	else:
		FightManager.enemy_ready_status = false
	

func exit():
	FightManager.resume_fighting_signal.disconnect(transition)
	FightManager.start_intro_animation_signal.disconnect(play_intro)
	
func play_intro():
	anim_state_machine.travel("intro")
	
func perform_attack(_height : int, _direction : int, _action_name : String, _special_move : bool):
	pass
	
func perform_defense(_move : int, _action_name : String):
	pass
