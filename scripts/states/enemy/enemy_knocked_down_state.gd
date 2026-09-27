@tool
@icon("res://assets/icons/StreamlineSleepSolid.svg")

class_name EnemyKnockedDown extends State
## This is the state in which the [Enemy] is knocked down.
##
## It is a required state for all [Enemy].

## The rate in which the chance to do a failed get up animation increases so that it performs the minimum amount.
const CHANCE_INCREASE_INCREMENT : float = 5.0

## The minimum amount of time in seconds the enemy will get up from being knocked down.
@export_range(1.0, 9.0, 1.0, "suffix:s") var min_getup_time : float = 1.0 :
	set(value):
		min_getup_time = value
		
		# Makes sure that max_getup_time is always greater than
		# or at at least equal to min_getup_time
		if max_getup_time < min_getup_time:
			max_getup_time = min_getup_time


## The maximum amount of time in seconds the enemy will get up from being knocked down.
@export_range(1.0, 9.0, 1.0, "suffix:s") var max_getup_time : float = 8.0 :
	set(value):
		max_getup_time = value
		
		# Makes sure that max_getup_time is always greater than
		# or at at least equal to min_getup_time
		if max_getup_time < min_getup_time:
			max_getup_time = min_getup_time

@export var does_failed_get_up : bool = true

@export_range(1, 4, 1) var min_failed_attempts : int = 1

## The chance the enemy will do a failed get up animation during each second of the [member get_up_timer]
@export_range(0.0, 30.0, 5.0, "suffix:%") var chance_for_failed_attempt : float = 15.0

## The timer used to count the get up time.
var get_up_timer : Timer = null

## Stores the [param wait_time] of the [member get_up_timer] for readability.
var get_up_wait_time : float = 0.0

## Stores the [param time_left] of the [member get_up_timer] for comparision.
var stored_time_left : float = 0.0

## Stores how many failed get up attempts the [Enemy] has done.
var stored_attempts : int = 0

var check_count : int = 0

#ar roll_value : float = 0.0

func _ready() -> void:
	get_up_timer = TimerCreator.create_timer_and_add_as_child("Get Up Timer", true, 1.0, false, self)
	
	

func _process(_delta: float) -> void:
	if Engine.is_editor_hint(): # Only Runs the function in-game and not the editor
		return
	if state_machine.current_state == self and get_up_timer.is_stopped() == false:
		#print("get_up_timer.time_left: ",ceilf(get_up_timer.time_left))
		#print("stored_time_left: ", stored_time_left)
		if ceilf(get_up_timer.time_left) < stored_time_left:
			
			stored_time_left = ceilf(get_up_timer.time_left)
			
			var roll_value = randf()
			
			#print("check_count: ", check_count)
			#prints(remap(chance_for_failed_attempt, 0.0, 100.0, 0.0, 1.0), randy)
			
			var modified_chance : float = chance_for_failed_attempt + (CHANCE_INCREASE_INCREMENT * check_count)
			
			var remapped_chance = remap(modified_chance, 0.0, 100.0, 0.0, 1.0)
			
			#print("modified_chance: ", modified_chance)
			#print("remapped_chance: ", remapped_chance)
			#if stored_attempts < min_failed_attempts:
				#roll_value = remap(chance_for_failed_attempt + CHANCE_INCREASE_INCREMENT, 0.0, 100.0, 0.0, 1.0)
			#print("Roll Value: ", roll_value)
			
			if remapped_chance > roll_value:
				play_failed_get_up_animation()
				stored_attempts += 1
				check_count = 0
				return
			check_count += 1
		return

func enter() -> void:
	print_rich("[color=orange]Enemy Entered State: [/color]", self.name)
	FightManager.enemy_ready_status = false
	
	FightManager.resume_fighting_signal.connect(transition_to_previous_state)
	animation_tree.animation_finished.connect(check_finished_animation)
	animation_tree.animation_started.connect(check_started_animation)
	get_up_timer.timeout.connect(play_get_up_animation)
	
	stored_time_left = 0.0
	
	stored_attempts = 0

func exit() -> void:
	FightManager.resume_fighting_signal.disconnect(transition_to_previous_state)
	get_up_timer.stop()
	animation_tree.animation_finished.disconnect(check_finished_animation)
	animation_tree.animation_started.disconnect(check_started_animation)
	
	if get_up_timer.timeout.is_connected(play_get_up_animation) == true:
		get_up_timer.timeout.disconnect(play_get_up_animation)

## Plays the get up animation to leave state.
func play_get_up_animation() -> void:
	
	await get_tree().create_timer(0.4).timeout
	anim_state_machine.travel("get_up")


func play_failed_get_up_animation() -> void:
	print("\nPlaying Failed Get Up Animation...")
	
	await get_tree().create_timer(0.4).timeout
	anim_state_machine.start("get_up_failed", true)
	FightManager.pause_ko_count_signal.emit()
	get_up_timer.paused = true
	stored_time_left -= 1.0

func start_get_up_timer() -> void:
	
	# Emits the signal so that it starts playing the KO Count animation.
	FightManager.start_ko_count_signal.emit()
	
	# Grabs a random number between min_getup_time and max_getup_time
	# Then rounds it to the nearest whole number.
	get_up_wait_time = roundf(randf_range(min_getup_time, max_getup_time))
	
	if owner.instant_kd_component.is_fully_knocked_out == true:
		get_up_wait_time = 9.0
		
	if FightManager.enemy_kd_count == FightManager.MAX_KD_COUNT:
		print("Not getting up.")
		get_up_timer.timeout.disconnect(play_get_up_animation)
		return
		
		
	
	print("STARTING GETUP TIMER")
	
	stored_time_left = get_up_wait_time
	
	# Starts the get up timer.
	get_up_timer.start(get_up_wait_time)
	
func check_started_animation(animation : String) -> void:
	if animation.contains("get_up") == true and animation.contains("failed") == false:
		health_component.reset_hp()
		return

func check_finished_animation(animation : String) -> void:
	
	print(animation)
	#print(animation.contains("get_up") == true and animation.contains("failed") == true)
	
	if animation.contains("knockdown") == true:
		start_get_up_timer()
		return
		
	#elif animation.contains("get_up") == true and animation.contains("failed") == false:
		#health_component.reset_hp()
		#return
		
	elif animation.contains("return_to_fight") == true:
		FightManager.enemy_ready_status = true
		print("ENEMY READY")
		FightManager.fighter_ready_signal.emit()
		return
	
	elif animation.contains("get_up") == true and animation.contains("failed") == true:
		FightManager.pause_ko_count_signal.emit()
		get_up_timer.paused = false
		return
