class_name VariableDebugTool extends Resource

@export var override_values : bool = false

## The number of stars the player currently has.
@export var star_count : int = 0 :
	set(value):
		if override_values == true :
			FightManager.star_count = star_count

## The Player's stamina
@export var stamina : int = 10 :
	set(value):
		if override_values == true :
			FightManager.stamina = stamina

## Number of times the player has been knocked down in the current round.
@export var player_ko_count : int = 0 :
	set(value):
		if override_values == true :
			FightManager.player_ko_count = player_ko_count

## Number of times the player has been knocked down in the current round.
@export var enemy_ko_count : int = 0 :
	set(value):
		if override_values == true :
			FightManager.enemy_ko_count = enemy_ko_count

## Which round of the fight it currently is. 0 = 1st round, 1 = 2nd round , 2 = 3rd round.
var round_idx : int = 0 

## The maximum players stamina.
@export var max_player_stamina : int = 12 :
	set(value):
		if override_values == true :
			FightManager.max_player_stamina = max_player_stamina
