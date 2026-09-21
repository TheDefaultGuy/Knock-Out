@icon("res://assets/icons/IconParkSolidArena.svg")

class_name Arena extends Node2D
## The main scene where fights take place.
##
## You can select the player and enemy scenes.

@export_category("Fighters")
## Place the [Player] or the controllable fighter node here.
@export var player_scene : PackedScene = null

## Place the [Enemy] node here.
@export var enemy_scene : PackedScene = null

const RESULTS_SCREEN = preload("uid://b4unduv261ia0")


## Stores the [Player] node/scene.
var player_node = null

## Stores the [Enemy] node/scene.
var enemy_node = null

var lerp_timer : Timer = null

#var enemy_starting_hp : float = 0.0
#var player_starting_hp : float = 0.0

var target_time_scale := 0.025
var secs := 1.25

#@onready var player_bar_front: ProgressBar = $Camera2D/UI/PlayerBarFront
#@onready var enemy_bar_front: ProgressBar = $Camera2D/UI/EnemyBarFront

## The player's health bar.
@onready var player_bar: ProgressBar = $Camera2D/UI/PlayerBar

## The enemy's health bar.
@onready var enemy_bar: ProgressBar = $Camera2D/UI/EnemyBar

## The label that displays the player's health bar.
@onready var star_count_label: Label = $Camera2D/UI/StarCountLabel

## The label that displays the player's stamina.
@onready var stamina_label: Label = $Camera2D/UI/StaminaLabel

##The label that displays the time left in the round..
@onready var time_left_label: Label = $Camera2D/UI/TimeLeftLabel
@onready var state_label: Label = $Camera2D/UI/StateLabel


@onready var player_ko_counter: HBoxContainer = $"Camera2D/UI/Ko Counters/Player"
@onready var enemy_ko_counter: HBoxContainer = $"Camera2D/UI/Ko Counters/Enemy"

@onready var fight_logic_component : FightLogicComponent = %FightLogicComponent
@onready var match_settings : MatchSettings = %MatchSettings


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	
	player_node = player_scene.instantiate()
	enemy_node = enemy_scene.instantiate()
	Global.player_node = player_node
	Global.enemy_node = enemy_node
	
	add_child(player_node)
	add_child(enemy_node)
	#create_lerp_timer()
	player_node.health_component.health_changed_signal.connect(update_ui)
	enemy_node.health_component.health_changed_signal.connect(update_ui)
	FightManager.update_ui_signal.connect(update_ui)
	
	FightManager.enemy_knocked_down_signal.connect(slow_down_effect)
	FightManager.player_knocked_down_signal.connect(slow_down_effect)
	
	FightManager.enemy_knocked_down_signal.connect(enemy_ko_counter.update_ko_counters)
	FightManager.player_knocked_down_signal.connect(player_ko_counter.update_ko_counters)
	
	FightManager.go_to_results_screen_signal.connect(go_to_results_screen)
	update_ui()
	
	if match_settings == null:
		printerr(self.name, ": Match Settings Component has not been assigned.")
	if fight_logic_component == null:
		printerr(self.name, ": Fight Logic Component has not been assigned.")

func slow_down_effect() -> void:
	Engine.time_scale = target_time_scale
	await get_tree().create_timer(secs * target_time_scale).timeout
	Engine.time_scale = 1.0
	
	
func _process(_delta: float) -> void:
	if enemy_node != null:
		state_label.text = enemy_node.state_machine.current_state.name
	
func update_ui() -> void:
	player_bar.value = Global.player_node.health_component.hp
	enemy_bar.value = Global.enemy_node.health_component.hp
	star_count_label.text = str("Stars: ", FightManager.star_count)
	stamina_label.text = str("Stamina: ", FightManager.stamina)
	#enemy_starting_hp = enemy_bar_front.value
	#player_starting_hp = player_bar_front.value
	#
#func lerp_the_health_bars() -> void:
	#player_bar.value = lerp(player_starting_hp, player_bar_front.value, 1 - lerp_timer.time_left)
	#enemy_bar.value = lerp(enemy_starting_hp, enemy_bar_front.value, 1 - lerp_timer.time_left)
	#
#func create_lerp_timer() -> void:
	#lerp_timer = Timer.new()
	#lerp_timer.wait_time = 1.0
	#lerp_timer.one_shot = true
	
func go_to_results_screen() -> void:
	var results : Control = RESULTS_SCREEN.instantiate()
	get_tree().change_scene_to_node(results)
	self.queue_free()
