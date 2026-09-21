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

@onready var fight_logic_component : FightLogicComponent = %FightLogicComponent
@onready var match_settings : MatchSettings = %MatchSettings

@onready var arena_ui: Control = %"Arena UI"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player_node = player_scene.instantiate()
	enemy_node = enemy_scene.instantiate()
	
	Global.player_node = player_node
	Global.enemy_node = enemy_node
	
	add_child(player_node)
	add_child(enemy_node)
	
	FightManager.enemy_knocked_down_signal.connect(slow_down_effect)
	FightManager.player_knocked_down_signal.connect(slow_down_effect)
	
	FightManager.go_to_results_screen_signal.connect(go_to_results_screen)
	
	
	if match_settings == null:
		printerr(self.name, ": Match Settings Component has not been assigned.")
	if fight_logic_component == null:
		printerr(self.name, ": Fight Logic Component has not been assigned.")
	
	arena_ui.connect_signals()

func slow_down_effect() -> void:
	Engine.time_scale = target_time_scale
	await get_tree().create_timer(secs * target_time_scale).timeout
	Engine.time_scale = 1.0

func go_to_results_screen() -> void:
	var results : Control = RESULTS_SCREEN.instantiate()
	get_tree().change_scene_to_node(results)
	self.queue_free()
