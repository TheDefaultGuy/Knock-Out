extends Control

const HP_BAR_TWEEN_DURATION_SHORT : float = 0.075
const HP_BAR_TWEEN_DURATION_LONG : float = 0.5
const HP_BAR_TWEEN_DURATION_KNOCKDOWN : float = 1.5

## How long the [member accumulation_timer] waits until depleting the white progress bar.
const ACCUMULATION_WAIT_TIME : float = 1.0

var accumulation_timer : Timer = null

## The label that displays the player's star amount.
@onready var star_count_label: Label = %StarCountLabel

## The label that displays the player's stamina.
@onready var stamina_label: Label = %StaminaLabel

##The label that displays the time left in the round..
@onready var time_left_label: Label = %TimeLeftLabel

@onready var state_label: Label = %StateLabel

## The label that displays the player's points.
@onready var points_label: Label = %PointsLabel

@onready var ko: Label = %KO

@onready var player_ko_counter: HBoxContainer = %Player
@onready var enemy_ko_counter: HBoxContainer = %Enemy

@onready var enemy_front_bar: ProgressBar = $"MarginContainer/HBoxContainer/VBoxContainer/Health Bars/Enemy Health Bar/Front Bar"
@onready var enemy_back_bar: ProgressBar = $"MarginContainer/HBoxContainer/VBoxContainer/Health Bars/Enemy Health Bar/Back Bar"

@onready var player_front_bar: ProgressBar = $"MarginContainer/HBoxContainer/VBoxContainer/Health Bars/Player Health Bar/Front Bar"
@onready var player_back_bar: ProgressBar = $"MarginContainer/HBoxContainer/VBoxContainer/Health Bars/Player Health Bar/Back Bar"

@onready var enemy_damage: Label = %EnemyDamage
@onready var player_damage: Label = %PlayerDamage
@onready var attack_multipler_label: Label = %AttackMultiplierLabel

func _ready() -> void:
	state_label.visible = OS.is_debug_build() and !OS.has_feature("mobile")
	enemy_front_bar.show_percentage = OS.is_debug_build() and !OS.has_feature("mobile")
	player_front_bar.show_percentage = OS.is_debug_build() and !OS.has_feature("mobile")
	enemy_damage.visible = OS.is_debug_build() and !OS.has_feature("mobile")
	player_damage.visible = OS.is_debug_build() and !OS.has_feature("mobile")
	attack_multipler_label.visible = OS.is_debug_build() and !OS.has_feature("mobile")
	
	accumulation_timer = TimerCreator.create_timer_and_add_as_child("Acc Timer", true, ACCUMULATION_WAIT_TIME, false, self)
	accumulation_timer.timeout.connect(_on_timer_timeout)
	


# Called when the node enters the scene tree for the first time.
func connect_signals() -> void:
	
	owner.player_node.health_component.health_changed_signal.connect(handle_health_change_player)
	owner.enemy_node.health_component.health_changed_signal.connect(handle_health_change_enemy)
	FightManager.update_ui_signal.connect(update_ui)
	
	FightManager.enemy_knocked_down_signal.connect(enemy_ko_counter.update_ko_counters)
	FightManager.player_knocked_down_signal.connect(player_ko_counter.update_ko_counters)
	
	Global.player_node.attacking_component.attack_multiplier_changed_signal.connect(update_attack_multiplier_label)
	
	
	Global.player_node.health_component.damage_taken_signal.connect(update_player_damage_label)
	Global.enemy_node.health_component.damage_taken_signal.connect(update_enemy_damage_label)
	
	update_ui()

func _process(_delta: float) -> void:
	if Global.enemy_node != null:
		state_label.text = Global.enemy_node.state_machine.current_state.name

func _on_timer_timeout() -> void:
	# Animates the enemy's white bar after the accumulation timer is over.
	animate_bar(enemy_back_bar, HP_BAR_TWEEN_DURATION_LONG, Global.enemy_node.health_component.hp)

func update_player_damage_label(amount : float) -> void:
	player_damage.text = str(amount)
	
func update_enemy_damage_label(amount : float) -> void:
	enemy_damage.text = str(amount)

func update_attack_multiplier_label() -> void:
	attack_multipler_label.text = str("x", Global.player_node.attacking_component.attack_multiplier)

func handle_health_change_player() -> void:
	
	if player_front_bar.value < Global.player_node.health_component.hp:
		animate_bar(player_back_bar, HP_BAR_TWEEN_DURATION_SHORT, Global.player_node.health_component.hp)
		await get_tree().create_timer(0.1).timeout
		animate_bar(player_front_bar, HP_BAR_TWEEN_DURATION_KNOCKDOWN, Global.player_node.health_component.hp)
		return
	
	animate_bar(player_front_bar, HP_BAR_TWEEN_DURATION_SHORT, Global.player_node.health_component.hp)
	await get_tree().create_timer(0.1).timeout
	animate_bar(player_back_bar, HP_BAR_TWEEN_DURATION_LONG, Global.player_node.health_component.hp)

func handle_health_change_enemy() -> void:
	if enemy_front_bar.value < Global.enemy_node.health_component.hp:
		animate_bar(enemy_back_bar, HP_BAR_TWEEN_DURATION_SHORT, Global.enemy_node.health_component.hp)
		
		await get_tree().create_timer(0.1).timeout
		animate_bar(enemy_front_bar, HP_BAR_TWEEN_DURATION_KNOCKDOWN, Global.enemy_node.health_component.hp)
		return
		
	animate_bar(enemy_front_bar, HP_BAR_TWEEN_DURATION_SHORT, Global.enemy_node.health_component.hp)
	
	# Starts the accumulation_timer after storing the HP.
	accumulation_timer.start()

func update_ui() -> void:
	star_count_label.text = str("Stars: ", FightManager.star_count)
	stamina_label.text = str("Stamina: ", FightManager.stamina)
	points_label.text = str("Points: ", PointsManager.points)
	
## Animates the progress bars depleting.
func animate_bar(bar : ProgressBar, duration : float, hp_value : float) -> void:
	var tween : Tween = create_tween()
	if duration < 0.2:
		tween.tween_property(bar, "value", hp_value , duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
		return
	tween.tween_property(bar, "value", hp_value , duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
