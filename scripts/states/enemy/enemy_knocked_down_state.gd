@icon("res://assets/icons/StreamlineSleepSolid.svg")

class_name EnemyKnockedDown extends State
## This is the state in which the [Enemy] is knocked down.
##
## It is a required state for all [Enemy].


## The minimum amount of time in seconds the enemy will get up from being knocked down.
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var min_getup_time : float = 1.0

## The maximum amount of time in seconds the enemy will get up from being knocked down.
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var max_getup_time : float = 8.0

## The timer used to count the get up time.
var get_up_timer : Timer = null

func _ready() -> void:
	get_up_timer = Timer.new()
	get_up_timer.autostart = false
	get_up_timer.one_shot = true
	add_child(get_up_timer)
	get_up_timer.timeout.connect(play_get_up_animation)
	
func enter() -> void:
	print_rich("[color=orange]Enemy Entered State: [/color]", self.name)
	FightManager.enemy_ready_status = false
	FightManager.resume_fighting_signal.connect(transition_to_previous_state)
	animation_tree.animation_finished.connect(check_finished_animation)
	
func exit() -> void:
	FightManager.resume_fighting_signal.disconnect(transition_to_previous_state)
	get_up_timer.stop()
	animation_tree.animation_finished.disconnect(check_finished_animation)

func play_get_up_animation() -> void:
	anim_state_machine.travel("get_up")

func start_get_up_timer() -> void:
	
	FightManager.start_ko_count_signal.emit()
	
	if FightManager.enemy_kd_count >= FightManager.MAX_KD_COUNT or owner.instant_kd_component.is_fully_knocked_out == true:
		print("Not getting up.")
		#FightManager.fight_is_over_signal.emit()
		return
		
	
	print("STARTING GETUP TIMER")
	get_up_timer.start(randf_range(min_getup_time, max_getup_time))

func check_finished_animation(animation : String) -> void:
		
	if animation.contains("knockdown") == true :
		start_get_up_timer()
		return
		
	elif animation.contains("get_up") == true :
		health_component.reset_hp()
		return
		
	elif animation.contains("return_to_fight") == true :
		FightManager.enemy_ready_status = true
		print("ENEMY READY")
		FightManager.fighter_ready_signal.emit()
		return
