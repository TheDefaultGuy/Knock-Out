@icon("res://assets/icons/MaterialSymbolsSettings.svg")

## This component stores the settings of the match.
## How many rounds, the round time, the heal amounts for the enemy and player, etc...
class_name MatchSettings extends Node

@export_category("🥊 Fight Variables")
@export_range(0.0, 180.0, 5.0, "suffix:s") var round_length: float = 180.0
@export_custom(PROPERTY_HINT_RANGE, "suffix:rounds") var number_of_rounds : int = 3
#@export var override_player_hp : bool = false
#@export var override_enemy_hp : bool = false

@export var player_invincible : bool = false
@export var enemy_invincible : bool = false
