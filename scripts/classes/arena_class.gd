@icon("res://assets/icons/IconParkSolidArena.svg")

class_name Arena extends Node2D
@export_category("Fighters")
## Place the player or the controllable fighter node here.
@export var player_scene : PackedScene
## Place the opponent node here.
@export var enemy_scene : PackedScene
## The timer used for tracking the time left in the round.




var target_time_scale := 0.025
var secs := 1.25


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


@onready var fight_logic_component : FightLogicComponent = %FightLogicComponent
@onready var match_settings : MatchSettings = %MatchSettings

var player_node = null
var enemy_node = null
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player_node = player_scene.instantiate()
	enemy_node = enemy_scene.instantiate()
	Global.player_node = player_node
	Global.enemy_node = enemy_node
	
	add_child(player_node)
	add_child(enemy_node)
	
	player_node.health_component.health_changed_signal.connect(update_ui)
	enemy_node.health_component.health_changed_signal.connect(update_ui)
	FightManager.update_ui_signal.connect(update_ui)
	
	FightManager.enemy_knocked_down_signal.connect(slow_down_effect)
	FightManager.player_knocked_down_signal.connect(slow_down_effect)
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
	if enemy_node !=null:
		state_label.text = enemy_node.state_machine.current_state.name
	
func update_ui() -> void:

	player_bar.value = Global.player_node.health_component.hp
	enemy_bar.value = Global.enemy_node.health_component.hp
	star_count_label.text = str("Stars: ", FightManager.star_count)
	stamina_label.text = str("Stamina: ", FightManager.stamina)
	
