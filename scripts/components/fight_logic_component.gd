@icon("res://assets/icons/IconParkSolidBranchTwo.svg")
class_name FightLogicComponent extends Node
## Handles the logic of the fight itself.
##
## Handles the winner, the round time, the KO count, determining when the fight is over, etc...

## Signal emitted after the round timer has fully reached 0.000 time left.
signal time_is_over_signal

const RESULTS_SCREEN = preload("uid://b4unduv261ia0")
const CHARACTER_SELECTION_MENU = preload("uid://bvyokq5qbudmq")

## The timer that keeps track of how much time is left in the round.
var round_timer: Timer = null

## Stores if [member round_timer] has been fully started and the match is under way
## so that [method check_for_round_over] can start checking.
var can_start_checking : bool = false

@onready var animation_player: AnimationPlayer = %AnimationPlayer

func _ready() -> void:
	FightManager.enemy_knocked_down_signal.connect(toggle_round_timer)
	FightManager.player_knocked_down_signal.connect(toggle_round_timer)
	FightManager.resume_fighting_signal.connect(toggle_round_timer)
	FightManager.start_ko_count_signal.connect(start_ko_count)
	FightManager.fighter_got_up_signal.connect(stop_ko_count)
	
	# Have to call deferred otherwise it doesn't work for some reason.
	call_deferred("create_round_timer")
	
	time_is_over_signal.connect(_on_round_timer_timeout)
	
	FightManager.pause_ko_count_signal.connect(pause_ko_count)


func _process(_delta: float) -> void:
	
	# Sets the round time in Fight Manager as the the that has ellapsed in the round_timer.
	FightManager.round_time = snappedf((round_timer.wait_time - round_timer.time_left), 0.001)
	
	# Does the math to convert the seconds to M:SS:MSS format.
	@warning_ignore("integer_division")
	var minutes: int = int(FightManager.round_time) / 60
	var seconds: int = int(fmod(FightManager.round_time, 60))
	var milliseconds : int = int((FightManager.round_time - int(FightManager.round_time)) * 1000)
	owner.arena_ui.time_left_label.text = str( "%d'%02d\"%03d" % [minutes, seconds, milliseconds])
	check_for_round_over()

## Checks if the round is over via timeout.
func check_for_round_over() -> void:
	# This is done because the timer label can stop at a number like: 2'59"997 instead of 3'00"000.
	if can_start_checking == true and round_timer.is_stopped() == true:
		if FightManager.is_fight_over == false:
			time_is_over_signal.emit()

## Pauses/unpauses the [member round_timer] and starts it if it's stopped.
func toggle_round_timer() -> void:
	print_rich("[b]🧠 Fight Logic Component:[/b] Toggling round timer...")
	
	# Checks if the timer is stopped/hasn't been started.
	if round_timer.is_stopped() == true:
		
		# If it's stopped, start it and set the paused status to false.
		round_timer.start()
		round_timer.paused = false
		
		# Sets this as true to that check_for_fight_over() can work.
		can_start_checking = true
		return
		
	# If the timer has been started already, then toggle the pause.
	round_timer.paused = !round_timer.paused


## Plays the KO Count animation in the animation player.
func start_ko_count() -> void:
	
	# If the fight's still going, play the regular KO count animation.
	if FightManager.is_fight_over == false:
		print_rich("[b]🧠 Fight Logic Component:[/b] Starting KO count...")
		animation_player.play("ko_count")
		
	# If one of the fighters has 3 Knockdowns, meaning the fight is already over,
	# then play the TKO animation.
	elif FightManager.is_fight_over == true:
		animation_player.play("TKO")

## Pauses the KO count animation. Used for failed get ups.
func pause_ko_count() -> void:
	if animation_player.is_playing() == true:
		animation_player.pause()
	
	elif animation_player.is_playing() == false:
		animation_player.play()

## Stops the KO Count animation.
func stop_ko_count() -> void:
	
	# Waits a little to avoid cutting the voicelines.
	await get_tree().create_timer(0.5).timeout
	animation_player.play("RESET")

## Functions called be the TKO and KO Count animations.
## Handles setting the winner of the fight.
func end_fight() -> void:
	print_rich("[b]🧠 Fight Logic Component:[/b] Fighter could not get up.")
	stop_ko_count()
	
	FightManager.is_fight_over = true
	
	match true:
		Global.player_node.is_knocked_down:
			Global.winner = Global.WinnerEnum.ENEMY
			
		Global.enemy_node.is_knocked_down:
			Global.winner = Global.WinnerEnum.PLAYER
	print_rich("[b]🧠 Fight Logic Component:[/b] Winner: ", Global.WinnerEnum.find_key(Global.winner))
	
	FightManager.fight_is_over_signal.emit()

## Handles what to do when the round timer has reached zero.
func _on_round_timer_timeout() -> void:
	FightManager.fight_is_over_signal.emit()
	FightManager.is_fight_over = true
	get_tree().paused = true
	print_rich("[b]🧠 Fight Logic Component:[/b] Round is over; Time is up.")
	SceneChanger.change_scene(RESULTS_SCREEN, self)

## Creates the [member round_timer] with code.
func create_round_timer() -> void:
	round_timer = TimerCreator.create_timer_and_add_as_child("Round Timer", true, owner.match_settings.round_length, false, self)
