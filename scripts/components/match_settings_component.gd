@icon("res://assets/icons/MaterialSymbolsSettings.svg")

class_name MatchSettings extends Node
## This component stores the settings of the match.
##
## How many rounds, the round time, the heal amounts for the enemy and player, etc...


@export_category("🥊 Fight Variables")

## How long the a round is in seconds.
@export_range(0.0, 180.0, 1.0, "suffix:s") var round_length: float = 180.0

## How many rounds are there in the fight.
@export_range(0, 3, 1, "suffix:rounds") var number_of_rounds : int = 3
#@export var override_player_hp : bool = false
#@export var override_enemy_hp : bool = false

@export var player_invincible : bool = false
@export var enemy_invincible : bool = false


func _ready() -> void:
	if OS.is_debug_build() == false:
		round_length = 180.0
