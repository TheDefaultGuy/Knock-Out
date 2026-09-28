@icon("res://assets/icons/IconParkSolidArena.svg")

class_name Arena extends Node2D
## The main scene where fights take place.
##
## You can select the player and enemy scenes.

const RESULTS_SCREEN = preload("uid://b4unduv261ia0")
const CHARACTER_SELECTION_MENU = preload("uid://bvyokq5qbudmq")

@export_category("Fighters")
## Place the [Player] or the controllable fighter node here.
@export var player_scene : PackedScene = null

## Place the [Enemy] node here.
@export var enemy_scene : PackedScene = null

## Curve dictating how the slow motion easing will be like.
@export var slow_motion_curve : Curve

## Stores the [Player] node/scene.
var player_node = null

## Stores the [Enemy] node/scene.
var enemy_node = null

## Stores whether it's currently slow motion or not.
var is_slow_motion : bool = false

## Stores the delta time that has passed in slow motion.
## Sampled by the [member slow_motion_curve].
var slow_mo_time_passed : float = 0.0

@onready var fight_logic_component : FightLogicComponent = %FightLogicComponent
@onready var match_settings : MatchSettings = %MatchSettings
@onready var arena_ui: Control = %"Arena UI"

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	
	# Instantiates the player and enemy packed scenes into nodes.
	player_node = player_scene.instantiate()
	enemy_node = enemy_scene.instantiate()
	
	# Sets the Global player and enemy nodes to be the instantiated scenes.
	Global.player_node = player_node
	Global.enemy_node = enemy_node
	
	# Adds the nodes as children.
	add_child(player_node)
	add_child(enemy_node)
	
	FightManager.enemy_knocked_down_signal.connect(slow_down_effect)
	FightManager.player_knocked_down_signal.connect(slow_down_effect)
	
	FightManager.go_to_results_screen_signal.connect(SceneChanger.change_scene.bind(RESULTS_SCREEN, self))
	
	FightManager.is_fight_over = false
	
	
	if match_settings == null:
		printerr(self.name, ": Match Settings Component has not been assigned.")
	if fight_logic_component == null:
		printerr(self.name, ": Fight Logic Component has not been assigned.")
	
	arena_ui.connect_signals()

func _process(delta: float) -> void:
	if is_slow_motion == true:
		
		# Update how much time has passed by adding the delta.
		slow_mo_time_passed += delta
		
		# Samples the slow motion curve to achieve the slow motion effect.
		Engine.time_scale = slow_motion_curve.sample(slow_mo_time_passed)
		
		# If time scale is back to normal, then it's no longer slow motion.
		if Engine.time_scale == 1.0: 
			is_slow_motion = false
			return

func _exit_tree() -> void:
	FightManager.enemy_knocked_down_signal.disconnect(slow_down_effect)
	FightManager.player_knocked_down_signal.disconnect(slow_down_effect)
	FightManager.go_to_results_screen_signal.disconnect(SceneChanger.change_scene.bind(RESULTS_SCREEN, self))

#func _input(_event: InputEvent) -> void:
	#if Input.is_action_pressed("esc"):
		#get_tree().paused = not get_tree().paused
	

## Sets [member is_slow_motion] to [code]true[/code] and resets [member slow_mo_time_passed] back to 0.0 so that the [member slow_motion_curve] can be sampled.
func slow_down_effect() -> void:
	slow_mo_time_passed = 0.0
	is_slow_motion = true
