@icon("res://assets/icons/IconParkSolidBranchTwo.svg")
class_name FightLogicComponent extends Node

signal time_is_over_signal

const RESULTS_SCREEN = preload("uid://b4unduv261ia0")
const CHARACTER_SELECTION_MENU = preload("uid://bvyokq5qbudmq")

var round_timer: Timer = null
var ko_timer: Timer  = null

var can_start_checking : bool = false

@onready var animation_player: AnimationPlayer = %AnimationPlayer

func _ready() -> void:
	FightManager.enemy_knocked_down_signal.connect(toggle_round_timer)
	FightManager.player_knocked_down_signal.connect(toggle_round_timer)
	FightManager.resume_fighting_signal.connect(toggle_round_timer)
	FightManager.start_ko_count_signal.connect(start_ko_count)
	FightManager.fighter_got_up_signal.connect(stop_ko_count)
	
	call_deferred("create_timers")
	
	#await get_tree().create_timer(0.4).timeout
	
	time_is_over_signal.connect(_on_round_timer_timeout)
	
	FightManager.pause_ko_count_signal.connect(pause_ko_count)
	
	#FightManager.start_intro_animation_signal.emit()
	
	#owner.arena_ui.time_left_label.text = str("0'00",str(000))
	
	#start_the_match()

func _process(_delta: float) -> void:
	
	# Does the math to convert the seconds to M:SS:MSS format.
	
	
	FightManager.round_time = snappedf((round_timer.wait_time - round_timer.time_left), 0.001)
	
	#print(FightManager.round_time)
	
	@warning_ignore("integer_division")
	var minutes: int = int(FightManager.round_time) / 60
	var seconds: int = int(fmod(FightManager.round_time, 60))
	var milliseconds : int = int((FightManager.round_time - int(FightManager.round_time)) * 1000)
	owner.arena_ui.time_left_label.text = str( "%d'%02d\"%03d" % [minutes, seconds, milliseconds])
	#prints(round_timer.wait_time, round_timer.time_left)
	#prints(FightManager.round_time, owner.arena_ui.time_left_label.text)
	#print(FightManager.is_fight_over)
	#print(round_timer.is_stopped())
	#print(round_timer.time_left)
	#print("Timer Paused?: ", round_timer.paused)
	#print("Timer Stopped?: ", round_timer.is_stopped())
	# This is done because the timer label can stop at a number like: 2'59"997
	if can_start_checking == true and round_timer.is_stopped() == true:
		if FightManager.is_fight_over == false:
			time_is_over_signal.emit()
	
	#if ko_timer.is_stopped() == false:
		#print("KO Timer: ",ko_timer.time_left)
		#print("KO Text: ",owner.arena_ui.ko.text)

func toggle_round_timer() -> void:
	print("Fight Logic Component: Toggling round timer...")
	if round_timer.is_stopped() == true:
		round_timer.start()
		round_timer.paused = false
		can_start_checking = true
		return
	round_timer.paused = !round_timer.paused
	
func start_the_match() -> void:
	round_timer.paused = true
	
func start_ko_count() -> void:
	
	if FightManager.is_fight_over == false:
		print("Fight Logic Component: Starting KO count...")
		#ko_timer.start(10.0)
		animation_player.play("ko_count")
		
	if FightManager.is_fight_over == true:
		animation_player.play("TKO")

func pause_ko_count() -> void:
	
	#print("KO Count is Animation PLaying?: ", animation_player.is_playing())
	#print("Timer Paused?: ", ko_timer.paused)
	
	if animation_player.is_playing() == true:
		animation_player.pause()
	
	elif animation_player.is_playing() == false:
		animation_player.play()
	
	#ko_timer.paused = !ko_timer.paused

func stop_ko_count() -> void:
	#ko_timer.stop()
	await get_tree().create_timer(0.5).timeout
	animation_player.play("RESET")
	
func end_fight() -> void:
	print("Fight Logic Component: FIGHTER COULDNT GET UP")
	stop_ko_count()
	
	FightManager.is_fight_over = true
	
	match true:
		Global.player_node.is_knocked_down:
			Global.winner = Global.WinnerEnum.ENEMY
			
		Global.enemy_node.is_knocked_down:
			Global.winner = Global.WinnerEnum.PLAYER
	print("Winner: ", Global.winner)
	
	FightManager.fight_is_over_signal.emit()

func set_that_fight_is_over() -> void:
	FightManager.is_fight_over = true


func _on_round_timer_timeout() -> void:
	FightManager.fight_is_over_signal.emit()
	FightManager.is_fight_over = true
	get_tree().paused = true
	print("Fight Logic Component: ROUND OVER; TIMES UP")
	SceneChanger.change_scene(RESULTS_SCREEN, self)
	#get_tree().paused = false
	
	

## Creates the timers with code so that  you don't have to make a round timer node and then manually assign it.
func create_timers() -> void:
	round_timer = TimerCreator.create_timer("Round Timer", true, owner.match_settings.round_length, false)
	add_child.call_deferred(round_timer)
	#round_timer.timeout.connect(_on_round_timer_timeout)
	
	#ko_timer = TimerCreator.create_timer("KO Count Timer", true, 10.0, false)
	#add_child.call_deferred(ko_timer)
	#ko_timer.timeout.connect(set_that_fight_is_over)
