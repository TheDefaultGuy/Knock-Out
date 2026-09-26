extends Control

## The player's health bar.
@onready var player_bar: ProgressBar = $PlayerBar

## The enemy's health bar.
@onready var enemy_bar: ProgressBar = $EnemyBar

## The label that displays the player's health bar.
@onready var star_count_label: Label = $StarCountLabel

## The label that displays the player's stamina.
@onready var stamina_label: Label = $StaminaLabel

##The label that displays the time left in the round..
@onready var time_left_label: Label = $TimeLeftLabel
@onready var state_label: Label = $StateLabel

@onready var ko: Label = $KO

@onready var player_ko_counter: HBoxContainer = $"Ko Counters/Player"
@onready var enemy_ko_counter: HBoxContainer = $"Ko Counters/Enemy"

func _ready() -> void:
	state_label.visible = OS.is_debug_build()

# Called when the node enters the scene tree for the first time.
func connect_signals() -> void:
	
	owner.player_node.health_component.health_changed_signal.connect(update_ui)
	owner.enemy_node.health_component.health_changed_signal.connect(update_ui)
	FightManager.update_ui_signal.connect(update_ui)
	
	FightManager.enemy_knocked_down_signal.connect(enemy_ko_counter.update_ko_counters)
	FightManager.player_knocked_down_signal.connect(player_ko_counter.update_ko_counters)
	update_ui()

func _process(_delta: float) -> void:
	if Global.enemy_node != null:
		state_label.text = Global.enemy_node.state_machine.current_state.name

func update_ui() -> void:
	player_bar.value = Global.player_node.health_component.hp
	enemy_bar.value = Global.enemy_node.health_component.hp
	star_count_label.text = str("Stars: ", FightManager.star_count)
	stamina_label.text = str("Stamina: ", FightManager.stamina)
