@icon("res://assets/icons/IconParkSolidArena.svg")

class_name Arena extends Node2D
@export_category("Fighters")
## Place the player or the controllable fighter node here.
@export var player_scene : PackedScene
## Place the opponent node here.
@export var enemy_scene : PackedScene
## The timer used for tracking the time left in the round.


@export var round_timer: Timer

var target_time_scale := 0.025
var secs := 1.25

@export_category("UI Elements")
## The player's health bar.
@export var player_bar: ProgressBar
## The enemy's health bar.
@export var enemy_bar: ProgressBar
## The label that displays the player's health bar.
@export var star_count_label: Label
## The label that displays the player's stamina.
@export var stamina_label: Label
##The label that displays the time left in the round..
@export var time_left_label: Label

@export var animation_player: AnimationPlayer

@export_category("Fight Variables")
@export_range(0.0, 180.0, 5.0, "suffix:s") var round_length: float = 180.0
@export_custom(PROPERTY_HINT_NONE, "suffix:rounds") var number_of_rounds : int = 3

@onready var ko_timer: Timer = %"KO Timer"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	var player_node = player_scene.instantiate()
	var enemy_node = enemy_scene.instantiate()
	Global.player_node = player_node
	Global.enemy_node = enemy_node
	
	add_child(player_node)
	add_child(enemy_node)
	
	player_node.health_component.health_changed.connect(update_ui)
	enemy_node.health_component.health_changed.connect(update_ui)
	FightManager.update_ui_signal.connect(update_ui)
	FightManager.enemy_knocked_down_signal.connect(toggle_round_timer)
	FightManager.player_knocked_down_signal.connect(toggle_round_timer)
	FightManager.resume_fighting_signal.connect(toggle_round_timer)
	FightManager.start_get_up_signal.connect(start_ko_count)
	FightManager.fighter_got_up_signal.connect(stop_ko_count)
	
	FightManager.enemy_knocked_down_signal.connect(slow_down_effect)
	FightManager.player_knocked_down_signal.connect(slow_down_effect)
	round_timer.start(round_length)
	round_timer.paused = true
	update_ui()
	
	FightManager.start_the_fight_signal.connect(start_the_match)
	await get_tree().create_timer(2.0).timeout
	FightManager.start_intro_animation_signal.emit()
	
func start_the_match():
	round_timer.paused = false
	
	
func _process(_delta: float) -> void:
	# Does the match to convert the seconds to M:SS format.
	FightManager.round_time = (round_timer.wait_time - round_timer.time_left)
	#print("ROUND TIME : ", FightManager.round_time)
	@warning_ignore("integer_division")
	var minutes: int = int(FightManager.round_time) / 60
	var seconds: int = int(fmod(FightManager.round_time, 60))
	var milliseconds : int = int((FightManager.round_time - int(FightManager.round_time)) * 1000)
	#var milli: int = int
	time_left_label.text = str( "%d'%02d\"%03d" % [minutes, seconds, milliseconds])
	
	#if ko_timer.is_stopped() == false:
		#print(round(ko_timer.wait_time - ko_timer.time_left))
	#
func slow_down_effect():
	Engine.time_scale = target_time_scale
	await get_tree().create_timer(secs * target_time_scale).timeout
	Engine.time_scale = 1.0
	
func toggle_round_timer() -> void:
	round_timer.paused = !round_timer.paused
	
func update_ui():
	player_bar.value = Global.player_node.health_component.hp
	enemy_bar.value = Global.enemy_node.health_component.hp
	star_count_label.text = str("Stars: ", FightManager.star_count)
	stamina_label.text = str("Stamina: ", FightManager.stamina)
	
func start_ko_count():
	ko_timer.start(10.0)
	animation_player.play("ko_count")
	
func stop_ko_count():
	ko_timer.stop()
	animation_player.play("RESET")

func end_fight():
	print("FIGHT'S OVER")
	FightManager.fight_is_over_signal.emit()

func _on_round_timer_timeout() -> void:
	print('ROUND OVER; TIMES UP')
