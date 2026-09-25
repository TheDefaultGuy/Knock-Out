@icon("res://assets/icons/IconParkSolidBranchTwo.svg")
class_name FightLogicComponent extends Node

var round_timer: Timer = null
var ko_timer: Timer  = null

@onready var animation_player: AnimationPlayer = %AnimationPlayer

func _ready() -> void:
	FightManager.enemy_knocked_down_signal.connect(toggle_round_timer)
	FightManager.player_knocked_down_signal.connect(toggle_round_timer)
	FightManager.resume_fighting_signal.connect(toggle_round_timer)
	FightManager.start_ko_count_signal.connect(start_ko_count)
	FightManager.fighter_got_up_signal.connect(stop_ko_count)
	
	call_deferred("create_timers")
	
	await get_tree().create_timer(0.4).timeout
	#FightManager.start_intro_animation_signal.emit()
	start_the_match()

func _process(_delta: float) -> void:
	
	# Does the math to convert the seconds to M:SS:MSS format.
	FightManager.round_time = (round_timer.wait_time - round_timer.time_left)
	@warning_ignore("integer_division")
	var minutes: int = int(FightManager.round_time) / 60
	var seconds: int = int(fmod(FightManager.round_time, 60))
	var milliseconds : int = int((FightManager.round_time - int(FightManager.round_time)) * 1000)
	owner.arena_ui.time_left_label.text = str( "%d'%02d\"%03d" % [minutes, seconds, milliseconds])
	
	if FightManager.is_fight_over == true:
		stop_ko_count()

func toggle_round_timer() -> void:
	round_timer.paused = !round_timer.paused
	
func start_the_match() -> void:
	round_timer.paused = false
	
func start_ko_count() -> void:
	if FightManager.is_fight_over == false:
		print("Fight Logic Component: Starting KO count...")
		ko_timer.start(10.0)
		animation_player.play("ko_count")

func stop_ko_count() -> void:
	ko_timer.stop()
	animation_player.play("RESET")
	
func end_fight() -> void:
	print("Fight Logic Component: FIGHTER COULDNT GET UP")
	
	match true:
		Global.player_node.is_knocked_down:
			Global.winner = Global.WinnerEnum.ENEMY
			
		Global.enemy_node.is_knocked_down:
			Global.winner = Global.WinnerEnum.PLAYER
	
	FightManager.is_fight_over = true
	FightManager.fight_is_over_signal.emit()

func _on_round_timer_timeout() -> void:
	print("Fight Logic Component: ROUND OVER; TIMES UP")

## Creates the timers with code so that  you don't have to make a round timer node and then manually assign it.
func create_timers() -> void:
	round_timer = TimerCreator.create_timer("Round Timer", true, owner.match_settings.round_length, true)
	add_child.call_deferred(round_timer)
	round_timer.timeout.connect(_on_round_timer_timeout)
	
	ko_timer = TimerCreator.create_timer("KO Count Timer", true, 10.0, false)
	add_child.call_deferred(ko_timer)
	ko_timer.timeout.connect(end_fight)
