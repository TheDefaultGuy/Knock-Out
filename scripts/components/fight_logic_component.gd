@icon("res://assets/icons/IconParkSolidBranchTwo.svg")
class_name FightLogicComponent extends Node

var round_timer: Timer = null
var ko_timer: Timer  = null
@export var animation_player: AnimationPlayer

func _ready() -> void:
	FightManager.enemy_knocked_down_signal.connect(toggle_round_timer)
	FightManager.player_knocked_down_signal.connect(toggle_round_timer)
	FightManager.resume_fighting_signal.connect(toggle_round_timer)
	FightManager.start_get_up_signal.connect(start_ko_count)
	FightManager.fighter_got_up_signal.connect(stop_ko_count)
	FightManager.start_the_fight_signal.connect(start_the_match)
	
	create_timers()
	
	await get_tree().create_timer(0.4).timeout
	FightManager.start_intro_animation_signal.emit()
	start_the_match()

func _process(_delta: float) -> void:
	## Does the match to convert the seconds to M:SS format.
	FightManager.round_time = (round_timer.wait_time - round_timer.time_left)
	#print("ROUND TIME : ", FightManager.round_time)
	@warning_ignore("integer_division")
	var minutes: int = int(FightManager.round_time) / 60
	var seconds: int = int(fmod(FightManager.round_time, 60))
	var milliseconds : int = int((FightManager.round_time - int(FightManager.round_time)) * 1000)
	get_parent().time_left_label.text = str( "%d'%02d\"%03d" % [minutes, seconds, milliseconds])


func toggle_round_timer() -> void:
	round_timer.paused = !round_timer.paused
	
func start_the_match() -> void:
	round_timer.paused = false
	
func start_ko_count() -> void:
	ko_timer.start(10.0)
	animation_player.play("ko_count")
	
func stop_ko_count() -> void:
	ko_timer.stop()
	animation_player.play("RESET")
	
func end_fight() -> void:
	print("FIGHT'S OVER")
	FightManager.fight_is_over_signal.emit()

func _on_round_timer_timeout() -> void:
	print('ROUND OVER; TIMES UP')

## Creates the timers with code so that  you don't have to make a round timer node and then manually assign it.
func create_timers() -> void:
	round_timer = Timer.new()
	round_timer.one_shot = true
	round_timer.wait_time = get_parent().match_settings.round_length
	round_timer.name = "Round Timer"
	get_parent().add_child.call_deferred(round_timer)
	
	ko_timer = Timer.new()
	ko_timer.one_shot = true
	ko_timer.wait_time = 10.0
	ko_timer.name = "KO Count Timer"
	round_timer.timeout.connect(_on_round_timer_timeout)
	get_parent().add_child.call_deferred(ko_timer)
