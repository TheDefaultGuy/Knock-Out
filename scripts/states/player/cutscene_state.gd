@icon("res://assets/icons/RiMovie2Line.svg")

class_name CutSceneState extends State

## This is the state where the enemy and/or player are in during cutscenes (Beginning and end of the fight.)
##
## This state is required and used by both the player and enemies

@export var skip_cutscene : bool = false

@export var next_state : State

func _ready() -> void:
	if next_state == null and state_machine.initial_state == self:
		push_error(owner.name, " CutScene State: next state not set")
		
	skip_cutscene = OS.is_debug_build()

func enter() -> void:
	print_rich("[color=yellow]",owner.name," Entered State: [/color]", self.name)
	
	FightManager.resume_fighting_signal.connect(transition.bind(next_state))
	
	FightManager.player_ready_status = true
	FightManager.enemy_ready_status = false
	
	animation_tree.animation_finished.connect(check_finished_animation)
	
	play_intro()

func exit() -> void:
	FightManager.resume_fighting_signal.disconnect(transition)
#	FightManager.start_intro_animation_signal.disconnect(play_intro)
	animation_tree.animation_finished.disconnect(check_finished_animation)

func check_finished_animation(animation : String) -> void:
	
	if animation == "intro":
		if owner is Enemy:
			FightManager.enemy_ready_status = true
			
		#elif owner is Player:
			#FightManager.player_ready_status = true
			
			FightManager.fighter_ready_signal.emit()

func play_intro() -> void:
	
	print(self.owner.name, FightManager.enemy_ready_status)
	#if owner is Player:
		#if FightManager.enemy_ready_status == true:
			#anim_state_machine.travel("intro")
	
	if owner is Enemy:
		if skip_cutscene == true:
			await get_tree().create_timer(0.4).timeout
			FightManager.enemy_ready_status = true
			FightManager.fighter_ready_signal.emit()
			return
		
		anim_state_machine.travel("intro")
